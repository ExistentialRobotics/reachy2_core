# Joint limits audit (DVT / real robot, image `1.7.5.9_release`)

Symptom: on the real robot configured as DVT, reported `/joint_states` values fall
outside the joint limits declared in the robot description, which makes MoveIt reject
plans ("start state out of bounds") and RViz/`robot_state_publisher` complain.

## Where limits live

There are three independent sources of "limits" in this stack, and nothing keeps them
in sync:

| Source | File | Applies to |
| --- | --- | --- |
| URDF `<limit>` | `reachy_description/urdf/*.xacro` + the `orbita2d_description` / `orbita3d_description` packages shipped in the base image | MoveIt bounds, RViz, `joint_trajectory_controller` |
| Actuator software limits | `reachy_config/config/default/*.yaml` (`orientation_limits`), overridable per robot from `~/.reachy_config_override` | Orbita command clamping only |
| Mechanical hard stops | comments in the same YAML ("touching at ...") | physics |

Two facts make the mismatch visible:

* `Orbita2dController::set_target_orientation` clamps the **target** against
  `orientation_limits`. `Orbita2dSystem::read()` copies the measured orientation into
  the state interface **unclamped**. So `/joint_states` is bounded by the mechanics, not
  by the URDF.
* MoveIt is launched with `start_state_max_bounds_error: 0.1`
  (`reachy_bringup/launch/reachy.launch.py:131`), so it only absorbs 0.1 rad of
  out-of-bounds start state. Anything larger is a hard planning failure.

## Findings

### 1. `*_shoulder_roll` — URDF bound is 0.0, hardware reaches ±0.55 (root cause, fixed here)

`reachy_description/urdf/arm.urdf.xacro` declared:

```
left :  min_shoulder_roll = -0.0   max = pi
right:  min_shoulder_roll = -pi    max =  0.0
```

while `reachy_config/config/default/{right,left}_shoulder_poulpe2d.yaml` allow
`[-2.9, 0.55]` / `[-0.55, 2.9]` (hard stops at ±0.61), and the simulation configs
`fake_{r,l}_shoulder.yaml` allow `[-3.14, 0.51]` / `[-0.51, 3.14]`.

The URDF bound sits exactly on 0.0, i.e. on the neutral pose, so the joint crosses it
constantly and can be up to 0.55 rad outside — 5x the MoveIt tolerance.

Upstream `pollen-robotics/reachy2_core` fixed this in commit `04f3b11`
("Fix shoulder roll limits.", 2025-10-27), released in **v1.7.6**. This fork branched
from upstream at `0c79e40` (2025-08-25, the v1.7.5 line), which is why the running
`1.7.5.9` image still has the old value.

**Fixed**: `min/max_shoulder_roll` are now `∓0.51`, matching upstream and the fake
configs. The stale `reachy_description/urdf/reachy2.urdf` snapshot was updated to match.

Residual: the actuator still clamps commands at 0.55 while the URDF says 0.51, so up to
0.04 rad of out-of-bounds state is still possible. That is inside MoveIt's 0.1 rad
tolerance, so it is harmless; close it fully by either widening the URDF to 0.55 or
tightening `orientation_limits` to 0.51 in `~/.reachy_config_override`.

### 2. `*_wrist_roll` / `*_wrist_pitch` / `neck_roll` / `neck_pitch` — ±0.35 rad in URDF, no software limit at all

`orbita3d_description/urdf/orbita3d.urdf.xacro` in the `1.7.5.9` image (orbita3d_control
v1.1.5) declares `lower="-0.35" upper="0.35"` for roll and pitch. The Orbita3D platform
mechanically reaches a 42.5° cone (0.7418 rad) — more than twice that.

Worse, there is **no software limit** on these joints: `Orbita3dConfig`
(`orbita3d_controller/src/lib.rs`) has no `orientation_limits` field, so the
`orientation_limits: {orbita3D_max_angle: 0.7417649320975901}` block in
`reachy_config/config/default/{right,left}_wrist_poulpe3d.yaml` is a dead key that serde
silently ignores. `neck.yaml` does not even declare one.

Upstream fixed the URDF side in orbita3d_control `da373b8` ("Update angle limits of
O3D."), released in **v1.1.6** (2026-01-06) — after the `1.7.5.9` image was built:
`-0.35/0.35` → `-0.70/0.70`.

This cannot be fixed from this repository — the limits live in `orbita3d_description`
in the base image. Options:

1. Rebuild/bump the base image so it carries orbita3d_control ≥ v1.1.6, or patch
   `orbita3d_description/urdf/orbita3d.urdf.xacro` in the `Dockerfile`.
2. As a stopgap, raise `start_state_max_bounds_error` — but note the gap is up to
   0.39 rad, so this only masks the problem.

Even v1.1.6's ±0.70 is slightly narrower than the 0.7418 rad mechanical cone.

### 3. `*_shoulder_pitch` / `*_elbow_yaw` — hardware is effectively unlimited

All four `*_poulpe2d.yaml` files set axis 1 to:

```yaml
- !AngleLimits:
    min: -10000.0 # todo make better limts
    max:  10000.0 # todo make better limts
```

The URDF declares `[-pi, pi]`. Nothing clamps commands and nothing wraps the measured
angle, so any accumulated/multi-turn reading is reported verbatim and lands outside the
URDF bounds. These placeholders should be replaced with the real mechanical range.

### 4. `*_elbow_pitch` — fine on hardware, out of bounds in simulation

URDF `[-2.25, 0.1]`; real configs `[-2.22, 0.02]` (inside — OK); but
`reachy_config/config/fake/fake_{r,l}_elbow.yaml` use `[-2.26, 0.06]`, whose lower bound
is 0.01 rad *below* the URDF bound. Simulation can therefore report an out-of-bounds
elbow. Left unchanged here to avoid altering sim behaviour as part of a hardware fix.

### 5. Minor / housekeeping

* `reachy_description/urdf/reachy2.urdf` is a 3.6k-line generated snapshot with **no
  consumers** in the workspace. It is a trap: it still encodes the ±0.35 wrist bounds.
  It should be regenerated from the xacro at build time or deleted.
* `orbita2d.urdf.xacro` emits `<safety_controller soft_lower_limit="-3.1415"
  soft_upper_limit="3.1415">` regardless of the joint limits actually passed in. MoveIt
  intersects safety limits with hard limits, so the only visible effect is that
  `l_shoulder_roll`/`*_shoulder_pitch`/`*_elbow_yaw` upper bounds become 3.1415 instead
  of π (9.3e-5 rad tighter). Harmless, but the soft limits are useless as written.
* `reachy_config/config/default/neck.yaml` in this fork dropped the
  `name: NeckOrbita3d` field that upstream has, while
  `robot_ethercat_config.yaml` still declares slave 0 as `NeckOrbita3d`. Unrelated to
  limits, but worth reconciling.

## How to verify on the robot

```bash
ros2 param get /robot_state_publisher robot_description > /tmp/live.urdf   # what is really loaded
ros2 topic echo --once /joint_states
```

Then compare each `<limit>` in `/tmp/live.urdf` against the measured positions. In
particular check whether `*_wrist_roll`/`*_wrist_pitch` show `±0.35` or `±0.70` — that
tells you which `orbita3d_description` version the image carries.

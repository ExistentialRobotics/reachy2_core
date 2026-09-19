# Hardware alignment and description snapshot

Implemented 2026-09-19. This is source alignment, not certification of a particular
robot. No physical device was connected or moved during validation.

## Source basis

- Official `develop`: `b7000c1255f322826f4d0ad1f1e54d424e55c051`, already in ERL.
- ERL starting point: `c73a72f7820cb7ef1053c795d3f3114e7032ef61` (`sh_dev`).
- Ported `40eb4c5bc95ee6b43ca42a3d34dddf3188a75356`: both Orbbec driver
  `camera_name=torso_camera` and its `torso_camera_link` URDF attachment.
- Ported `01b329a3e78b5172793502c29577affddbd91fb2`: head ToF Gazebo stream.
- PR #7 is closed without merging. Porting these changes does not imply that all
  changes from its hardware branch have been merged.
- Shoulder bounds were already present; neither `d2b0ca9` nor `5e683c6` was reapplied.

## Camera meaning

`depth_cam_{l,r,rgb}_*` again use the official torso parents and transforms.
The RGB optical origin is `(0.058, 0.0155, -0.030)` in torso coordinates;
the camera looks 47.5 degrees down. The head RGB and ToF parents are unchanged.

The separate ERL `torso_camera` mount remains `(0.05, 0, 0)` with no mounting
rotation. Its child `torso_camera_link` connects the Orbbec driver's calibrated
stream frames. This is a **different nominal mount**, not proof of alignment with
the official RGB optical frame or the actual robot. Retaining connectivity must
not be interpreted as calibration. Check live TF, mounting/CAD and CameraInfo.
The driver should publish its own stream transforms; do not add duplicate URDF
parents for those frames.

The ToF Gazebo model uses 640x480, horizontal FOV 1.2207509 rad
(`fx=fy=457.484 px`), 0.1–6 m clipping and 0.007 m Gaussian noise from the ERL
implementation. These are approximations, not verified calibration. The previous
claim that recorded `fy` was a placeholder is not adopted as established fact.
Check the emitted topics against the installed Gazebo camera plugin on ROS.

## Reproducible snapshot

`tools/description-lock.json` pins Xacro 2.1.1 and each source dependency. Notably,
Zuuu comes from `pollen-robotics/mobile_base/zuuu_description`; the older standalone
`zuuu_description` repository changes the wheel and lidar geometry and is not used.

Requires Python 3 and PyYAML. From this repository root, clone the lock once into
an empty directory (the example uses `/tmp/reachy-hardware-deps`):

```python
import json
from pathlib import Path
import subprocess
root = Path('/tmp/reachy-hardware-deps')
root.mkdir(parents=True, exist_ok=True)
for name, spec in json.loads(Path('tools/description-lock.json').read_text())['repositories'].items():
    target = root / name
    subprocess.run(['git', 'clone', spec['url'], str(target)], check=True)
    subprocess.run(['git', '-C', str(target), 'checkout', '--detach', spec['commit']], check=True)
```

```sh
python tools/generate_description.py --deps-root /tmp/reachy-hardware-deps
python tools/generate_description.py --deps-root /tmp/reachy-hardware-deps --check
python tools/generate_description.py --deps-root /tmp/reachy-hardware-deps --gazebo --output /tmp/reachy-gazebo.urdf
python -m pytest -q test/test_launch_configuration.py
```

The generator rejects a wrong SHA or tracked dependency edits. Only Xacro package
lookup is redirected to the locked source trees; macros are expanded by Xacro.
The snapshot is full-kit DVT, fake hardware, non-Gazebo/non-MuJoCo, depth enabled.
Generated mesh paths use package URIs. Control configuration paths use the stable
`/opt/reachy-description/share` prefix: this snapshot is for geometry consumers,
**not a standalone hardware control configuration**. Real launch expands the
Xacro with installed packages and the robot's own configuration as before.

The generated XML drops comments and standardizes whitespace, so the textual diff
is larger than the semantic change. Compared with the starting snapshot, existing
joint origins/axes/limits and link inertials are unchanged except for the seven
intended `depth_cam_*` fixed transforms. Three torso camera links and joints are
added: 103 links, 102 joints before downstream normalization.

## Launch behavior and verification

| Mode | Clock | EtherCAT / Orbbec | Simulation interface |
|---|---|---|---|
| Real | Wall | EtherCAT; Orbbec when enabled | None |
| Fake | Wall | Neither | One |
| Gazebo | Simulation | Neither | One |
| MuJoCo | Simulation | Neither | One |

MoveIt files and its node/event handler are constructed only when enabled.
RViz receives MoveIt parameters only in that case. MuJoCo alone requires the
selected scene XML; launch declaration does not scan the scene directory.
Gazebo and MuJoCo cannot both be enabled. The mobile-base include receives fake
mode for every non-real mode (also suppressing the real lidar), and an explicit
MuJoCo flag. Video SDK uses simulation input in every non-real mode.

Validation completed:

- Pinned snapshot regenerated twice with byte-identical output (`--check`).
- Gazebo variant expands successfully and includes the ToF optical frame/topic
  remappings.
- 17 launch construction tests pass: 4 modes x MoveIt on/off x default/trajectory
  controllers, plus invalid simulator combination/missing scene checks.
- Launch tests use inert ROS doubles. They verify construction and selected
  actions without launching processes; they are **not ROS integration tests**.
- Downstream `reachy_task` geometry tests and an Isaac 34-joint / five-camera
  rendering smoke test passed (see the parent handoff).

No ROS installation is available on the validation host. ROS package loading,
controller lifecycle, `/clock` publication, live TF and camera driver/Gazebo stream
behavior remain integration checks on the matching ROS workspace. Do not count
those checks as passed based on the Python construction tests.

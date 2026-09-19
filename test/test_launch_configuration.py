"""Evaluate launch construction with inert ROS doubles, never starting processes.

These tests check Python branching and emitted actions, not ROS integration.
"""

import ast
import os
from pathlib import Path
from types import SimpleNamespace

import pytest


class Action:
    def __init__(self, *args, **kwargs):
        self.args, self.kw = args, kwargs

    def execute(self, *args, **kwargs):
        pass


class LaunchConfiguration(Action):
    def perform(self, context):
        return context[self.args[0]]


class PythonExpression(Action):
    def perform(self, context):
        return eval(self.args[0], {"__builtins__": {}})


class IfCondition(Action):
    def evaluate(self, context):
        value = self.args[0].perform(context)
        return value is True or value == "true"


def setup(monkeypatch, tmp_path, moveit):
    path = (
        Path(__file__).resolve().parents[1] / "reachy_bringup/launch/reachy.launch.py"
    )
    tree = ast.parse(path.read_text())
    imported = [
        a.asname or a.name
        for node in tree.body
        if isinstance(node, ast.ImportFrom)
        for a in node.names
    ]
    tree.body = [
        node for node in tree.body if not isinstance(node, (ast.Import, ast.ImportFrom))
    ]
    ns = {name: type(name, (Action,), {}) for name in imported}
    ns.update(
        os=os,
        LaunchConfiguration=LaunchConfiguration,
        PythonExpression=PythonExpression,
        IfCondition=IfCondition,
    )
    exec(compile(tree, str(path), "exec"), ns)
    config = SimpleNamespace(
        model="full_kit",
        beta=False,
        mobile_base={"enable": True},
        config={
            "robot_ethercat_config": {"path": "/unused"},
            "reachy": {"path": "/unused"},
        },
        part_conf=lambda *a, **kw: "/unused/config.yaml",
    )
    ns.update(
        ReachyConfig=lambda: config,
        log_config=str,
        title_print=lambda *a: Action(),
        clear_bags_and_logs=lambda **kw: None,
        get_current_run_log_dir=lambda: "/unused",
        get_node_list=lambda nodes, context: [],
        build_watchers_from_node_list=lambda nodes: [],
        ROSBAG_TOPICS=[],
        BETA="beta",
        DVT="dvt",
        FULL_KIT="full_kit",
        HEADLESS="headless",
        MINI="mini",
        STARTER_KIT_LEFT="starter_kit_left",
        STARTER_KIT_RIGHT="starter_kit_right",
        ReachyCoreMode=SimpleNamespace(GAZEBO=1, MUJOCO=2, FAKE=3, REAL=4),
    )
    reads = []

    def load(package, filename):
        assert moveit, "MoveIt disabled but package accessed"
        reads.append(filename)
        return "<robot/>" if filename.endswith(".srdf") else {}

    ns.update(load_file=load, load_yaml=load, SCENES_DIR=str(tmp_path / "absent"))
    return ns, reads


def walk(value, context):
    if isinstance(value, Action):
        condition = value.kw.get("condition")
        if condition is not None and not condition.evaluate(context):
            return
        yield value
        for key in ("actions", "event_handler", "on_exit"):
            yield from walk(value.kw.get(key), context)
        if type(value).__name__ == "LaunchDescription":
            yield from walk(value.args[0], context)
    elif isinstance(value, (tuple, list)):
        for entry in value:
            yield from walk(entry, context)


def context(mode="real", moveit=False, controllers="default"):
    return dict(
        start_rviz="true",
        fake=str(mode == "fake").lower(),
        gazebo=str(mode == "gazebo").lower(),
        mujoco=str(mode == "mujoco").lower(),
        start_sdk_server="true",
        controllers=controllers,
        foxglove="false",
        orbbec="true",
        log="WARN",
        moveit=str(moveit).lower(),
        scene="base",
    )


@pytest.mark.parametrize("mode", ["real", "fake", "gazebo", "mujoco"])
@pytest.mark.parametrize("moveit", [False, True])
@pytest.mark.parametrize("controllers", ["default", "trajectory"])
def test_mode_matrix(monkeypatch, tmp_path, mode, moveit, controllers):
    ns, reads = setup(monkeypatch, tmp_path, moveit)
    # Even declaration must not need a MuJoCo directory.
    ns["generate_launch_description"]()
    if mode == "mujoco":
        scene_dir = Path(ns["SCENES_DIR"])
        scene_dir.mkdir()
        (scene_dir / "base_scene.xml").write_text("<mujoco/>")
    ctx = context(mode, moveit, controllers)
    actions = list(walk(ns["launch_setup"](ctx), ctx))
    assert bool(reads) == moveit
    assert sum(a.kw.get("executable") == "move_group" for a in actions) == int(moveit)
    assert sum(a.kw.get("name") == "ethercat_master_server" for a in actions) == int(
        mode == "real"
    )
    assert sum(a.kw.get("executable") == "fake_gz_interface" for a in actions) == int(
        mode != "real"
    )
    assert sum(a.kw.get("executable") == "ros2_control_node" for a in actions) == int(
        mode in ("real", "fake")
    )
    assert sum(a.kw.get("executable") == "mujoco_ros2_control" for a in actions) == int(
        mode == "mujoco"
    )
    includes = [a for a in actions if type(a).__name__ == "IncludeLaunchDescription"]
    orbbec = [
        a for a in includes if "camera_name" in dict(a.kw.get("launch_arguments", []))
    ]
    assert len(orbbec) == int(mode == "real")
    sim = mode in ("gazebo", "mujoco")
    assert [a.args[0] for a in actions if type(a).__name__ == "SetUseSimTime"] == [sim]
    for a in actions:
        for p in a.kw.get("parameters", []):
            if isinstance(p, dict) and "use_sim_time" in p:
                assert p["use_sim_time"] is sim
    base = next(
        dict(a.kw["launch_arguments"])
        for a in includes
        if "fake" in dict(a.kw.get("launch_arguments", []))
    )
    assert base["fake"] == str(mode != "real")
    assert base["mujoco"] == str(mode == "mujoco")


def test_conflicting_simulators_and_missing_scene(monkeypatch, tmp_path):
    ns, _ = setup(monkeypatch, tmp_path, False)
    ctx = context("mujoco")
    with pytest.raises(RuntimeError, match="Scene file not found"):
        ns["launch_setup"](ctx)
    ctx["gazebo"] = "true"
    with pytest.raises(ValueError, match="cannot both"):
        ns["launch_setup"](ctx)

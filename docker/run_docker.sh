RMW_IMPLEMENTATION=${RMW_IMPLEMENTATION:-rmw_fastrtps_cpp}

docker run -it --rm --network=host \
    -u root \
    -e ROS_DOMAIN_ID=42 \
    -e RMW_IMPLEMENTATION=$RMW_IMPLEMENTATION \
    -e ROS_LOCALHOST_ONLY=0 \
    -e XDG_RUNTIME_DIR=/tmp/runtime-root \
    -p 8888:8888 -p 6080:6080 -p 50051:50051 \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -e DISPLAY=$DISPLAY \
    -e LIBGL_DRIVERS_PATH=/usr/lib/x86_64-linux-gnu/dri \
    -v /dev/dri/card0:/dev/dri/card0 \
    -v /dev/drm_dp_aux0:/dev/drm_dp_aux0 \
    -v /dev/dri:/dev/dri \
    -v $(pwd):/home/reachy/reachy_ws/src/reachy2_core \
    --entrypoint /home/reachy/reachy_ws/src/reachy2_core/launch.sh \
    -v /tmp:/tmp \
    -e XDG_RUNTIME_DIR=/tmp/runtime-root \
    --device /dev/snd \
    --name reachy2 reachy2:latest \
    service_dev \
    start_rviz:=true start_sdk_server:=true \
    fake:=true orbbec:=false gazebo:=true \
    world:='simple_table.world'
#
# world:=
# 
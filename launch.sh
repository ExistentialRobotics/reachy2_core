#!/bin/bash
shopt -s expand_aliases
source /opt/ros/humble/setup.bash
source /home/reachy/reachy_ws/install/setup.bash
source /home/reachy/.utils.bash
source /package/reachy.bash
source /usr/share/gazebo/setup.bash
source /package/standalone.bashrc
/package/generate_asoundrc.sh


# launch_vnc &
# /home/reachy/.local/bin/jupyter notebook --ip=0.0.0.0 --port=8888 --no-browser --allow-root --NotebookApp.token='' --notebook-dir=/home/reachy/dev/reachy2-sdk/src/examples &
# sed -i 's/Frame Rate: 5/Frame Rate: 30/' /home/reachy/reachy_ws/src/reachy2_core/reachy_description/config/reachy.rviz

echo -e "\n\n Launched without VNC.\n\n"

print_interface(){
    sleep 15
    # Get the container's IP address
    CONTAINER_IP=$(hostname -I | awk '{print $1}')
    CONTAINER_IP="localhost"
    # Define known services
    JUPYTER_PORT=8888
    VNC_PORT=6080
    echo -e "\n\n=== Reachy2 Standalone Playground ==="
    echo -e "Jupyter Notebook:\t\thttp://$CONTAINER_IP:8888/tree"
    echo -e "VNC Viewer (RViz/Gazebo):\thttp://$CONTAINER_IP:6080/vnc.html?autoconnect=1&resize=remote"
    echo -e "======================================\n\n"
}

# Trap SIGTERM and SIGINT (handle Ctrl+C properly)
trap 'echo "Stopping container..."; exit 0' SIGTERM SIGINT

print_interface &
# Handle Fake mode toggle
args=("$@")
if [ "$REACHY2_CORE_SERVICE_FAKE" = "true" ]; then
    args+=("fake:=true")
fi 

# Check if the first argument is "sleep"
if [ "$1" = "sleep" ]; then
    # If the first argument is "sleep", execute sleep infinity
    sleep infinity

elif [ "$1" = "service_dev" ]; then
    # sb doesnt work well in that kind of non-interactive environment, specifically re source-ing the setup.bash
    full_build
    cbuilds 
    source /home/reachy/reachy_ws/install/setup.bash
    ros2 launch reachy_bringup reachy.launch.py "${args[@]:1}"
else
    exec ros2 launch reachy_bringup reachy.launch.py "${args[@]}"
fi

# aplay /home/reachy/dev/reachy2_sounds/MA_BANT_Bubbles_Pops_2.wav
#!/bin/bash



# echo "=== Reachy2 Standalone Playground ==="
# echo "Jupyter Notebook:  http://$CONTAINER_IP:$JUPYTER_PORT/tree"
# echo "VNC Viewer (RViz/Gazebo):        http://localhost:$VNC_PORT/vnc.html?autoconnect=1&resize=remote"
# echo "======================================"

FROM pollenrobotics/reachy2_core:1.7.5.9_release

USER root

# The purpose of this dockerfile is to deploy planning algorithms in the real Reachy 2 robot using the MoveIt 2 perception pipeline
# The Docker image is built on pollenrobotics/reachy2_core:1.7.5.9_release


# Update the expired ROS 2 repository key and install ROS 2 / MoveIt / Gazebo dependencies

# Fix ROS 2 repository key and configure ROS 2 repository

RUN set -eux; \
    apt-key del F42ED6FBAB17C654 || true; \
    mkdir -p /usr/share/keyrings; \
    curl -fsSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
        -o /usr/share/keyrings/ros-archive-keyring.gpg; \
    chmod 644 /usr/share/keyrings/ros-archive-keyring.gpg; \
    rm -f /etc/apt/sources.list.d/ros2-latest.list; \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu jammy main" \
        > /etc/apt/sources.list.d/ros2-latest.list; \
    rm -rf /var/lib/apt/lists/*; \
    apt-get update; \
    apt-get --fix-broken install -y; \
    apt-get upgrade -y; \
    apt-get install -y \
        ros-humble-point-cloud-transport \
        ros-humble-image-transport-plugins \
        ros-humble-image-view \
        ros-humble-moveit* \
        ros-humble-gazebo-ros-pkgs \
        ros-humble-teleop-twist-keyboard \
        protobuf-compiler \
        libprotobuf-dev \
        git \
        build-essential \
        cmake \
        libssl-dev \
        libusb-1.0-0-dev \
        pkg-config \
        libgtk-3-dev \
        libglfw3-dev \
        libgl1-mesa-dev \
        libglu1-mesa-dev \
        python3-numpy \
        python3-transforms3d; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

# Install Intel RealSense SDK

# Fix APT dependency state and install Intel RealSense build dependencies
RUN rm -rf /var/lib/apt/lists/* && \
    apt-get update && \
    apt-get --fix-broken install -y && \
    apt-get install -y \
        python3-numpy \
        python3-transforms3d \
        git \
        build-essential \
        cmake \
        libssl-dev \
        libusb-1.0-0-dev \
        pkg-config \
        libgtk-3-dev \
        libglfw3-dev \
        libgl1-mesa-dev \
        libglu1-mesa-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Build and install Intel RealSense SDK
RUN git clone \
        https://github.com/IntelRealSense/librealsense.git \
        /tmp/librealsense && \
    cd /tmp/librealsense && \
    git checkout v2.57.2 && \
    mkdir build && \
    cd build && \
    cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_EXAMPLES=false \
        -DBUILD_GRAPHICAL_EXAMPLES=false \
        -DFORCE_RSUSB_BACKEND=true \
        -DBUILD_PYTHON_BINDINGS=false && \
    make -j$(nproc) && \
    make install && \
    ldconfig && \
    rm -rf /tmp/librealsense




# Create Reachy configuration override directory
# ReachyConfig expects ~/.reachy_config_override to be a directory
# containing optional YAML configuration overrides.

RUN mkdir -p /home/reachy/.reachy_config_override && \
    chown -R 1000:0 /home/reachy/.reachy_config_override

# Switch to reachy user

USER reachy

WORKDIR /home/reachy/reachy_ws/src

RUN rm -rf reachy2_core && \
    git clone \
        --branch develop \
        --recurse-submodules \
        https://github.com/ExistentialRobotics/reachy2_core.git \
        reachy2_core

RUN cd /home/reachy/reachy_ws/src/reachy2_core/reachy_moveit_config_ros2 && \
    git fetch origin main && \
    git switch main

RUN git clone \
        https://github.com/JosePabloTec/Reachy2-Camera-Viewer.git \
        Reachy2-Camera-Viewer

RUN git clone \
        --branch humble-devel \
        https://github.com/pal-robotics/realsense_gazebo_plugin.git \
        realsense_gazebo_plugin

WORKDIR /home/reachy/reachy_ws

RUN git config --global --add safe.directory /home/reachy/reachy_ws/src/reachy2_core && \
    git config --global --add safe.directory /home/reachy/reachy_ws/src/reachy2_core/reachy_moveit_config_ros2

# The base image seems to have inherited build artifacts
# remove them 
# This ensures the workspace is rebuilt from the current source tree.

RUN rm -rf \
    /home/reachy/reachy_ws/build \
    /home/reachy/reachy_ws/install \
    /home/reachy/reachy_ws/log

RUN /bin/bash -c \
    "source /opt/ros/humble/setup.bash && \
     colcon list"

# Build the complete ROS 2 workspace

RUN /bin/bash -c \
    "source /opt/ros/humble/setup.bash && \
     colcon build \
     --symlink-install \
     --event-handlers console_direct+"

# Automatically source ROS 2 and the Reachy workspace, the user doesn't have to source

RUN echo "source /opt/ros/humble/setup.bash" >> /home/reachy/.bashrc && \
    echo "source /home/reachy/reachy_ws/install/setup.bash" >> /home/reachy/.bashrc

CMD ["/bin/bash"]

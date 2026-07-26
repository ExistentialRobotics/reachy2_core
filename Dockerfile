FROM pollenrobotics/reachy2_core:1.7.5.9_release
<<<<<<< Updated upstream
=======

>>>>>>> Stashed changes

USER root

<<<<<<< Updated upstream
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
=======



# The purpose of this dockerfile is to deploy planning algorithms in the real Reachy 2 robot using the MoveIt 2 perception pipeline
# The Docker image is built on pollenrobotics/reachy2_core:1.7.5.9_release


# Delete the old key
RUN set -eux; \
    apt-key del F42ED6FBAB17C654; \
    # Make a directory for the new key
    mkdir -p /usr/share/keyrings; \
    # Transfer the key from ROS repository's GPG signing key using curl and save it as /usr/share/keyrings/ros-archive-keyring.gpg
    curl -fsSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg; \
    # Give permissions to the key file. 6 = owner can read and write, 4 = users can read, 4 = others can read
    chmod 644 /usr/share/keyrings/ros-archive-keyring.gpg; \
    # Remove the old ROS2 Repository Configuration
    rm -f /etc/apt/sources.list.d/ros2-latest.list; \
    # Generate a line that describes the ROS 2 package repository and save that line into an APT configuration file so that APT knows where to find ROS 2 packages
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu jammy main" > /etc/apt/sources.list.d/ros2-latest.list; \
    # Deletes all downloaded APT package lists to reduce the final Docker image size, it does not uninstall any packages.
    rm -rf /var/lib/apt/lists/*;


RUN set -eux; \
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
        libprotobuf-dev; \
    apt-get clean; \
>>>>>>> Stashed changes
    rm -rf /var/lib/apt/lists/*
# Deletes all downloaded APT package lists to reduce the final Docker image size, it does not uninstall any packages.
RUN rm -rf /var/lib/apt/lists/*;

<<<<<<< Updated upstream
# Build and install Intel RealSense SDK
RUN git clone \
        https://github.com/IntelRealSense/librealsense.git \
        /tmp/librealsense && \
=======
RUN apt-get update && \
    apt-get --fix-broken install -y; \
    apt-get install -y \
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
    git clone https://github.com/IntelRealSense/librealsense.git /tmp/librealsense && \
>>>>>>> Stashed changes
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

<<<<<<< Updated upstream
=======

# Switch to reachy user for all development work
>>>>>>> Stashed changes
USER reachy

WORKDIR /home/reachy/reachy_ws/src

<<<<<<< Updated upstream
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

=======
# Clone and build as reachy user to avoid permission issues
RUN git clone --recurse-submodules https://github.com/pal-robotics/realsense_gazebo_plugin.git -b humble-devel


# access the reachy2_core directory and reset to the ERL fork develop branch

WORKDIR /home/reachy/reachy_ws/src/reachy2_core

RUN git remote set-url origin https://github.com/ExistentialRobotics/reachy2_core.git && \
    git fetch origin && \
    git checkout develop && \
    git reset --hard origin/develop && \
    git submodule update --init --recursive

# submodules /home/reachy/reachy_ws/src/reachy2_core/reachy_moveit_config_ros2

WORKDIR /home/reachy/reachy_ws

# Build the complete ROS 2 workspace

# Source first
RUN /bin/bash -c "source /opt/ros/humble/setup.bash && colcon build"
RUN /bin/bash -c "source /opt/ros/humble/setup.bash && colcon build --symlink-install"
>>>>>>> Stashed changes
# Automatically source ROS 2 and the Reachy workspace, the user doesn't have to source

RUN echo "source /opt/ros/humble/setup.bash" >> /home/reachy/.bashrc && \
    echo "source /home/reachy/reachy_ws/install/setup.bash" >> /home/reachy/.bashrc

CMD ["/bin/bash"]
<<<<<<< Updated upstream
=======

# Create Reachy configuration override directory
# ReachyConfig expects ~/.reachy_config_override to be a directory containing optional YAML configuration overrides, if not present, it raises an Error when running Sims 
RUN mkdir -p /home/reachy/.reachy_config_override
# Make reachy (UID 1000) the owner and root (GID 0) the group of this folder and everything inside it
RUN chown -R 1000:0 /home/reachy/.reachy_config_override
>>>>>>> Stashed changes

FROM pollenrobotics/reachy2:latest

# Switch to root for package installation
USER root

RUN apt-get update && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys F42ED6FBAB17C654 && \
    apt-get update && \
    apt-get install -y \
    ros-humble-point-cloud-transport \
    ros-humble-image-transport-plugins \
    ros-humble-moveit* \
    ros-humble-gazebo-ros-pkgs \
    protobuf-compiler \
    libprotobuf-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update && \
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
    cd /tmp/librealsense && \
    git checkout v2.57.2 && \
    mkdir build && cd build && \
    cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_EXAMPLES=false \
        -DBUILD_GRAPHICAL_EXAMPLES=false \
        -DFORCE_RSUSB_BACKEND=true \
        -DBUILD_PYTHON_BINDINGS=false && \
    make -j$(nproc) && \
    make install && \
    ldconfig && \
    rm -rf /tmp/librealsense && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Switch to reachy user for all development work
USER reachy
WORKDIR /home/reachy/reachy_ws/src

# Clone and build as reachy user to avoid permission issues
RUN git clone https://github.com/pal-robotics/realsense_gazebo_plugin.git -b humble-devel

WORKDIR /home/reachy/reachy_ws

WORKDIR /home/reachy
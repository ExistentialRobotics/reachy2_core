FROM pollenrobotics/reachy2:latest

USER root

RUN apt-get update && \
    # Fix the ROS repository key issue
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys F42ED6FBAB17C654 && \
    # Update package lists
    apt-get update && \
    # Install ROS packages
    apt-get install -y \
    ros-humble-point-cloud-transport \
    ros-humble-image-transport-plugins \
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
    # Clone and build latest stable version
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
    # Clean up
    rm -rf /tmp/librealsense && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Fix permissions before switching user
RUN chown -R 1000:1000 /home/reachy/ 2>/dev/null || true

USER reachy
WORKDIR /home/reachy/reachy_ws/src
RUN git clone https://github.com/pal-robotics/realsense_gazebo_plugin.git -b humble-devel

WORKDIR /home/reachy
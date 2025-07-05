FROM ubuntu:noble

# Set environment variables
ENV ANDROID_SDK_ROOT=/usr/lib/android-sdk

ENV FLUTTER_SDK_ROOT=/usr/lib/flutter
ENV FLUTTER_SDK_VERSION=3.32.0-stable

ENV CMDLINE_TOOLS_VERSION=10406996

# Include flutter and android tools in path
ENV PATH="${PATH}:${FLUTTER_SDK_ROOT}/bin:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools"

# Enable noninteractive installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies and tools
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y \
    watchman \
    openjdk-21-jdk \
    android-sdk \
    wget \
    unzip \
    zip \
    curl \
    git-all \
    xz-utils \
    libglu1-mesa \
    libc6:amd64 libstdc++6:amd64 lib32z1 libbz2-1.0:amd64 \
    clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev mesa-utils \
    usbutils sudo && \
    rm -rf /var/lib/apt/lists/*

# Create ubuntu user and add to necessary groups
RUN usermod -aG sudo,plugdev ubuntu && \
    echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Add flutter to safe directory in git
RUN git config --global --add safe.directory /usr/lib/flutter

# # Configure git user name and email
# RUN git config --global user.name "Your Name" \
#     && git config --global user.email "mail@example.com"

# Download and install Android Command Line Tools
RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools && \
    wget -O commandlinetools.zip "https://dl.google.com/android/repository/commandlinetools-linux-${CMDLINE_TOOLS_VERSION}_latest.zip" && \
    unzip commandlinetools.zip -d ${ANDROID_SDK_ROOT}/cmdline-tools && \
    mv ${ANDROID_SDK_ROOT}/cmdline-tools/cmdline-tools ${ANDROID_SDK_ROOT}/cmdline-tools/latest && \
    rm commandlinetools.zip

# Accept Android SDK licenses and install necessary components
RUN yes | ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager --licenses && \
    ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager "platform-tools" "platforms;android-35" "build-tools;34.0.0" "ndk;27.0.12077973" "ndk;26.3.11579264" "cmake;3.22.1"

# Insall Flutter SDK
RUN mkdir -p ${FLUTTER_SDK_ROOT} && \
    cd ${FLUTTER_SDK_ROOT} && \
    curl -OL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_SDK_VERSION}.tar.xz && \
    tar -xf flutter_linux_${FLUTTER_SDK_VERSION}.tar.xz -C /usr/lib/ && \
    rm -rf flutter_linux_${FLUTTER_SDK_VERSION}.tar.xz

RUN chown -R ubuntu:ubuntu ${ANDROID_SDK_ROOT} && \
    chown -R ubuntu:ubuntu ${FLUTTER_SDK_ROOT}

# Disable Flutter telemetry
RUN flutter --disable-analytics

# Default shell to bash
SHELL ["/bin/bash", "-c"]

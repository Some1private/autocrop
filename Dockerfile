FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
ENV HERMETIC_PYTHON_VERSION=3.9

# Install basic dependencies
RUN apt-get update && apt-get install -y \
    python3.9 \
    python3.9-dev \
    python3-pip \
    git \
    build-essential \
    pkg-config \
    cmake \
    wget \
    libopencv-dev \
    libopencv-core-dev \
    libopencv-highgui-dev \
    libopencv-calib3d-dev \
    libopencv-features2d-dev \
    libopencv-imgproc-dev \
    libopencv-video-dev

# Install Bazelisk
RUN wget https://github.com/bazelbuild/bazelisk/releases/download/v1.25.0/bazelisk-amd64.deb \
    && dpkg -i bazelisk-amd64.deb \
    && rm bazelisk-amd64.deb

# Clone MediaPipe
RUN git clone https://github.com/google/mediapipe.git
WORKDIR /mediapipe

# Build AutoFlip with Python 3.9
RUN bazel build -c opt \
    --define MEDIAPIPE_DISABLE_GPU=1 \
    --repo_env=HERMETIC_PYTHON_VERSION=3.9 \
    mediapipe/examples/desktop/autoflip:run_autoflip

# Create working directory
WORKDIR /workspace

# Create entrypoint script
RUN echo '#!/bin/bash\n\
GLOG_logtostderr=1 /mediapipe/bazel-bin/mediapipe/examples/desktop/autoflip/run_autoflip \
--calculator_graph_config_file=/mediapipe/mediapipe/examples/desktop/autoflip/autoflip_graph.pbtxt \
--input_side_packets=input_video_path=$1,output_video_path=$2,aspect_ratio=$3' > /usr/local/bin/process_video && \
chmod +x /usr/local/bin/process_video

ENTRYPOINT ["process_video"]

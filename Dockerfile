FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
ENV HERMETIC_PYTHON_VERSION=3.9
ENV PYTHON_BIN_PATH=/usr/bin/python3.9
ENV PYTHON_LIB_PATH=/usr/lib/python3.9

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

# Set Python 3.9 as default
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.9 1

# Install Bazelisk
RUN wget https://github.com/bazelbuild/bazelisk/releases/download/v1.25.0/bazelisk-amd64.deb \
    && dpkg -i bazelisk-amd64.deb \
    && rm bazelisk-amd64.deb

# Clone specific MediaPipe version
RUN git clone https://github.com/google/mediapipe.git \
    && cd mediapipe \
    && git checkout tags/v0.8.11

WORKDIR /mediapipe

# Build AutoFlip with optimizations
RUN bazel build -c opt \
    --define MEDIAPIPE_DISABLE_GPU=1 \
    --action_env PYTHON_BIN_PATH=/usr/bin/python3.9 \
    --action_env PYTHON_LIB_PATH=/usr/lib/python3.9 \
    --repo_env=HERMETIC_PYTHON_VERSION=3.9 \
    --copt=-mavx2 \
    --copt=-mfma \
    --copt=-msse4.1 \
    --copt=-msse4.2 \
    mediapipe/examples/desktop/autoflip:run_autoflip

WORKDIR /workspace

RUN echo '#!/bin/bash\n\
GLOG_logtostderr=1 /mediapipe/bazel-bin/mediapipe/examples/desktop/autoflip/run_autoflip \
--calculator_graph_config_file=/mediapipe/mediapipe/examples/desktop/autoflip/autoflip_graph.pbtxt \
--input_side_packets=input_video_path=$1,output_video_path=$2,aspect_ratio=$3' > /usr/local/bin/process_video && \
chmod +x /usr/local/bin/process_video

ENTRYPOINT ["process_video"]

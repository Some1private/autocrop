FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    git \
    bazel \
    build-essential \
    opencv-python \
    pkg-config \
    libopencv-dev=3.2.0

# Clone MediaPipe
RUN git clone https://github.com/google/mediapipe.git
WORKDIR /mediapipe

# Build AutoFlip
RUN bazel build -c opt --define MEDIAPIPE_DISABLE_GPU=1 mediapipe/examples/desktop/autoflip:run_autoflip

# Create working directory
WORKDIR /workspace

# Create entrypoint script
RUN echo '#!/bin/bash\n\
GLOG_logtostderr=1 /mediapipe/bazel-bin/mediapipe/examples/desktop/autoflip/run_autoflip \
--calculator_graph_config_file=/mediapipe/mediapipe/examples/desktop/autoflip/autoflip_graph.pbtxt \
--input_side_packets=input_video_path=$1,output_video_path=$2,aspect_ratio=$3' > /usr/local/bin/process_video && \
chmod +x /usr/local/bin/process_video

ENTRYPOINT ["process_video"]

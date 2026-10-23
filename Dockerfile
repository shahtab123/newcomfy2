# Build argument for base image selection
ARG BASE_IMAGE=nvidia/cuda:12.6.3-cudnn-runtime-ubuntu24.04

# Stage 1: Base image with common dependencies
FROM ${BASE_IMAGE} AS base

# Build arguments for this stage with sensible defaults for standalone builds
ARG COMFYUI_VERSION=latest
ARG CUDA_VERSION_FOR_COMFY
ARG ENABLE_PYTORCH_UPGRADE=false
ARG PYTORCH_INDEX_URL

# Prevents prompts from packages asking for user input during installation
ENV DEBIAN_FRONTEND=noninteractive
# Prefer binary wheels over source distributions for faster pip installations
ENV PIP_PREFER_BINARY=1
# Ensures output from python is printed immediately to the terminal without buffering
ENV PYTHONUNBUFFERED=1
# Speed up some cmake builds
ENV CMAKE_BUILD_PARALLEL_LEVEL=8
# Prevent pip from asking for confirmation during uninstall steps in custom nodes
ENV PIP_NO_INPUT=1
# Increase timeout for long-running operations
ENV UV_HTTP_TIMEOUT=300

# Install Python, git and other necessary tools
RUN apt-get update && apt-get install -y \
    python3.12 \
    python3.12-venv \
    git \
    wget \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender1 \
    ffmpeg \
    && ln -sf /usr/bin/python3.12 /usr/bin/python \
    && ln -sf /usr/bin/pip3 /usr/bin/pip

# Clean up to reduce image size
RUN apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Install uv (latest) using official installer and create isolated venv
RUN wget -qO- https://astral.sh/uv/install.sh | sh \
    && ln -s /root/.local/bin/uv /usr/local/bin/uv \
    && ln -s /root/.local/bin/uvx /usr/local/bin/uvx \
    && uv venv /opt/venv

# Use the virtual environment for all subsequent commands
ENV PATH="/opt/venv/bin:${PATH}"

# Install comfy-cli + dependencies needed by it to install ComfyUI
# comfy-cli is pinned: its install/torch-index behavior decides what lands in
# the workspace venv, so an unpinned version makes builds non-reproducible.
RUN uv pip install comfy-cli==1.13.0 pip setuptools wheel

# Install ComfyUI
RUN if [ -n "${CUDA_VERSION_FOR_COMFY}" ]; then \
      /usr/bin/yes | comfy --workspace /comfyui install --version "${COMFYUI_VERSION}" --cuda-version "${CUDA_VERSION_FOR_COMFY}" --nvidia; \
    else \
      /usr/bin/yes | comfy --workspace /comfyui install --version "${COMFYUI_VERSION}" --nvidia; \
    fi

# Upgrade PyTorch if needed (for newer CUDA versions)
RUN if [ "$ENABLE_PYTORCH_UPGRADE" = "true" ]; then \
      uv pip install --force-reinstall torch torchvision torchaudio --index-url ${PYTORCH_INDEX_URL}; \
    fi

# Change working directory to ComfyUI
WORKDIR /comfyui

# Support for the network volume
ADD src/extra_model_paths.yaml ./

# Add script to install custom nodes (must be before using it)
COPY scripts/comfy-node-install.sh /usr/local/bin/comfy-node-install
RUN chmod +x /usr/local/bin/comfy-node-install

# Custom nodes commented out to stay under Runpod's 30m image-build limit.
# Current API workflows (flux/WAN/trellis) use ComfyUI CORE nodes only when
# COMFYUI_VERSION=latest. Uncomment batches below if a workflow needs them.
#
# # Batch 1: Core nodes (Impact Pack, D2, Kimara)
# RUN comfy-node-install \
#     https://github.com/ltdrdata/ComfyUI-Impact-Pack \
#     https://github.com/ltdrdata/ComfyUI-Impact-Subpack \
#     https://github.com/da2el-ai/D2-nodes-ComfyUI \
#     https://github.com/kimara-ai/ComfyUI-Kimara-AI-Advanced-Watermarks
#
# # Batch 2: Utility nodes (Save)
# RUN comfy-node-install \
#     https://github.com/WUYUDING2583/ComfyUI-Save-Image-Callback
#
# # Batch 3: InfiniteTalk / WAN wrapper nodes
# RUN comfy-node-install \
#     https://github.com/kijai/ComfyUI-WanVideoWrapper \
#     https://github.com/rgthree/rgthree-comfy \
#     https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite
#
# # Batch 4: Additional utility and workflow nodes
# RUN comfy-node-install \
#     https://github.com/kijai/ComfyUI-KJNodes \
#     https://github.com/ClownsharkBatwing/RES4LYF \
#     https://github.com/alexopus/ComfyUI-Image-Saver
#
# Trellis2 / Pixal3D / MoGe are ComfyUI CORE — do not install third-party
# ComfyUI-TRELLIS2 packs (conflicts). Models on network volume, e.g.:
#   models/diffusion_models/trellis_2_int8_convrot.safetensors
#   models/vae/trellis_2_shape_vae_bf16.safetensors
#   models/clip_vision/dino_v3_L_naf_fp32.safetensors
#   models/background_removal/birefnet.safetensors
#   models/geometry_estimation/moge_2_vitl_normal_fp16.safetensors
# See https://docs.comfy.org/tutorials/3d/trellis2

# Go back to the root
WORKDIR /

# Handler-only deps in /opt/venv. ComfyUI uses /comfyui/.venv (see start.sh).
# Skipping a second torch/requirements mirror keeps the GitHub build under 30m.
RUN uv pip install runpod requests websocket-client

# Add application code and scripts
ADD src/start.sh handler.py test_input.json ./
RUN chmod +x /start.sh

# Copy helper script to switch Manager network mode at container start
COPY scripts/comfy-manager-set-mode.sh /usr/local/bin/comfy-manager-set-mode
RUN chmod +x /usr/local/bin/comfy-manager-set-mode

# Set the default command to run when starting the container
CMD ["/start.sh"]

# Models are NOT baked into the image — use the Runpod network volume mounted at
# /runpod-volume (see src/extra_model_paths.yaml). Place files under e.g.
#   /runpod-volume/models/checkpoints/
#   /runpod-volume/models/diffusion_models/
#   /runpod-volume/models/vae/
# Optional bake-in stages kept commented if you need a Hub smoke-test image later:
#
# # Stage 2: Download models
# FROM base AS downloader
# ARG HUGGINGFACE_ACCESS_TOKEN
# ARG MODEL_TYPE=flux1-dev-fp8
# WORKDIR /comfyui
# RUN mkdir -p models/checkpoints models/vae models/unet models/clip
# RUN if [ "$MODEL_TYPE" = "flux1-dev-fp8" ]; then \
#       wget -q -O models/checkpoints/flux1-dev-fp8.safetensors \
#         https://huggingface.co/Comfy-Org/flux1-dev/resolve/main/flux1-dev-fp8.safetensors; \
#     fi
#
# FROM base AS final
# COPY --from=downloader /comfyui/models /comfyui/models

# Final image alias (same as base; keeps docker-bake `target = "final"` working)
FROM base AS final
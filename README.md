# RunPod Serverless ComfyUI

> [ComfyUI](https://github.com/comfyanonymous/ComfyUI) as a serverless API on [RunPod](https://www.runpod.io/)

## Quick Start

This repository contains RunPod serverless workflows for image and video generation using ComfyUI.

## Available Workflows

### Image Generation Workflows

#### `main_api_postman.json` - Full Featured Image Generation
- **Features**: Image input, LoRA enhancement, flexible resolutions
- **Use case**: Advanced image generation with reference images
- **Models**: Flux 1-dev with clothes_remover LoRA
- **Resolution**: Variable (640x1536 portrait by default)

#### `wan_api_postman_fast.json` - Fast Video Generation
- **Features**: Text-to-video generation, optimized for speed
- **Use case**: Quick video generation for testing
- **Models**: WAN 2.1 video model
- **Output**: 512x512, 16 frames, 8 FPS (~2 seconds)
- **Speed**: ~15-30 seconds generation time

#### `wan_api_postman.json` - High Quality Video Generation
- **Features**: Text-to-video generation, high quality
- **Use case**: Production quality videos
- **Models**: WAN 2.1 video model
- **Output**: 832x480, 33 frames, 16 FPS (~2 seconds)
- **Speed**: ~2-3 minutes generation time

#### `new api.json` - Updated API Configuration
- **Features**: Latest API endpoint configurations
- **Use case**: Current API specifications and parameters
- **Compatibility**: Works with all existing workflows

## Additional Utilities

### Video Processing Tools

#### `base64_to_video.py` - Python Video Converter
- **Purpose**: Convert base64 encoded video data to playable video files
- **Usage**: `python base64_to_video.py base64.txt`
- **Output**: Creates `base64.webp` file for browser/VLC playback
- **Dependencies**: Python with base64 and webp support

#### `convert_base64.sh` - Shell Script Converter
- **Purpose**: Alternative shell-based conversion script
- **Usage**: `./convert_base64.sh`
- **Platform**: Unix/Linux compatible
- **Features**: Automated base64 to video conversion

### Sample Data Files

#### `base64.txt` - Sample Base64 Data
- **Purpose**: Contains sample base64 encoded video data
- **Use case**: Testing video conversion utilities
- **Format**: Plain text with base64 encoded content

#### `base64.webp` - Sample Video Output
- **Purpose**: Example output video file
- **Format**: WebP video format
- **Compatibility**: Browser and VLC player support

### API Documentation

#### `wan_api_postman.json` - Postman Collection
- **Purpose**: Complete API collection for testing
- **Features**: Pre-configured requests for all endpoints
- **Use case**: API testing and development
- **Format**: Postman collection v2.1

## Environment Variables Configuration

### Required Environment Variables

#### Hugging Face Access Token
For downloading models that require authentication:

```
HUGGINGFACE_ACCESS_TOKEN=your_hf_token_here
```

### Optional Environment Variables

#### Timeout Configuration
To handle longer generation times (especially for high-quality videos):

```
COMFY_POLLING_MAX_RETRIES=2000
COMFY_POLLING_INTERVAL_MS=500
```

### Setting Environment Variables in RunPod

#### Option 1: RunPod Web Interface
1. Go to your RunPod dashboard
2. Navigate to your serverless endpoint
3. Click "Edit" or "Settings"
4. Add the environment variables in the Environment Variables section

### Option 2: Docker Compose
Add to your `docker-compose.yml`:

```yaml
environment:
  - HUGGINGFACE_ACCESS_TOKEN=your_hf_token_here
  - COMFY_POLLING_MAX_RETRIES=2000
  - COMFY_POLLING_INTERVAL_MS=500
```

### Option 3: Docker Build
When building the Docker image locally:

```bash
docker build --build-arg HUGGINGFACE_ACCESS_TOKEN=your_hf_token_here -t your-image-name .
```

### Timeout Calculation
- **Default**: 500 retries × 250ms = 125 seconds (2 minutes)
- **Extended**: 2000 retries × 500ms = 1000 seconds (16.7 minutes)

## API Usage

### Image Generation
```json
{
  "input": {
    "workflow": { /* workflow JSON */ },
    "images": [
      {
        "name": "input.png",
        "image": "base64_encoded_image_data"
      }
    ]
  }
}
```

### Video Generation
```json
{
  "input": {
    "workflow": { /* workflow JSON */ }
  }
}
```

## Output Processing

### Converting Base64 to Video

#### Method 1: Python Script (Recommended)
Use the provided Python script to convert base64 output to video files:

```bash
python base64_to_video.py base64.txt
```

This creates a `base64.webp` file that can be played in browsers or VLC.

#### Method 2: Shell Script (Alternative)
For Unix/Linux systems, you can use the shell script:

```bash
chmod +x convert_base64.sh
./convert_base64.sh
```

#### Method 3: Manual Conversion
If you have base64 data in a text file, you can manually decode it:

```bash
# Decode base64 to binary
base64 -d base64.txt > output.webp

# Or using Python
python -c "import base64; open('output.webp', 'wb').write(base64.b64decode(open('base64.txt').read()))"
```

### Sample Data
The repository includes sample files for testing:
- `base64.txt` - Sample base64 encoded video data
- `base64.webp` - Example output video file

## Model Requirements

### Image Generation Models
- `flux1-dev-kontext_fp8_scaled.safetensors` - Main model
- `clip_l.safetensors` - CLIP encoder
- `t5xxl_fp16.safetensors` - T5 encoder
- `ae.safetensors` - VAE decoder
- `clothes_remover_v0.safetensors` - LoRA (optional)

### Video Generation Models
- `wan2.1_t2v_1.3B_fp16.safetensors` - WAN video model
- `umt5_xxl_fp8_e4m3fn_scaled.safetensors` - WAN CLIP
- `wan_2.1_vae.safetensors` - WAN VAE

## Troubleshooting

### Timeout Issues
- Increase `COMFY_POLLING_MAX_RETRIES` for longer generation
- Use fast workflows for testing
- Reduce steps/frames for quicker results

### Model Loading Issues
- Ensure all required model files are in the correct directories
- Check model file names match workflow specifications

## Acknowledgments

- [ComfyUI](https://github.com/comfyanonymous/ComfyUI) by comfyanonymous
- [RunPod](https://www.runpod.io/) for serverless infrastructure
- Original worker inspiration from [runpod-worker-comfy](https://github.com/blib-la/runpod-worker-comfy)

# llama-cpp-sycl

Run [llama.cpp](https://github.com/ggml-org/llama.cpp) with the **SYCL backend on Intel iGPUs** (Meteor Lake, Arrow Lake, Arc).

## Quick start

Download a GGUF model (e.g. from [Hugging Face](https://huggingface.co/models?sort=trending&search=gguf)):

```bash
mkdir -p models
curl -L -o models/Qwen3-4B-Q4_K_M.gguf \
  https://huggingface.co/Qwen/Qwen3-4B-GGUF/resolve/main/Qwen3-4B-Q4_K_M.gguf
```

Run:

```bash
docker run -d \
  --device /dev/dri \
  -v /path/to/models:/models:ro \
  -p 8080:8080 \
  llama-cpp-sycl \
  --model /models/Qwen3-4B-Q4_K_M.gguf
```

Test it:

```bash
curl http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "local",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

### Interactive CLI

```bash
docker run -it --rm \
  --device /dev/dri \
  -v /path/to/models:/models:ro \
  llama-cpp-sycl \
  llama-cli --model /models/your-model.gguf -cnv
```

### Docker Compose

Copy `docker-compose.yml` to your server and adjust the model path:

```bash
docker compose up -d
```

## Environment variables

| Variable | Default | Description |
|---|---|---|
| `LLAMA_HOST` | `0.0.0.0` | Bind address |
| `LLAMA_PORT` | `8080` | Listen port |

## GPU access

The non-root user inside the container must be in the `render` group to access the GPU. Find your GID and pass it to Docker:

```bash
docker run --device /dev/dri --group-add $(stat -c '%g' /dev/dri/renderD128) ...
```

In `docker-compose.yml`, set the GID under `group_add` (default: `109`).

### Proxmox LXC

Make sure the container has access to `/dev/dri` and the GIDs match between host and container. See [Proxmox GPU Passthrough docs](https://pve.proxmox.com/wiki/PCI_Passthrough).

## Build from source

```bash
git clone https://github.com/richardvenneman/llama-cpp-sycl.git
cd llama-cpp-sycl
docker build -t llama-cpp-sycl .
```

### Build args

| Arg | Default | Description |
|---|---|---|
| `ONEAPI_VERSION` | `2025.2.2-0-devel-ubuntu24.04` | Base image tag |
| `LLAMA_CPP_COMMIT` | `34ba7b5a` (b7965) | llama.cpp git commit |
| `GGML_SYCL_F16` | `OFF` | Enable FP16 SYCL kernels |

## Benchmarks

Intel Core Ultra 5 125H — Meteor Lake iGPU (7 Xe-cores), 64 GB RAM, Proxmox LXC.

| Model | Prompt eval | Generation |
|---|---|---|
| Qwen3 1.7B Q4_K_M | 30 t/s | 13.5 t/s |
| Qwen3 4B Q4_K_M | 20 t/s | 8.8 t/s |

Warm results (after SYCL JIT compilation). First request is ~60-70% slower.

## Tested hardware

- Intel Core Ultra 5 125H — Meteor Lake iGPU (7 Xe-cores)
- 64 GB system RAM
- Proxmox VE, LXC with GPU passthrough

## Known issues

- **Cold start**: The first request after startup is ~60-70% slower due to SYCL JIT kernel compilation.
- **Flash Attention** is auto-disabled on iGPUs (CPU tensor assignment issue).
- **Ollama Vulkan backend** produces garbage output on Meteor Lake.
- **IPEX-LLM** is archived and its fork is poorly maintained.

## Credits

Based on the [official llama.cpp SYCL Dockerfile](https://github.com/ggml-org/llama.cpp/blob/master/.devops/intel.Dockerfile).

## License

MIT

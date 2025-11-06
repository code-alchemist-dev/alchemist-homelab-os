# Ollama - Local AI API Server

## Overview
Ollama provides a local OpenAI-compatible API server that runs popular open-source language models. Perfect for privacy-focused AI workflows in n8n without sending data to external services.

## Features
- **OpenAI-Compatible API**: Drop-in replacement for OpenAI API calls
- **Multiple Models**: Llama 2/3, Mistral, CodeLlama, Phi, and many more
- **Resource Efficient**: Runs on CPU with optional GPU acceleration
- **Privacy-First**: All processing happens locally on your hardware
- **Easy Model Management**: Simple commands to download and manage models

## Quick Start

### 1. **Start Ollama Service**
```bash
# Start Ollama
./scripts/manage.sh start ollama

# Or add to your stack startup
./scripts/stack.sh start
```

### 2. **Download a Model**
```bash
# Download Llama 2 7B (most popular, ~4GB)
docker exec ollama ollama pull llama2

# Download Mistral 7B (excellent performance, ~4GB)
docker exec ollama ollama pull mistral

# Download Code Llama for coding tasks (~4GB)
docker exec ollama ollama pull codellama

# Download smaller models for testing
docker exec ollama ollama pull phi        # ~2GB
docker exec ollama ollama pull tinyllama  # ~700MB
```

### 3. **Test the API**
```bash
# Test with curl
curl http://localhost:11434/api/generate -d '{
  "model": "llama2",
  "prompt": "Why is the sky blue?",
  "stream": false
}'

# Test OpenAI-compatible endpoint
curl http://localhost:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama2",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

## Access Points
- **API Endpoint**: http://localhost:11434
- **OpenAI Compatible**: http://localhost:11434/v1/chat/completions
- **Via Traefik**: http://ollama.localhost
- **External**: Access through your Cloudflare tunnel URL + /ollama

## n8n Integration

### Configure n8n to Use Ollama

1. **In n8n workflow, add "OpenAI" node**
2. **Configure credentials:**
   - **API Key**: `ollama` (can be any value, not used)
   - **Base URL**: `http://ollama:11434/v1`
   - **Organization**: Leave empty

3. **Use in Message a Model:**
   - **Model**: `llama2` (or any model you've downloaded)
   - **Messages**: Configure your prompts normally
   - **All other settings**: Work exactly like OpenAI

### Example n8n Workflow
```json
{
  "nodes": [
    {
      "name": "AI Chat",
      "type": "@n8n/n8n-nodes-langchain.openAi",
      "parameters": {
        "model": "llama2",
        "messages": {
          "values": [
            {
              "role": "user",
              "content": "Explain quantum computing in simple terms"
            }
          ]
        }
      },
      "credentials": {
        "openAiApi": "ollama-local"
      }
    }
  ]
}
```

## Model Recommendations

### For General Use
- **Llama 2 7B**: Excellent general performance, good balance
- **Mistral 7B**: Fast and efficient, great for most tasks
- **Phi-3**: Microsoft's small but capable model

### For Coding
- **CodeLlama 7B**: Specialized for code generation
- **StarCoder**: Good alternative for programming tasks

### For Testing/Low Resources
- **TinyLlama**: Very small model for testing
- **Phi**: Compact but surprisingly capable

## Configuration

### Environment Variables
```bash
# Ollama Settings
OLLAMA_IMAGE=ollama/ollama:latest
OLLAMA_CONTAINER_NAME=ollama
OLLAMA_HOST=0.0.0.0
OLLAMA_ORIGINS=*
OLLAMA_PORT=11434

# Enable for GPU support
OLLAMA_GPU_SUPPORT=false
```

### GPU Acceleration (Optional)
If you have an NVIDIA GPU:

1. **Install nvidia-docker**:
```bash
# Ubuntu/Debian
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
sudo systemctl restart docker
```

2. **Uncomment GPU section** in docker-compose.yml
3. **Restart service**: `./scripts/manage.sh restart ollama`

## Usage Examples

### Basic Chat Completion
```bash
curl http://localhost:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama2",
    "messages": [
      {"role": "system", "content": "You are a helpful assistant."},
      {"role": "user", "content": "What is Docker?"}
    ],
    "max_tokens": 500,
    "temperature": 0.7
  }'
```

### Streaming Response
```bash
curl http://localhost:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "mistral",
    "messages": [{"role": "user", "content": "Tell me a story"}],
    "stream": true
  }'
```

### Code Generation
```bash
curl http://localhost:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "codellama",
    "messages": [
      {"role": "user", "content": "Write a Python function to calculate factorial"}
    ]
  }'
```

## Management Commands

### Service Management
```bash
# Start/stop Ollama
./scripts/manage.sh start ollama
./scripts/manage.sh stop ollama
./scripts/manage.sh logs ollama

# Check status
./scripts/manage.sh status
```

### Model Management
```bash
# List installed models
docker exec ollama ollama list

# Pull new models
docker exec ollama ollama pull <model-name>

# Remove models
docker exec ollama ollama rm <model-name>

# Show model info
docker exec ollama ollama show <model-name>
```

### Interactive Chat (for testing)
```bash
# Start interactive chat session
docker exec -it ollama ollama run llama2

# Chat with different model
docker exec -it ollama ollama run mistral
```

## Troubleshooting

### Common Issues

#### Model Download Fails
```bash
# Check disk space
df -h

# Check Ollama logs
docker logs ollama

# Retry download
docker exec ollama ollama pull llama2
```

#### API Not Responding
```bash
# Check if service is running
docker ps | grep ollama

# Check logs
docker logs ollama

# Restart service
./scripts/manage.sh restart ollama
```

#### n8n Can't Connect
- Verify Ollama is on same network: `docker network ls`
- Check URL in n8n: Use `http://ollama:11434/v1`
- Test API manually: `curl http://localhost:11434/api/tags`

## Performance Tips

### Optimize for Your Hardware
- **8GB+ RAM**: Can run 7B models comfortably
- **16GB+ RAM**: Can run 13B models
- **GPU**: Significantly faster inference
- **SSD Storage**: Faster model loading

### Model Selection
- **Start small**: Try `tinyllama` or `phi` first
- **General use**: `llama2` or `mistral` 7B models
- **Coding**: `codellama` for programming tasks
- **Large context**: `mistral` handles longer conversations better

## Security Considerations

### Network Security
- Ollama runs on internal Docker network
- External access only through Traefik proxy
- No authentication required (local network only)

### Data Privacy
- All processing happens locally
- No data sent to external services
- Models stored in local Docker volume
- Complete privacy for sensitive workflows

## Resource Requirements

### Minimum System Requirements
- **CPU**: 4+ cores recommended
- **RAM**: 8GB minimum, 16GB+ recommended
- **Storage**: 10GB+ for models and data
- **Network**: Local network only

### Model Storage Requirements
- **TinyLlama**: ~700MB
- **Phi**: ~2GB
- **Llama2/Mistral 7B**: ~4GB
- **Llama2 13B**: ~7GB
- **CodeLlama 34B**: ~19GB

Your homelab can now run AI models locally! 🤖🚀
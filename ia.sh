#!/bin/bash

# 1. Instalar Ollama automáticamente
echo "=== Instalando Ollama ==="
curl -fsSL https://ollama.com/install.sh | sh

# 2. Imprimir por pantalla el comando solicitado
echo "ollama launch claude --model gemma4:31b-cloud"

# 3. Ejecutar el comando
echo "=== Ejecutando comando ==="
ollama launch claude --model gemma4:31b-cloud
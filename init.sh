#!/bin/bash
set -e

# Запуск Ollama в фоне, если не запущен
if ! pgrep -x "ollama" > /dev/null; then
    echo " Starting Ollama server..."
    ollama serve &
    OLLAMA_PID=$!
    
    # Ожидание готовности Ollama
    echo " Waiting for Ollama to be ready..."
    for i in {1..30}; do
        if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
            echo " Ollama is ready"
            break
        fi
        if [ $i -eq 30 ]; then
            echo " Ollama failed to start"
            exit 1
        fi
        sleep 2
    done
    
    # Pull модели, если не скачана
    if ! ollama list | grep -q "${LLM_MODEL:-Qwen2.5:0.5B}"; then
        echo " Pulling model ${LLM_MODEL:-Qwen2.5:0.5B}..."
        ollama pull "${LLM_MODEL:-Qwen2.5:0.5B}"
    fi
fi

# Запуск FastAPI приложения
echo " Starting FastAPI server on port 8000..."
exec uvicorn main:app --host 0.0.0.0 --port 8000

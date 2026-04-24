# -*- coding: utf-8 -*-
"""
SMS Spam Classifier — упрощённая версия (без авторизации)
"""

import os
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import requests

# === Конфигурация (можно переопределить через .env) ===
OLLAMA_URL = os.getenv("OLLAMA_URL", "http://localhost:11434/api/generate")
MODEL_NAME = os.getenv("LLM_MODEL", "Qwen2.5:0.5B")

app = FastAPI(title="SMS Spam Classifier", version="1.0.0")


class RequestModel(BaseModel):
    """
    Модель входного запроса.

    Attributes:
        prompt (str): текст SMS-сообщения для классификации
    """
    prompt: str


@app.post("/generate")
def generate(request: RequestModel):
    """
    Обрабатывает запрос на классификацию SMS и отправляет его в Ollama.

    Args:
        request (RequestModel): объект с текстом сообщения

    Returns:
        dict: JSON-ответ с классификацией
    """
    # === Формирование промпта ===
    prompt = f"""
Ты классификатор SMS-спама. Отвечай строго одним словом: "spam" или "not spam".

Примеры:
- "Привет! Сегодня встречаемся в 18:00?" → not spam
- "Напоминание: завтрашняя встреча в 10:00" → not spam
- "Твои документы готовы к отправке" → not spam
- "Скидка 50% на все товары до конца недели!" → spam
- "Вы выиграли бесплатную подписку! Нажмите здесь!" → spam
- "Получите быстрый кредит без проверки кредитной истории" → spam

Классифицируй строго сообщение: "{request.prompt}"
"""

    payload = {
        "model": MODEL_NAME,
        "prompt": prompt,
        "stream": False
    }

    try:
        response = requests.post(OLLAMA_URL, json=payload, timeout=30)
        response.raise_for_status()
        raw_answer = response.json().get("response", "").strip().lower()
       
        print(raw_answer)
        # Нормализация ответа
        if "spam" in raw_answer:
            classification = "spam"
        elif "not spam" in raw_answer or "not_spam" in raw_answer:
            classification = "not spam"
        else:
            classification = "unknown"  # fallback для некорректных ответов
            
        return {"answer": classification}
        
    except requests.RequestException as e:
        raise HTTPException(status_code=502, detail=f"LLM service error: {str(e)}")


@app.get("/health")
def health_check():
    """Эндпоинт для проверки работоспособности сервиса."""
    return {"status": "ok", "version": "1.0.0"}

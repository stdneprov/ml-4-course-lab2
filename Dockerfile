FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive
ARG APP_USER=appuser
ARG APP_UID=1000

RUN sed -i 's|http://archive.ubuntu.com/ubuntu|http://mirror.yandex.ru/ubuntu|g' /etc/apt/sources.list && \
    sed -i 's|http://security.ubuntu.com/ubuntu|http://mirror.yandex.ru/ubuntu|g' /etc/apt/sources.list

RUN for i in 1 2 3; do \
        apt-get update && \
        apt-get install -y --no-install-recommends \
            python3 \
            python3-pip \
            curl \
            wget \
            git \
            zstd \
            ca-certificates && \
        break || sleep 10; \
    done && \
    rm -rf /var/lib/apt/lists/*

RUN for i in 1 2 3; do \
        apt-get update && \
        apt-get install -y --no-install-recommends build-essential && \
        break || sleep 10; \
    done && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -m -u ${APP_UID} -s /bin/bash ${APP_USER}

RUN ln -sf /usr/bin/python3 /usr/bin/python && \
    pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir \
        fastapi \
        uvicorn[standard] \
        requests \
        python-dotenv \
        pydantic[email]

# === Установка Ollama ===
RUN curl -fsSL https://ollama.com/install.sh | sh && \
    ollama --version

WORKDIR /app
COPY --chown=${APP_USER}:${APP_USER} . .

RUN chmod +x /app/init.sh

USER ${APP_USER}

ENV ALLOWED_HOSTS=localhost,127.0.0.1 \
    OLLAMA_URL=http://localhost:11434/api/generate \
    LLM_MODEL=Qwen2.5:0.5B \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# === Порты ===
EXPOSE 8000 11434

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

CMD ["/app/init.sh"]

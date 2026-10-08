FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
WORKDIR /app

# Yapay zekalı imaj için: docker build --build-arg INSTALL_AI=1
ARG INSTALL_AI=0
COPY requirements.txt requirements-ai.txt ./
# torch'un CPU sürümü (~200MB) — CUDA sürümü gereksiz yere GB'larca yer kaplar
RUN if [ "$INSTALL_AI" = "1" ]; then \
      pip install --no-cache-dir --extra-index-url https://download.pytorch.org/whl/cpu -r requirements-ai.txt; \
    else \
      pip install --no-cache-dir -r requirements.txt; \
    fi

# Root olmayan kullanıcı: uygulamada bir açık olsa bile container'ı ele geçiremesin
RUN useradd --create-home --uid 10001 app
COPY --chown=app:app . .
RUN mkdir -p /app/torch_models && chown app:app /app/torch_models
USER app

ENV PORT=8000 AI_ENABLED=${INSTALL_AI}
EXPOSE 8000
# AI worker thread'i import sırasında başladığı için tek process + thread kullanılıyor
CMD gunicorn app:app --bind 0.0.0.0:${PORT} --workers 1 --threads 8 --timeout 120

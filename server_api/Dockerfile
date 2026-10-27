FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
WORKDIR /app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Root olmayan kullanıcı: uygulamada bir açık olsa bile container'ı ele geçiremesin
RUN useradd --create-home --uid 10001 app
COPY --chown=app:app . .
USER app

ENV PORT=8000
EXPOSE 8000
# Tek process: istek sınırı ve şifre sıfırlama sayacı process belleğinde tutuluyor
CMD gunicorn app:app --bind 0.0.0.0:${PORT} --workers 1 --threads 8 --timeout 120

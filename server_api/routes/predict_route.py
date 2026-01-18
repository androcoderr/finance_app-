# app/routes/predict_route.py
import json
import pika
from flask import Blueprint, request, jsonify

p_bp = Blueprint('predict', __name__, url_prefix='/predict')

# RABBITMQ connection (local test ise localhost, docker içi ise rabbitmq yaz)
RABBIT_URL = "amqp://guest:guest@localhost:5672/"
connection = pika.BlockingConnection(pika.URLParameters(RABBIT_URL))
channel = connection.channel()

# worker’ın dinlediği queue garanti olsun
channel.queue_declare(queue="prediction")

@p_bp.route('/', methods=['POST'])
def predict():
    """
    JSON payload’ı alır → prediction worker’a ateşler.
    “response” yok, sadece publish.
    """
    payload = request.get_json()

    if not payload:
        return jsonify({"error": "body empty"}), 400

    channel.basic_publish(
        exchange='',
        routing_key='prediction',
        body=json.dumps(payload)
    )

    return jsonify({"status": "prediction request queued"}), 200

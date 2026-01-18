from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from sklearn.ensemble import IsolationForest
import pandas as pd
import numpy as np
from datetime import datetime

# Gerekli model import'ları (Hatayı çözmek için)
# Lütfen bu yolların projenizdeki modellerin konumuyla eşleştiğinden emin olun.
from models.transaction_model import TransactionType, UserTransaction
from models.category_model import Category

anomaly_bp = Blueprint('anomaly_bp', __name__, url_prefix='/anomaly')


@anomaly_bp.route('', methods=['POST'])
@jwt_required()
def detect_anomaly():
    """
    Performs anomaly detection on the authenticated user's transaction data using Isolation Forest.
    Returns anomaly detection results for the user's transactions.
    """
    current_user_id = get_jwt_identity()

    from services.transaction_service import TransactionService
    transaction_service = TransactionService()

    user_transactions = transaction_service.get_transactions_by_user(current_user_id)

    if not user_transactions:
        return jsonify({
            "message": "No transactions found for this user",
            "anomalies": [],
            "user_id": current_user_id
        }), 200

    transaction_data = []
    # 'i' (index) değerini alabilmek için enumerate kullanıyoruz
    for i, transaction in enumerate(user_transactions):
        # --- DÜZELTME BAŞLANGICI ---

        # 1. 'type' (Enum) nesnesini güvenle string'e çevir
        # HATA BURADAYDI: 'TransactionType.Expense' -> 'TransactionType.expense' (küçük 'e') olarak düzeltildi
        tx_type_obj = getattr(transaction, 'type', TransactionType.expense)
        tx_type_str = tx_type_obj.name if isinstance(tx_type_obj, TransactionType) else str(tx_type_obj)

        # 2. 'category' (Kategori nesnesi olabilir) güvenle string'e çevir
        cat_obj = getattr(transaction, 'category', 'General')  # Varsayılan 'General'
        cat_str = cat_obj.name if hasattr(cat_obj, 'name') and not isinstance(cat_obj, str) else str(cat_obj)

        # 3. 'date' (datetime) nesnesini JSON uyumlu string'e (ISO format) çevir
        date_obj = transaction.date if hasattr(transaction, 'date') else None
        date_str = date_obj.isoformat() if date_obj else None

        # 4. 'id'yi güvenle al
        tx_id = getattr(transaction, 'id', f"index_{i}")  # ID yoksa geçici index kullan

        # --- DÜZELTME SONU ---

        transaction_dict = {
            "id": tx_id,
            "date": date_str,
            "amount": float(getattr(transaction, 'amount', 0.0)),
            "type": tx_type_str,
            "category": cat_str
        }
        transaction_data.append(transaction_dict)

    if not transaction_data:
        return jsonify({
            "message": "No valid transaction data found for analysis",
            "anomalies": [],
            "user_id": current_user_id
        }), 200

    df = pd.DataFrame(transaction_data)

    # Feature engineering
    if 'date' in df.columns and df['date'].notna().any():
        df['date'] = pd.to_datetime(df['date'], errors='coerce')
        df['day_of_week'] = df['date'].dt.dayofweek.fillna(0)
        df['day_of_month'] = df['date'].dt.day.fillna(1)
        df['month'] = df['date'].dt.month.fillna(1)
    else:
        df['day_of_week'] = 0
        df['day_of_month'] = 1
        df['month'] = 1

    # Encode categorical variables
    df['type_encoded'] = df['type'].map({'income': 1, 'expense': 0, 'Income': 1, 'Expense': 0}).fillna(0)
    df['category_encoded'] = df['category'].astype('category').cat.codes

    feature_columns = ['amount', 'day_of_week', 'day_of_month', 'month', 'type_encoded', 'category_encoded']
    X = df[feature_columns].values

    iso_forest = IsolationForest(
        contamination=0.1,
        random_state=42,
        n_estimators=100
    )

    anomaly_labels = iso_forest.fit_predict(X)

    anomalies = []
    # 'transaction_data' listesini (içinde string'ler olan) 'anomaly_labels' ile birleştir
    for i, is_anomaly in enumerate(anomaly_labels):
        if is_anomaly == -1:  # -1 anomali demektir

            anomalous_transaction = transaction_data[i].copy()
            anomalous_transaction["is_anomaly"] = True

            # Gerçek transaction ID'sini 'id' anahtarından al
            anomalous_transaction["transaction_id"] = anomalous_transaction.pop('id')

            anomalies.append(anomalous_transaction)

    # 'anomalies' listesi artık sadece JSON uyumlu string'ler içeriyor
    return jsonify({
        "anomalies_detected": len(anomalies),
        "total_transactions": len(transaction_data),
        "anomalies": anomalies,
        "user_id": current_user_id
    })
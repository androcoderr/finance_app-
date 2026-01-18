import torch
import torch.nn as nn
import torch.optim as optim
import os
import threading
from pathlib import Path
from queue import Queue
import time
from datetime import datetime, timedelta
from collections import defaultdict
import numpy as np
from models.model_lock_user_data import ModelLockUserData


# --- PYTORCH HYBRID LSTM-FFN MODEL ---
class BudgetHybridModel(nn.Module):
    """
    Hybrid LSTM-FFN model for budget anomaly detection.
    
    Architecture:
    - LSTM Branch: Processes sequential monthly data (6 months x 3 features)
      - Features: [Income, Expense, SavingsRatio]
    - Static Branch: Processes global stats (8 features)
    - Fusion: Concatenates LSTM hidden state + Static features
    - Heads: Savings (Reg), Risk (Sigmoid), Prob (Sigmoid)
    - Uses GELU activation and Dropout for regularization
    """
    def __init__(self):
        super(BudgetHybridModel, self).__init__()
        
        # Branch 1: LSTM for Temporal Patterns
        # Input: (Batch, Seq_Len=6, Features=3)
        self.lstm = nn.LSTM(
            input_size=3, 
            hidden_size=64, 
            num_layers=2, 
            batch_first=True, 
            dropout=0.2
        )
        
        # Branch 2: Static Features FFN with GELU
        # Input: 8 global features
        self.static_ffn = nn.Sequential(
            nn.Linear(8, 64),
            nn.GELU(),
            nn.Dropout(0.3)
        )
        
        # Fusion Layer with GELU and Dropout
        # LSTM output (64) + Static output (64) = 128
        self.fusion = nn.Sequential(
            nn.Linear(128, 64),
            nn.GELU(),
            nn.Dropout(0.3),
            nn.Linear(64, 32),
            nn.GELU()
        )
        
        # Heads
        self.savings_head = nn.Linear(32, 1)
        
        self.risk_head = nn.Sequential(
            nn.Linear(32, 1),
            nn.Sigmoid()
        )
        
        self.prob_head = nn.Sequential(
            nn.Linear(32, 1),
            nn.Sigmoid()
        )

    def forward(self, x_seq, x_static):
        # LSTM Branch - x_seq: (Batch, 6, 3)
        _, (h_n, _) = self.lstm(x_seq)
        lstm_out = h_n[-1]  # (Batch, 64) - Take last layer hidden state
        
        # Static Branch
        static_out = self.static_ffn(x_static)  # (Batch, 64)
        
        # Fusion
        combined = torch.cat((lstm_out, static_out), dim=1)  # (Batch, 128)
        features = self.fusion(combined)
        
        # Heads
        savings = self.savings_head(features)
        risk = self.risk_head(features)
        prob = self.prob_head(features)
        
        return savings, prob, risk


# --- AI SERVICE ---
class AIService:
    """
    Singleton service for AI anomaly detection with Hybrid LSTM-FFN model.
    
    Features:
    - LSTM for temporal spending pattern analysis
    - Traditional algorithm for rule-based predictions
    - Hybrid ensemble (average of LSTM + Traditional)
    - AdamW optimizer with aggressive LR for fast learning
    - Early stopping to prevent overfitting
    - Dropout for regularization
    """
    
    _instance = None
    _lock = threading.Lock()
    
    def __new__(cls):
        if cls._instance is None:
            with cls._lock:
                if cls._instance is None:
                    cls._instance = super(AIService, cls).__new__(cls)
        return cls._instance
    
    def __init__(self):
        if hasattr(self, 'initialized'):
            return
            
        self.initialized = True
        self.models_dir = Path("torch_models")
        self.models_dir.mkdir(exist_ok=True)
        
        self.app_instance = None
        self.training_lock = threading.Lock()
        self.request_queue = Queue()
        self.results_cache = {}
        self.results_lock = threading.Lock()
        self.worker_thread = None
        self.worker_running = False
        
        print("[AIService] Initialized successfully")

    # --- UTILITY METHODS ---
    def get_metadata_path(self, user_id: str) -> Path:
        return self.models_dir / f"{user_id}_meta.json"

    def save_metadata(self, user_id: str, data: dict):
        import json
        with open(self.get_metadata_path(user_id), 'w') as f:
            json.dump(data, f)
            
    def get_metadata(self, user_id: str) -> dict:
        import json
        path = self.get_metadata_path(user_id)
        if path.exists():
            with open(path, 'r') as f:
                return json.load(f)
        return {}

    def get_model_path(self, user_id: str) -> Path:
        return self.models_dir / f"{user_id}_model.pth"

    def is_trained(self, user_id: str) -> bool:
        return self.get_model_path(user_id).exists()

    # --- TRADITIONAL ALGORITHM ---
    def calculate_traditional_metrics(self, transactions, recurring_txs):
        """
        Traditional Rule-Based Algorithm (50/30/20 Rule Adaptation).
        Analyzes spending habits without ML.
        
        Returns: (recommended_savings, success_prob, risk_level)
        """
        total_income = 0
        total_expenses = 0
        
        for t in transactions:
            if t.type.value == 'income':
                total_income += float(t.amount)
            else:
                total_expenses += float(t.amount)
            
        for rt in recurring_txs:
            if rt.type == 'income':
                total_income += float(rt.amount)
            else:
                total_expenses += float(rt.amount)
            
        if total_income == 0:
            return 0, 20, 80
        
        savings_ratio = (total_income - total_expenses) / total_income
        surplus = max(0, total_income - total_expenses)
        
        # 50/30/20 Rule: 20% of income should be saved
        recommended = total_income * 0.20
        recommended = min(recommended, surplus * 0.9)  # Cap at 90% of surplus
        
        # Probability & Risk based on savings ratio
        if savings_ratio >= 0.20:
            prob, risk = 90, 10
        elif savings_ratio >= 0.10:
            prob, risk = 70, 30
        elif savings_ratio > 0:
            prob, risk = 50, 50
        else:
            prob, risk = 20, 80
            
        return recommended, prob, risk

    # --- TRAINING METHOD ---
    def train(self, user_data):
        """
        Train the Hybrid LSTM-FFN model for a specific user.
        Uses AdamW optimizer with aggressive LR and Early Stopping.
        """
        user_id = user_data.user_id
        
        if not self.training_lock.acquire(blocking=False):
            print(f"[{user_id}] Training already in progress. Skipping.")
            return

        try:
            from models.transaction_model import UserTransaction
            from models.recurring_transaction_model import RecurringTransaction
            
            transactions = UserTransaction.query.filter_by(user_id=user_id).all()
            recurring_txs = RecurringTransaction.query.filter_by(user_id=user_id).all()
            total_data_points = len(transactions) + len(recurring_txs)
            
            # --- Prepare Sequential Data (6 months) ---
            monthly_stats = defaultdict(lambda: {'income': 0, 'expenses': 0})
            
            def get_month_key(date_obj):
                return date_obj.strftime('%Y-%m')
            
            for t in transactions:
                key = 'income' if t.type.value == 'income' else 'expenses'
                monthly_stats[get_month_key(t.date)][key] += float(t.amount)
                
            for rt in recurring_txs:
                current_month = datetime.now()
                for i in range(6):
                    m_key = get_month_key(current_month - timedelta(days=30*i))
                    key = 'income' if rt.type == 'income' else 'expenses'
                    monthly_stats[m_key][key] += float(rt.amount)

            sorted_months = sorted(monthly_stats.keys())
            sequence_data = []
            for m in sorted_months[-6:]:
                d = monthly_stats[m]
                inc, exp = d['income'], d['expenses']
                ratio = (inc - exp) / max(inc, 1)
                sequence_data.append([inc, exp, ratio])
                
            while len(sequence_data) < 6:
                sequence_data.insert(0, [0.0, 0.0, 0.0])
                
            x_seq_tensor = torch.tensor([sequence_data], dtype=torch.float32)
            x_static_tensor = torch.randn(1, 8)  # Placeholder static features
            
            # Targets (will be refined with synthetic data)
            y_savings = torch.tensor([[100.0]], dtype=torch.float32)
            y_prob = torch.tensor([[0.8]], dtype=torch.float32)
            y_risk = torch.tensor([[0.2]], dtype=torch.float32)

            # Initialize Model with AdamW (aggressive LR)
            model = BudgetHybridModel()
            optimizer = optim.AdamW(model.parameters(), lr=0.005, weight_decay=1e-5)
            
            # Early Stopping Setup
            best_loss = float('inf')
            patience, trigger_times = 5, 0
            
            model.train()
            for epoch in range(50):  # Max 50 epochs
                optimizer.zero_grad()
                
                # Create synthetic batch with noise for generalization
                batch_size = 32
                batch_seq = x_seq_tensor.repeat(batch_size, 1, 1) + torch.randn(batch_size, 6, 3) * 0.1
                batch_static = x_static_tensor.repeat(batch_size, 1) + torch.randn(batch_size, 8) * 0.1
                
                savings, prob, risk = model(batch_seq, batch_static)
                
                loss = nn.MSELoss()(savings, y_savings.repeat(batch_size, 1)) + \
                       nn.BCELoss()(prob, y_prob.repeat(batch_size, 1)) + \
                       nn.BCELoss()(risk, y_risk.repeat(batch_size, 1))
                       
                loss.backward()
                optimizer.step()
                
                # Early Stopping Check
                current_loss = loss.item()
                if current_loss < best_loss - 1e-4:
                    best_loss = current_loss
                    trigger_times = 0
                else:
                    trigger_times += 1
                    if trigger_times >= patience:
                        print(f"[{user_id}] Early stopping at epoch {epoch}")
                        break
            
            # Save Model
            save_path = self.get_model_path(user_id)
            torch.save(model.state_dict(), save_path)
            
            self.save_metadata(user_id, {
                "last_train_date": datetime.now().isoformat(),
                "training_count": total_data_points,
                "model_type": "hybrid_lstm"
            })
            print(f"[{user_id}] Hybrid Training completed.")
            
        except Exception as e:
            print(f"[{user_id}] Training failed: {str(e)}")
            import traceback
            traceback.print_exc()
        finally:
            self.training_lock.release()

    # --- INFERENCE METHOD ---
    def prompt(self, user_id: str, goal_id: str, goal_date: str = None):
        """
        Perform budget analysis using Hybrid LSTM + Traditional Algorithm ensemble.
        """
        if not self.is_trained(user_id):
            print(f"[{user_id}] ERROR: Model not found!")
            return None

        try:
            from models.goal_model import Goal
            from models.goal_date import GoalDate
            from models.transaction_model import UserTransaction
            from models.recurring_transaction_model import RecurringTransaction
            
            # Fetch goal information
            goal = Goal.query.filter_by(id=goal_id, user_id=user_id).first()
            if not goal:
                print(f"[{user_id}] ERROR: Goal {goal_id} not found!")
                return None
            
            # Get goal date
            if goal_date:
                goal_date_obj = GoalDate.query.filter_by(goal_id=goal_id, date=goal_date).first()
            else:
                goal_date_obj = GoalDate.query.filter_by(goal_id=goal_id).order_by(GoalDate.date.desc()).first()
            
            if not goal_date_obj:
                target_date = datetime.now()
                months_remaining = 12
            else:
                target_date = datetime.fromisoformat(str(goal_date_obj.date))
                months_delta = (target_date.year - datetime.now().year) * 12 + (target_date.month - datetime.now().month)
                months_remaining = max(1, months_delta)
            
            # Goal info
            target_amount = float(goal.target_amount)
            current_amount = float(goal.current_amount)
            remaining_amount = max(0, target_amount - current_amount)
            
            # Fetch transaction data
            transactions = UserTransaction.query.filter_by(user_id=user_id).all()
            recurring_txs = RecurringTransaction.query.filter_by(user_id=user_id).all()
            
            # Calculate financial features
            total_income = 0
            total_expenses = 0
            monthly_data = defaultdict(lambda: {'income': 0, 'expenses': 0})
            
            for t in transactions:
                month_key = t.date.strftime('%Y-%m')
                if t.type.value == 'income':
                    total_income += float(t.amount)
                    monthly_data[month_key]['income'] += float(t.amount)
                else:
                    total_expenses += float(t.amount)
                    monthly_data[month_key]['expenses'] += float(t.amount)
            
            for rt in recurring_txs:
                if rt.type == 'income':
                    total_income += float(rt.amount)
                else:
                    total_expenses += float(rt.amount)
            
            months_with_data = max(len(monthly_data), 1)
            avg_monthly_income = total_income / months_with_data
            avg_monthly_expenses = total_expenses / months_with_data
            
            # --- Prepare Sequential Data for LSTM ---
            monthly_stats = defaultdict(lambda: {'income': 0, 'expenses': 0})
            
            def get_month_key(date_obj):
                return date_obj.strftime('%Y-%m')
            
            for t in transactions:
                key = 'income' if t.type.value == 'income' else 'expenses'
                monthly_stats[get_month_key(t.date)][key] += float(t.amount)
                
            for rt in recurring_txs:
                current_month = datetime.now()
                for i in range(6):
                    m_key = get_month_key(current_month - timedelta(days=30*i))
                    key = 'income' if rt.type == 'income' else 'expenses'
                    monthly_stats[m_key][key] += float(rt.amount)

            sorted_months = sorted(monthly_stats.keys())
            sequence_data = []
            for m in sorted_months[-6:]:
                d = monthly_stats[m]
                inc, exp = d['income'], d['expenses']
                ratio = (inc - exp) / max(inc, 1)
                sequence_data.append([inc, exp, ratio])
                
            while len(sequence_data) < 6:
                sequence_data.insert(0, [0.0, 0.0, 0.0])
                
            x_seq_tensor = torch.tensor([sequence_data], dtype=torch.float32)
            x_static_tensor = torch.randn(1, 8)
            
            # Load model
            model = BudgetHybridModel()
            model.load_state_dict(torch.load(self.get_model_path(user_id)))
            model.eval()

            # LSTM Model Inference
            with torch.no_grad():
                savings, prob, risk = model(x_seq_tensor, x_static_tensor)
            
            model_savings = savings.item()
            model_prob = prob.item() * 100
            model_risk = risk.item() * 100
            
            # --- HYBRID ENSEMBLE: LSTM + Traditional Algorithm ---
            trad_savings, trad_prob, trad_risk = self.calculate_traditional_metrics(transactions, recurring_txs)
            
            print(f"[{user_id}] LSTM: Sav={model_savings:.0f}, Prob={model_prob:.0f}%, Risk={model_risk:.0f}%")
            print(f"[{user_id}] Trad: Sav={trad_savings:.0f}, Prob={trad_prob:.0f}%, Risk={trad_risk:.0f}%")
            
            # Average (60% Model, 40% Traditional)
            savings_raw = (model_savings * 0.6) + (trad_savings * 0.4)
            prob_raw = ((model_prob * 0.6) + (trad_prob * 0.4)) / 100.0
            risk_raw = ((model_risk * 0.6) + (trad_risk * 0.4)) / 100.0
            
            # --- REALISTIC OUTPUT PROCESSING ---
            actual_monthly_savings = max(0, avg_monthly_income - avg_monthly_expenses)
            required_monthly = remaining_amount / max(months_remaining, 1)
            
            # Monthly Savings Recommendation
            if required_monthly > avg_monthly_income * 0.7:
                aylik_tasarruf = min(avg_monthly_income * 0.7, actual_monthly_savings * 1.2)
            elif required_monthly > actual_monthly_savings:
                aylik_tasarruf = (required_monthly * 0.6) + (max(0, savings_raw) * 0.4)
                aylik_tasarruf = min(aylik_tasarruf, actual_monthly_savings * 1.2)
            else:
                aylik_tasarruf = required_monthly
            
            min_limit = min(100.0, required_monthly)
            aylik_tasarruf = max(min_limit, min(aylik_tasarruf, avg_monthly_income * 0.75))
            
            # Success Probability
            savings_gap = required_monthly / max(actual_monthly_savings, 1.0)
            base_prob = prob_raw * 100
            
            if savings_gap <= 0.5:
                boost = (0.5 - savings_gap) * 60
                basari_olasiligi = min(98, base_prob + boost)
                if savings_gap < 0.2:
                    basari_olasiligi = max(basari_olasiligi, 90)
            elif savings_gap <= 1.0:
                penalty_factor = 1.0 - ((savings_gap - 0.5) * 0.2)
                basari_olasiligi = base_prob * penalty_factor
            else:
                penalty_factor = 1.0 / (1.0 + (savings_gap - 1.0) * 2.0)
                basari_olasiligi = base_prob * penalty_factor
            
            income_share = required_monthly / max(avg_monthly_income, 1.0)
            if income_share > 0.5:
                basari_olasiligi = min(basari_olasiligi, 60)
            if income_share > 0.7:
                basari_olasiligi = min(basari_olasiligi, 30)
                
            basari_olasiligi = max(5, round(basari_olasiligi, 0))
            
            # Risk Level
            base_risk = risk_raw * 100
            if savings_gap > 2.0:
                risk_seviyesi = max(65, min(90, base_risk + 40))
            elif savings_gap > 1.5:
                risk_seviyesi = max(45, min(75, base_risk + 25))
            elif savings_gap > 1.0:
                risk_seviyesi = max(25, min(55, base_risk + 15))
            else:
                risk_seviyesi = max(5, min(35, base_risk))
                
            risk_seviyesi = max(5, round(risk_seviyesi, 0))
            
            if basari_olasiligi + risk_seviyesi > 110:
                risk_seviyesi = max(10, 105 - basari_olasiligi)
            
            # Generate Turkish description
            risk_label = "düşük" if risk_seviyesi < 33 else "orta" if risk_seviyesi < 67 else "yüksek"
            
            aciklama = (
                f"{months_remaining} aylık {goal.name} hedefiniz için "
                f"aylık {aylik_tasarruf:,.0f} TL tasarruf öneriyoruz. "
                f"Başarı şansınız %{basari_olasiligi:.0f}, "
                f"risk seviyeniz {risk_label} (%{risk_seviyesi:.0f})."
            )
            
            result = {
                "aylik_tasarruf": round(aylik_tasarruf, 2),
                "basari_olasiligi": round(basari_olasiligi, 2),
                "risk_seviyesi": round(risk_seviyesi, 2),
                "aciklama": aciklama,
                "goal_info": {
                    "goal_name": goal.name,
                    "target_amount": target_amount,
                    "current_amount": current_amount,
                    "remaining_amount": remaining_amount,
                    "target_date": target_date.strftime('%Y-%m-%d') if goal_date_obj else None,
                    "months_remaining": months_remaining
                }
            }
            
            # Cache result
            with self.results_lock:
                self.results_cache[goal_id] = result
                print(f"[{user_id}] Result cached for goal_id: {goal_id}")
            
            print(f"[{user_id}] Budget Analysis for goal '{goal.name}': {result}")
            return result
            
        except Exception as e:
            print(f"[{user_id}] Inference failed: {str(e)}")
            import traceback
            traceback.print_exc()
            return None

    # --- WORKER METHODS ---
    def get_result(self, goal_id: str):
        with self.results_lock:
            return self.results_cache.get(goal_id)
    
    def queue_request(self, user_data: ModelLockUserData):
        self.request_queue.put(user_data)
        print(f"[AIService] Request queued for user: {user_data.user_id}")

    def start_worker(self, app=None):
        if self.worker_running:
            print("[AIService] Worker already running")
            return
        
        if app:
            self.app_instance = app
            
        self.worker_running = True
        self.worker_thread = threading.Thread(target=self._worker, daemon=True)
        self.worker_thread.start()
        print("[AIService] Background worker started")

    def stop_worker(self):
        self.worker_running = False
        if self.worker_thread:
            self.worker_thread.join(timeout=5)
        print("[AIService] Worker stopped")

    def _worker(self):
        print("[AIService Worker] Started and waiting for requests...")
        
        while self.worker_running:
            try:
                user_data = self.request_queue.get(timeout=1)
                user_id = user_data.user_id
                
                print(f"\n[Worker] Processing request for user: {user_id}")
                
                if not self.app_instance:
                    print(f"[Worker] ERROR: No Flask app instance available!")
                    continue
                    
                with self.app_instance.app_context():
                    needs_training = not self.is_trained(user_id)
                    
                    if not needs_training:
                        try:
                            from models.transaction_model import UserTransaction
                            from models.recurring_transaction_model import RecurringTransaction
                            
                            tx_count = UserTransaction.query.filter_by(user_id=user_id).count()
                            rec_count = RecurringTransaction.query.filter_by(user_id=user_id).count()
                            current_total = tx_count + rec_count
                            
                            metadata = self.get_metadata(user_id)
                            last_count = metadata.get("training_count", 0)
                            
                            if current_total >= last_count * 2 and current_total > 5:
                                print(f"[Worker] Data doubled ({last_count} -> {current_total}). Retraining...")
                                needs_training = True
                        except Exception as e:
                            print(f"[Worker] Retraining check failed: {e}")
                    
                    if needs_training:
                        print(f"[Worker] Starting training for {user_id}...")
                        self.train(user_data)
                        
                    if user_data.goal_id:
                        if self.is_trained(user_id):
                            print(f"[Worker] Running budget analysis for goal {user_data.goal_id}...")
                            self.prompt(user_id, user_data.goal_id, user_data.goal_date)
                        else:
                            print(f"[Worker] ERROR: Training failed, cannot run inference.")
                
                self.request_queue.task_done()
                
            except Exception as e:
                if "Empty" not in str(type(e).__name__):
                    print(f"[Worker] Error: {str(e)}")
                    import traceback
                    traceback.print_exc()
                continue

from database.db import db
import uuid

class Insight(db.Model):
    __tablename__ = 'insights'

    id = db.Column(db.String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.String, db.ForeignKey('users.id'), nullable=False)
    content = db.Column(db.Text)
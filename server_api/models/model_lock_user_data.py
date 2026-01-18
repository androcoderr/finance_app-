class ModelLockUserData:
    """
    Data class for queue items in the AI budget analysis system.
    Contains user information and optional goal data for inference.
    """
    def __init__(self, user_id: str, goal_id: str = None, goal_date: str = None):
        self.user_id = user_id
        self.goal_id = goal_id  # For inference: specific goal to analyze
        self.goal_date = goal_date  # Optional: specific goal_date to use
        self.transaction_ids = []  # Will be populated from database

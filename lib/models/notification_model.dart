class NotificationModel {
  final String id;
  final String message;
  final bool isAnomaly;
  final DateTime timestamp;
  final String? transactionId;
  bool isRead;

  NotificationModel({
    required this.id,
    required this.message,
    required this.isAnomaly,
    required this.timestamp,
    this.transactionId,
    bool? isRead,
  }) : isRead = isRead ?? false;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      message: json['message'],
      isAnomaly: json['isAnomaly'],
      timestamp: DateTime.parse(json['timestamp']),
      transactionId: json['transactionId'],
      isRead: json['isRead'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'isAnomaly': isAnomaly,
      'timestamp': timestamp.toIso8601String(),
      'transactionId': transactionId,
      'isRead': isRead,
    };
  }

  void markAsRead() {
    isRead = true;
  }
}

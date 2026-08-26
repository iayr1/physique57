class ApprovalStepModel {
  final String title;
  final String? actorName;
  final String? actorRole;
  final DateTime? timestamp;
  final bool isCompleted;
  final bool isRejected;
  final String? comment;

  const ApprovalStepModel({
    required this.title,
    this.actorName,
    this.actorRole,
    this.timestamp,
    this.isCompleted = false,
    this.isRejected = false,
    this.comment,
  });

  factory ApprovalStepModel.fromJson(Map<String, dynamic> json) {
    return ApprovalStepModel(
      title: json['title'] as String,
      actorName: json['actorName'] as String?,
      actorRole: json['actorRole'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
      isCompleted: json['isCompleted'] as bool? ?? false,
      isRejected: json['isRejected'] as bool? ?? false,
      comment: json['comment'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'actorName': actorName,
      'actorRole': actorRole,
      'timestamp': timestamp?.toIso8601String(),
      'isCompleted': isCompleted,
      'isRejected': isRejected,
      'comment': comment,
    };
  }
}

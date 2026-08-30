enum NotificationType {
  predictionResult,
  featureUpdate,
  reward,
  collection,
  general,
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isRead,
    this.relatedPredictionId,
    this.relatedCompanyId,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final String? relatedPredictionId;
  final String? relatedCompanyId;

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    type: type,
    title: title,
    message: message,
    createdAt: createdAt,
    isRead: isRead ?? this.isRead,
    relatedPredictionId: relatedPredictionId,
    relatedCompanyId: relatedCompanyId,
  );

  Map<String, Object> toJson() => {
    'id': id,
    'type': type.name,
    'title': title,
    'message': message,
    'createdAt': createdAt.toIso8601String(),
    'isRead': isRead,
    'relatedPredictionId': ?relatedPredictionId,
    'relatedCompanyId': ?relatedCompanyId,
  };

  factory AppNotification.fromJson(Map<String, Object?> json) =>
      AppNotification(
        id: json['id']! as String,
        type: NotificationType.values.byName(json['type']! as String),
        title: json['title']! as String,
        message: json['message']! as String,
        createdAt: DateTime.parse(json['createdAt']! as String),
        isRead: json['isRead'] as bool? ?? false,
        relatedPredictionId: json['relatedPredictionId'] as String?,
        relatedCompanyId: json['relatedCompanyId'] as String?,
      );
}

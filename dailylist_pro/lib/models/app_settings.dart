class AppSettings {
  final bool notificationsEnabled;

  AppSettings({
    required this.notificationsEnabled,
  });

  // Convert AppSettings to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'notificationsEnabled': notificationsEnabled,
    };
  }

  // Create AppSettings from JSON
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      notificationsEnabled: json['notificationsEnabled'] ?? true,
    );
  }

  // Create a copy of AppSettings with modified fields
  AppSettings copyWith({
    bool? notificationsEnabled,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  // Default settings
  static AppSettings get defaultSettings {
    return AppSettings(
      notificationsEnabled: true,
    );
  }

  @override
  String toString() {
    return 'AppSettings(notificationsEnabled: $notificationsEnabled)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSettings && 
           other.notificationsEnabled == notificationsEnabled;
  }

  @override
  int get hashCode {
    return notificationsEnabled.hashCode;
  }
}
class MaintenanceData {
  final bool active;
  final bool showBanner;
  final bool showMaintenancePage;

  final String title;
  final String subtitle;
  final String message;

  final String hindiTitle;
  final String hindiSubtitle;
  final String hindiMessage;

  final DateTime? startAt;
  final DateTime? endAt;

  const MaintenanceData({
    required this.active,
    required this.showBanner,
    required this.showMaintenancePage,
    required this.title,
    required this.subtitle,
    required this.message,
    required this.hindiTitle,
    required this.hindiSubtitle,
    required this.hindiMessage,
    this.startAt,
    this.endAt,
  });

  factory MaintenanceData.fromJson(Map<String, dynamic> json) {
    return MaintenanceData(
      active: json['active'] == true,

      showBanner: json['showBanner'] == true,

      showMaintenancePage:
          json['showMaintenancePage'] == true,

      title: json['title']?.toString().trim() ?? '',
      subtitle: json['subtitle']?.toString().trim() ?? '',
      message: json['message']?.toString().trim() ?? '',

      hindiTitle:
          json['hindiTitle']?.toString().trim() ?? '',

      hindiSubtitle:
          json['hindiSubtitle']?.toString().trim() ?? '',

      hindiMessage:
          json['hindiMessage']?.toString().trim() ?? '',

      startAt: _parseDate(
        json['startDateTime'] ?? json['startAt'],
      ),

      endAt: _parseDate(
        json['endDateTime'] ?? json['endAt'],
      ),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    return DateTime.tryParse(
      value.toString(),
    )?.toLocal();
  }
}
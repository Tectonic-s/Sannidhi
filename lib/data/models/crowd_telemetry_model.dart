class CrowdTelemetryModel {
  final String status;
  final int estimatedWaitMinutes;
  final String timestamp;
  final int currentVisitors;
  
  CrowdTelemetryModel({
    required this.status,
    required this.estimatedWaitMinutes,
    required this.timestamp,
    required this.currentVisitors,
  });
  
  factory CrowdTelemetryModel.fromJson(Map<String, dynamic> json) {
    return CrowdTelemetryModel(
      status: json['status'] as String,
      estimatedWaitMinutes: json['estimated_wait_minutes'] as int,
      timestamp: json['timestamp'] as String,
      currentVisitors: json['current_visitors'] as int,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'estimated_wait_minutes': estimatedWaitMinutes,
      'timestamp': timestamp,
      'current_visitors': currentVisitors,
    };
  }
  
  CrowdTelemetryModel copyWith({
    String? status,
    int? estimatedWaitMinutes,
    String? timestamp,
    int? currentVisitors,
  }) {
    return CrowdTelemetryModel(
      status: status ?? this.status,
      estimatedWaitMinutes: estimatedWaitMinutes ?? this.estimatedWaitMinutes,
      timestamp: timestamp ?? this.timestamp,
      currentVisitors: currentVisitors ?? this.currentVisitors,
    );
  }
}

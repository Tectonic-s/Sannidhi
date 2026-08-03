class FestivalModel {
  final String id;
  final String name;
  final String date;
  final String description;
  final String imageUrl;
  final bool isSpecial;
  final bool isTamilMonth;
  final String tamilName;
  
  FestivalModel({
    required this.id,
    required this.name,
    required this.date,
    required this.description,
    required this.imageUrl,
    this.isSpecial = false,
    this.isTamilMonth = false,
    required this.tamilName,
  });
  
  factory FestivalModel.fromJson(Map<String, dynamic> json) {
    return FestivalModel(
      id: json['id'] as String,
      name: json['name'] as String,
      date: json['date'] as String,
      description: json['description'] as String,
      imageUrl: json['image_url'] as String,
      isSpecial: json['is_special'] as bool? ?? false,
      isTamilMonth: json['is_tamil_month'] as bool? ?? false,
      tamilName: json['tamil_name'] as String,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'date': date,
      'description': description,
      'image_url': imageUrl,
      'is_special': isSpecial,
      'is_tamil_month': isTamilMonth,
      'tamil_name': tamilName,
    };
  }
  
  FestivalModel copyWith({
    String? id,
    String? name,
    String? date,
    String? description,
    String? imageUrl,
    bool? isSpecial,
    bool? isTamilMonth,
    String? tamilName,
  }) {
    return FestivalModel(
      id: id ?? this.id,
      name: name ?? this.name,
      date: date ?? this.date,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      isSpecial: isSpecial ?? this.isSpecial,
      isTamilMonth: isTamilMonth ?? this.isTamilMonth,
      tamilName: tamilName ?? this.tamilName,
    );
  }
}

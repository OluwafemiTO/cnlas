class SearchableItem {
  final String type;
  final String id;
  final String name;
  final String? email;
  final String? department;
  final Map<String, dynamic> location;

  SearchableItem({
    required this.type,
    required this.id,
    required this.name,
    this.email,
    this.department,
    required this.location,
  });

  factory SearchableItem.fromJson(Map<String, dynamic> json) {
    return SearchableItem(
      type: json['type'],
      id: json['id'],
      name: json['Name'],
      email: json['Email'],
      department: json['Department'],
      location: json['location'],
    );
  }

  String get searchableText {
    final parts = [
      name,
      email ?? '',
      department ?? '',
      location['Office_Building'] ?? '',
      location['abbv'] ?? '',
      location['Office_Number'] ?? '',
    ];
    return parts.join(' ').toLowerCase();
  }
}
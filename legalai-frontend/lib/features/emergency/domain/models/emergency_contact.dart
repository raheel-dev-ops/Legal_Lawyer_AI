class EmergencyContact {
  final int id;
  final String name;
  final String relation;
  final String phone;
  final String countryCode;
  final bool isPrimary;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.relation,
    required this.phone,
    required this.countryCode,
    required this.isPrimary,
  });

  factory EmergencyContact.fromApi(Map<String, dynamic> json) {
    return EmergencyContact(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      relation: (json['relation'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      countryCode: (json['countryCode'] ?? '+92').toString(),
      isPrimary: json['isPrimary'] == true,
    );
  }

  Map<String, dynamic> toApi() {
    return {
      'name': name,
      'relation': relation,
      'phone': phone,
      'countryCode': countryCode,
      'isPrimary': isPrimary,
    };
  }

  String get fullNumber => '$countryCode$phone';

  String get displayNumber {
    final raw = fullNumber.replaceAll(' ', '');
    if (raw.length < 6) return raw;
    return raw.replaceFirstMapped(RegExp(r'(\\+?\\d{2})(\\d{3})(\\d+)'), (m) {
      return '${m[1]} ${m[2]} ${m[3]}';
    });
  }
}

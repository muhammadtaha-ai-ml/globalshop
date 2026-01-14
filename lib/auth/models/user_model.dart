class AppUser {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String deviceId;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.deviceId,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'deviceId': deviceId,
    };
  }
}

class ToBuyUser {
  final String uid;
  final String email;
  final DateTime createdAt;

  ToBuyUser({
    required this.uid,
    required this.email,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ToBuyUser.fromMap(Map<String, dynamic> map) {
    return ToBuyUser(
      uid: map['uid'] as String,
      email: map['email'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
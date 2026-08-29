class UserModel {
  final String id;
  final String email;
  final String name;
  final String? avatarUrl;
  final String? birthday;
  final String pairCode;
  final String? coupleId;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
    this.birthday,
    required this.pairCode,
    this.coupleId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String,
        avatarUrl: json['avatarUrl'] as String?,
        birthday: json['birthday'] as String?,
        pairCode: json['pairCode'] as String,
        coupleId: json['coupleId'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'avatarUrl': avatarUrl,
        'birthday': birthday,
        'pairCode': pairCode,
        'coupleId': coupleId,
      };

  bool get isPaired => coupleId != null;
}

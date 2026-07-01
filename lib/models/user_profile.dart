class UserProfile {
  final String email;
  final String password;
  final String name;
  final String gender;
  final bool marketingNews;
  final bool marketingShare;

  const UserProfile({
    required this.email,
    required this.password,
    required this.name,
    required this.gender,
    this.marketingNews = false,
    this.marketingShare = false,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'name': name,
        'gender': gender,
        'marketingNews': marketingNews,
        'marketingShare': marketingShare,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      email: json['email'] as String? ?? '',
      password: json['password'] as String? ?? '',
      name: json['name'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      marketingNews: json['marketingNews'] as bool? ?? false,
      marketingShare: json['marketingShare'] as bool? ?? false,
    );
  }
}

class KriptonUser {
  final String id;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final String subscriptionTier;
  final int monthlyLinksGenerated;
  final DateTime? subscriptionExpiresAt;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  KriptonUser({
    required this.id,
    required this.email,
    this.displayName,
    this.avatarUrl,
    this.subscriptionTier = 'free',
    this.monthlyLinksGenerated = 0,
    this.subscriptionExpiresAt,
    required this.createdAt,
    this.lastLoginAt,
  });

  factory KriptonUser.fromJson(Map<String, dynamic> json) {
    return KriptonUser(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      subscriptionTier: json['subscription_tier'] as String? ?? 'free',
      monthlyLinksGenerated: json['monthly_links_generated'] as int? ?? 0,
      subscriptionExpiresAt: json['subscription_expires_at'] != null
          ? DateTime.parse(json['subscription_expires_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'subscription_tier': subscriptionTier,
      'monthly_links_generated': monthlyLinksGenerated,
      'subscription_expires_at': subscriptionExpiresAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
    };
  }

  bool get isFree => subscriptionTier == 'free';
  bool get isPremium => subscriptionTier == 'premium' || subscriptionTier == 'enterprise';
  int get linksRemaining => 50 - monthlyLinksGenerated; // max 50 for free tier
  bool get canCreateLink => isPremium || monthlyLinksGenerated < 50;
}

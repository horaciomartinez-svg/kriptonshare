import '../utils/constants.dart';

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
  final int totalStorageUsedBytes;
  final int maxStoragePremiumBytes;

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
    this.totalStorageUsedBytes = 0,
    this.maxStoragePremiumBytes = 2147483648,
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
      totalStorageUsedBytes: json['total_storage_used_bytes'] as int? ?? 0,
      maxStoragePremiumBytes: json['max_storage_premium_bytes'] as int? ?? 2147483648,
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
      'total_storage_used_bytes': totalStorageUsedBytes,
      'max_storage_premium_bytes': maxStoragePremiumBytes,
    };
  }

  bool get isFree => subscriptionTier == 'free';
  bool get isPremium => subscriptionTier == 'premium' || subscriptionTier == 'enterprise';

  int get linksRemaining => (AppConstants.maxLinksPerMonth - monthlyLinksGenerated).clamp(0, AppConstants.maxLinksPerMonth);
  bool get canCreateLink => isPremium || monthlyLinksGenerated < AppConstants.maxLinksPerMonth;

  int get maxFileSizeBytes => isPremium
      ? AppConstants.premiumMaxFileSizeBytes
      : AppConstants.freeMaxFileSizeBytes;

  int get maxDurationHours => isPremium
      ? AppConstants.premiumMaxDurationHours
      : AppConstants.freeMaxDurationHours;

  int get remainingPremiumStorageBytes => isPremium
      ? (maxStoragePremiumBytes - totalStorageUsedBytes).clamp(0, maxStoragePremiumBytes)
      : 0;
}

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import '../db/database.dart';
import '../utils/unique_id.dart';

/// Subscription tier levels
enum SubscriptionTier {
  archer,       // Free - £0/mo
  competitor,   // Base - £2/mo
  professional, // Premium - £7.20/mo
  hustonSchool, // Future - £40/mo
}

extension SubscriptionTierExtension on SubscriptionTier {
  String get displayName {
    switch (this) {
      case SubscriptionTier.archer:
        return 'Archer';
      case SubscriptionTier.competitor:
        return 'Competitor';
      case SubscriptionTier.professional:
        return 'Professional';
      case SubscriptionTier.hustonSchool:
        return 'Huston School';
    }
  }

  String get price {
    switch (this) {
      case SubscriptionTier.archer:
        return 'Free';
      case SubscriptionTier.competitor:
        return '£2/mo';
      case SubscriptionTier.professional:
        return '£7.20/mo';
      case SubscriptionTier.hustonSchool:
        return '£40/mo';
    }
  }

  String get description {
    switch (this) {
      case SubscriptionTier.archer:
        return 'Equipment, volume, scores, breathing, bow training, Plotting course';
      case SubscriptionTier.competitor:
        return 'Everything in Archer + Shaft analysis, OLY training, Auto-Plot (50/mo)';
      case SubscriptionTier.professional:
        return 'Everything in Competitor + Unlimited Auto-Plot';
      case SubscriptionTier.hustonSchool:
        return 'Everything in Professional + Video coaching library';
    }
  }

  int get autoPlotLimit {
    switch (this) {
      case SubscriptionTier.archer:
        return 0;
      case SubscriptionTier.competitor:
        return 50;
      case SubscriptionTier.professional:
      case SubscriptionTier.hustonSchool:
        return -1; // Unlimited
    }
  }

  static SubscriptionTier fromString(String value) {
    switch (value.toLowerCase()) {
      case 'competitor':
        return SubscriptionTier.competitor;
      case 'professional':
        return SubscriptionTier.professional;
      case 'hustonschool':
      case 'huston_school':
        return SubscriptionTier.hustonSchool;
      default:
        return SubscriptionTier.archer;
    }
  }
}

/// Manages user entitlements, subscription status, and feature gating
class EntitlementProvider extends ChangeNotifier {
  final AppDatabase _db;

  SubscriptionTier _tier = SubscriptionTier.archer;
  DateTime? _expiresAt;
  DateTime? _graceEndsAt;
  bool _isLegacy3dAiming = false;
  String? _stripeCustomerId;
  String? _stripeSubscriptionId;
  bool _isLoading = true;

  EntitlementProvider(this._db);

  // Getters
  SubscriptionTier get tier => _tier;
  DateTime? get expiresAt => _expiresAt;
  DateTime? get graceEndsAt => _graceEndsAt;
  bool get isLegacy3dAiming => _isLegacy3dAiming;
  bool get isLoading => _isLoading;
  String? get stripeCustomerId => _stripeCustomerId;
  String? get stripeSubscriptionId => _stripeSubscriptionId;

  /// Whether the subscription is active (not expired or in grace period)
  bool get isSubscriptionActive {
    if (_tier == SubscriptionTier.archer) return true; // Free tier always active
    if (_expiresAt == null) return true; // No expiry set
    final now = DateTime.now();
    return now.isBefore(_expiresAt!);
  }

  /// Whether we're in the 72-hour grace period after expiry
  bool get isInGracePeriod {
    if (_tier == SubscriptionTier.archer) return false;
    if (_expiresAt == null || _graceEndsAt == null) return false;
    final now = DateTime.now();
    return now.isAfter(_expiresAt!) && now.isBefore(_graceEndsAt!);
  }

  /// Whether the subscription has fully expired (past grace period)
  bool get isExpired {
    if (_tier == SubscriptionTier.archer) return false;
    if (_graceEndsAt == null) return false;
    return DateTime.now().isAfter(_graceEndsAt!);
  }

  /// Time remaining in grace period
  Duration? get graceTimeRemaining {
    if (!isInGracePeriod || _graceEndsAt == null) return null;
    return _graceEndsAt!.difference(DateTime.now());
  }

  // ===========================================================================
  // FEATURE GATES
  // ===========================================================================

  /// Has access to shaft analysis (Ranger+)
  bool get hasShaftAnalysis {
    if (isExpired) return false;
    return _tier.index >= SubscriptionTier.competitor.index;
  }

  /// Has access to OLY training (Ranger+)
  bool get hasOlyTraining {
    if (isExpired) return false;
    return _tier.index >= SubscriptionTier.competitor.index;
  }

  /// Has access to Auto-Plot (Ranger+)
  bool get hasAutoPlot {
    if (isExpired) return false;
    return _tier.index >= SubscriptionTier.competitor.index;
  }

  /// Has unlimited Auto-Plot (Elite+)
  bool get hasUnlimitedAutoPlot {
    if (isExpired) return false;
    return _tier.index >= SubscriptionTier.professional.index;
  }

  /// Has access to Huston School video library (HustonSchool only)
  bool get hasHustonSchool {
    if (isExpired) return false;
    return _tier == SubscriptionTier.hustonSchool;
  }

  /// Has access to 3D Aiming course (purchased or legacy)
  bool get has3dAimingCourse => _isLegacy3dAiming;

  /// Monthly Auto-Plot limit based on tier
  int get autoPlotMonthlyLimit => _tier.autoPlotLimit;

  /// Check if user can use Auto-Plot based on current usage
  Future<bool> canUseAutoPlot() async {
    if (!hasAutoPlot) return false;
    if (hasUnlimitedAutoPlot) return true;

    final currentUsage = await _db.getCurrentAutoPlotScanCount();
    return currentUsage < autoPlotMonthlyLimit;
  }

  /// Get remaining Auto-Plot scans this month
  Future<int> getRemainingAutoPlotScans() async {
    if (!hasAutoPlot) return 0;
    if (hasUnlimitedAutoPlot) return -1;

    final currentUsage = await _db.getCurrentAutoPlotScanCount();
    return (autoPlotMonthlyLimit - currentUsage).clamp(0, autoPlotMonthlyLimit);
  }

  // ===========================================================================
  // DATA LOADING
  // ===========================================================================

  /// Load entitlement from database
  Future<void> loadEntitlement() async {
    _isLoading = true;
    notifyListeners();

    try {
      final entitlement = await _db.getEntitlement();
      if (entitlement != null) {
        _tier = SubscriptionTierExtension.fromString(entitlement.tier);
        _expiresAt = entitlement.expiresAt;
        _graceEndsAt = entitlement.graceEndsAt;
        _isLegacy3dAiming = entitlement.isLegacy3dAiming;
        _stripeCustomerId = entitlement.stripeCustomerId;
        _stripeSubscriptionId = entitlement.stripeSubscriptionId;
      } else {
        // Create default free tier entitlement
        await _createDefaultEntitlement();
      }

      // Also check purchases for 3D Aiming course
      final has3dPurchase = await _db.isProductPurchased('3d_aiming_course');
      if (has3dPurchase) {
        _isLegacy3dAiming = true;
      }
    } catch (e) {
      debugPrint('Error loading entitlement: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _createDefaultEntitlement() async {
    await _db.insertEntitlement(EntitlementsCompanion.insert(
      id: UniqueId.withPrefix('ent'),
      tier: const Value('archer'),
    ));
    _tier = SubscriptionTier.archer;
  }

  // ===========================================================================
  // SUBSCRIPTION MANAGEMENT
  // ===========================================================================

  /// Update subscription tier from Stripe webhook
  Future<void> updateSubscription({
    required SubscriptionTier tier,
    required String stripeCustomerId,
    required String stripeSubscriptionId,
    DateTime? expiresAt,
  }) async {
    final gracePeriod = expiresAt?.add(const Duration(hours: 72));

    await _db.upsertEntitlement(EntitlementsCompanion(
      tier: Value(tier.name),
      stripeCustomerId: Value(stripeCustomerId),
      stripeSubscriptionId: Value(stripeSubscriptionId),
      expiresAt: Value(expiresAt),
      graceEndsAt: Value(gracePeriod),
    ));

    _tier = tier;
    _stripeCustomerId = stripeCustomerId;
    _stripeSubscriptionId = stripeSubscriptionId;
    _expiresAt = expiresAt;
    _graceEndsAt = gracePeriod;
    notifyListeners();
  }

  /// Cancel subscription (moves to expired state after grace period)
  Future<void> cancelSubscription() async {
    final now = DateTime.now();
    final graceEnd = now.add(const Duration(hours: 72));

    await _db.upsertEntitlement(EntitlementsCompanion(
      expiresAt: Value(now),
      graceEndsAt: Value(graceEnd),
    ));

    _expiresAt = now;
    _graceEndsAt = graceEnd;
    notifyListeners();
  }

  /// Grant legacy 3D Aiming access
  Future<void> grantLegacy3dAiming(String email) async {
    await _db.upsertEntitlement(EntitlementsCompanion(
      isLegacy3dAiming: const Value(true),
      legacyEmail: Value(email),
    ));

    _isLegacy3dAiming = true;
    notifyListeners();
  }

  /// Record a purchase
  Future<void> recordPurchase({
    required String productId,
    String? stripePaymentId,
    double? amountPaid,
    String source = 'stripe',
  }) async {
    await _db.insertPurchase(PurchasesCompanion.insert(
      id: UniqueId.withPrefix('pur'),
      productId: productId,
      stripePaymentId: Value(stripePaymentId),
      amountPaid: Value(amountPaid),
      source: Value(source),
    ));

    // Update local state if it's 3D Aiming course
    if (productId == '3d_aiming_course') {
      _isLegacy3dAiming = true;
      notifyListeners();
    }
  }

  /// Downgrade to free tier (full expiry)
  Future<void> downgradeToFree() async {
    await _db.upsertEntitlement(EntitlementsCompanion(
      tier: const Value('archer'),
      stripeSubscriptionId: const Value(null),
      expiresAt: const Value(null),
      graceEndsAt: const Value(null),
    ));

    _tier = SubscriptionTier.archer;
    _stripeSubscriptionId = null;
    _expiresAt = null;
    _graceEndsAt = null;
    notifyListeners();
  }
}

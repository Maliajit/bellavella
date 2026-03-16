import 'package:flutter/foundation.dart';
import 'package:bellavella/features/professional/models/professional_models.dart';

/// Single source of truth for the professional's active (accepted) job.
/// Maintains a singleton instance for global access if context is not available.
class DashboardController extends ChangeNotifier {
  // Singleton instance
  static final DashboardController instance = DashboardController();

  ProfessionalBooking? _activeJob;

  ProfessionalBooking? get activeJob => _activeJob;

  bool get hasActiveJob => _activeJob != null;

  /// Call this immediately after the professional accepts a request.
  void setActiveJob(ProfessionalBooking job) {
    debugPrint('✅ DashboardController: setActiveJob → ${job.id} (${job.status.name})');
    _activeJob = job;
    notifyListeners();
  }

  /// Alias for setActiveJob to maintain compatibility
  void setJob(ProfessionalBooking job) => setActiveJob(job);

  /// Call this after job completion, rejection, or manual clear.
  void clearJob() {
    debugPrint('🗑️ DashboardController: clearJob');
    _activeJob = null;
    notifyListeners();
  }

  /// Refresh the job status (e.g. after a journey step update) without clearing.
  void updateJob(ProfessionalBooking updated) {
    debugPrint('🔄 DashboardController: updateJob → ${updated.id} (${updated.status.name})');
    _activeJob = updated;
    notifyListeners();
  }
}

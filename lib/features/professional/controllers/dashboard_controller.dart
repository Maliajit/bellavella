import 'dart:async';
import 'package:flutter/material.dart';
import 'package:bellavella/features/professional/models/professional_models.dart';
import 'package:bellavella/features/professional/services/professional_api_service.dart';
import 'package:bellavella/core/models/data_models.dart';

class DashboardController extends ChangeNotifier {
  // Singleton instance
  static final DashboardController instance = DashboardController._internal();

  DashboardController._internal();

  ProfessionalBooking? _activeJob;
  Timer? _jobPollingTimer;

  /// The current active job accepted by the professional
  ProfessionalBooking? get activeJob => _activeJob;

  /// Returns the current step (1-5) based on the job status
  int get currentStep {
    if (_activeJob == null) return 1;
    switch (_activeJob!.status) {
      case BookingStatus.onTheWay:
      case BookingStatus.accepted:
      case BookingStatus.arrived:
        return 1;
      case BookingStatus.scanKit:
        return 2;
      case BookingStatus.inProgress:
        return 3;
      case BookingStatus.paymentPending:
        return 4;
      case BookingStatus.completed:
        return 5;
      default:
        return 1;
    }
  }

  /// Sets the active job and starts polling for status updates
  void setActiveJob(ProfessionalBooking job) {
    _activeJob = job;
    notifyListeners();
    
    // Start polling when a job becomes "active" for the workflow
    if (_isActiveForWorkflow(job.status)) {
      startJobPolling(job.id);
    } else {
      stopJobPolling();
    }
  }

  /// Updates the active job details (e.g., status change)
  void updateJob(ProfessionalBooking job) {
    if (_activeJob?.id == job.id) {
      bool statusChanged = _activeJob?.status != job.status;
      _activeJob = job;
      
      if (statusChanged) {
        notifyListeners();
      }
      
      if (!_isActiveForWorkflow(job.status)) {
        debugPrint('🏁 Job transitioned to terminal status: ${job.status.name}. Clearing active state.');
        clearJob();
      }
    }
  }

  /// Clears the active job when it's completed or cancelled
  void clearJob() {
    _activeJob = null;
    stopJobPolling();
    notifyListeners();
  }

  bool _isActiveForWorkflow(BookingStatus status) {
    return status == BookingStatus.accepted ||
           status == BookingStatus.onTheWay ||
           status == BookingStatus.arrived ||
           status == BookingStatus.scanKit ||
           status == BookingStatus.inProgress ||
           status == BookingStatus.paymentPending;
  }

  /// Starts polling the backend for job status updates
  void startJobPolling(String jobId) {
    if (_jobPollingTimer != null && _jobPollingTimer!.isActive) return;

    debugPrint('🔄 Starting Real-Time Status Polling for Job: $jobId');
    _jobPollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final latestJob = await ProfessionalApiService.getActiveJob();
        if (latestJob != null && latestJob.id == jobId) {
          if (latestJob.status != _activeJob?.status) {
            debugPrint('🔔 Status Change Detected: ${latestJob.status.name}');
            _activeJob = latestJob;
            notifyListeners();
            
            if (!_isActiveForWorkflow(latestJob.status)) {
              debugPrint('🏁 Polling: Job transitioned to terminal status: ${latestJob.status.name}. Clearing.');
              clearJob();
              stopJobPolling();
            }
          }
        } else if (latestJob == null && _activeJob != null) {
          // Job might have been completed and cleared from active-job endpoint
          debugPrint('🏁 Active job no longer returned by API. Clearing.');
          clearJob();
        }
      } catch (e) {
        debugPrint('⚠️ Polling Error: $e');
      }
    });
  }

  /// Stops the polling timer
  void stopJobPolling() {
    if (_jobPollingTimer != null) {
      debugPrint('🛑 Stopping Status Polling');
      _jobPollingTimer?.cancel();
      _jobPollingTimer = null;
    }
  }

  @override
  void dispose() {
    stopJobPolling();
    super.dispose();
  }
}

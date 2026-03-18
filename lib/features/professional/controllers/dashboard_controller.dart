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
  bool _isUpdating = false;
  JobStep _currentWorkflowStep = JobStep.arrived;

  /// The current active job accepted by the professional
  ProfessionalBooking? get activeJob => _activeJob;
  
  /// Whether an update is currently in progress (API call pending)
  bool get isUpdating => _isUpdating;

  /// Reactive step for the UI flow
  JobStep get currentWorkflowStep => _currentWorkflowStep;

  /// Derived UI step index (1-5)
  int get currentStepIndex => _currentWorkflowStep.index + 1;

  /// Legacy getter for backward compatibility
  int get currentStep => currentStepIndex;

  /// Centralized step update with downgrade protection
  void _updateStep(JobStep newStep) {
    if (newStep.index < _currentWorkflowStep.index) {
       debugPrint('⚠️ DashboardController: Prevention of step downgrade from ${_currentWorkflowStep.name} to ${newStep.name}');
       return;
    }
    _currentWorkflowStep = newStep;
    notifyListeners();
  }

  /// Sets the active job and starts polling for status updates
  void setActiveJob(ProfessionalBooking job) {
    if (!job.isActive) {
      debugPrint('🚫 DashboardController: Attempted to set a non-active job as active. Clearing instead.');
      clearJob();
      return;
    }
    _activeJob = job;
    _syncWorkflowStep(job.status);
    notifyListeners();
    
    // Start polling when a job becomes "active" for the workflow
    if (_isActiveForWorkflow(job.status)) {
      startJobPolling(job.id);
    } else {
      stopJobPolling();
    }
  }

  /// Syncs the local JobStep with the BookingStatus from server
  void _syncWorkflowStep(BookingStatus status) {
    JobStep step = JobStep.arrived;
    switch (status) {
      case BookingStatus.accepted:
      case BookingStatus.onTheWay:
      case BookingStatus.arrived:
        step = JobStep.arrived;
        break;
      case BookingStatus.scanKit:
        step = JobStep.scanKit;
        break;
      case BookingStatus.inProgress:
        step = JobStep.service;
        break;
      case BookingStatus.paymentPending:
        step = JobStep.payment;
        break;
      case BookingStatus.completed:
        step = JobStep.complete;
        break;
      default:
        step = JobStep.arrived;
    }
    _updateStep(step);
  }

  /// Updates the active job details (e.g., status change from user action)
  void updateJob(ProfessionalBooking job) {
    if (_activeJob?.id == job.id) {
      _activeJob = job;
      _syncWorkflowStep(job.status);
      
      if (!_isActiveForWorkflow(job.status)) {
        debugPrint('🏁 Job transitioned to terminal status: ${job.status.name}. Clearing active state.');
        clearJob();
      }
    }
  }

  // --- Centralized API Action Methods ---

  Future<void> confirmArrival() async {
    if (_activeJob == null || _isUpdating) return;
    _isUpdating = true;
    notifyListeners();

    try {
      final res = await ProfessionalApiService.jobArrived(_activeJob!.id);
      if (res['success'] == true) {
        _updateStep(JobStep.scanKit);
        // Refresh job details to get server-side status consistency
        final latest = await ProfessionalApiService.getBookingDetail(_activeJob!.id);
        _activeJob = latest;
      }
    } catch (e) {
      debugPrint('❌ confirmArrival Error: $e');
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  Future<void> verifyKit() async {
    if (_activeJob == null || _isUpdating) return;
    _isUpdating = true;
    notifyListeners();

    try {
      await ProfessionalApiService.jobScanKit(_activeJob!.id);
      final latest = await ProfessionalApiService.getBookingDetail(_activeJob!.id);
      _activeJob = latest;
    } catch (e) {
      debugPrint('❌ verifyKit Error: $e');
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  Future<void> startService() async {
    if (_activeJob == null || _isUpdating) return;
    _isUpdating = true;
    notifyListeners();

    try {
      final res = await ProfessionalApiService.jobStartService(_activeJob!.id);
      if (res['success'] == true) {
        _updateStep(JobStep.service);
        final latest = await ProfessionalApiService.getBookingDetail(_activeJob!.id);
        _activeJob = latest;
      }
    } catch (e) {
      debugPrint('❌ startService Error: $e');
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  Future<void> finishService() async {
    if (_activeJob == null || _isUpdating) return;
    _isUpdating = true;
    notifyListeners();

    try {
      final res = await ProfessionalApiService.jobFinishService(_activeJob!.id);
      if (res['success'] == true) {
        _updateStep(JobStep.payment);
        final latest = await ProfessionalApiService.getBookingDetail(_activeJob!.id);
        _activeJob = latest;
      }
    } catch (e) {
      debugPrint('❌ finishService Error: $e');
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  Future<void> completeJob() async {
    if (_activeJob == null || _isUpdating) return;
    _isUpdating = true;
    notifyListeners();

    try {
      final res = await ProfessionalApiService.jobComplete(_activeJob!.id);
      if (res['success'] == true) {
        // 🔥 Re-fetch final details to get accurate totalPrice / stats for completion screen
        final finalDetails = await ProfessionalApiService.getBookingDetail(_activeJob!.id);
        _activeJob = finalDetails;
        _updateStep(JobStep.complete);
      }
    } catch (e) {
      debugPrint('❌ completeJob Error: $e');
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  Future<bool> verifyPayment({
    required String razorpayPaymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
  }) async {
    if (_activeJob == null || _isUpdating) return false;
    _isUpdating = true;
    notifyListeners();

    try {
      final res = await ProfessionalApiService.verifyJobPayment(
        id: _activeJob!.id,
        razorpayPaymentId: razorpayPaymentId,
        razorpayOrderId: razorpayOrderId,
        razorpaySignature: razorpaySignature,
      );
      
      if (res['success'] == true) {
        // 🔥 Re-fetch final details for accurate stats
        final finalDetails = await ProfessionalApiService.getBookingDetail(_activeJob!.id);
        _activeJob = finalDetails;
        _updateStep(JobStep.complete);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ verifyPayment Error: $e');
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  /// Clears the active job when it's completed or cancelled
  void clearJob() {
    debugPrint('🧹 DashboardController: Clearing active job session.');
    _activeJob = null;
    _currentWorkflowStep = JobStep.arrived;
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
      // 🔥 Safety Check: Ignore polling if we are currently performing a manual transition
      if (_isUpdating) {
        debugPrint('🛡️ Polling: Skip due to active update');
        return;
      }

      try {
        final latestJob = await ProfessionalApiService.getActiveJob();
        
        // Re-check _isUpdating after async call to prevent late API response from overriding local transition
        if (_isUpdating) return;

        if (latestJob != null && latestJob.id == jobId) {
          if (latestJob.status != _activeJob?.status) {
            debugPrint('🔔 Status Change Detected from Polling: ${latestJob.status.name}');
            _activeJob = latestJob;
            _syncWorkflowStep(latestJob.status);
            
            if (!_isActiveForWorkflow(latestJob.status)) {
              debugPrint('🏁 Polling: Job transitioned to terminal status: ${latestJob.status.name}. Clearing.');
              clearJob();
              stopJobPolling();
            }
          }
        } else if (latestJob == null && _activeJob != null) {
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

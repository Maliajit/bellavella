import 'dart:async';

import 'package:flutter/material.dart';

import 'package:bellavella/core/models/data_models.dart';
import 'package:bellavella/features/professional/models/professional_models.dart';
import 'package:bellavella/features/professional/services/professional_api_service.dart';

class DashboardController extends ChangeNotifier {
  static final DashboardController instance = DashboardController._internal();

  DashboardController._internal();

  ProfessionalBooking? _activeJob;
  Timer? _jobPollingTimer;
  bool _isUpdating = false;
  JobStep _currentWorkflowStep = JobStep.arrived;

  ProfessionalBooking? get activeJob => _activeJob;
  bool get isUpdating => _isUpdating;
  JobStep get currentWorkflowStep => _currentWorkflowStep;
  int get currentStepIndex => _currentWorkflowStep.index + 1;
  int get currentStep => currentStepIndex;
  bool get hasCompletedJob =>
      _activeJob != null && _activeJob!.status == BookingStatus.completed;

  void _updateStep(JobStep newStep) {
    if (newStep.index < _currentWorkflowStep.index) {
      debugPrint(
        'DashboardController: prevented step downgrade from '
        '${_currentWorkflowStep.name} to ${newStep.name}',
      );
      return;
    }
    _currentWorkflowStep = newStep;
    notifyListeners();
  }

  void setActiveJob(ProfessionalBooking job) {
    if (!job.isActive && job.status != BookingStatus.completed) {
      debugPrint(
        'DashboardController: attempted to set a non-active job; clearing instead.',
      );
      clearJob();
      return;
    }

    _activeJob = job;
    _syncWorkflowStep(job.status);
    notifyListeners();

    if (_isActiveForWorkflow(job.status)) {
      startJobPolling(job.id);
    } else {
      stopJobPolling();
    }
  }

  void _syncWorkflowStep(BookingStatus status) {
    JobStep step = JobStep.arrived;
    switch (status) {
      case BookingStatus.assigned:
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

  void updateJob(ProfessionalBooking job) {
    if (_activeJob == null || _activeJob?.id == job.id) {
      _activeJob = job;
      _syncWorkflowStep(job.status);

      if (job.status == BookingStatus.completed) {
        debugPrint(
          'DashboardController: retaining completed job for review flow.',
        );
        stopJobPolling();
        notifyListeners();
      } else if (!_isActiveForWorkflow(job.status)) {
        debugPrint(
          'DashboardController: job moved to terminal status ${job.status.name}; clearing.',
        );
        clearJob();
      } else {
        notifyListeners();
      }
    }
  }

  Future<bool> startJourney([ProfessionalBooking? fallbackJob]) async {
    if (_isUpdating) return false;

    final job = _activeJob ?? fallbackJob;
    if (job == null) return false;

    if (_activeJob == null || _activeJob?.id != job.id) {
      _activeJob = job;
    }

    _isUpdating = true;
    notifyListeners();

    try {
      final res = await ProfessionalApiService.jobStartJourney(job.id);
      if (res['success'] == true) {
        final data = res['data'];
        if (data != null) {
          _activeJob = ProfessionalBooking.fromJson(data);
        } else {
          _activeJob = await ProfessionalApiService.getBookingDetail(job.id);
        }
        _syncWorkflowStep(_activeJob!.status);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('startJourney error: $e');
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  Future<void> confirmArrival() async {
    if (_activeJob == null || _isUpdating) return;
    _isUpdating = true;
    notifyListeners();

    try {
      final res = await ProfessionalApiService.jobArrived(_activeJob!.id);
      if (res['success'] == true) {
        _updateStep(JobStep.scanKit);
        _activeJob = await ProfessionalApiService.getBookingDetail(_activeJob!.id);
      }
    } catch (e) {
      debugPrint('confirmArrival error: $e');
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
      _activeJob = await ProfessionalApiService.getBookingDetail(_activeJob!.id);
    } catch (e) {
      debugPrint('verifyKit error: $e');
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
        _activeJob = await ProfessionalApiService.getBookingDetail(_activeJob!.id);
      }
    } catch (e) {
      debugPrint('startService error: $e');
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
        _activeJob = await ProfessionalApiService.getBookingDetail(_activeJob!.id);
      }
    } catch (e) {
      debugPrint('finishService error: $e');
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
        _activeJob = await ProfessionalApiService.getBookingDetail(_activeJob!.id);
        _updateStep(JobStep.complete);
        stopJobPolling();
      }
    } catch (e) {
      debugPrint('completeJob error: $e');
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

      if (res['success'] == true || res['verified'] == true || res.isEmpty) {
        _activeJob = await ProfessionalApiService.getBookingDetail(_activeJob!.id);
        _updateStep(JobStep.complete);
        stopJobPolling();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('verifyPayment error: $e');
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  void clearJob() {
    debugPrint('DashboardController: clearing active job session.');
    _activeJob = null;
    _currentWorkflowStep = JobStep.arrived;
    stopJobPolling();
    notifyListeners();
  }

  bool _isActiveForWorkflow(BookingStatus status) {
    return status == BookingStatus.assigned ||
        status == BookingStatus.accepted ||
        status == BookingStatus.onTheWay ||
        status == BookingStatus.arrived ||
        status == BookingStatus.scanKit ||
        status == BookingStatus.inProgress ||
        status == BookingStatus.paymentPending;
  }

  void startJobPolling(String jobId) {
    if (_jobPollingTimer != null && _jobPollingTimer!.isActive) return;

    debugPrint('DashboardController: starting real-time polling for job $jobId');
    _jobPollingTimer =
        Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_isUpdating) {
        debugPrint('DashboardController: polling skipped during active update.');
        return;
      }

      try {
        final latestJob = await ProfessionalApiService.getActiveJob();

        if (_isUpdating) return;

        if (latestJob != null && latestJob.id == jobId) {
          if (latestJob.status != _activeJob?.status) {
            debugPrint(
              'DashboardController: polling detected status ${latestJob.status.name}.',
            );
            _activeJob = latestJob;
            _syncWorkflowStep(latestJob.status);

            if (latestJob.status == BookingStatus.completed) {
              debugPrint(
                'DashboardController: polling saw completed status; preserving review screen.',
              );
              stopJobPolling();
              notifyListeners();
            } else if (!_isActiveForWorkflow(latestJob.status)) {
              debugPrint(
                'DashboardController: polling saw terminal status; clearing.',
              );
              clearJob();
              stopJobPolling();
            }
          }
        } else if (latestJob == null && _activeJob != null) {
          if (_activeJob!.status == BookingStatus.completed) {
            debugPrint(
              'DashboardController: active endpoint no longer returns completed job; preserving local review state.',
            );
            stopJobPolling();
            notifyListeners();
          } else {
            debugPrint('DashboardController: active job no longer returned; clearing.');
            clearJob();
          }
        }
      } catch (e) {
        debugPrint('DashboardController polling error: $e');
      }
    });
  }

  void stopJobPolling() {
    if (_jobPollingTimer != null) {
      debugPrint('DashboardController: stopping status polling.');
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

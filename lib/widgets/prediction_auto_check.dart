import 'dart:async';

import 'package:flutter/widgets.dart';

import '../services/prediction_resolution_service.dart';
import '../state/prediction_store.dart';

/// One app-level observer keeps date-derived lists/badges current and retries
/// due results while the app is in the foreground. No background polling.
class PredictionAutoCheck extends StatefulWidget {
  const PredictionAutoCheck({
    super.key,
    required this.store,
    required this.child,
    this.resolutionService,
  });

  final PredictionStore store;
  final PredictionResolutionService? resolutionService;
  final Widget child;

  @override
  State<PredictionAutoCheck> createState() => _PredictionAutoCheckState();
}

class _PredictionAutoCheckState extends State<PredictionAutoCheck>
    with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lifecycle = WidgetsBinding.instance.lifecycleState;
      if (!mounted ||
          (lifecycle != null && lifecycle != AppLifecycleState.resumed)) {
        return;
      }
      _check();
      _startTimer();
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _check());
  }

  void _check() {
    widget.store.refreshTime();
    widget.resolutionService?.resolveEligiblePredictions(automatic: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _timer?.cancel();
    if (state == AppLifecycleState.resumed) {
      _check();
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

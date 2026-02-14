import 'package:flutter/material.dart';

class DashboardActionsFabHelper {

  bool fabOpen;
  late final AnimationController _fabCtrl;
  late final Animation<double> _fabRotation;

  DashboardActionsFabHelper({required this.fabOpen});

  bool isInitialized = false;

  AnimationController get fabCtrl {
    try {
      return _fabCtrl;
    } catch (e) {
      throw Exception("AnimationController not initialized");
    }
  }
  Animation<double> get fabRotation {
    try {
      return _fabRotation;
    } catch (e) {
      throw Exception("AnimationController not initialized");
    }
  }

  void initialize(TickerProvider vsync) {
    if (isInitialized) return;

    _fabCtrl = AnimationController(
        vsync: vsync, duration: Duration(milliseconds: 250));
    _fabRotation = Tween<double>(begin: 0, end: 0.375)
        .animate(CurvedAnimation(parent: _fabCtrl, curve: Curves.easeOut));

    isInitialized = true;
  }

  void dispose() {
    _fabCtrl.dispose();
  }
}
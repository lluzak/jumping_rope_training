import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

/// Apple Health: save finished workouts, read weight and heart rate.
class HealthSync {
  final _health = Health();
  bool _configured = false;

  static const _types = [
    HealthDataType.WORKOUT,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.WEIGHT,
    HealthDataType.HEART_RATE,
  ];
  static const _access = [
    HealthDataAccess.READ_WRITE,
    HealthDataAccess.READ_WRITE,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

  bool get available => !kIsWeb && Platform.isIOS;

  Future<void> _configure() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  /// Shows the iOS permission sheet. iOS does not reveal whether reading was
  /// allowed, so `true` only means the sheet was handled.
  Future<bool> connect() async {
    if (!available) return false;
    try {
      await _configure();
      return await _health.requestAuthorization(_types, permissions: _access);
    } catch (e) {
      debugPrint('HealthSync.connect: $e');
      return false;
    }
  }

  /// Latest weight in kg from the last year, if any.
  Future<double?> latestWeightKg() async {
    if (!available) return null;
    try {
      await _configure();
      final now = DateTime.now();
      final points = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.WEIGHT],
        startTime: now.subtract(const Duration(days: 365)),
        endTime: now,
      );
      if (points.isEmpty) return null;
      points.sort((a, b) => b.dateTo.compareTo(a.dateTo));
      final v = points.first.value;
      return v is NumericHealthValue ? v.numericValue.toDouble() : null;
    } catch (e) {
      debugPrint('HealthSync.latestWeightKg: $e');
      return null;
    }
  }

  /// Average heart rate during the workout (e.g. from an Apple Watch).
  Future<int?> averageHeartRate(DateTime start, DateTime end) async {
    if (!available) return null;
    try {
      await _configure();
      final points = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.HEART_RATE],
        startTime: start,
        endTime: end,
      );
      final values = points.map((p) => p.value).whereType<NumericHealthValue>().map((v) => v.numericValue).toList();
      if (values.isEmpty) return null;
      return (values.reduce((a, b) => a + b) / values.length).round();
    } catch (e) {
      debugPrint('HealthSync.averageHeartRate: $e');
      return null;
    }
  }

  Future<bool> saveWorkout({
    required DateTime start,
    required DateTime end,
    required int kcal,
    required String title,
  }) async {
    if (!available) return false;
    try {
      await _configure();
      return await _health.writeWorkoutData(
        activityType: HealthWorkoutActivityType.JUMP_ROPE,
        start: start,
        end: end,
        totalEnergyBurned: kcal,
        title: title,
        recordingMethod: RecordingMethod.manual,
      );
    } catch (e) {
      debugPrint('HealthSync.saveWorkout: $e');
      return false;
    }
  }
}

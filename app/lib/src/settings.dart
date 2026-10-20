import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'plan.dart';

class Settings extends ChangeNotifier {
  Settings._(this._prefs);

  static Future<Settings> load() async => Settings._(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  bool get beeps => _prefs.getBool('beeps') ?? true;
  set beeps(bool v) => _set(() => _prefs.setBool('beeps', v));

  bool get voice => _prefs.getBool('voice') ?? true;
  set voice(bool v) => _set(() => _prefs.setBool('voice', v));

  bool get halfway => _prefs.getBool('halfway') ?? false;
  set halfway(bool v) => _set(() => _prefs.setBool('halfway', v));

  double get volume => _prefs.getDouble('volume') ?? 0.8;
  set volume(double v) => _set(() => _prefs.setDouble('volume', v));

  /// Manual weight, used when Apple Health has none.
  double get weightKg => _prefs.getDouble('weightKg') ?? 75;
  set weightKg(double v) => _set(() => _prefs.setDouble('weightKg', v));

  bool get healthEnabled => _prefs.getBool('healthEnabled') ?? false;
  set healthEnabled(bool v) => _set(() => _prefs.setBool('healthEnabled', v));

  bool get autoSave => _prefs.getBool('autoSave') ?? true;
  set autoSave(bool v) => _set(() => _prefs.setBool('autoSave', v));

  String get planId => _prefs.getString('planId') ?? 'beg';
  set planId(String v) => _set(() => _prefs.setString('planId', v));

  Plan get customPlan {
    final d = defaultCustomPlan;
    return d.copyWith(
      work: _prefs.getInt('c.work'),
      rest: _prefs.getInt('c.rest'),
      sets: _prefs.getInt('c.sets'),
      setRest: _prefs.getInt('c.setRest'),
      exerciseIds: _prefs.getStringList('c.ex'),
      warmup: _prefs.getBool('c.warmup'),
      cooldown: _prefs.getBool('c.cooldown'),
    );
  }

  set customPlan(Plan p) => _set(() async {
    await _prefs.setInt('c.work', p.work);
    await _prefs.setInt('c.rest', p.rest);
    await _prefs.setInt('c.sets', p.sets);
    await _prefs.setInt('c.setRest', p.setRest);
    await _prefs.setStringList('c.ex', p.exerciseIds);
    await _prefs.setBool('c.warmup', p.warmup);
    await _prefs.setBool('c.cooldown', p.cooldown);
  });

  Plan get selectedPlan =>
      planId == 'custom' ? customPlan : presetPlans.firstWhere((p) => p.id == planId, orElse: () => presetPlans.first);

  void _set(Future<void> Function() write) {
    write();
    notifyListeners();
  }
}

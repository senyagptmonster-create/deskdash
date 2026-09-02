import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ResetPack {
  final String id;
  String title;
  int minutes;
  String iconName;
  List<String> steps;
  bool isCustom;

  ResetPack({
    required this.id,
    required this.title,
    required this.minutes,
    required this.iconName,
    required this.steps,
    this.isCustom = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'minutes': minutes,
        'iconName': iconName,
        'steps': steps,
        'isCustom': isCustom,
      };

  static ResetPack fromJson(Map<String, dynamic> j) => ResetPack(
        id: (j['id'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        minutes: (j['minutes'] as num?)?.toInt() ?? 5,
        iconName: (j['iconName'] ?? 'desktop_mac').toString(),
        steps: (j['steps'] as List? ?? []).map((e) => e.toString()).toList(),
        isCustom: j['isCustom'] == true,
      );
}

class CompletedSprint {
  final String id;
  final String packTitle;
  final int minutes;
  final DateTime date;

  CompletedSprint({
    required this.id,
    required this.packTitle,
    required this.minutes,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'packTitle': packTitle,
        'minutes': minutes,
        'date': date.toIso8601String(),
      };

  static CompletedSprint fromJson(Map<String, dynamic> j) => CompletedSprint(
        id: (j['id'] ?? '').toString(),
        packTitle: (j['packTitle'] ?? '').toString(),
        minutes: (j['minutes'] as num?)?.toInt() ?? 5,
        date: DateTime.tryParse('${j['date']}') ?? DateTime.now(),
      );
}

class DashStore extends ChangeNotifier {
  static const _packsKey = 'deskdash_packs_v1';
  static const _historyKey = 'deskdash_history_v1';

  final List<ResetPack> _packs = [];
  final List<CompletedSprint> _history = [];
  bool _ready = false;

  bool get ready => _ready;
  List<ResetPack> get packs => List.unmodifiable(_packs);
  List<CompletedSprint> get history => List.unmodifiable(_history);

  int get totalMinutesSpent => _history.fold(0, (sum, h) => sum + h.minutes);
  int get totalSprints => _history.length;

  Future<void> load() async {
    _seedDefaultPacks();

    try {
      final prefs = await SharedPreferences.getInstance();
      final rawPacks = prefs.getString(_packsKey);
      if (rawPacks != null) {
        final list = jsonDecode(rawPacks) as List;
        final custom = list.map((e) => ResetPack.fromJson(e as Map<String, dynamic>)).toList();
        _packs.addAll(custom);
      }
      final rawHist = prefs.getString(_historyKey);
      if (rawHist != null) {
        final list = jsonDecode(rawHist) as List;
        _history.clear();
        for (final item in list) {
          _history.add(CompletedSprint.fromJson(item as Map<String, dynamic>));
        }
      }
    } catch (_) {}

    if (_history.isEmpty) {
      _seedDemoHistory();
    }

    _ready = true;
    notifyListeners();
  }

  void _seedDefaultPacks() {
    _packs.clear();
    _packs.addAll([
      ResetPack(
        id: 'p1',
        title: 'Чистый стол 5 минут',
        minutes: 5,
        iconName: 'desktop_mac',
        steps: [
          'Убрать кружки и посуду на кухню (1 мин)',
          'Сложить бумаги и блокноты в одну аккуратную стопку (1 мин)',
          'Протереть поверхность стола влажной салфеткой (1.5 мин)',
          'Расставить клавиатуру, мышь и лампу на свои места (1.5 мин)',
        ],
      ),
      ResetPack(
        id: 'p2',
        title: 'Рюкзак в путь 7 минут',
        minutes: 7,
        iconName: 'backpack',
        steps: [
          'Полностью вытряхнуть всё содержимое на кровать (1.5 мин)',
          'Выбросить старые чеки, фантики и мусор (1.5 мин)',
          'Проверить кабели, наушники и пауэрбанк (2 мин)',
          'Сложить нужные вещи обратно по карманам (2 мин)',
        ],
      ),
      ResetPack(
        id: 'p3',
        title: 'Цифровой детокс 10 минут',
        minutes: 10,
        iconName: 'folder_zip',
        steps: [
          'Разобрать папку Загрузки (3 мин)',
          'Закрыть ненужные вкладки в браузере (2 мин)',
          'Удалить временные файлы с рабочего стола (3 мин)',
          'Очистить корзину и протереть экран салфеткой (2 мин)',
        ],
      ),
      ResetPack(
        id: 'p4',
        title: 'Рабочая зона турбо 8 минут',
        minutes: 8,
        iconName: 'chair',
        steps: [
          'Поставить монитор и стул на рабочую высоту (1 мин)',
          'Спрятать и скрутить висящие провода (2 мин)',
          'Вынести мусор из настольной корзины (2 мин)',
          'Открыть окно и проветрить комнату (3 мин)',
        ],
      ),
    ]);
  }

  void _seedDemoHistory() {
    final now = DateTime.now();
    _history.addAll([
      CompletedSprint(
        id: 'h1',
        packTitle: 'Чистый стол 5 минут',
        minutes: 5,
        date: now.subtract(const Duration(hours: 4)),
      ),
      CompletedSprint(
        id: 'h2',
        packTitle: 'Цифровой детокс 10 минут',
        minutes: 10,
        date: now.subtract(const Duration(days: 1)),
      ),
    ]);
  }

  Future<void> _persistCustomPacks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final custom = _packs.where((p) => p.isCustom).map((p) => p.toJson()).toList();
      await prefs.setString(_packsKey, jsonEncode(custom));
      await prefs.setString(_historyKey, jsonEncode(_history.map((h) => h.toJson()).toList()));
    } catch (_) {}
  }

  Future<void> addSprint(String packTitle, int minutes) async {
    _history.insert(0, CompletedSprint(
      id: 'h_${DateTime.now().millisecondsSinceEpoch}',
      packTitle: packTitle,
      minutes: minutes,
      date: DateTime.now(),
    ));
    notifyListeners();
    await _persistCustomPacks();
  }

  Future<void> addCustomPack(String title, int minutes, List<String> steps) async {
    _packs.add(ResetPack(
      id: 'p_${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim(),
      minutes: minutes,
      iconName: 'cleaning_services',
      steps: steps.where((s) => s.trim().isNotEmpty).toList(),
      isCustom: true,
    ));
    notifyListeners();
    await _persistCustomPacks();
  }

  Future<void> deletePack(ResetPack pack) async {
    _packs.removeWhere((p) => p.id == pack.id);
    notifyListeners();
    await _persistCustomPacks();
  }

  Future<void> resetAll() async {
    _packs.clear();
    _history.clear();
    _seedDefaultPacks();
    _seedDemoHistory();
    notifyListeners();
    await _persistCustomPacks();
  }
}

class DashScope extends InheritedNotifier<DashStore> {
  const DashScope({super.key, required DashStore store, required super.child})
      : super(notifier: store);

  static DashStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<DashScope>();
    assert(scope != null, 'DashScope not found');
    return scope!.notifier!;
  }
}

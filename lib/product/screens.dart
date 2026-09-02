import 'dart:async';

import 'package:flutter/material.dart';

import '../app/brand.dart';
import '../app/theme.dart';
import 'dash_store.dart';

IconData iconForDash(String name) {
  return switch (name) {
    'desktop_mac' => Icons.desktop_mac_rounded,
    'backpack' => Icons.backpack_rounded,
    'folder_zip' => Icons.folder_zip_rounded,
    'chair' => Icons.chair_rounded,
    'cleaning_services' => Icons.cleaning_services_rounded,
    _ => Icons.timer_rounded,
  };
}

/// Экран 1. Пакеты быстрой уборки
class ResetPacksScreen extends StatelessWidget {
  const ResetPacksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = DashScope.of(context);
    final packs = store.packs;

    return Scaffold(
      backgroundColor: cBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
          children: [
            Text('DeskDash', style: AppTheme.display(28)),
            const SizedBox(height: 4),
            Text('10-минутные сценарии быстрой уборки пространства', style: AppTheme.text(13.5, color: AppTheme.textMuted)),
            const SizedBox(height: 18),
            ...packs.map((p) {
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: cSurface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: cEdge),
                  boxShadow: [
                    BoxShadow(
                      color: cAccent.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cAccent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(iconForDash(p.iconName), color: cAccent, size: 24),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: cAccent2.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.bolt_rounded, size: 16, color: cAccent2),
                                const SizedBox(width: 4),
                                Text('${p.minutes} мин', style: AppTheme.text(13, color: cAccent2, weight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(p.title, style: AppTheme.display(20)),
                      const SizedBox(height: 10),
                      ...p.steps.take(3).map((s) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.5),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline_rounded, size: 14, color: cAccent),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(s, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTheme.text(13, color: AppTheme.textMuted)),
                                ),
                              ],
                            ),
                          )),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: cAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => SprintScreen(pack: p, store: store),
                              ),
                            );
                          },
                          icon: const Icon(Icons.play_arrow_rounded, size: 20),
                          label: Text('Начать спринт', style: AppTheme.text(15, color: Colors.white, weight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Экран 2. Спринт уборки с таймером
class SprintScreen extends StatefulWidget {
  const SprintScreen({super.key, required this.pack, required this.store});

  final ResetPack pack;
  final DashStore store;

  @override
  State<SprintScreen> createState() => _SprintScreenState();
}

class _SprintScreenState extends State<SprintScreen> {
  int _currentStepIndex = 0;
  int _remainingSeconds = 60;
  Timer? _timer;
  bool _isRunning = true;

  @override
  void initState() {
    super.initState();
    _startStepTimer();
  }

  void _startStepTimer() {
    _timer?.cancel();
    _remainingSeconds = (widget.pack.minutes * 60) ~/ widget.pack.steps.length;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _nextStep();
      }
    });
  }

  void _nextStep() {
    if (_currentStepIndex < widget.pack.steps.length - 1) {
      setState(() {
        _currentStepIndex++;
      });
      _startStepTimer();
    } else {
      _timer?.cancel();
      widget.store.addSprint(widget.pack.title, widget.pack.minutes);
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: cSurface,
          title: Text('Спринт завершён! 🎉', style: AppTheme.display(20)),
          content: Text('Пространство убрано за ${widget.pack.minutes} минут. Отличная работа!', style: AppTheme.text(14, color: cInk)),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: cAccent),
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Завершить'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.pack.steps;
    final mins = _remainingSeconds ~/ 60;
    final secs = _remainingSeconds % 60;
    final timeStr = '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: cBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: cInk),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.pack.title, style: AppTheme.display(18)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: LinearProgressIndicator(
                value: (_currentStepIndex + 1) / steps.length,
                backgroundColor: cEdge,
                valueColor: const AlwaysStoppedAnimation(cAccent),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const Spacer(),
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: cSurface,
                shape: BoxShape.circle,
                border: Border.all(color: cAccent, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: cAccent.withValues(alpha: 0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  timeStr,
                  style: AppTheme.display(36, color: cInk),
                ),
              ),
            ),
            const SizedBox(height: 36),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cEdge),
                ),
                child: Column(
                  children: [
                    Text(
                      'Шаг ${_currentStepIndex + 1} из ${steps.length}',
                      style: AppTheme.text(12.5, color: cAccent, weight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      steps[_currentStepIndex],
                      textAlign: TextAlign.center,
                      style: AppTheme.display(18),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: cEdge),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        setState(() {
                          _isRunning = !_isRunning;
                          if (_isRunning) {
                            _startStepTimer();
                          } else {
                            _timer?.cancel();
                          }
                        });
                      },
                      child: Text(_isRunning ? 'Пауза' : 'Продолжить', style: AppTheme.text(15, color: cInk)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: cAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _nextStep,
                      child: Text(
                        _currentStepIndex == steps.length - 1 ? 'Завершить' : 'След. шаг',
                        style: AppTheme.text(15, color: Colors.white, weight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Экран 3. Конструктор своего сценария
class CustomPackScreen extends StatefulWidget {
  const CustomPackScreen({super.key});

  @override
  State<CustomPackScreen> createState() => _CustomPackScreenState();
}

class _CustomPackScreenState extends State<CustomPackScreen> {
  final _titleController = TextEditingController(text: 'Мой спринт');
  int _minutes = 10;
  final List<TextEditingController> _stepControllers = [
    TextEditingController(text: 'Убрать вещи на свои места (3 мин)'),
    TextEditingController(text: 'Протереть пыль (3 мин)'),
    TextEditingController(text: 'Проветрить помещение (4 мин)'),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    for (final c in _stepControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addStep() {
    if (_stepControllers.length < 8) {
      setState(() {
        _stepControllers.add(TextEditingController());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = DashScope.of(context);

    return Scaffold(
      backgroundColor: cBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
          children: [
            Text('Конструктор сценария', style: AppTheme.display(28)),
            const SizedBox(height: 4),
            Text('Создай персональный сценарий уборки', style: AppTheme.text(13.5, color: AppTheme.textMuted)),
            const SizedBox(height: 18),
            TextField(
              controller: _titleController,
              style: AppTheme.text(16, color: cInk),
              decoration: InputDecoration(
                labelText: 'Название сценария',
                filled: true,
                fillColor: cSurface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: cEdge)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Общая длительность: $_minutes минут', style: AppTheme.display(16)),
            Slider(
              value: _minutes.toDouble(),
              min: 3,
              max: 25,
              divisions: 22,
              activeColor: cAccent,
              onChanged: (v) => setState(() => _minutes = v.toInt()),
            ),
            const SizedBox(height: 16),
            Text('Шаги спринта (${_stepControllers.length})', style: AppTheme.display(16)),
            const SizedBox(height: 8),
            ...List.generate(_stepControllers.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _stepControllers[index],
                        style: AppTheme.text(15, color: cInk),
                        decoration: InputDecoration(
                          hintText: 'Шаг ${index + 1}',
                          filled: true,
                          fillColor: cSurface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: cEdge)),
                        ),
                      ),
                    ),
                    if (_stepControllers.length > 2)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.redAccent),
                        onPressed: () {
                          setState(() {
                            _stepControllers.removeAt(index);
                          });
                        },
                      ),
                  ],
                ),
              );
            }),
            TextButton.icon(
              onPressed: _addStep,
              icon: const Icon(Icons.add_rounded, color: cAccent),
              label: Text('Добавить шаг', style: AppTheme.text(14, color: cAccent, weight: FontWeight.w700)),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: cAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () async {
                  final title = _titleController.text.trim();
                  final steps = _stepControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
                  if (steps.length >= 2) {
                    await store.addCustomPack(title.isEmpty ? 'Мой спринт' : title, _minutes, steps);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Сценарий сохранён в каталог!')),
                      );
                    }
                  }
                },
                child: Text('Сохранить сценарий', style: AppTheme.text(15.5, color: Colors.white, weight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Экран 4. История спринтов
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = DashScope.of(context);
    final history = store.history;

    return Scaffold(
      backgroundColor: cBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
          children: [
            Text('История спринтов', style: AppTheme.display(28)),
            const SizedBox(height: 4),
            Text('Твоя продуктивность в уборке', style: AppTheme.text(13.5, color: AppTheme.textMuted)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cSurface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: cEdge),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.flash_on_rounded, color: cAccent, size: 28),
                        const SizedBox(height: 10),
                        Text('${store.totalSprints}', style: AppTheme.display(26, color: cAccent)),
                        const SizedBox(height: 2),
                        Text('Спринтов завершено', style: AppTheme.text(12.5, color: AppTheme.textMuted)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cSurface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: cEdge),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.timer_rounded, color: cAccent2, size: 28),
                        const SizedBox(height: 10),
                        Text('${store.totalMinutesSpent}м', style: AppTheme.display(26, color: cAccent2)),
                        const SizedBox(height: 2),
                        Text('Минут порядка', style: AppTheme.text(12.5, color: AppTheme.textMuted)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Последние спринты', style: AppTheme.display(18)),
            const SizedBox(height: 10),
            if (history.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text('История пуста', style: AppTheme.text(14, color: AppTheme.textMuted)),
                ),
              )
            else
              ...history.map((h) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cEdge),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: cAccent.withValues(alpha: 0.15), shape: BoxShape.circle),
                        child: const Icon(Icons.check_rounded, color: cAccent, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(h.packTitle, style: AppTheme.text(15, color: cInk, weight: FontWeight.w700)),
                            Text('${h.minutes} мин фокуса', style: AppTheme.text(12, color: AppTheme.textMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

/// Экран 5. Настройки
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = DashScope.of(context);

    return Scaffold(
      backgroundColor: cBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
          children: [
            Text('Настройки', style: AppTheme.display(28)),
            const SizedBox(height: 4),
            Text('DeskDash v1.0.0', style: AppTheme.text(13.5, color: AppTheme.textMuted)),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: cSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cEdge),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.cleaning_services_outlined, color: cAccent),
                    title: Text('Сценариев в каталоге', style: AppTheme.text(15, color: cInk)),
                    trailing: Text('${store.packs.length}', style: AppTheme.text(15, color: cAccent, weight: FontWeight.w700)),
                  ),
                  const Divider(height: 1, color: cEdge),
                  ListTile(
                    leading: const Icon(Icons.restart_alt_rounded, color: Colors.redAccent),
                    title: const Text('Сбросить историю и свои сценарии', style: TextStyle(color: Colors.redAccent)),
                    onTap: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: cSurface,
                          title: Text('Сбросить данные?', style: AppTheme.display(18)),
                          content: Text('Вся история спринтов будет очищена.', style: AppTheme.text(14, color: cInk)),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Отмена')),
                            FilledButton(
                              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Сбросить'),
                            ),
                          ],
                        ),
                      );
                      if (ok == true) {
                        await store.resetAll();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

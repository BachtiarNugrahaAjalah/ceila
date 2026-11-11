import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:intl/intl.dart';

import '../../entries/domain/entities/entry_entity.dart';

class QuickAddOverlay extends StatefulWidget {
  const QuickAddOverlay({super.key});

  @override
  State<QuickAddOverlay> createState() => _QuickAddOverlayState();
}

class _QuickAddOverlayState extends State<QuickAddOverlay> {
  static const _bubbleSize = 76;
  static const _overlayChannel = MethodChannel('x-slayer/overlay');

  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _amount = TextEditingController();
  final _category = TextEditingController();
  final _note = TextEditingController();
  final _odometer = TextEditingController();
  final _nextKm = TextEditingController();
  EntryKind _type = EntryKind.task;
  DateTime? _dueDate;
  _OverlayPage _page = _OverlayPage.bubble;
  bool _sending = false;
  bool _loadingTasks = false;
  bool _transitioning = false;
  String? _status;
  Timer? _responseTimeout;
  List<_OverlayTask> _tasks = const [];
  double? _screenWidth;
  double? _screenHeight;
  OverlayPosition? _bubblePosition;
  StreamSubscription<dynamic>? _messages;

  @override
  void initState() {
    super.initState();
    _messages = FlutterOverlayWindow.overlayListener.listen(_handleMessage);
  }

  @override
  void dispose() {
    _messages?.cancel();
    _responseTimeout?.cancel();
    _title.dispose();
    _amount.dispose();
    _category.dispose();
    _note.dispose();
    _odometer.dispose();
    _nextKm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_transitioning) return const SizedBox.expand();

    if (_page == _OverlayPage.bubble) {
      return Material(
        color: Colors.transparent,
        child: Align(alignment: Alignment.bottomRight, child: _buildBubble()),
      );
    }

    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _closeToBubble,
            child: const ColoredBox(color: Color(0x33000000)),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: _buildCurrentPanel(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble() {
    return Material(
      color: Colors.teal,
      shape: const CircleBorder(),
      elevation: 8,
      child: IconButton(
        tooltip: 'Buka menu Ceila',
        onPressed: _openMenu,
        icon: const Icon(Icons.apps_rounded, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _buildCurrentPanel(BuildContext context) => switch (_page) {
    _OverlayPage.menu => _buildMenu(context),
    _OverlayPage.quickAdd => _buildQuickAdd(context),
    _OverlayPage.tasks => _buildTasks(context),
    _OverlayPage.bubble => const SizedBox.shrink(),
  };

  Widget _buildPanel(BuildContext context, Widget child) {
    final screenWidth = _screenWidth ?? 360;
    final screenHeight = _screenHeight ?? 800;
    return Container(
      width: math.min(320, screenWidth - 24),
      constraints: BoxConstraints(maxHeight: screenHeight - 24),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(blurRadius: 16, color: Colors.black26)],
      ),
      child: child,
    );
  }

  Widget _buildMenu(BuildContext context) {
    return _buildPanel(
      context,
      SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  child: Icon(Icons.apps_rounded),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Ceila',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  tooltip: 'Tutup',
                  onPressed: _closeToBubble,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Quick-add'),
              onTap: _openQuickAdd,
            ),
            ListTile(
              leading: const Icon(Icons.checklist),
              title: const Text('List tugas'),
              onTap: _openTasks,
            ),
            ListTile(
              leading: const Icon(Icons.power_settings_new),
              title: const Text('Matikan bubble'),
              onTap: _stopBubble,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAdd(BuildContext context) {
    return _buildPanel(
      context,
      SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Quick-add',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Kembali ke menu',
                    onPressed: _backToMenu,
                    icon: const Icon(Icons.arrow_back),
                  ),
                ],
              ),
              DropdownButtonFormField<EntryKind>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Tipe'),
                items: EntryKind.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(_label(type)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _type = value);
                },
              ),
              TextFormField(
                controller: _title,
                maxLength: 120,
                decoration: const InputDecoration(labelText: 'Judul'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Judul wajib diisi'
                    : null,
              ),
              if (_type == EntryKind.income || _type == EntryKind.expense) ...[
                TextFormField(
                  controller: _amount,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Nominal (Rp)'),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Nominal wajib diisi'
                      : null,
                ),
                TextFormField(
                  controller: _category,
                  decoration: const InputDecoration(labelText: 'Kategori'),
                ),
              ],
              if (_type == EntryKind.task || _type == EntryKind.maintenance)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _dueDate == null
                        ? 'Tambah tenggat (opsional)'
                        : DateFormat('d MMM, HH:mm').format(_dueDate!),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _pickDueDate(context),
                ),
              if (_type == EntryKind.maintenance) ...[
                TextFormField(
                  controller: _odometer,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Kilometer saat ini',
                  ),
                ),
                TextFormField(
                  controller: _nextKm,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Servis berikutnya (km)',
                  ),
                ),
              ],
              TextFormField(
                controller: _note,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                ),
              ),
              if (_status != null) ...[
                const SizedBox(height: 8),
                Text(_status!),
              ],
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _sending ? null : _submit,
                icon: const Icon(Icons.save_outlined),
                label: Text(_sending ? 'Menyimpan...' : 'Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTasks(BuildContext context) {
    return _buildPanel(
      context,
      SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'List tugas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  tooltip: 'Kembali ke menu',
                  onPressed: _backToMenu,
                  icon: const Icon(Icons.arrow_back),
                ),
              ],
            ),
            const Divider(),
            if (_loadingTasks)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_status != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(_status!),
              )
            else if (_tasks.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Tidak ada tugas yang belum selesai.'),
              )
            else
              ..._tasks.map(
                (task) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    task.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: task.dueDate == null
                      ? null
                      : Text(
                          '${task.dueDate!.isBefore(DateTime.now()) ? 'Terlambat · ' : ''}${DateFormat('d MMM, HH:mm').format(task.dueDate!)}',
                        ),
                  trailing: IconButton(
                    tooltip: 'Tandai selesai',
                    icon: const Icon(Icons.check_circle_outline),
                    onPressed: () => _completeTask(task.id),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMenu() async {
    if (_transitioning) return;
    final width = _screenWidth;
    final height = _screenHeight;
    if (width == null || height == null) return;
    setState(() => _transitioning = true);
    try {
      _bubblePosition = await FlutterOverlayWindow.getOverlayPosition();
      await _moveOverlay(const OverlayPosition(0, 0));
      await FlutterOverlayWindow.resizeOverlay(
        width.round(),
        height.round(),
        false,
      );
      await FlutterOverlayWindow.updateFlag(OverlayFlag.defaultFlag);
      if (!mounted) return;
      setState(() {
        _page = _OverlayPage.menu;
        _transitioning = false;
      });
    } finally {
      if (mounted && _transitioning) {
        setState(() => _transitioning = false);
      }
    }
  }

  Future<void> _openQuickAdd() async {
    await FlutterOverlayWindow.updateFlag(OverlayFlag.focusPointer);
    if (!mounted) return;
    setState(() {
      _page = _OverlayPage.quickAdd;
      _status = null;
    });
  }

  Future<void> _backToMenu() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await FlutterOverlayWindow.updateFlag(OverlayFlag.defaultFlag);
    if (!mounted) return;
    setState(() => _page = _OverlayPage.menu);
  }

  Future<void> _closeToBubble() async {
    if (_transitioning) return;
    setState(() => _transitioning = true);
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      await FlutterOverlayWindow.updateFlag(OverlayFlag.defaultFlag);
      await FlutterOverlayWindow.resizeOverlay(_bubbleSize, _bubbleSize, true);
      final position = _bubblePosition;
      if (position != null) {
        await _moveOverlay(position);
      }
      if (!mounted) return;
      setState(() {
        _page = _OverlayPage.bubble;
        _transitioning = false;
      });
    } finally {
      if (mounted && _transitioning) {
        setState(() => _transitioning = false);
      }
    }
  }

  Future<void> _moveOverlay(OverlayPosition position) async {
    final moved = await _overlayChannel.invokeMethod<bool>(
      'updateOverlayPosition',
      {'x': position.x.toInt(), 'y': position.y.toInt()},
    );
    if (moved != true) {
      throw PlatformException(
        code: 'OVERLAY_MOVE_FAILED',
        message: 'Android could not update the overlay position.',
      );
    }
  }

  Future<void> _openTasks() async {
    _responseTimeout?.cancel();
    setState(() {
      _page = _OverlayPage.tasks;
      _loadingTasks = true;
      _tasks = const [];
      _status = null;
    });
    _responseTimeout = Timer(const Duration(seconds: 10), () {
      if (!mounted || !_loadingTasks) return;
      setState(() {
        _loadingTasks = false;
        _status = 'Daftar tugas tidak dapat dimuat.';
      });
    });
    try {
      await FlutterOverlayWindow.shareData({'action': 'load_open_tasks'});
    } on PlatformException {
      _responseTimeout?.cancel();
      if (!mounted) return;
      setState(() {
        _loadingTasks = false;
        _status = 'Daftar tugas tidak dapat dimuat.';
      });
    }
  }

  Future<void> _completeTask(int id) async {
    _responseTimeout?.cancel();
    _responseTimeout = Timer(const Duration(seconds: 10), () {
      if (!mounted) return;
      setState(() => _status = 'Tugas gagal diperbarui.');
    });
    try {
      await FlutterOverlayWindow.shareData({
        'action': 'complete_task',
        'id': id,
      });
    } on PlatformException {
      _responseTimeout?.cancel();
      if (!mounted) return;
      setState(() => _status = 'Tugas gagal diperbarui.');
    }
  }

  Future<void> _stopBubble() async {
    await FlutterOverlayWindow.shareData({'action': 'stop_overlay'});
  }

  Future<void> _pickDueDate(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueDate ?? now),
    );
    if (time == null || !mounted) return;
    setState(
      () => _dueDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    _responseTimeout?.cancel();
    setState(() {
      _sending = true;
      _status = null;
    });
    _responseTimeout = Timer(const Duration(seconds: 10), () {
      if (!mounted || !_sending) return;
      setState(() {
        _sending = false;
        _status = 'Catatan tidak dapat disimpan. Coba lagi.';
      });
    });
    await FlutterOverlayWindow.shareData({
      'action': 'add_entry',
      'type': _type.name,
      'title': _title.text.trim(),
      'amount': _type == EntryKind.income || _type == EntryKind.expense
          ? int.tryParse(_amount.text)
          : null,
      'category': _type == EntryKind.income || _type == EntryKind.expense
          ? _category.text.trim()
          : null,
      'note': _note.text.trim(),
      'dueDate': _type == EntryKind.task || _type == EntryKind.maintenance
          ? _dueDate?.toIso8601String()
          : null,
      'odometerKm': _type == EntryKind.maintenance
          ? int.tryParse(_odometer.text)
          : null,
      'nextKm': _type == EntryKind.maintenance
          ? int.tryParse(_nextKm.text)
          : null,
    });
  }

  void _handleMessage(dynamic message) {
    if (message is! Map) return;
    switch (message['action']) {
      case 'screen_size':
        final width = message['width'];
        final height = message['height'];
        if (!mounted || width is! num || height is! num) return;
        if (width <= 0 || height <= 0) return;
        setState(() {
          _screenWidth = width.toDouble();
          _screenHeight = height.toDouble();
        });
        return;
      case 'entry_result':
        _responseTimeout?.cancel();
        final success = message['success'] == true;
        if (!mounted) return;
        setState(() {
          _sending = false;
          _status = success ? 'Catatan tersimpan.' : 'Catatan gagal disimpan.';
        });
        if (success) _clearForm();
        return;
      case 'task_result':
        _responseTimeout?.cancel();
        if (!mounted) return;
        setState(
          () => _status = message['success'] == true
              ? 'Tugas ditandai selesai.'
              : 'Tugas gagal diperbarui.',
        );
        return;
      case 'open_tasks':
        _responseTimeout?.cancel();
        final items = message['items'];
        if (!mounted || items is! List) return;
        setState(() {
          _loadingTasks = false;
          _status = null;
          _tasks = items
              .whereType<Map>()
              .map(
                (item) => _OverlayTask(
                  id: item['id'] is int ? item['id'] as int : -1,
                  title: item['title'] is String ? item['title'] as String : '',
                  dueDate: item['dueDate'] is String
                      ? DateTime.tryParse(item['dueDate'] as String)
                      : null,
                ),
              )
              .where((task) => task.id >= 0 && task.title.isNotEmpty)
              .toList();
        });
        return;
      case 'open_tasks_error':
        _responseTimeout?.cancel();
        if (!mounted) return;
        setState(() {
          _loadingTasks = false;
          _status = 'Daftar tugas tidak dapat dimuat.';
        });
        return;
    }
  }

  void _clearForm() {
    _form.currentState?.reset();
    _title.clear();
    _amount.clear();
    _category.clear();
    _note.clear();
    _odometer.clear();
    _nextKm.clear();
    setState(() => _dueDate = null);
  }

  String _label(EntryKind type) => switch (type) {
    EntryKind.task => 'Tugas',
    EntryKind.income => 'Pemasukan',
    EntryKind.expense => 'Pengeluaran',
    EntryKind.maintenance => 'Perawatan',
  };
}

enum _OverlayPage { bubble, menu, quickAdd, tasks }

class _OverlayTask {
  final int id;
  final String title;
  final DateTime? dueDate;

  const _OverlayTask({
    required this.id,
    required this.title,
    required this.dueDate,
  });
}

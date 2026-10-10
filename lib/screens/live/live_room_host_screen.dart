import 'package:flutter/material.dart';
import 'package:quizistan_academy/core/constants/app_constants.dart';
import 'package:quizistan_academy/core/theme/app_theme.dart';
import 'package:quizistan_academy/models/test_room.dart';
import 'package:quizistan_academy/services/auth_service.dart';
import 'package:quizistan_academy/services/firestore_service.dart';

class LiveRoomHostScreen extends StatefulWidget {
  const LiveRoomHostScreen({super.key});

  @override
  State<LiveRoomHostScreen> createState() => _LiveRoomHostScreenState();
}

class _LiveRoomHostScreenState extends State<LiveRoomHostScreen> {
  String? _uid;
  String _board = AppConstants.boards.first;
  String _classLevel = AppConstants.classLevels.first;
  String _subject = AppConstants.subjects.first;
  int _count = AppConstants.defaultQuestionCount;
  bool _creating = false;
  String? _code;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initUid();
  }

  Future<void> _initUid() async {
    try {
      final user = await AuthService.instance.ensureSignedIn();
      if (mounted) setState(() => _uid = user.uid);
    } catch (e) {
      debugPrint('host sign-in: $e');
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _createRoom() async {
    if (_uid == null) {
      _snack('Sign in ho raha hai, thori der ruko.');
      return;
    }
    setState(() {
      _creating = true;
      _error = null;
    });
    try {
      final code = await FirestoreService().createRoom(
        hostUid: _uid!,
        board: _board,
        classLevel: _classLevel,
        subject: _subject,
        questionCount: _count,
      );
      if (!mounted) return;
      setState(() => _code = code);
    } catch (e) {
      debugPrint('create room: $e');
      if (!mounted) return;
      setState(() => _error = 'Room nahi bana. Dobara try karo.');
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _setStatus(String code, String status) async {
    try {
      await FirestoreService().setRoomStatus(code, status);
    } catch (e) {
      debugPrint('set room status: $e');
      _snack('Status change nahi hua.');
    }
  }

  Future<void> _confirmEnd(String code) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Test khatam karo?'),
        content: const Text('Students ab jawab nahi de payenge.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child:
                  const Text('Khatam karo', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) _setStatus(code, 'ended');
  }

  String _statusText(String status) {
    switch (status) {
      case 'waiting':
        return 'Waiting...';
      case 'live':
        return 'Live!';
      case 'ended':
        return 'Khatam';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Room - Host')),
      body: _code == null ? _buildCreateForm() : _buildRoom(),
    );
  }

  Widget _drop(String label, String value, List<String> items,
      ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label),
      items:
          items.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildCreateForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _drop('Board', _board, AppConstants.boards,
              (v) => setState(() => _board = v ?? _board)),
          const SizedBox(height: 8),
          _drop('Class', _classLevel, AppConstants.classLevels,
              (v) => setState(() => _classLevel = v ?? _classLevel)),
          const SizedBox(height: 8),
          _drop('Subject', _subject, AppConstants.subjects,
              (v) => setState(() => _subject = v ?? _subject)),
          const SizedBox(height: 12),
          Text('Sawalon ki tadaad: $_count'),
          Slider(
            value: _count.toDouble(),
            min: 5,
            max: 30,
            divisions: 25,
            label: '$_count',
            onChanged: (v) => setState(() => _count = v.round()),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _creating ? null : _createRoom,
            child: _creating
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Room Banao'),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!,
                  style: const TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }

  Widget _buildRoom() {
    final code = _code!;
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              gradient: AppTheme.brandGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text('Room Code',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                Text(code,
                    style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                        color: Colors.white)),
              ],
            ),
          ),
          StreamBuilder<TestRoom?>(
            stream: FirestoreService().watchRoom(code),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator());
              }
              final room = snap.data;
              if (room == null) {
                return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Room nahi mila.'));
              }
              return Column(
                children: [
                  Text(_statusText(room.status),
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _controlButtons(code, room.status),
                  StreamBuilder<List<RoomParticipant>>(
                    stream: FirestoreService().watchParticipants(code),
                    builder: (context, psnap) {
                      final parts =
                          [...(psnap.data ?? const <RoomParticipant>[])]
                            ..sort((a, b) => b.score.compareTo(a.score));
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text('Students: ${parts.length}',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                          ),
                          if (psnap.connectionState ==
                                  ConnectionState.waiting &&
                              parts.isEmpty)
                            const Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator()),
                          ListView.builder(
                            shrinkWrap: true,
                            physics:
                                const NeverScrollableScrollPhysics(),
                            itemCount: parts.length,
                            itemBuilder: (context, i) => ListTile(
                              leading: CircleAvatar(
                                  child: Text('${i + 1}')),
                              title: Text(parts[i].name),
                              trailing: Text('Score: ${parts[i].score}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _controlButtons(String code, String status) {
    if (status == 'waiting') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _setStatus(code, 'live'),
            child: const Text('Test Shuru Karo'),
          ),
        ),
      );
    }
    if (status == 'live') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => _confirmEnd(code),
            child: const Text('Test Khatam Karo'),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

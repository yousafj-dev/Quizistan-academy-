import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quizistan_academy/core/constants/app_constants.dart';
import 'package:quizistan_academy/core/theme/app_theme.dart';
import 'package:quizistan_academy/models/question.dart';
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
  bool _signingIn = true;
  String? _signInError;
  String? _code;
  String? _error;

  @override
  void initState() {
    super.initState();
    _signIn();
  }

  /// Signs in (anonymously) and keeps the real failure reason visible,
  /// so the screen never gets stuck on a silent "wait" message.
  Future<void> _signIn() async {
    setState(() {
      _signingIn = true;
      _signInError = null;
    });
    try {
      final user = await AuthService.instance.ensureSignedIn();
      if (mounted) {
        setState(() {
          _uid = user.uid;
          _signingIn = false;
        });
      }
    } catch (e) {
      debugPrint('host sign-in: $e');
      if (mounted) {
        setState(() {
          _signingIn = false;
          _signInError = _plainError(e);
        });
      }
    }
  }

  /// Plain-language reason for a sign-in failure (Roman Urdu).
  String _plainError(Object e) {
    final code = e is FirebaseAuthException ? e.code : '';
    switch (code) {
      case 'operation-not-allowed':
        return 'Anonymous login Firebase Console me off hai — on karo.';
      case 'network-request-failed':
        return 'Internet nahi mil raha. Connection check karo.';
      case 'too-many-requests':
        return 'Bohat zyada koshishain — thori der baad try karo.';
      default:
        return code.isEmpty
            ? 'Sign-in nahi hua. Dobara try karo.'
            : 'Sign-in nahi hua ($code). Dobara try karo.';
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _createRoom() async {
    if (_uid == null) {
      // Sign-in abhi tak nahi hua (ya fail hua) — foran dobara try karo.
      await _signIn();
      if (_uid == null) {
        if (mounted) {
          _snack(_signInError ?? 'Sign in ho raha hai, thori der ruko.');
        }
        return;
      }
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
          if (_signingIn)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(),
            ),
          if (_signInError != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(_signInError!,
                      style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _signingIn ? null : _signIn,
                    child: const Text('Dobara try karo'),
                  ),
                ],
              ),
            ),
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
                  _paperPreview(room),
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
                            itemBuilder: (context, i) {
                              final p = parts[i];
                              final answered = p.answers.length;
                              final total = room.questions.length;
                              return ListTile(
                                leading: CircleAvatar(
                                    child: Text('${i + 1}')),
                                title: Text(p.name),
                                subtitle: Text(
                                    '$answered/$total jawab diye'),
                                trailing: Text('Score: ${p.score}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                onTap: () =>
                                    _showStudentDetail(p, room.questions),
                              );
                            },
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

  /// Teacher ko paper (sawal) dikhao — expandable list.
  Widget _paperPreview(TestRoom room) {
    final qs = room.questions;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: ExpansionTile(
          leading: const Icon(Icons.description),
          title: Text('Paper (${qs.length} sawal)'),
          subtitle: const Text('Yehi paper sab students ko milega'),
          children: [
            for (var i = 0; i < qs.length; i++)
              ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 14,
                  child: Text('${i + 1}',
                      style: const TextStyle(fontSize: 12)),
                ),
                title: Text(qs[i].text,
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13)),
                subtitle: Text(
                    'Sahi jawab: ${qs[i].options[qs[i].correctIndex]}',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.green)),
              ),
          ],
        ),
      ),
    );
  }

  /// Kisi student par tap: uske har sawal ka jawab dekho.
  void _showStudentDetail(
      RoomParticipant p, List<Question> questions) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        builder: (_, controller) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('${p.name} — Score: ${p.score}/${questions.length}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: questions.length,
                itemBuilder: (_, i) {
                  final q = questions[i];
                  final picked = p.answers[q.id];
                  final correct = picked == q.correctIndex;
                  return Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    child: ListTile(
                      leading: Icon(
                        picked == null
                            ? Icons.radio_button_unchecked
                            : correct
                                ? Icons.check_circle
                                : Icons.cancel,
                        color: picked == null
                            ? Colors.grey
                            : correct
                                ? Colors.green
                                : Colors.red,
                      ),
                      title: Text('Q${i + 1}: ${q.text}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13)),
                      subtitle: Text(
                        picked == null
                            ? 'Jawab nahi diya'
                            : 'Uska jawab: ${q.options[picked]}'
                                '${correct ? '' : '  |  Sahi: ${q.options[q.correctIndex]}'}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _controlButtons(String code, String status) {    if (status == 'waiting') {
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

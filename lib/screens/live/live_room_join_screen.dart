import 'dart:async';

import 'package:flutter/material.dart';
import 'package:quizistan_academy/models/question.dart';
import 'package:quizistan_academy/models/test_room.dart';
import 'package:quizistan_academy/services/auth_service.dart';
import 'package:quizistan_academy/services/firestore_service.dart';
import 'package:quizistan_academy/widgets/option_button.dart';
import 'package:quizistan_academy/widgets/question_card.dart';
import 'package:quizistan_academy/widgets/timer_ring.dart';

class LiveRoomJoinScreen extends StatefulWidget {
  const LiveRoomJoinScreen({super.key});
  @override
  State<LiveRoomJoinScreen> createState() => _LiveRoomJoinScreenState();
}

class _LiveRoomJoinScreenState extends State<LiveRoomJoinScreen> {
  final TextEditingController _codeCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();
  bool _loading = false;
  String? _code; // non-null = joined
  String? _uid;
  String? _error;
  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _join() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    final name = _nameCtrl.text.trim();
    if (code.length != 6) {
      _snack('6 harf ka code likho.');
      return;
    }
    if (name.isEmpty) {
      _snack('Apna naam likho.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await AuthService.instance.ensureSignedIn();
      await FirestoreService().joinRoom(code: code, uid: user.uid, name: name);
      if (!mounted) return;
      setState(() {
        _code = code;
        _uid = user.uid;
      });
    } catch (e) {
      debugPrint('join room: $e');
      if (!mounted) return;
      setState(() => _error = 'Room nahi mila. Code check karo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Room - Join')),
      body: _code == null ? _buildJoinForm() : _buildLobby(_code!, _uid),
    );
  }

  Widget _buildJoinForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
              controller: _codeCtrl,
              maxLength: 6,
              textCapitalization: TextCapitalization.characters,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 8),
              decoration: const InputDecoration(
                  hintText: 'ABC123',
                  labelText: 'Room Code',
                  border: OutlineInputBorder(),
                  counterText: '')),
          const SizedBox(height: 16),
          TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Apna naam', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          ElevatedButton(
              onPressed: _loading ? null : _join,
              child: _loading
                  ? const SizedBox(
                      height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Join Karo')),
          if (_error != null)
            Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Widget _buildLobby(String code, String? uid) {
    return StreamBuilder<TestRoom?>(
      stream: FirestoreService().watchRoom(code),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final room = snap.data;
        if (room == null) return const Center(child: Text('Room band ho gaya.'));
        if (room.status == 'waiting') {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Teacher ke start karne ka intezar karo...',
                  style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              StreamBuilder<List<RoomParticipant>>(
                  stream: FirestoreService().watchParticipants(code),
                  builder: (context, psnap) => Text(
                      'Students joined: ${(psnap.data ?? const <RoomParticipant>[]).length}')),
            ]),
          );
        }
        if (room.status == 'live') {
          return _LiveQuizView(code: code, uid: uid!, room: room);
        }
        return buildResultView(
            code: code, uid: uid, header: 'Test khatam! Final result:');
      },
    );
  }
}

/// Shared result/leaderboard view used after a test ends or finishes.
Widget buildResultView(
    {required String code, String? uid, required String header}) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        Text(header,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _Leaderboard(code: code, highlightUid: uid),
      ],
    ),
  );
}

class _Leaderboard extends StatelessWidget {
  const _Leaderboard({required this.code, this.highlightUid});
  final String code;
  final String? highlightUid;
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RoomParticipant>>(
      stream: FirestoreService().watchParticipants(code),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final parts = [...(snap.data ?? const <RoomParticipant>[])]
          ..sort((a, b) => b.score.compareTo(a.score));
        if (parts.isEmpty) {
          return const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Abhi koi result nahi.'));
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: parts.length,
          itemBuilder: (context, i) {
            final p = parts[i];
            final mine = p.uid == highlightUid;
            return Card(
              color: mine ? Colors.amber.shade100 : null,
              child: ListTile(
                leading: CircleAvatar(child: Text('${i + 1}')),
                title: Text(mine ? '${p.name} (Tum)' : p.name),
                trailing: Text('Score: ${p.score}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            );
          },
        );
      },
    );
  }
}

class _LiveQuizView extends StatefulWidget {
  const _LiveQuizView(
      {required this.code, required this.uid, required this.room});
  final String code;
  final String uid;
  final TestRoom room;
  @override
  State<_LiveQuizView> createState() => _LiveQuizViewState();
}

class _LiveQuizViewState extends State<_LiveQuizView> {
  static const int _perQuestionSeconds = 30;
  String? _error; // null + empty questions = loading
  List<Question> _questions = const [];
  int _index = 0;
  int? _selected;
  bool _answered = false;
  int _secondsLeft = _perQuestionSeconds;
  int _score = 0;
  bool _done = false;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final qs = await FirestoreService().fetchQuestions(
        board: widget.room.board,
        classLevel: widget.room.classLevel,
        subject: widget.room.subject,
        limit: widget.room.questionCount,
      );
      if (!mounted) return;
      setState(() {
        _questions = qs;
        if (qs.isEmpty) _error = 'Sawal nahi mile.';
      });
      if (qs.isNotEmpty) _startTimer();
    } catch (e) {
      debugPrint('live quiz load: $e');
      if (!mounted) return;
      setState(() => _error = 'Sawal load nahi hue.');
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        _answer(null); // timeout
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _answer(int? i) {
    if (_answered || _done) return;
    _timer?.cancel();
    final q = _questions[_index];
    setState(() {
      _answered = true;
      _selected = i;
      if (i != null && i == q.correctIndex) _score++;
    });
    FirestoreService().submitRoomAnswer(
        code: widget.code, uid: widget.uid, questionId: q.id, selectedIndex: i, score: _score)
        .catchError((Object e) => debugPrint('submit answer: $e'));
    Future.delayed(const Duration(seconds: 1), _advance);
  }

  void _advance() {
    if (!mounted || _done) return;
    if (_index + 1 < _questions.length) {
      setState(() {
        _index++;
        _selected = null;
        _answered = false;
        _secondsLeft = _perQuestionSeconds;
      });
      _startTimer();
    } else {
      _timer?.cancel();
      setState(() => _done = true);
    }
  }

  OptionState _stateFor(int i) => !_answered
      ? OptionState.normal
      : (i == _selected ? OptionState.selected : OptionState.disabled);

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Center(child: Text(_error!));
    if (_questions.isEmpty) return const Center(child: CircularProgressIndicator());
    if (_done) {
      return buildResultView(
          code: widget.code,
          uid: widget.uid,
          header:
              'Tumhara score: $_score/${_questions.length}\nFinal result:');
    }
    final q = _questions[_index];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TimerRing(
              secondsLeft: _secondsLeft, totalSeconds: _perQuestionSeconds),
          const SizedBox(height: 12),
          QuestionCard(question: q, index: _index, total: _questions.length),
          const SizedBox(height: 12),
          for (int i = 0; i < q.options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OptionButton(
                label: 'ABCD'[i],
                text: q.options[i],
                state: _stateFor(i),
                onTap: _answered ? null : () => _answer(i),
              ),
            ),
        ],
      ),
    );
  }
}

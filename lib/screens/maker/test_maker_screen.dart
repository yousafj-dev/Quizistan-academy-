import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quizistan_academy/core/constants/app_constants.dart';
import 'package:quizistan_academy/models/question.dart';
import 'package:quizistan_academy/services/auth_service.dart';
import 'package:quizistan_academy/services/firestore_service.dart';

class TestMakerScreen extends StatefulWidget {
  const TestMakerScreen({super.key});

  @override
  State<TestMakerScreen> createState() => _TestMakerScreenState();
}

class _TestMakerScreenState extends State<TestMakerScreen> {
  bool _loadingRole = true;
  bool _isTeacher = false;
  String? _uid;

  String _board = AppConstants.boards.first;
  String _classLevel = AppConstants.classLevels.first;
  String _subject = AppConstants.subjects.first;
  final TextEditingController _chapter = TextEditingController();
  int _count = AppConstants.defaultQuestionCount;
  bool _loading = false;
  final List<Question> _picked = [];

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  @override
  void dispose() {
    _chapter.dispose();
    super.dispose();
  }

  Future<void> _loadRole() async {
    try {
      final user = await AuthService.instance.ensureSignedIn();
      final profile = await AuthService.instance.loadProfile();
      if (!mounted) return;
      setState(() {
        _uid = user.uid;
        _isTeacher = profile?.isTeacher ?? false;
        _loadingRole = false;
      });
    } catch (e) {
      debugPrint('TestMaker role load failed: $e');
      if (!mounted) return;
      setState(() {
        _isTeacher = false;
        _loadingRole = false;
      });
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickQuestions() async {
    setState(() => _loading = true);
    try {
      final all = await FirestoreService().fetchQuestions(
        board: _board,
        classLevel: _classLevel,
        subject: _subject,
        chapter: _chapter.text.trim().isEmpty ? null : _chapter.text.trim(),
        limit: 60,
      );
      if (!mounted) return;
      if (all.isEmpty) {
        _snack('Sawal nahi mile.');
      } else {
        all.shuffle();
        setState(() {
          _picked
            ..clear()
            ..addAll(all.take(_count));
        });
        _snack('${_picked.length} sawal chun liye.');
      }
    } catch (e) {
      debugPrint('pick questions: $e');
      _snack('Sawal load nahi hue.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveTest() async {
    if (_picked.isEmpty) return;
    try {
      await FirestoreService().saveTest({
        'title': '$_subject Test - $_board Class $_classLevel',
        'board': _board,
        'classLevel': _classLevel,
        'subject': _subject,
        'chapter': _chapter.text.trim(),
        'questionIds': _picked.map((q) => q.id).toList(),
        'createdBy': _uid ?? '',
        'createdAt': Timestamp.now(),
      });
      if (!mounted) return;
      setState(() => _picked.clear());
      _snack('Test save ho gaya!');
    } catch (e) {
      debugPrint('save test: $e');
      _snack('Test save nahi hua.');
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Maker')),
      body: _loadingRole
          ? const Center(child: CircularProgressIndicator())
          : !_isTeacher
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Ye feature sirf teachers ke liye hai.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                )
              : _buildForm(),
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _drop('Board', _board, AppConstants.boards,
                  (v) => setState(() => _board = v ?? _board)),
              const SizedBox(height: 8),
              _drop('Class', _classLevel, AppConstants.classLevels,
                  (v) => setState(() => _classLevel = v ?? _classLevel)),
              const SizedBox(height: 8),
              _drop('Subject', _subject, AppConstants.subjects,
                  (v) => setState(() => _subject = v ?? _subject)),
              const SizedBox(height: 8),
              TextField(
                controller: _chapter,
                decoration:
                    const InputDecoration(labelText: 'Chapter (optional)'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Sawal:'),
                  Expanded(
                    child: Slider(
                      value: _count.toDouble(),
                      min: 5,
                      max: 30,
                      divisions: 25,
                      label: '$_count',
                      onChanged: (v) =>
                          setState(() => _count = v.round()),
                    ),
                  ),
                  Text('$_count'),
                ],
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _pickQuestions,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Sawal Chuno'),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _picked.isEmpty
              ? const Center(
                  child: Text('Abhi koi sawal nahi chuna.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: _picked.length,
                  itemBuilder: (context, i) => ListTile(
                    leading: CircleAvatar(child: Text('${i + 1}')),
                    title: Text(_picked[i].text,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Hatao',
                      onPressed: () =>
                          setState(() => _picked.removeAt(i)),
                    ),
                  ),
                ),
        ),
        if (_picked.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveTest,
                child: const Text('Test Save Karo'),
              ),
            ),
          ),
      ],
    );
  }
}

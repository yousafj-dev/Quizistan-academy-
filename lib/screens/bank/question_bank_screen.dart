import 'package:flutter/material.dart';
import 'package:quizistan_academy/core/constants/app_constants.dart';
import 'package:quizistan_academy/models/question.dart';
import 'package:quizistan_academy/services/auth_service.dart';
import 'package:quizistan_academy/services/firestore_service.dart';
import 'package:quizistan_academy/services/local_question_bank.dart';

class QuestionBankScreen extends StatefulWidget {
  const QuestionBankScreen({super.key});

  @override
  State<QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends State<QuestionBankScreen> {
  final TextEditingController _search = TextEditingController();
  String? _subject;
  bool _isTeacher = false;
  bool _loadingRole = true;
  String? _uid;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadRole() async {
    try {
      // Offline mode: no sign-in needed, profile comes from the phone.
      if (AuthService.firebaseReady) {
        final user = await AuthService.instance.ensureSignedIn();
        _uid = user.uid;
      }
      final profile = await AuthService.instance.loadProfile();
      if (!mounted) return;
      setState(() {
        _isTeacher = profile?.isTeacher ?? false;
        _loadingRole = false;
      });
    } catch (e) {
      debugPrint('QuestionBank role load failed: $e');
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

  String _safePick(String? value, List<String> options) {
    if (value != null && options.contains(value)) return value;
    return options.first;
  }

  @override
  Widget build(BuildContext context) {
    final offline = !AuthService.firebaseReady;
    return Scaffold(
      appBar: AppBar(title: const Text('Question Bank')),
      body: Column(
        children: [
          if (offline)
            Container(
              width: double.infinity,
              color: Colors.amber.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const Text(
                'Offline mode: sample sawalat dikhaye ja rahe hain.',
                style: TextStyle(fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Sawal talash karo...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Sab'),
                  selected: _subject == null,
                  onSelected: (_) => setState(() => _subject = null),
                ),
                const SizedBox(width: 8),
                for (final s in AppConstants.subjects) ...[
                  ChoiceChip(
                    label: Text(s),
                    selected: _subject == s,
                    onSelected: (_) => setState(() => _subject = s),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Question>>(
              // Offline: bundled questions. Online: Firestore.
              stream: offline
                  ? LocalQuestionBank.watch(
                      search: _search.text.trim().isEmpty
                          ? null
                          : _search.text.trim(),
                      subject: _subject,
                    )
                  : FirestoreService().watchQuestions(
                      search: _search.text.trim().isEmpty
                          ? null
                          : _search.text.trim(),
                      subject: _subject,
                    ),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                final list = snap.data ?? const <Question>[];
                if (list.isEmpty) {
                  return const Center(child: Text('Koi sawal nahi mila.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final q = list[i];
                    return Card(
                      child: ListTile(
                        title: Text(q.text,
                            maxLines: 3, overflow: TextOverflow.ellipsis),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [q.board, q.classLevel, q.subject, q.chapter]
                                .where((s) => s.isNotEmpty)
                                .map((s) => Chip(
                                      label: Text(s,
                                          style:
                                              const TextStyle(fontSize: 10)),
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                    ))
                                .toList(),
                          ),
                        ),
                        trailing: _isTeacher
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    tooltip: 'Edit',
                                    onPressed: () =>
                                        _showQuestionDialog(existing: q),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    tooltip: 'Delete',
                                    onPressed: () => _confirmDelete(q),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: (_isTeacher && !_loadingRole)
          ? FloatingActionButton.extended(
              onPressed: () => _showQuestionDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Naya sawal'),
            )
          : null,
    );
  }

  Future<void> _confirmDelete(Question q) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sawal delete karo?'),
        content: const Text('Ye sawal hamesha ke liye delete ho jayega.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child:
                  const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;
    if (!AuthService.firebaseReady) {
      _snack('Sawal delete karna online mode me hoga.');
      return;
    }
    try {
      await FirestoreService().deleteQuestion(q.id);
      _snack('Delete ho gaya.');
    } catch (e) {
      debugPrint('delete question: $e');
      _snack('Delete nahi hua. Dobara try karo.');
    }
  }

  void _showQuestionDialog({Question? existing}) {
    final textCtrl = TextEditingController(text: existing?.text ?? '');
    final optionCtrls = List.generate(
        4, (i) => TextEditingController(text: existing?.options[i] ?? ''));
    final expCtrl = TextEditingController(text: existing?.explanation ?? '');
    final chapterCtrl = TextEditingController(text: existing?.chapter ?? '');
    String board = _safePick(existing?.board, AppConstants.boards);
    String classLevel = _safePick(existing?.classLevel, AppConstants.classLevels);
    String subject = _safePick(existing?.subject, AppConstants.subjects);
    int correctIndex = existing?.correctIndex ?? 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setD) => AlertDialog(
          title: Text(existing == null ? 'Naya sawal' : 'Sawal edit karo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: textCtrl,
                    maxLines: 3,
                    decoration:
                        const InputDecoration(labelText: 'Sawal *')),
                for (int i = 0; i < 4; i++)
                  TextField(
                      controller: optionCtrls[i],
                      decoration: InputDecoration(
                          labelText: 'Option ${'ABCD'[i]} *')),
                DropdownButtonFormField<int>(
                  value: correctIndex,
                  decoration:
                      const InputDecoration(labelText: 'Sahi jawab'),
                  items: List.generate(
                      4,
                      (i) => DropdownMenuItem(
                          value: i,
                          child: Text('Option ${'ABCD'[i]}'))),
                  onChanged: (v) => setD(() => correctIndex = v ?? 0),
                ),
                TextField(
                    controller: expCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                        labelText: 'Wazahat (optional)')),
                TextField(
                    controller: chapterCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Chapter')),
                DropdownButtonFormField<String>(
                  value: board,
                  decoration: const InputDecoration(labelText: 'Board'),
                  items: AppConstants.boards
                      .map((b) =>
                          DropdownMenuItem(value: b, child: Text(b)))
                      .toList(),
                  onChanged: (v) => setD(() {
                    if (v != null) board = v;
                  }),
                ),
                DropdownButtonFormField<String>(
                  value: classLevel,
                  decoration: const InputDecoration(labelText: 'Class'),
                  items: AppConstants.classLevels
                      .map((c) =>
                          DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setD(() {
                    if (v != null) classLevel = v;
                  }),
                ),
                DropdownButtonFormField<String>(
                  value: subject,
                  decoration:
                      const InputDecoration(labelText: 'Subject'),
                  items: AppConstants.subjects
                      .map((s) =>
                          DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setD(() {
                    if (v != null) subject = v;
                  }),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx2).pop(),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final q = Question(
                  id: existing?.id ?? '',
                  board: board,
                  classLevel: classLevel,
                  subject: subject,
                  chapter: chapterCtrl.text.trim(),
                  text: textCtrl.text.trim(),
                  options:
                      optionCtrls.map((c) => c.text.trim()).toList(),
                  correctIndex: correctIndex,
                  explanation: expCtrl.text.trim(),
                  createdBy: _uid ?? '',
                  createdAt: existing?.createdAt ?? DateTime.now(),
                );
                if (!q.isValid) {
                  _snack('Sawal poora bharo (text + 4 options).');
                  return;
                }
                if (!AuthService.firebaseReady) {
                  if (ctx2.mounted) Navigator.of(ctx2).pop();
                  _snack('Sawal save karna online mode me hoga.');
                  return;
                }
                try {
                  if (existing == null) {
                    await FirestoreService().addQuestion(q);
                  } else {
                    await FirestoreService().updateQuestion(q);
                  }
                  if (ctx2.mounted) Navigator.of(ctx2).pop();
                  _snack(existing == null
                      ? 'Sawal add ho gaya.'
                      : 'Sawal update ho gaya.');
                } catch (e) {
                  debugPrint('save question: $e');
                  _snack('Save nahi hua. Dobara try karo.');
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

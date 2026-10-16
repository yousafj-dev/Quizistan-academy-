import 'package:flutter/material.dart';
import 'package:quizistan_academy/core/constants/app_constants.dart';
import 'package:quizistan_academy/core/theme/app_theme.dart';
import 'package:quizistan_academy/models/app_user.dart';
import 'package:quizistan_academy/screens/home/home_screen.dart';
import 'package:quizistan_academy/screens/plans/plans_screen.dart';
import 'package:quizistan_academy/screens/splash/splash_screen.dart';
import 'package:quizistan_academy/services/auth_service.dart';

/// User profile: view, onboarding form, sign out.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<AppUser?>? _future;

  @override
  void initState() {
    super.initState();
    _future = AuthService.instance.loadProfile();
  }

  void _reload() {
    setState(() {
      _future = AuthService.instance.loadProfile();
    });
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Kya aap waqai sign out karna chahte ho?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Nahi'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Haan', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await AuthService.instance.signOut();
    } catch (e) {
      debugPrint('ProfileScreen signOut error: $e');
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: FutureBuilder<AppUser?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _errorState(snapshot.error);
          }
          final user = snapshot.data;
          if (user == null) {
            return const _ProfileForm();
          }
          return _profileView(user);
        },
      ),
    );
  }

  Widget _errorState(Object? error) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              const Text('Profile load nahi ho saka.'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _reload,
                child: const Text('Dobara try karo'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileView(AppUser user) {
    final initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : '?';
    final roleLabel = user.isTeacher ? 'Teacher' : 'Student';
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: CircleAvatar(
            radius: 44,
            backgroundColor: AppTheme.deepBlue,
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            user.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: (user.isTeacher ? AppTheme.vividOrange : AppTheme.deepBlue)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(roleLabel, style: TextStyle(fontWeight: FontWeight.bold, color: user.isTeacher ? AppTheme.vividOrange : AppTheme.deepBlue)),
          ),
        ),
        const SizedBox(height: 20),
        _row('Board', user.board.isEmpty ? '—' : '${user.board} Board'),
        _row('Class', user.classLevel.isEmpty ? '—' : 'Class ${user.classLevel}'),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.workspace_premium,
                  color: user.isPremium ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 12),
                Text(
                  user.isPremium ? 'Premium Active' : 'Free Plan',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: user.isPremium ? Colors.green : Colors.grey,
                  ),
                ),
                const Spacer(),
                if (!user.isPremium)
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PlansScreen(),
                        ),
                      );
                    },
                    child: const Text('Premium lo'),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: _signOut,
          child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

/// First-time profile onboarding form.
class _ProfileForm extends StatefulWidget {
  const _ProfileForm();

  @override
  State<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<_ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _role = 'student';
  String? _board;
  String? _classLevel;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      // Firebase ready? Use real auth. Otherwise local-only profile.
      String uid = 'local-user';
      if (AuthService.firebaseReady) {
        final firebaseUser = await AuthService.instance.ensureSignedIn();
        uid = firebaseUser.uid;
      }
      final user = AppUser(
        uid: uid,
        name: _nameController.text.trim(),
        role: _role,
        board: _board ?? '',
        classLevel: _classLevel ?? '',
        isPremium: false,
        createdAt: DateTime.now(),
      );
      await AuthService.instance.saveProfile(user);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } catch (e) {
      debugPrint('ProfileForm save error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile save nahi ho saka.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 16),
        const Text(
          'Profile Mukammal Karo',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Apna naam aur class batao.',
          style: TextStyle(color: Colors.grey, fontSize: 15),
        ),
        const SizedBox(height: 24),
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Naam',
                  hintText: 'Apna poora naam likho',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Naam zaroori hai' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _role,
                decoration: const InputDecoration(
                  labelText: 'Aap kaun hain?',
                  border: OutlineInputBorder(),
                ),
                items: const [DropdownMenuItem(value: 'student', child: Text('Student')), DropdownMenuItem(value: 'teacher', child: Text('Teacher'))],
                onChanged: (v) => setState(() => _role = v ?? 'student'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _board,
                decoration: const InputDecoration(
                  labelText: 'Board',
                  border: OutlineInputBorder(),
                ),
                items: AppConstants.boards.map((b) => DropdownMenuItem(value: b, child: Text('$b Board'))).toList(),
                onChanged: (v) => setState(() => _board = v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _classLevel,
                decoration: const InputDecoration(
                  labelText: 'Class',
                  border: OutlineInputBorder(),
                ),
                items: AppConstants.classLevels.map((c) => DropdownMenuItem(value: c, child: Text('Class $c'))).toList(),
                onChanged: (v) => setState(() => _classLevel = v),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Karo'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

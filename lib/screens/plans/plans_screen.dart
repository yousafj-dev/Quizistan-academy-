import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quizistan_academy/core/constants/app_constants.dart';
import 'package:quizistan_academy/core/theme/app_theme.dart';
import 'package:quizistan_academy/services/purchase_service.dart';

/// Free vs Premium plans — Roman Urdu UI only.
class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PurchaseService()..init(),
      child: const _PlansBody(),
    );
  }
}

class _PlansBody extends StatefulWidget {
  const _PlansBody();

  @override
  State<_PlansBody> createState() => _PlansBodyState();
}

class _PlansBodyState extends State<_PlansBody> {
  bool _buying = false;

  Future<void> _buy(PurchaseService service) async {
    setState(() => _buying = true);
    try {
      final ok = await service.buyPremium();
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kharidari shuru nahi ho saki. Dobara try karo.'),
          ),
        );
      }
    } catch (e) {
      debugPrint('PlansScreen buy error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kuch ghalat ho gaya. Dobara try karo.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _buying = false);
    }
  }

  Future<void> _restore(PurchaseService service) async {
    try {
      await service.restore();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restore ki koshish ho gayi.')),
      );
    } catch (e) {
      debugPrint('PlansScreen restore error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restore nahi ho saka. Dobara try karo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<PurchaseService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Plans')),
      body: service.isLoading
          ? const Center(child: _Loader())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _freeCard(service),
                const SizedBox(height: 16),
                _premiumCard(service),
                const SizedBox(height: 16),
                if (!service.isAvailable)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Payment is device par available nahi hai.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _freeCard(PurchaseService service) {
    final bool current = !service.isPremium;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: current ? AppTheme.deepBlue : Colors.transparent,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Free Plan',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (current) _badge('Maujooda Plan', AppTheme.deepBlue),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Rs 0',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppTheme.inkNavy,
              ),
            ),
            const SizedBox(height: 12),
            _feature('Banner ads'),
            _feature('Rozana ${AppConstants.freeDailyQuizLimit} quiz'),
            _feature('Question bank dekhna'),
          ],
        ),
      ),
    );
  }

  Widget _premiumCard(PurchaseService service) {
    final bool active = service.isPremium;
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.brandGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(2),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  const Text(
                    'Premium',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (active) _badge('Active hai', Colors.green),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Rs 999 mahina',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppTheme.vividOrange,
              ),
            ),
            const SizedBox(height: 12),
            _feature('Pro ki sab sahulatain'),
            _feature('Test Maker (teachers)'),
            _feature('Live Room priority'),
            const SizedBox(height: 20),
            if (active)
              const SizedBox.shrink()
            else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _buying ? null : () => _buy(service),
                  child: _buying
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Premium Lo'),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => _restore(service),
                  child: const Text('Pehle se kharida hai? Restore karo'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _feature(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _Loader extends StatelessWidget {
  const _Loader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 12),
        Text('Load ho raha hai...'),
      ],
    );
  }
}

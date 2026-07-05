import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../navigation/app_routes.dart';
import '../services/app_navigation_service.dart';
import '../services/deezer_api_service.dart';
import '../theme/app_theme.dart';

class CodeScannerScreen extends StatefulWidget {
  const CodeScannerScreen({super.key});

  @override
  State<CodeScannerScreen> createState() => _CodeScannerScreenState();
}

class _CodeScannerScreenState extends State<CodeScannerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _pickFromPhotos() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Photo scan saved — searching catalog…')),
    );
    if (!mounted) return;
    Navigator.pop(context);
    context.read<AppNavigationService>().openSearchTab('scanned music');
  }

  void _searchCatalog() {
    Navigator.pop(context);
    context.read<AppNavigationService>().openSearchTab('top hits');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          'Scan code',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                const Spacer(),
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) {
                    final scale = 1.0 + (_pulse.value * 0.04);
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.musikAccent, width: 3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Icon(Icons.qr_code_scanner, size: 120, color: AppColors.musikAccent),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                Text(
                  'Point at a Musik share code or album QR',
                  style: TextStyle(color: context.textSecondary),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _searchCatalog,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.musikAccent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Search catalog instead', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _pickFromPhotos,
                        child: const Text('Pick from photos'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}



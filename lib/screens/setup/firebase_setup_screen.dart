import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class FirebaseSetupScreen extends StatelessWidget {
  const FirebaseSetupScreen({required this.error, super.key});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: AppColors.surfaceStrong,
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                            child: const Icon(
                              Icons.cloud_off_outlined,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Firebase nao configurado',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'O app precisa dos arquivos gerados pelo Firebase para autenticar usuarios e salvar os pontos.',
                      ),
                      const SizedBox(height: 12),
                      const _CommandBox(
                        text:
                            'dart pub global activate flutterfire_cli\nflutterfire configure',
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          error.toString(),
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CommandBox extends StatelessWidget {
  const _CommandBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: SelectableText(
        text,
        style: const TextStyle(color: AppColors.white, fontFamily: 'monospace'),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:geolocator/geolocator.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/location_security_service.dart';
import '../../services/punch_location_service.dart';

class CreateLocationScreen extends StatefulWidget {
  const CreateLocationScreen({super.key});

  @override
  State<CreateLocationScreen> createState() => _CreateLocationScreenState();
}

class _CreateLocationScreenState extends State<CreateLocationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _radiusCtrl = TextEditingController(text: '100');
  final _locationService = PunchLocationService();
  final _securityService = const LocationSecurityService();

  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _radiusCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    setState(() => _loading = true);
    try {
      final position = await _securityService.captureSetupPosition();
      final result = await _locationService.createLocation(
        name: _nameCtrl.text.trim(),
        allowedRadiusMeters: double.parse(_radiusCtrl.text),
        position: position,
        admin: user,
      );
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Local criado'),
          content: SelectableText(
            'Codigo para equipe: ${result.code}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } on LocationSecurityException catch (error) {
      if (!mounted) return;
      final isBlocked = error.message.contains('bloqueada');
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Permissão de localização'),
          content: Text(error.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
            if (isBlocked)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Geolocator.openAppSettings();
                },
                child: const Text('Abrir Configurações'),
              ),
          ],
        ),
      );
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString()), duration: const Duration(seconds: 6)),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar local de ponto')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _SecurityNote(),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Nome do local',
                      prefixIcon: Icon(Icons.business_outlined),
                    ),
                    validator: (value) =>
                        value == null || value.trim().length < 3
                        ? 'Informe um nome com pelo menos 3 letras.'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _radiusCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Raio permitido em metros',
                      prefixIcon: Icon(Icons.radar_outlined),
                    ),
                    validator: (value) {
                      final radius = double.tryParse(value ?? '');
                      if (radius == null) return 'Informe o raio.';
                      if (radius < 10 || radius > 500) {
                        return 'Use um raio entre 10 e 500 metros.';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loading ? null : _create,
              icon: _loading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : const Icon(Icons.my_location),
              label: const Text('Usar meu GPS e criar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecurityNote extends StatelessWidget {
  const _SecurityNote();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.shield_outlined, color: AppColors.primaryDark),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'O local sera salvo na posicao GPS atual. O app rejeita GPS simulado e localizacao muito imprecisa.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

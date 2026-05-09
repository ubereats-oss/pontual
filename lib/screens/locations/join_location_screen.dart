import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/utils/firestore_mapper.dart';
import '../../providers/auth_provider.dart';
import '../../services/punch_location_service.dart';

class JoinLocationScreen extends StatefulWidget {
  const JoinLocationScreen({super.key});

  @override
  State<JoinLocationScreen> createState() => _JoinLocationScreenState();
}

class _JoinLocationScreenState extends State<JoinLocationScreen> {
  final _codeCtrl = TextEditingController();
  final _service = PunchLocationService();

  bool _loading = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final code = cleanJoinCode(_codeCtrl.text);
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o codigo de 6 caracteres.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await _service.joinLocationWithCode(rawCode: code, user: user);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entrar com codigo')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _codeCtrl,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: const InputDecoration(
                  labelText: 'Codigo do local',
                  prefixIcon: Icon(Icons.key_outlined),
                ),
                onChanged: (value) {
                  final clean = cleanJoinCode(value);
                  if (clean != value) {
                    _codeCtrl.value = TextEditingValue(
                      text: clean,
                      selection: TextSelection.collapsed(offset: clean.length),
                    );
                  }
                },
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _loading ? null : _join,
                icon: _loading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.login),
                label: const Text('Entrar no local'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

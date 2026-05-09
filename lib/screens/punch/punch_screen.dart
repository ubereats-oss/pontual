import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/punch_location.dart';
import '../../models/punch_record.dart';
import '../../providers/auth_provider.dart';
import '../../services/location_security_service.dart';
import '../../services/punch_location_service.dart';

class PunchScreen extends StatefulWidget {
  const PunchScreen({required this.locationId, super.key});

  final String locationId;

  @override
  State<PunchScreen> createState() => _PunchScreenState();
}

class _PunchScreenState extends State<PunchScreen> {
  final _locationService = PunchLocationService();
  final _securityService = const LocationSecurityService();

  PunchType? _busyType;

  Future<void> _punch(PunchLocation location, PunchType type) async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    setState(() => _busyType = type);
    final gate = await _securityService.evaluate(location);

    try {
      await _locationService.registerPunch(
        location: location,
        user: user,
        type: type,
        gate: gate,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${type.label} registrada.')));
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _busyType = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PunchLocation?>(
      stream: _locationService.watchLocation(widget.locationId),
      builder: (context, snapshot) {
        final location = snapshot.data;
        return Scaffold(
          appBar: AppBar(title: Text(location?.name ?? 'Ponto')),
          body: SafeArea(
            child: snapshot.connectionState == ConnectionState.waiting
                ? const Center(child: CircularProgressIndicator())
                : location == null
                ? const Center(child: Text('Local nao encontrado.'))
                : _PunchBody(
                    location: location,
                    busyType: _busyType,
                    onPunch: _punch,
                  ),
          ),
        );
      },
    );
  }
}

class _PunchBody extends StatelessWidget {
  const _PunchBody({
    required this.location,
    required this.busyType,
    required this.onPunch,
  });

  final PunchLocation location;
  final PunchType? busyType;
  final Future<void> Function(PunchLocation location, PunchType type) onPunch;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _LocationStatusCard(location: location),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: busyType == null
                    ? () => onPunch(location, PunchType.arrival)
                    : null,
                icon: busyType == PunchType.arrival
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Icon(Icons.login),
                label: const Text('Chegada'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: busyType == null
                    ? () => onPunch(location, PunchType.departure)
                    : null,
                icon: busyType == PunchType.departure
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout),
                label: const Text('Saida'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Ultimos registros',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        _PunchList(locationId: location.id),
      ],
    );
  }
}

class _LocationStatusCard extends StatelessWidget {
  const _LocationStatusCard({required this.location});

  final PunchLocation location;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_user_outlined, color: AppColors.blue),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'GPS protegido',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Permitido ate ${location.allowedRadiusMeters.toStringAsFixed(0)} m do local. Codigo ${location.code}.',
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 8),
            const Text(
              'O app bloqueia localizacao simulada, GPS antigo, GPS impreciso e distancia fora do raio definido.',
              style: TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _PunchList extends StatelessWidget {
  const _PunchList({required this.locationId});

  final String locationId;

  @override
  Widget build(BuildContext context) {
    final service = PunchLocationService();

    return StreamBuilder<List<PunchRecord>>(
      stream: service.watchRecentPunches(locationId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final records = snapshot.data ?? const <PunchRecord>[];
        if (records.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Nenhum ponto registrado ainda.'),
            ),
          );
        }

        final formatter = DateFormat('dd/MM HH:mm');
        return Column(
          children: [
            for (final record in records)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: ListTile(
                    leading: Icon(
                      record.type == PunchType.arrival
                          ? Icons.login
                          : Icons.logout,
                      color: AppColors.primaryDark,
                    ),
                    title: Text(record.userName),
                    subtitle: Text(
                      '${record.type.label} • ${formatter.format(record.createdAt)}',
                    ),
                    trailing: Text(
                      '${record.distanceMeters.toStringAsFixed(0)} m',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

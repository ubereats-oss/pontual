import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/punch_location.dart';
import '../../providers/auth_provider.dart';
import '../../services/punch_location_service.dart';
import '../locations/create_location_screen.dart';
import '../locations/join_location_screen.dart';
import '../punch/punch_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final service = PunchLocationService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus locais'),
        actions: [
          IconButton(
            tooltip: 'Sair',
            onPressed: () => auth.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              _ActionRow(userName: user.name),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<List<PunchLocation>>(
                  stream: service.watchMyLocations(user.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return _StateMessage(
                        icon: Icons.error_outline,
                        title: 'Nao foi possivel carregar',
                        message: snapshot.error.toString(),
                      );
                    }

                    final locations = snapshot.data ?? const <PunchLocation>[];
                    if (locations.isEmpty) {
                      return const _StateMessage(
                        icon: Icons.pin_drop_outlined,
                        title: 'Nenhum local de ponto',
                        message:
                            'Crie um local como admin ou entre com um codigo.',
                      );
                    }

                    return ListView.separated(
                      itemCount: locations.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        return _LocationCard(location: locations[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ola, $userName',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'Escolha onde voce quer bater ponto.',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const CreateLocationScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_location_alt_outlined),
                    label: const Text('Criar local'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const JoinLocationScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.key_outlined),
                    label: const Text('Entrar'),
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

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.location});

  final PunchLocation location;

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthProvider>().user?.uid ?? '';
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: const CircleAvatar(
          backgroundColor: AppColors.surfaceStrong,
          child: Icon(Icons.place_outlined, color: AppColors.primaryDark),
        ),
        title: Text(
          location.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          'Raio ${location.allowedRadiusMeters.toStringAsFixed(0)} m  •  Codigo ${location.code}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: location.isAdmin(uid)
            ? const Tooltip(
                message: 'Admin',
                child: Icon(Icons.admin_panel_settings_outlined),
              )
            : const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => PunchScreen(locationId: location.id),
            ),
          );
        },
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.muted, size: 38),
            const SizedBox(height: 10),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

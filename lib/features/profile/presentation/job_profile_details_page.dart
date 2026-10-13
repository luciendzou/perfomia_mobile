import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class JobProfileDetailsPage extends StatelessWidget {
  const JobProfileDetailsPage({
    super.key,
    required this.jobProfile,
    this.fallbackRole,
  });

  final Map<String, dynamic> jobProfile;
  final String? fallbackRole;

  (String, String) _parseLevel(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return ('', '');
    for (final separator in [' | ', ' - ']) {
      if (raw.contains(separator)) {
        final parts = raw.split(separator);
        return (parts.first.trim(), parts.skip(1).join(separator).trim());
      }
    }
    return (raw, '');
  }

  String _value(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? 'Non renseigne' : text;
  }

  @override
  Widget build(BuildContext context) {
    final level = _parseLevel(jobProfile['level']?.toString());
    final role = jobProfile['role']?.toString() ?? fallbackRole;
    final description = jobProfile['description']?.toString();
    final missions = jobProfile['missions']?.toString();

    return Scaffold(
      appBar: AppBar(title: const Text('Fiche de poste')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text(
            'Référentiel professionnel',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Les informations utilisées pour votre suivi et votre évaluation.',
            style: TextStyle(color: Colors.blueGrey.shade600),
          ),
          const SizedBox(height: 20),
          _InfoCard(
            title: 'Positionnement',
            icon: Iconsax.personalcard,
            children: [
              _DetailRow(label: 'Role', value: _value(role)),
              _DetailRow(label: 'Dernier diplome', value: _value(level.$1)),
              _DetailRow(label: "Domaine d'etude", value: _value(level.$2)),
            ],
          ),
          const SizedBox(height: 14),
          _TextCard(
            title: 'Description du poste',
            icon: Iconsax.document_text,
            text: _value(description),
          ),
          const SizedBox(height: 14),
          _TextCard(
            title: 'Missions principales',
            icon: Iconsax.task_square,
            text: _value(missions),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.icon,
    required this.children,
  });
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(title: title, icon: icon),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    ),
  );
}

class _TextCard extends StatelessWidget {
  const _TextCard({
    required this.title,
    required this.icon,
    required this.text,
  });
  final String title;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(title: title, icon: icon),
          const SizedBox(height: 14),
          Text(text, style: const TextStyle(height: 1.55)),
        ],
      ),
    ),
  );
}

class _CardTitle extends StatelessWidget {
  const _CardTitle({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 10),
      Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
    ],
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 128,
          child: Text(label, style: TextStyle(color: Colors.blueGrey.shade600)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

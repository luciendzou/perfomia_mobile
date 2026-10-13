import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

final appMessengerKey = GlobalKey<ScaffoldMessengerState>();

String frenchMessage(String message) {
  final normalized = message.trim();
  if (normalized.isEmpty) return 'Une erreur est survenue.';

  const exact = <String, String>{
    'Unauthenticated.': 'Votre session a expire. Veuillez vous reconnecter.',
    'Unauthorized': 'Vous n\'etes pas autorise a effectuer cette action.',
    'Forbidden': 'Vous n\'etes pas autorise a effectuer cette action.',
    'The given data was invalid.': 'Certaines donnees sont invalides.',
    'Validation failed': 'La validation des donnees a echoue.',
    'Not Found': 'La ressource demandee est introuvable.',
    'Server Error': 'Le serveur a rencontre une erreur.',
    'Network Error':
        'Impossible de joindre le serveur. Verifiez votre connexion.',
  };
  return exact[normalized] ??
      normalized
          .replaceAll(
            'The selected value is invalid.',
            'La valeur selectionnee est invalide.',
          )
          .replaceAll(
            'The selected value is invalid',
            'La valeur selectionnee est invalide',
          )
          .replaceAll('This field is required.', 'Ce champ est obligatoire.')
          .replaceAll('This field is required', 'Ce champ est obligatoire')
          .replaceAll(
            'must be a valid email address',
            'doit etre une adresse e-mail valide',
          )
          .replaceAll(' field is required.', ' est obligatoire.');
}

void showAppError(String message) {
  final messenger = appMessengerKey.currentState;
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      _messageSnackBar(
        frenchMessage(message),
        const Color(0xffb42318),
        Iconsax.danger,
      ),
    );
}

void showAppSuccess(String message) {
  final messenger = appMessengerKey.currentState;
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      _messageSnackBar(
        frenchMessage(message),
        const Color(0xff07884f),
        Iconsax.tick_circle,
      ),
    );
}

SnackBar _messageSnackBar(String message, Color color, IconData icon) =>
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      backgroundColor: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      content: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

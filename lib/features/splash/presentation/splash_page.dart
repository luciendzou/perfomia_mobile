import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7fbff),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/perfomia_logo.png',
                width: 220,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),
              const Text(
                'Perfomia',
                style: TextStyle(
                  color: Color(0xff123b78),
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).appDescription,
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xff64748b), fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

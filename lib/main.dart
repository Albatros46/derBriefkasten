import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'l10n/strings.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/database_service.dart';
import 'services/document_repository.dart';
import 'services/notification_service.dart';

final _database = DatabaseService();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  await NotificationService.init();

  String? firebaseError;
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    firebaseError = '$e';
  }
  runApp(EvrakApp(firebaseError: firebaseError));
}

class EvrakApp extends StatelessWidget {
  const EvrakApp({super.key, this.firebaseError});

  final String? firebaseError;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (c) => c.t('appTitle'),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF1565C0), useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF1565C0),
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      supportedLocales: supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      localeResolutionCallback: (device, _) =>
          device?.languageCode == 'de' ? const Locale('de') : const Locale('tr'),
      home: firebaseError == null ? const AuthGate() : _SetupErrorScreen(firebaseError!),
    );
  }
}

/// Oturum durumuna göre giriş ekranını veya kullanıcının evraklarını gösterir.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = snapshot.data;
        if (user == null) return const LoginScreen();
        return ChangeNotifierProvider(
          key: ValueKey(user.uid),
          create: (_) => DocumentRepository(user.uid, _database),
          child: const HomeScreen(),
        );
      },
    );
  }
}

class _SetupErrorScreen extends StatelessWidget {
  const _SetupErrorScreen(this.details);

  final String details;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 64),
              const SizedBox(height: 16),
              Text(context.t('firebaseMissing'), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(details, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

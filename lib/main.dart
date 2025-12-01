import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'controllers/theme_controller.dart';
import 'screens/phone_auth_screen.dart';
import 'screens/chats_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'services/chat_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MemRoot());
}

class MemRoot extends StatelessWidget {
  const MemRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeController(),
      child: const MemApp(),
    );
  }
}

class MemApp extends StatelessWidget {
  const MemApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>();

    return MaterialApp(
      title: 'mem',
      debugShowCheckedModeBanner: false,
      theme: theme.lightTheme,
      darkTheme: theme.darkTheme,
      themeMode: theme.isDark ? ThemeMode.dark : ThemeMode.light,
      home: const RootScreen(),
    );
  }
}

class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snap.data;
        if (user == null) {
          // مو مسجل دخول → شاشة التوثيق
          return const PhoneAuthScreen();
        }

        return FutureBuilder<bool>(
          future: ChatService.isProfileCompleted(user.uid),
          builder: (context, profileSnap) {
            if (profileSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (profileSnap.data == true) {
              return const ChatsScreen();
            } else {
              return ProfileSetupScreen(
                uid: user.uid,
                phoneNumber: user.phoneNumber ?? '',
              );
            }
          },
        );
      },
    );
  }
}
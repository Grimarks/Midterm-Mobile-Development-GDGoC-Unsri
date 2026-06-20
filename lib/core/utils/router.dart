import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:focusdeck/features/auth/presentation/pages/splash_page.dart';
import 'package:focusdeck/features/auth/presentation/pages/login_page.dart';
import 'package:focusdeck/features/auth/presentation/pages/register_page.dart';
import 'package:focusdeck/features/home/presentation/pages/home_page.dart';
import 'package:focusdeck/features/deck/presentation/pages/deck_builder_page.dart';
import 'package:focusdeck/features/session/presentation/pages/session_page.dart';
import 'package:focusdeck/features/history/presentation/pages/history_page.dart';
import 'package:focusdeck/features/auth/providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isSplash = state.matchedLocation == '/splash';
      final isAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (isSplash) return null;
      if (!isLoggedIn && !isAuth) return '/login';
      if (isLoggedIn && isAuth) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/deck/new',
        builder: (context, state) => const DeckBuilderPage(),
      ),
      GoRoute(
        path: '/deck/edit/:deckId',
        builder: (context, state) {
          final deckId = state.pathParameters['deckId']!;
          return DeckBuilderPage(deckId: deckId);
        },
      ),
      GoRoute(
        path: '/session/:deckId',
        builder: (context, state) {
          final deckId = state.pathParameters['deckId']!;
          return SessionPage(deckId: deckId);
        },
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const HistoryPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});

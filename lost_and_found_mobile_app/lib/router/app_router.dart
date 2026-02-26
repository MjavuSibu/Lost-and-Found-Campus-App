import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/items/screens/post_item_screen.dart';
import '../features/items/screens/item_detail_screen.dart';
import '../features/search/screens/search_screen.dart';
import '../features/messaging/screens/conversations_screen.dart';
import '../features/messaging/screens/chat_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/notifications/screens/notifications_screen.dart';
import '../features/admin/screens/admin_dashboard_screen.dart';
import 'main_shell.dart';

abstract class AppRoutes {
  static const String splash        = '/';
  static const String login         = '/login';
  static const String register      = '/register';
  static const String home          = '/home';
  static const String search        = '/search';
  static const String conversations = '/messages';
  static const String profile       = '/profile';
  static const String post          = '/post';
  static const String itemDetail    = '/items/:itemId';
  static const String chat          = '/messages/:conversationId';
  static const String notifications = '/notifications';
  static const String admin         = '/admin';

  static String toItemDetail(String itemId) => '/items/$itemId';
  static String toChat(String conversationId) => '/messages/$conversationId';
  static String toPost({String type = 'lost'}) => '/post?type=$type';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    redirect: (BuildContext context, GoRouterState state) {
      final loggedIn    = authState.valueOrNull != null;
      final onSplash    = state.matchedLocation == AppRoutes.splash;
      final onLogin     = state.matchedLocation == AppRoutes.login;
      final onRegister  = state.matchedLocation == AppRoutes.register;

      // Always allow splash — navigation handled by button
      if (onSplash) return null;

      // Not logged in — send to login
      if (!loggedIn && !onLogin && !onRegister) return AppRoutes.login;

      // Logged in but on login or register — send to home
      if (loggedIn && (onLogin || onRegister)) return AppRoutes.home;

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.search,
            builder: (_, __) => const SearchScreen(),
          ),
          GoRoute(
            path: AppRoutes.conversations,
            builder: (_, __) => const ConversationsScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.post,
        builder: (context, state) {
          final type = state.uri.queryParameters['type'] ?? 'lost';
          return PostItemScreen(initialType: type);
        },
      ),
      GoRoute(
        path: AppRoutes.itemDetail,
        builder: (context, state) {
          final itemId = state.pathParameters['itemId']!;
          return ItemDetailScreen(itemId: itemId);
        },
      ),
      GoRoute(
        path: AppRoutes.chat,
        builder: (context, state) {
          final conversationId = state.pathParameters['conversationId']!;
          return ChatScreen(conversationId: conversationId);
        },
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.admin,
        builder: (_, __) => const AdminDashboardScreen(),
      ),
    ],
  );
});
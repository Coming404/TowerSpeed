import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/dashboard/dashboard_screen.dart';
import 'features/nodes/nodes_screen.dart';
import 'features/sources/sources_screen.dart';
import 'features/history/history_screen.dart';
import 'features/settings/settings_screen.dart';
import 'shared/widgets/app_shell.dart';

/// 路由：五个 Tab 各自独立栈，保留各自状态（StatefulShellRoute）。
/// 节点库放最左，承载订阅聚合与本地导入（clash-speedtest -c 多路径）。
final appRouter = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(shell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/sources',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: SourcesScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dashboard',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: DashboardScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/nodes',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: NodesScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/history',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: HistoryScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: SettingsScreen()),
            ),
          ],
        ),
      ],
    ),
  ],
);

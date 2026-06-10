// screens/workspace/project_workspace_screen.dart

import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../contract/contract_screen.dart';

class ProjectWorkspaceScreen extends StatelessWidget {
  final int contractId;
  final String userRole;

  const ProjectWorkspaceScreen({
    super.key,
    required this.contractId,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            t.projectWorkspace,
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
          elevation: 0,
          backgroundColor: theme.scaffoldBackgroundColor,
          foregroundColor: theme.colorScheme.onSurface,
          bottom: TabBar(
            indicatorColor: AppColors.secondary,
            labelColor: theme.colorScheme.onSurface,
            unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
            tabs: [
              Tab(icon: const Icon(Icons.flag), text: t.milestones),
              Tab(icon: const Icon(Icons.folder), text: t.files),
              Tab(icon: const Icon(Icons.chat), text: t.chat),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ContractScreen(contractId: contractId, userRole: userRole),
            _buildFilesTab(context),
            _buildChatTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFilesTab(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            t.filesSectionComingSoon,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTab(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            t.chatSectionComingSoon,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

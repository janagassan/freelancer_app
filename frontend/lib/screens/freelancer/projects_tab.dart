// screens/freelancer/projects_tab.dart

import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/project_model.dart';
import '../../models/favorite_model.dart';
import '../../services/api_service.dart';
import 'project_details_screen.dart';
import 'advanced_search_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../widgets/favorite_button.dart';
import '../../theme/app_theme.dart';

class ProjectsTab extends StatefulWidget {
  const ProjectsTab({super.key});

  @override
  State<ProjectsTab> createState() => _ProjectsTabState();
}

class _ProjectsTabState extends State<ProjectsTab> {
  List<Project> projects = [];
  List<Project> filteredProjects = [];
  bool loadingProjects = true;
  String selectedCategory = 'All';
  final searchController = TextEditingController();

  List<FavoriteProject> favorites = [];
  bool loadingFavorites = false;

  int _selectedView = 0;

  List<String> get categories {
    final t = AppLocalizations.of(context);
    return [
      t!.all,
      'Flutter',
      'React',
      'Node.js',
      'Python',
      'UI/UX',
      'Mobile',
      'Web',
    ];
  }

  static const Color accent = Color(0xFF2ECC71);

  @override
  void initState() {
    super.initState();
    fetchProjects();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchProjects() async {
    if (!mounted) return;
    setState(() => loadingProjects = true);

    try {
      final data = await ApiService.getAllProjects();
      if (!mounted) return;

      setState(() {
        projects = data.map((json) => Project.fromJson(json)).toList();
        filteredProjects = projects;
        loadingProjects = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loadingProjects = false);
      final t = AppLocalizations.of(context);
      Fluttertoast.showToast(msg: "${t!.errorLoadingProjects} $e");
    }
  }

  Future<void> loadFavorites() async {
    if (!mounted) return;
    setState(() => loadingFavorites = true);

    try {
      final response = await ApiService.getUserFavorites();
      if (response.success && mounted) {
        setState(() {
          favorites = response.favorites;
          loadingFavorites = false;
        });
      } else {
        if (mounted) setState(() => loadingFavorites = false);
      }
    } catch (e) {
      if (mounted) setState(() => loadingFavorites = false);
    }
  }

  void filterProjects(String query) {
    final t = AppLocalizations.of(context);

    setState(() {
      if (query.isEmpty && selectedCategory == t!.all) {
        filteredProjects = projects;
      } else {
        filteredProjects = projects.where((project) {
          final titleMatch = project.title?.toLowerCase().contains(query.toLowerCase()) ?? false;
          final descMatch = project.description?.toLowerCase().contains(query.toLowerCase()) ?? false;
          final categoryMatch = selectedCategory == t?.all ||
              (project.category?.toLowerCase() == selectedCategory.toLowerCase()) ||
              (project.skills?.any((skill) => skill.toLowerCase().contains(selectedCategory.toLowerCase())) ?? false);

          return (titleMatch || descMatch) && categoryMatch;
        }).toList();
      }
    });
  }

  void _showSortOptions() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.access_time, color: AppColors.accent),
            title: Text(t.newestFirst, style: TextStyle(color: theme.colorScheme.onSurface)),
            onTap: () {
              setState(() => filteredProjects.sort((a, b) => b.createdAt!.compareTo(a.createdAt!)));
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.attach_money, color: AppColors.accent),
            title: Text(t.budgetLowToHigh, style: TextStyle(color: theme.colorScheme.onSurface)),
            onTap: () {
              setState(() => filteredProjects.sort((a, b) => (a.budget ?? 0).compareTo(b.budget ?? 0)));
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.attach_money, color: AppColors.accent),
            title: Text(t.budgetHighToLow, style: TextStyle(color: theme.colorScheme.onSurface)),
            onTap: () {
              setState(() => filteredProjects.sort((a, b) => (b.budget ?? 0).compareTo(a.budget ?? 0)));
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.timer, color: AppColors.accent),
            title: Text(t.durationShortestFirst, style: TextStyle(color: theme.colorScheme.onSurface)),
            onTap: () {
              setState(() => filteredProjects.sort((a, b) => (a.duration ?? 0).compareTo(b.duration ?? 0)));
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(Project project) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProjectDetailsScreen(projectId: project.id!)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    project.title ?? t.untitled,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '\$${project.budget?.toStringAsFixed(0)}',
                    style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                FavoriteButton(projectId: project.id!),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                  backgroundImage: project.client?.avatar != null ? NetworkImage(project.client!.avatar!) : null,
                  child: project.client?.avatar == null
                      ? Text(project.client?.name?[0].toUpperCase() ?? 'C', style: const TextStyle(fontSize: 10, color: Colors.white))
                      : null,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    project.client?.name ?? t.unknownClient,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
                Icon(Icons.access_time, size: 14, color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint),
                const SizedBox(width: 4),
                Text(
                  _formatDate(project.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              project.description ?? t.noDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            if (project.skills != null && project.skills!.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: project.skills!.take(3).map((skill) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      skill,
                      style: TextStyle(fontSize: 10, color: isDark ? AppColors.accent : AppColors.primary),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint),
                    const SizedBox(width: 4),
                    Text(
                      '${project.duration} ${t.days}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.location_on, size: 14, color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint),
                    const SizedBox(width: 4),
                    Text(
                      t.remote,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProjectDetailsScreen(projectId: project.id!)),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    minimumSize: const Size(80, 32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(t.apply, style: const TextStyle(fontSize: 12, color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteCard(FavoriteProject favorite) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final project = favorite.project;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProjectDetailsScreen(projectId: project.id!)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.title ?? t.untitled,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    project.description ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '\$${project.budget?.toStringAsFixed(0)}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.secondary),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${project.duration} ${t.days}',
                          style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.favorite, color: Colors.red),
              onPressed: () async {
                await ApiService.removeFromFavorites(project.id!);
                loadFavorites();
                Fluttertoast.showToast(msg: t.removedFromFavorites);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    final t = AppLocalizations.of(context);
    if (date == null) return t!.unknown;
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays > 0) return '${difference.inDays} ${t!.daysAgo}';
    if (difference.inHours > 0) return '${difference.inHours} ${t!.hoursAgo}';
    return t!.justNow;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(40),
          ),
          child: Row(
            children: [
              _buildSegmentButton(0, Icons.explore, t.browse ?? 'Browse'),
              _buildSegmentButton(1, Icons.favorite, t.favorites),
              _buildSegmentButton(2, Icons.filter_alt, t.advancedSearch),
            ],
          ),
        ),

        if (_selectedView == 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: searchController,
                    style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                    decoration: InputDecoration(
                      hintText: t.searchProjects,
                      hintStyle: TextStyle(color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint),
                      prefixIcon: Icon(Icons.search, color: AppColors.accent),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.sort, color: AppColors.accent),
                        onPressed: _showSortOptions,
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: theme.cardColor,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: filterProjects,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedCategory,
                        icon: Icon(Icons.arrow_drop_down, color: AppColors.accent),
                        isExpanded: true,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                        items: categories.map((cat) {
                          return DropdownMenuItem(
                            value: cat,
                            child: Text(
                              cat,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedCategory = value;
                              filterProjects(searchController.text);
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 8),

        Expanded(
          child: IndexedStack(
            index: _selectedView,
            children: [
              _buildBrowseContent(t, theme, isDark),
              _buildFavoritesContent(t, theme),
              const AdvancedSearchScreen(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentButton(int index, IconData icon, String label) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = _selectedView == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedView = index;
            if (index == 1) loadFavorites();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.secondary : Colors.transparent,
            borderRadius: BorderRadius.circular(40),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrowseContent(AppLocalizations t, ThemeData theme, bool isDark) {
    if (loadingProjects) {
      return const Center(child: CircularProgressIndicator());
    }

    if (filteredProjects.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
              ),
              const SizedBox(height: 16),
              Text(
                t.noProjectsFound,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    selectedCategory = 'All';
                    searchController.clear();
                    filterProjects('');
                  });
                },
                child: Text(
                  t.reset ?? 'Reset filters',
                  style: TextStyle(color: AppColors.secondary),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchProjects,
      color: AppColors.accent,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        controller: ScrollController(),
        itemCount: filteredProjects.length,
        itemBuilder: (context, index) => _buildProjectCard(filteredProjects[index]),
      ),
    );
  }

  Widget _buildFavoritesContent(AppLocalizations t, ThemeData theme) {
    if (loadingFavorites) {
      return const Center(child: CircularProgressIndicator());
    }

    if (favorites.isEmpty) {
      final isDark = theme.brightness == Brightness.dark;
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_border,
                size: 64,
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                t.noFavoritesYet,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t.saveProjectsByTappingHeart,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => setState(() => _selectedView = 0),
                icon: const Icon(Icons.explore),
                label: Text(t.browseProjects),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadFavorites,
      color: AppColors.accent,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        controller: ScrollController(),
        itemCount: favorites.length,
        itemBuilder: (context, index) => _buildFavoriteCard(favorites[index]),
      ),
    );
  }
}
// ===== frontend/lib/screens/freelancer/advanced_search_screen.dart =====
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../l10n/app_localizations.dart';
import '../../models/project_model.dart';
import '../../models/financial_model.dart';
import '../../services/api_service.dart';
import 'project_details_screen.dart';
import '../../theme/app_theme.dart';

class AdvancedSearchScreen extends StatefulWidget {
  const AdvancedSearchScreen({super.key});

  @override
  State<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends State<AdvancedSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minBudgetController = TextEditingController();
  final TextEditingController _maxBudgetController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();

  List<Project> _projects = [];
  List<SavedFilter> _savedFilters = [];
  bool _loading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  int _totalPages = 1;

  String _selectedCategory = 'all';
  String _selectedSortBy = 'newest';
  String _selectedDuration = 'any';

  final ScrollController _scrollController = ScrollController();

  List<String> get _categories {
    final t = AppLocalizations.of(context);
    return [
      'all',
      t!.mobileDevelopment,
      t.webDevelopment,
      t.backendDevelopment,
      t.uiUxDesign,
      t.graphicDesign,
      t.contentWriting,
      t.digitalMarketing,
    ];
  }

  List<Map<String, dynamic>> get _sortOptions {
    final t = AppLocalizations.of(context);
    return [
      {'value': 'newest', 'label': t!.newestFirst, 'icon': Icons.access_time},
      {'value': 'budget_low', 'label': t.budgetLowToHigh, 'icon': Icons.attach_money},
      {'value': 'budget_high', 'label': t.budgetHighToLow, 'icon': Icons.attach_money},
    ];
  }

  List<Map<String, dynamic>> get _durationOptions {
    final t = AppLocalizations.of(context);
    return [
      {'value': 'any', 'label': t!.any, 'icon': Icons.timer_off, 'min': null, 'max': null},
      {'value': 'short', 'label': '1-7 ${t.days}', 'icon': Icons.timer, 'min': 1, 'max': 7},
      {'value': 'medium', 'label': '8-30 ${t.days}', 'icon': Icons.timer, 'min': 8, 'max': 30},
      {'value': 'long', 'label': '30+ ${t.days}', 'icon': Icons.timer, 'min': 30, 'max': null},
    ];
  }

  Map<String, dynamic> get _currentSortOption {
    return _sortOptions.firstWhere(
      (opt) => opt['value'] == _selectedSortBy,
      orElse: () => _sortOptions.first,
    );
  }

  Map<String, dynamic> get _currentDurationOption {
    return _durationOptions.firstWhere(
      (opt) => opt['value'] == _selectedDuration,
      orElse: () => _durationOptions.first,
    );
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadSavedFilters();
    _searchProjects();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minBudgetController.dispose();
    _maxBudgetController.dispose();
    _skillsController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (_hasMore && !_loading) {
        _searchProjects(loadMore: true);
      }
    }
  }

  Future<void> _loadSavedFilters() async {
    try {
      final filters = await ApiService.getSavedFilters();
      if (mounted) setState(() => _savedFilters = filters);
    } catch (e) {
    }
  }

  Future<void> _searchProjects({bool loadMore = false}) async {
    if (loadMore && !_hasMore) return;
    if (_loading) return;
    if (!mounted) return;

    setState(() => _loading = true);

    try {
      final page = loadMore ? _currentPage + 1 : 1;
      
      final durationOpt = _currentDurationOption;
      final minDuration = durationOpt['min'] as int?;
      final maxDuration = durationOpt['max'] as int?;

      final response = await ApiService.advancedProjectSearch(
        query: _searchController.text,
        category: _selectedCategory == 'all' ? null : _selectedCategory,
        minBudget: _minBudgetController.text.isNotEmpty ? double.tryParse(_minBudgetController.text) : null,
        maxBudget: _maxBudgetController.text.isNotEmpty ? double.tryParse(_maxBudgetController.text) : null,
        minDuration: minDuration,
        maxDuration: maxDuration,
        skills: _skillsController.text.isNotEmpty ? _skillsController.text : null,
        sortBy: _selectedSortBy,
        page: page,
      );

      if (!mounted) return;

      setState(() {
        if (loadMore) {
          _projects.addAll(response.projects);
          _currentPage = response.page;
        } else {
          _projects = response.projects;
          _currentPage = response.page;
        }
        _totalPages = response.totalPages;
        _hasMore = _currentPage < _totalPages;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        final t = AppLocalizations.of(context);
        Fluttertoast.showToast(msg: '${t!.searchError}: $e');
      }
    }
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategory = 'all';
      _minBudgetController.clear();
      _maxBudgetController.clear();
      _skillsController.clear();
      _selectedSortBy = 'newest';
      _selectedDuration = 'any';
    });
    _searchProjects();
  }

  void _applySavedFilter(SavedFilter filter) {
    final data = filter.filterData;
    setState(() {
      _searchController.text = data['query'] ?? '';
      _selectedCategory = data['category'] ?? 'all';
      _minBudgetController.text = data['minBudget'] ?? '';
      _maxBudgetController.text = data['maxBudget'] ?? '';
      _skillsController.text = data['skills'] ?? '';
      _selectedSortBy = data['sortBy'] ?? 'newest';
      _selectedDuration = data['duration'] ?? 'any';
    });
    _searchProjects();
  }

  Future<void> _saveCurrentFilter() async {
    final t = AppLocalizations.of(context)!;
    final nameController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.saveSearchFilter),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: t.filterName,
            hintText: t.filterHint,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
            child: Text(t.save),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.isNotEmpty) {
      final filterData = {
        'query': _searchController.text,
        'category': _selectedCategory,
        'minBudget': _minBudgetController.text,
        'maxBudget': _maxBudgetController.text,
        'skills': _skillsController.text,
        'sortBy': _selectedSortBy,
        'duration': _selectedDuration,
      };

      try {
        await ApiService.saveSearchFilter(name: nameController.text, filterData: filterData);
        Fluttertoast.showToast(msg: t.filterSaved);
        _loadSavedFilters();
      } catch (e) {
        Fluttertoast.showToast(msg: '${t.errorSavingFilter}: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        actions: [
          if (_savedFilters.isNotEmpty)
            IconButton(
              icon: Icon(Icons.bookmark_outline, color: theme.iconTheme.color),
              onPressed: _showSavedFiltersDialog,
              tooltip: t.savedSearches,
            ),
          IconButton(
            icon: Icon(Icons.save, color: theme.iconTheme.color),
            onPressed: _saveCurrentFilter,
            tooltip: t.saveThisSearch,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildQuickFiltersRow(t, theme, isDark),
          _buildSearchBar(t, theme, isDark),
          _buildFiltersPanel(t, theme, isDark),
          _buildResultsHeader(t, theme, isDark),
          Expanded(child: _buildResultsList(t, theme, isDark)),
        ],
      ),
    );
  }

  Widget _buildQuickFiltersRow(AppLocalizations t, ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedSortBy,
                icon: const Icon(Icons.arrow_drop_down, size: 18),
                style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface),
                items: _sortOptions.map((opt) {
                  return DropdownMenuItem(
                    value: opt['value'] as String,
                    child: Row(
                      children: [
                        Icon(opt['icon'] as IconData, size: 16, color: AppColors.secondary),
                        const SizedBox(width: 6),
                        Text(opt['label'] as String, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedSortBy = value);
                    _searchProjects();
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildQuickChip(
            label: _currentDurationOption['label'] as String,
            icon: Icons.timer,
            isSelected: _selectedDuration != 'any',
            onTap: _showDurationPicker,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? AppColors.secondary : Colors.grey),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, color: isSelected ? AppColors.secondary : null)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(AppLocalizations t, ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        style: TextStyle(fontSize: 16, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
        decoration: InputDecoration(
          hintText: t.searchProjects,
          hintStyle: TextStyle(fontSize: 16, color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint),
          prefixIcon: Icon(Icons.search, size: 24, color: AppColors.secondary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    _searchProjects();
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
          filled: true,
          fillColor: theme.cardColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        onChanged: (_) => _searchProjects(),
      ),
    );
  }

  Widget _buildFiltersPanel(AppLocalizations t, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: t.category,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  items: _categories.map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat == 'all' ? t.all : cat));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCategory = value);
                      _searchProjects();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _skillsController,
                  decoration: InputDecoration(
                    labelText: t.skills,
                    hintText: t.skillsCommaSeparated,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  onChanged: (_) => _searchProjects(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minBudgetController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: t.minBudget,
                    prefixText: '\$ ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  onChanged: (_) => _searchProjects(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _maxBudgetController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: t.maxBudget,
                    prefixText: '\$ ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  onChanged: (_) => _searchProjects(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _resetFilters,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.secondary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(t.reset),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsHeader(AppLocalizations t, ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_projects.length} ${t.projectsFound}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
            ),
          ),
          if (_loading && _projects.isNotEmpty)
            const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
        ],
      ),
    );
  }

  Widget _buildResultsList(AppLocalizations t, ThemeData theme, bool isDark) {
  if (_loading && _projects.isEmpty) {
    return const Center(child: CircularProgressIndicator());
  }

  if (_projects.isEmpty) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(),  
                  Icon(
                    Icons.search_off,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t.noProjectsFound,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _resetFilters,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.secondary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(
                      t.reset,
                      style: TextStyle(fontSize: 14, color: AppColors.secondary),
                    ),
                  ),
                  const Spacer(),  
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  return RefreshIndicator(
    onRefresh: () => _searchProjects(),
    color: AppColors.secondary,
    child: ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _projects.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _projects.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
          );
        }
        return _buildProjectCard(_projects[index], theme, isDark, t);
      },
    ),
  );
}

  Widget _buildProjectCard(Project project, ThemeData theme, bool isDark, AppLocalizations t) {
    if (project.id == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: theme.cardColor,
      elevation: isDark ? 1 : 2,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProjectDetailsScreen(projectId: project.id!)),
        ),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      project.title ?? t.untitled,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _FavoriteButton(projectId: project.id!),
                ],
              ),
              const SizedBox(height: 12),
              
              Text(
                project.description ?? t.noDescription,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              
              if (project.skills != null && project.skills!.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: project.skills!.map((skill) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        skill,
                        style: TextStyle(fontSize: 12, color: AppColors.secondary),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 16),
              
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.attach_money, size: 16, color: Colors.green.shade700),
                        const SizedBox(width: 4),
                        Text(
                          '${project.budget?.toStringAsFixed(0)}',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                        ),
                      ],
                    ),
                  ),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.blue.shade700),
                        const SizedBox(width: 4),
                        Text(
                          '${project.duration} ${t.days}',
                          style: TextStyle(fontSize: 14, color: Colors.blue.shade700),
                        ),
                      ],
                    ),
                  ),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                          backgroundImage: (project.client?.avatar != null && project.client!.avatar!.isNotEmpty)
                              ? NetworkImage(project.client!.avatar!)
                              : null,
                          child: (project.client?.avatar == null || project.client!.avatar!.isEmpty)
                              ? Text(
                                  (project.client?.name != null && project.client!.name!.isNotEmpty)
                                      ? project.client!.name![0].toUpperCase()
                                      : 'C',
                                  style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 150),
                          child: Text(
                            project.client?.name ?? t.unknownClient,
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _formatDate(project.createdAt, t),
                  style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date, AppLocalizations t) {
    if (date == null) return t.unknown;
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 7) return '${date.day}/${date.month}/${date.year}';
    if (diff.inDays > 0) return '${diff.inDays} ${t.daysAgo}';
    if (diff.inHours > 0) return '${diff.inHours} ${t.hoursAgo}';
    return t.justNow;
  }

  void _showDurationPicker() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: _durationOptions.map((opt) {
          final isSelected = _selectedDuration == opt['value'];
          return ListTile(
            leading: Icon(opt['icon'] as IconData, color: isSelected ? AppColors.secondary : null),
            title: Text(opt['label'] as String, style: TextStyle(color: isSelected ? AppColors.secondary : null)),
            trailing: isSelected ? Icon(Icons.check, color: AppColors.secondary) : null,
            onTap: () {
              setState(() => _selectedDuration = opt['value'] as String);
              Navigator.pop(context);
              _searchProjects();
            },
          );
        }).toList(),
      ),
    );
  }

  void _showSavedFiltersDialog() {
    final t = AppLocalizations.of(context)!;
    if (_savedFilters.isEmpty) return;
    
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Saved Searches', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const Divider(),
          ..._savedFilters.map((filter) => ListTile(
            leading: Icon(Icons.bookmark, color: AppColors.secondary),
            title: Text(filter.name),
            subtitle: Text(filter.filterData['category'] ?? t.all),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.grey),
              onPressed: () async {
                await ApiService.deleteSavedFilter(filter.id);
                if (mounted) {
                  Navigator.pop(context);
                  _loadSavedFilters();
                }
              },
            ),
            onTap: () {
              Navigator.pop(context);
              _applySavedFilter(filter);
            },
          )),
        ],
      ),
    );
  }
}

class _FavoriteButton extends StatefulWidget {
  final int projectId;
  const _FavoriteButton({required this.projectId});

  @override
  State<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<_FavoriteButton> {
  bool _isFavorite = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    try {
      final isFav = await ApiService.isProjectFavorite(widget.projectId);
      if (mounted) {
        setState(() {
          _isFavorite = isFav;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFavorite() async {
    final t = AppLocalizations.of(context);
    setState(() => _loading = true);
    try {
      if (_isFavorite) {
        await ApiService.removeFromFavorites(widget.projectId);
        if (mounted) setState(() => _isFavorite = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t?.removedFromFavorites ?? 'Removed from favorites')),
        );
      } else {
        await ApiService.addToFavorites(widget.projectId);
        if (mounted) setState(() => _isFavorite = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t?.addedToFavorites ?? 'Added to favorites')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${t?.error}: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    return IconButton(
      icon: Icon(
        _isFavorite ? Icons.favorite : Icons.favorite_border,
        color: _isFavorite ? Colors.red : Colors.grey,
        size: 28,
      ),
      onPressed: _toggleFavorite,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }
}
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skillstreakapp/data/models/talent_model.dart';
import '../../providers/talent_provider.dart';
import '../../core/widgets/talent_card.dart';
import '../../core/widgets/loading_shimmer.dart';
import '../talents/talent_detail_screen.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _selectedLevel = 'All';
  String _selectedSort = 'Most Popular';

  final List<String> _categories = [
    'All',
    'Sports',
    'Music',
    'Arts',
    'Debate',
    'Dance',
    'Science',
    'Technology',
    'Leadership',
  ];

  final List<String> _levels = [
    'All',
    'School',
    'District',
    'State',
    'National',
    'International',
  ];

  final List<String> _sortOptions = [
    'Most Popular',
    'Highest Rated',
    'Most Recent',
    'Most Viewed',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    // Refresh talents with filters
    ref.invalidate(talentsProvider);
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = 'All';
      _selectedLevel = 'All';
      _selectedSort = 'Most Popular';
      _searchController.clear();
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    final talents = ref.watch(talentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Talents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterBottomSheet(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search talents, skills, or names...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => _applyFilters(),
            ),
          ),

          // Categories
          SizedBox(
            height: 60,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _categories.map((category) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: _selectedCategory == category,
                    onSelected: (selected) {
                      setState(() => _selectedCategory = category);
                      _applyFilters();
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Active filters
          if (_selectedCategory != 'All' || _selectedLevel != 'All')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Filters:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_selectedCategory != 'All')
                    Chip(
                      label: Text(_selectedCategory),
                      onDeleted: () {
                        setState(() => _selectedCategory = 'All');
                        _applyFilters();
                      },
                    ),
                  if (_selectedLevel != 'All')
                    Chip(
                      label: Text(_selectedLevel),
                      onDeleted: () {
                        setState(() => _selectedLevel = 'All');
                        _applyFilters();
                      },
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Clear All'),
                  ),
                ],
              ),
            ),

          // Talents List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(talentsProvider.notifier).refreshTalents();
              },
              child: talents.when(
                data: (talents) {
                  if (talents.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No talents found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your filters',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    );
                  }

                  // Apply filters
                  var filteredTalents = talents;
                  
                  if (_selectedCategory != 'All') {
                    filteredTalents = filteredTalents
                        .where((talent) => talent.category == _selectedCategory)
                        .toList();
                  }
                  
                  if (_selectedLevel != 'All') {
                    filteredTalents = filteredTalents
                        .where((talent) => talent.level == _selectedLevel)
                        .toList();
                  }
                  
                  if (_searchController.text.isNotEmpty) {
                    final query = _searchController.text.toLowerCase();
                    filteredTalents = filteredTalents
                        .where((talent) =>
                            talent.title.toLowerCase().contains(query) ||
                            talent.description.toLowerCase().contains(query) ||
                            talent.userName.toLowerCase().contains(query) ||
                            talent.tags.any((tag) => tag.toLowerCase().contains(query)))
                        .toList();
                  }

                  // Apply sorting
                  switch (_selectedSort) {
                    case 'Most Popular':
                      filteredTalents.sort((a, b) => b.likes.compareTo(a.likes));
                      break;
                    case 'Highest Rated':
                      filteredTalents.sort((a, b) => b.rating.compareTo(a.rating));
                      break;
                    case 'Most Recent':
                      filteredTalents.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
                      break;
                    case 'Most Viewed':
                      filteredTalents.sort((a, b) => b.views.compareTo(a.views));
                      break;
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredTalents.length,
                    itemBuilder: (context, index) {
                      final talent = filteredTalents[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: TalentCard(
                          talent: talent,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TalentDetailScreen(talent: talent),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
                loading: () => const LoadingShimmer(),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading talents',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.read(talentsProvider.notifier).refreshTalents(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Level Filter
                  _buildFilterSection('Level', _levels, _selectedLevel, (value) {
                    setState(() => _selectedLevel = value);
                  }),

                  const SizedBox(height: 20),

                  // Sort Options
                  _buildFilterSection('Sort By', _sortOptions, _selectedSort, (value) {
                    setState(() => _selectedSort = value);
                  }),

                  const SizedBox(height: 30),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _clearFilters();
                          },
                          child: const Text('Clear All'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _applyFilters();
                          },
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterSection(
    String title,
    List<String> options,
    String selectedValue,
    ValueChanged<String> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            return FilterChip(
              label: Text(option),
              selected: selectedValue == option,
              onSelected: (selected) {
                if (selected) onChanged(option);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
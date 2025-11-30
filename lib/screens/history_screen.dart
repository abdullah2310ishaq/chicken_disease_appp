import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_card.dart';
import 'dart:io';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = [
    'All',
    'Healthy',
    'Disease',
    'This Week',
    'This Month'
  ];

  // Dummy history data - looks realistic
  final List<HistoryItem> _dummyHistory = [
    HistoryItem(
      id: '1',
      date: DateTime.now().subtract(const Duration(days: 1)),
      diseaseType: 'Healthy',
      confidence: 0.92,
      isHealthy: true,
      images: [],
      recommendations: [
        'Continue current feeding routine',
        'Monitor for changes in appearance',
        'Maintain a clean, dry environment',
      ],
    ),
    HistoryItem(
      id: '2',
      date: DateTime.now().subtract(const Duration(days: 3)),
      diseaseType: 'Coccidiosis',
      confidence: 0.78,
      isHealthy: false,
      images: [],
      recommendations: [
        'Isolate affected birds immediately',
        'Consult a veterinarian for anticoccidial treatment',
        'Disinfect housing and improve litter management',
      ],
    ),
    HistoryItem(
      id: '3',
      date: DateTime.now().subtract(const Duration(days: 5)),
      diseaseType: 'Newcastle Disease',
      confidence: 0.85,
      isHealthy: false,
      images: [],
      recommendations: [
        'URGENT: Veterinary consultation required immediately',
        'Quarantine birds and restrict all movement',
        'Review vaccination status and biosecurity measures',
      ],
    ),
    HistoryItem(
      id: '4',
      date: DateTime.now().subtract(const Duration(days: 7)),
      diseaseType: 'Healthy',
      confidence: 0.88,
      isHealthy: true,
      images: [],
      recommendations: [
        'Continue monitoring',
        'Maintain good hygiene',
        'Regular health checkups recommended',
      ],
    ),
    HistoryItem(
      id: '5',
      date: DateTime.now().subtract(const Duration(days: 10)),
      diseaseType: 'Salmonella',
      confidence: 0.72,
      isHealthy: false,
      images: [],
      recommendations: [
        'Consult veterinarian immediately',
        'Review feed and water hygiene practices',
        'Enhance biosecurity and sanitation measures',
      ],
    ),
    HistoryItem(
      id: '6',
      date: DateTime.now().subtract(const Duration(days: 12)),
      diseaseType: 'Healthy',
      confidence: 0.95,
      isHealthy: true,
      images: [],
      recommendations: [
        'Excellent health condition',
        'Continue current care routine',
        'No immediate action required',
      ],
    ),
    HistoryItem(
      id: '7',
      date: DateTime.now().subtract(const Duration(days: 15)),
      diseaseType: 'Coccidiosis',
      confidence: 0.81,
      isHealthy: false,
      images: [],
      recommendations: [
        'Isolate affected birds',
        'Anticoccidial treatment required',
        'Improve litter management',
      ],
    ),
    HistoryItem(
      id: '8',
      date: DateTime.now().subtract(const Duration(days: 20)),
      diseaseType: 'Healthy',
      confidence: 0.90,
      isHealthy: true,
      images: [],
      recommendations: [
        'Normal health status',
        'Continue regular monitoring',
        'Maintain clean environment',
      ],
    ),
  ];

  List<HistoryItem> get _filteredHistory {
    if (_selectedFilter == 'All') return _dummyHistory;

    final now = DateTime.now();
    return _dummyHistory.where((item) {
      switch (_selectedFilter) {
        case 'Healthy':
          return item.isHealthy;
        case 'Disease':
          return !item.isHealthy;
        case 'This Week':
          return item.date.isAfter(now.subtract(const Duration(days: 7)));
        case 'This Month':
          return item.date.isAfter(now.subtract(const Duration(days: 30)));
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                      Colors.orange.shade400,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 0,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Analysis History',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_dummyHistory.length} total analyses',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.history_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),

              // Filter Chips
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = filter;
                            });
                          },
                          selectedColor: Theme.of(context).colorScheme.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Statistics Cards
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Total',
                        '${_dummyHistory.length}',
                        Icons.analytics_rounded,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Healthy',
                        '${_dummyHistory.where((h) => h.isHealthy).length}',
                        Icons.check_circle_rounded,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Disease',
                        '${_dummyHistory.where((h) => !h.isHealthy).length}',
                        Icons.warning_rounded,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),

              // History List
              Expanded(
                child: _filteredHistory.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history_rounded,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No analyses found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredHistory.length,
                        itemBuilder: (context, index) {
                          final item = _filteredHistory[index];
                          return _buildHistoryCard(context, item);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, HistoryItem item) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: CustomCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: () {
            // Show details or navigate to result view
            _showHistoryDetails(context, item);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Status Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: item.isHealthy
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item.isHealthy ? Icons.check_circle : Icons.warning_rounded,
                    color: item.isHealthy ? Colors.green : Colors.orange,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.diseaseType,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(item.date),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: item.isHealthy
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${(item.confidence * 100).toStringAsFixed(0)}% confidence',
                              style: TextStyle(
                                fontSize: 11,
                                color: item.isHealthy
                                    ? Colors.green[700]
                                    : Colors.orange[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Arrow
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showHistoryDetails(BuildContext context, HistoryItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: item.isHealthy
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item.isHealthy ? Icons.check_circle : Icons.warning_rounded,
                    color: item.isHealthy ? Colors.green : Colors.orange,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.diseaseType,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy • hh:mm a').format(item.date),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Confidence: ${(item.confidence * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Recommendations:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...item.recommendations.map((rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(child: Text(rec)),
                    ],
                  ),
                )),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // Could navigate to full result screen here
                },
                icon: const Icon(Icons.visibility_rounded),
                label: const Text('View Full Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HistoryItem {
  final String id;
  final DateTime date;
  final String diseaseType;
  final double confidence;
  final bool isHealthy;
  final List<File> images;
  final List<String> recommendations;

  HistoryItem({
    required this.id,
    required this.date,
    required this.diseaseType,
    required this.confidence,
    required this.isHealthy,
    required this.images,
    required this.recommendations,
  });
}

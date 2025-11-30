import 'package:flutter/material.dart';
import '../widgets/custom_card.dart';

class TipsTricksScreen extends StatefulWidget {
  const TipsTricksScreen({super.key});

  @override
  State<TipsTricksScreen> createState() => _TipsTricksScreenState();
}

class _TipsTricksScreenState extends State<TipsTricksScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _selectedCategory = 0;

  final List<String> _categories = [
    'All',
    'Prevention',
    'Symptoms',
    'Treatment',
    'Care Tips',
    'Emergency',
  ];

  final List<TipItem> _allTips = [
    // Prevention Tips
    TipItem(
      category: 'Prevention',
      title: 'Biosecurity Measures',
      icon: Icons.shield_rounded,
      color: Colors.blue,
      tips: [
        'Keep visitors away from your flock',
        'Use footbaths with disinfectant',
        'Change clothes before entering coop',
        'Quarantine new birds for 30 days',
        'Keep wild birds away from feeders',
      ],
    ),
    TipItem(
      category: 'Prevention',
      title: 'Vaccination Schedule',
      icon: Icons.medical_services_rounded,
      color: Colors.green,
      tips: [
        'Newcastle: 1-3 days old',
        'Marek\'s: Day 1 (at hatchery)',
        'Infectious Bronchitis: 2-4 weeks',
        'Fowl Pox: 8-16 weeks',
        'Annual booster shots recommended',
      ],
    ),
    TipItem(
      category: 'Prevention',
      title: 'Clean Environment',
      icon: Icons.cleaning_services_rounded,
      color: Colors.orange,
      tips: [
        'Clean coop weekly with disinfectant',
        'Remove wet bedding immediately',
        'Ensure proper ventilation',
        'Keep feed and water clean',
        'Regular pest control measures',
      ],
    ),

    // Symptoms
    TipItem(
      category: 'Symptoms',
      title: 'Respiratory Issues',
      icon: Icons.air_rounded,
      color: Colors.red,
      tips: [
        'Sneezing and coughing',
        'Nasal discharge',
        'Difficulty breathing',
        'Wheezing sounds',
        'Head shaking',
      ],
    ),
    TipItem(
      category: 'Symptoms',
      title: 'Digestive Problems',
      icon: Icons.restaurant_rounded,
      color: Colors.brown,
      tips: [
        'Diarrhea or loose stools',
        'Blood in droppings',
        'Loss of appetite',
        'Weight loss',
        'Abnormal faeces color',
      ],
    ),
    TipItem(
      category: 'Symptoms',
      title: 'Behavioral Changes',
      icon: Icons.psychology_rounded,
      color: Colors.purple,
      tips: [
        'Lethargy and weakness',
        'Isolation from flock',
        'Reduced egg production',
        'Abnormal posture',
        'Loss of balance',
      ],
    ),

    // Treatment
    TipItem(
      category: 'Treatment',
      title: 'First Aid Kit',
      icon: Icons.medical_services_rounded,
      color: Colors.teal,
      tips: [
        'Antibiotics (prescribed by vet)',
        'Electrolyte solutions',
        'Probiotics for gut health',
        'Wound cleaning supplies',
        'Thermometer for temperature',
      ],
    ),
    TipItem(
      category: 'Treatment',
      title: 'Isolation Protocol',
      icon: Icons.home_work_rounded,
      color: Colors.indigo,
      tips: [
        'Separate sick birds immediately',
        'Provide warm, quiet space',
        'Ensure access to food and water',
        'Monitor symptoms closely',
        'Contact veterinarian if severe',
      ],
    ),

    // Care Tips
    TipItem(
      category: 'Care Tips',
      title: 'Daily Health Check',
      icon: Icons.health_and_safety_rounded,
      color: Colors.green,
      tips: [
        'Check for alert, bright eyes',
        'Observe eating and drinking',
        'Monitor droppings quality',
        'Check for any injuries',
        'Note any behavioral changes',
      ],
    ),
    TipItem(
      category: 'Care Tips',
      title: 'Nutrition Guidelines',
      icon: Icons.restaurant_menu_rounded,
      color: Colors.amber,
      tips: [
        'Provide balanced commercial feed',
        'Fresh water available 24/7',
        'Calcium supplements for layers',
        'Grit for digestion',
        'Avoid moldy or spoiled feed',
      ],
    ),
    TipItem(
      category: 'Care Tips',
      title: 'Seasonal Care',
      icon: Icons.wb_sunny_rounded,
      color: Colors.deepOrange,
      tips: [
        'Summer: Provide shade and cool water',
        'Winter: Protect from drafts and cold',
        'Spring: Clean and disinfect thoroughly',
        'Fall: Prepare for winter conditions',
        'Year-round: Monitor temperature',
      ],
    ),

    // Emergency
    TipItem(
      category: 'Emergency',
      title: 'Emergency Contacts',
      icon: Icons.phone_rounded,
      color: Colors.red,
      tips: [
        'Local poultry veterinarian',
        'Animal emergency clinic',
        'Poultry health hotline',
        'Extension service office',
        'Emergency backup contacts',
      ],
    ),
    TipItem(
      category: 'Emergency',
      title: 'Critical Signs',
      icon: Icons.warning_rounded,
      color: Colors.red,
      tips: [
        'Sudden death in multiple birds',
        'Severe respiratory distress',
        'Paralysis or inability to stand',
        'Blood in droppings',
        'Extreme lethargy or coma',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<TipItem> get _filteredTips {
    if (_selectedCategory == 0) return _allTips;
    return _allTips
        .where((tip) => tip.category == _categories[_selectedCategory])
        .toList();
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
              Colors.orange.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Header
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
                child: Column(
                  children: [
                    Row(
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
                                'Chicken Health Guide',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Expert tips for healthy chickens',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
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
                            Icons.lightbulb_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Category Filter
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _categories.asMap().entries.map((entry) {
                          final index = entry.key;
                          final category = entry.value;
                          final isSelected = _selectedCategory == index;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategory = index;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 8,
                                          spreadRadius: 0,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                category,
                                style: TextStyle(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              // Tips Content
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _filteredTips.length,
                    itemBuilder: (context, index) {
                      final tip = _filteredTips[index];
                      return _buildTipCard(context, tip, index);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipCard(BuildContext context, TipItem tip, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: CustomCard(
        padding: EdgeInsets.zero,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                tip.color.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: tip.color.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: tip.color.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      tip.color.withOpacity(0.1),
                      tip.color.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: tip.color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: tip.color.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        tip.icon,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tip.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: tip.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              tip.category,
                              style: TextStyle(
                                color: tip.color,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Tips List
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: tip.tips.asMap().entries.map((entry) {
                    final tipIndex = entry.key;
                    final tipText = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: tip.color.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${tipIndex + 1}',
                                style: TextStyle(
                                  color: tip.color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              tipText,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TipItem {
  final String category;
  final String title;
  final IconData icon;
  final Color color;
  final List<String> tips;

  TipItem({
    required this.category,
    required this.title,
    required this.icon,
    required this.color,
    required this.tips,
  });
}

import 'package:flutter/material.dart';
import '../widgets/custom_card.dart';

class DiseaseDatabaseScreen extends StatefulWidget {
  const DiseaseDatabaseScreen({super.key});

  @override
  State<DiseaseDatabaseScreen> createState() => _DiseaseDatabaseScreenState();
}

class _DiseaseDatabaseScreenState extends State<DiseaseDatabaseScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _searchQuery = '';

  final List<DiseaseInfo> _diseases = [
    DiseaseInfo(
      name: 'Newcastle Disease',
      severity: 'Critical',
      color: Colors.red,
      icon: Icons.warning_rounded,
      symptoms: [
        'Respiratory distress',
        'Green diarrhea',
        'Paralysis of legs/wings',
        'Twisted neck',
        'Sudden death',
      ],
      prevention: [
        'Vaccination at 1-3 days old',
        'Annual booster shots',
        'Strict biosecurity',
        'Quarantine new birds',
        'Clean environment',
      ],
      treatment: [
        'No specific treatment',
        'Supportive care',
        'Isolation of sick birds',
        'Veterinary consultation',
        'Report to authorities',
      ],
      transmission: 'Direct contact, contaminated feed/water, airborne',
      mortality: 'Up to 100% in unvaccinated flocks',
    ),
    DiseaseInfo(
      name: 'Coccidiosis',
      severity: 'High',
      color: Colors.orange,
      icon: Icons.bug_report_rounded,
      symptoms: [
        'Blood in droppings',
        'Pale comb and wattles',
        'Loss of appetite',
        'Ruffled feathers',
        'Weakness and lethargy',
      ],
      prevention: [
        'Keep coop dry and clean',
        'Avoid overcrowding',
        'Good ventilation',
        'Regular cleaning',
        'Medicated starter feed',
      ],
      treatment: [
        'Anticoccidial medication',
        'Electrolyte solutions',
        'Probiotics',
        'Clean, dry bedding',
        'Veterinary guidance',
      ],
      transmission: 'Fecal-oral route, contaminated environment',
      mortality: '5-50% if untreated',
    ),
    DiseaseInfo(
      name: 'Salmonella',
      severity: 'High',
      color: Colors.brown,
      icon: Icons.biotech_rounded,
      symptoms: [
        'Diarrhea',
        'Loss of appetite',
        'Depression',
        'Ruffled feathers',
        'Reduced egg production',
      ],
      prevention: [
        'Clean water sources',
        'Proper feed storage',
        'Good hygiene practices',
        'Rodent control',
        'Regular health checks',
      ],
      treatment: [
        'Antibiotic treatment',
        'Fluid therapy',
        'Isolation',
        'Environmental cleaning',
        'Veterinary consultation',
      ],
      transmission: 'Contaminated feed/water, direct contact',
      mortality: 'Variable, can be high in young birds',
    ),
    DiseaseInfo(
      name: 'E. coli Infection',
      severity: 'Medium',
      color: Colors.purple,
      icon: Icons.science_rounded,
      symptoms: [
        'Respiratory problems',
        'Joint swelling',
        'Diarrhea',
        'Loss of appetite',
        'Depression',
      ],
      prevention: [
        'Clean environment',
        'Proper ventilation',
        'Good nutrition',
        'Stress reduction',
        'Regular cleaning',
      ],
      treatment: [
        'Antibiotic therapy',
        'Supportive care',
        'Fluid replacement',
        'Isolation',
        'Veterinary treatment',
      ],
      transmission: 'Contaminated environment, poor hygiene',
      mortality: 'Low to moderate',
    ),
    DiseaseInfo(
      name: 'Marek\'s Disease',
      severity: 'High',
      color: Colors.indigo,
      icon: Icons.psychology_rounded,
      symptoms: [
        'Paralysis of legs',
        'Weight loss',
        'Irregular pupils',
        'Skin tumors',
        'Sudden death',
      ],
      prevention: [
        'Vaccination at day 1',
        'Strict biosecurity',
        'Clean environment',
        'Avoid stress',
        'Proper nutrition',
      ],
      treatment: [
        'No effective treatment',
        'Supportive care only',
        'Isolation of sick birds',
        'Prevention is key',
        'Veterinary consultation',
      ],
      transmission: 'Airborne, feather dander, contaminated environment',
      mortality: 'High in unvaccinated birds',
    ),
    DiseaseInfo(
      name: 'Infectious Bronchitis',
      severity: 'Medium',
      color: Colors.teal,
      icon: Icons.air_rounded,
      symptoms: [
        'Coughing and sneezing',
        'Nasal discharge',
        'Reduced egg production',
        'Soft-shelled eggs',
        'Respiratory distress',
      ],
      prevention: [
        'Vaccination program',
        'Good ventilation',
        'Avoid stress',
        'Clean environment',
        'Proper nutrition',
      ],
      treatment: [
        'Supportive care',
        'Antibiotics for secondary infections',
        'Good nutrition',
        'Isolation',
        'Veterinary guidance',
      ],
      transmission: 'Airborne, direct contact',
      mortality: 'Low, but production losses high',
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

  List<DiseaseInfo> get _filteredDiseases {
    if (_searchQuery.isEmpty) return _diseases;
    return _diseases
        .where((disease) =>
            disease.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            disease.symptoms.any((symptom) =>
                symptom.toLowerCase().contains(_searchQuery.toLowerCase())))
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
                                'Disease Database',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Comprehensive chicken disease guide',
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
                            Icons.medical_information_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: const InputDecoration(
                          hintText: 'Search diseases or symptoms...',
                          hintStyle: TextStyle(color: Colors.white70),
                          prefixIcon: Icon(Icons.search, color: Colors.white70),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              // Disease List
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _filteredDiseases.length,
                    itemBuilder: (context, index) {
                      final disease = _filteredDiseases[index];
                      return _buildDiseaseCard(context, disease, index);
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

  Widget _buildDiseaseCard(
      BuildContext context, DiseaseInfo disease, int index) {
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
                disease.color.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: disease.color.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: disease.color.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ExpansionTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: disease.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: disease.color.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                disease.icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(
              disease.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            subtitle: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: disease.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    disease.severity,
                    style: TextStyle(
                      color: disease.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${disease.symptoms.length} symptoms',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoSection('Symptoms', disease.symptoms,
                        Icons.visibility_rounded, Colors.red),
                    const SizedBox(height: 16),
                    _buildInfoSection('Prevention', disease.prevention,
                        Icons.shield_rounded, Colors.green),
                    const SizedBox(height: 16),
                    _buildInfoSection('Treatment', disease.treatment,
                        Icons.medical_services_rounded, Colors.blue),
                    const SizedBox(height: 16),
                    _buildInfoSection('Transmission', [disease.transmission],
                        Icons.warning_rounded, Colors.orange),
                    const SizedBox(height: 16),
                    _buildInfoSection('Mortality Rate', [disease.mortality],
                        Icons.trending_down_rounded, Colors.purple),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(
      String title, List<String> items, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items
            .map((item) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(top: 8, right: 12),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ],
    );
  }
}

class DiseaseInfo {
  final String name;
  final String severity;
  final Color color;
  final IconData icon;
  final List<String> symptoms;
  final List<String> prevention;
  final List<String> treatment;
  final String transmission;
  final String mortality;

  DiseaseInfo({
    required this.name,
    required this.severity,
    required this.color,
    required this.icon,
    required this.symptoms,
    required this.prevention,
    required this.treatment,
    required this.transmission,
    required this.mortality,
  });
}

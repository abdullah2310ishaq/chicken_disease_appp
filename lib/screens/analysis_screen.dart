import 'package:flutter/material.dart';
import 'dart:io';
import 'result_screen.dart';
import '../services/chicken_disease_service.dart';

class AnalysisScreen extends StatefulWidget {
  final File image1;

  const AnalysisScreen({
    super.key,
    required this.image1,
  });

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final ChickenDiseaseService _diseaseService = ChickenDiseaseService();
  bool _isInitialized = false;
  String _statusMessage = 'Initializing model...';

  @override
  void initState() {
    super.initState();
    _initializeAndAnalyze();
  }

  Future<void> _initializeAndAnalyze() async {
    print('');
    print('🎬 ========== ANALYSIS SCREEN: STARTING ANALYSIS ==========');
    print('📸 Image path: ${widget.image1.path}');
    print('📏 Image size: ${await widget.image1.length()} bytes');

    try {
      // Initialize the service (loads TFLite model)
      print('⏳ Step 1: Initializing disease service (loading TFLite model)...');
      setState(() {
        _statusMessage = 'Loading AI model...';
      });

      final initStart = Stopwatch()..start();
      await _diseaseService.initialize();
      initStart.stop();
      print('✅ Service initialized in ${initStart.elapsedMilliseconds}ms');

      setState(() {
        _isInitialized = true;
        _statusMessage = 'Analyzing image...';
      });
      print('⏳ Step 2: Analyzing image with TFLite model...');

      // Show SnackBar when starting analysis (will be confirmed by Gemini)
      // if (mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(
      //       content: Text('✅ Image is chicken faeces, proceeding with analysis...'),
      //       backgroundColor: Colors.green,
      //       duration: Duration(seconds: 2),
      //     ),
      //   );
      // }

      // Analyze image
      final analysisStart = Stopwatch()..start();
      final result = await _diseaseService.analyzeImage(widget.image1);
      analysisStart.stop();
      print(
          '✅ Image analysis completed in ${analysisStart.elapsedMilliseconds}ms');
      print('📊 Analysis result:');
      print('   └─ Disease type: ${result.diseaseType}');
      print(
          '   └─ Confidence: ${(result.confidence * 100).toStringAsFixed(2)}%');
      print('   └─ Is healthy: ${result.isHealthy}');
      print('   └─ Is irrelevant: ${result.isIrrelevant}');
      print('   └─ Recommendations count: ${result.recommendations.length}');
      print('   └─ Analysis details count: ${result.analysisDetails.length}');

      // Check for irrelevant image
      if (result.isIrrelevant) {
        print('⚠️ Image is irrelevant, showing dialog...');
        if (mounted) {
          _showIrrelevantImageDialog();
          return;
        }
      }

      print('⏳ Step 3: Navigating to result screen...');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              image1: widget.image1,
              // No image2 - single image analysis
              analysisResult: result,
            ),
          ),
        );
        print('✅ Navigation completed');
        print('🎉 ========== ANALYSIS SCREEN: COMPLETE ==========');
        print('');
      }
    } catch (e, stackTrace) {
      print('❌ ========== ANALYSIS SCREEN: ERROR ==========');
      print('❌ Error: $e');
      print('❌ Stack trace: $stackTrace');
      print('');

      if (mounted) {
        setState(() {
          _statusMessage = 'Analysis failed: $e';
        });

        // Show error and navigate back after delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Analysis failed: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        });
      }
    }
  }

  void _showIrrelevantImageDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),

              // Message
              const Text(
                'Photo is not of faeces',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Photo is not recognized',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Try Again'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _diseaseService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analyzing Image...'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated GIF
              SizedBox(
                width: 250,
                height: 250,
                child: Image.asset(
                  'assets/gif.gif',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

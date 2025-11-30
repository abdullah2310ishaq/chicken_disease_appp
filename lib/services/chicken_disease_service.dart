import 'dart:io';
import 'demo_disease_service.dart';
import 'tflite_image_classifier.dart';
import 'gemini_chat_service.dart';

/// Service for chicken disease detection using TFLite model
class ChickenDiseaseService {
  TFLiteImageClassifier? _classifier;
  GeminiChatService? _geminiService;
  bool _isInitialized = false;

  /// Initialize the service and load TFLite model
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Gemini service for faeces detection
      _geminiService = GeminiChatService(
        apiKey: 'AIzaSyAEI5_n8HuAT4VoKtQsiXLZq7svWRUx7AE',
      );
      print('✅ Gemini service initialized for faeces detection');

      // Initialize TFLite classifier
      _classifier = TFLiteImageClassifier();
      await _classifier!.initialize();

      // Set Gemini service in classifier
      _classifier!.setGeminiService(_geminiService);

      _isInitialized = true;
      print('✅ TFLite model initialized successfully');
    } catch (e, stackTrace) {
      print('❌ TFLite initialization failed: $e');
      print('Stack trace: $stackTrace');
      // Continue without TFLite - will use fallback
      _isInitialized = false;
    }
  }

  /// Analyze chicken faeces image for disease detection
  Future<DiseaseAnalysisResult> analyzeFecesImage(File imageFile) async {
    // Try TFLite first if available
    if (_isInitialized && _classifier != null) {
      try {
        return await _classifier!.classifyImage(imageFile);
      } catch (e) {
        print('TFLite analysis failed: $e, falling back to demo service');
      }
    }

    // Fallback to demo service if TFLite fails or not initialized
    final demoService = DemoDiseaseService();
    return await demoService.analyzeFecesImage(imageFile);
  }

  /// Analyze chicken image (for main image analysis)
  Future<DiseaseAnalysisResult> analyzeImage(File imageFile) async {
    // Try TFLite first if available
    if (_isInitialized && _classifier != null) {
      try {
        print('🔍 Using TFLite model for analysis...');
        final result = await _classifier!.classifyImage(imageFile);
        print(
            '✅ TFLite result: ${result.diseaseType} (${(result.confidence * 100).toStringAsFixed(1)}%)');
        return result;
      } catch (e, stackTrace) {
        print('❌ TFLite analysis failed: $e');
        print('Stack trace: $stackTrace');
        print('⚠️ Falling back to demo service');
      }
    } else {
      print('⚠️ TFLite not initialized, using demo service');
    }

    // Fallback to demo service (but without E.coli)
    final demoService = DemoDiseaseService();
    return await demoService.analyzeFecesImage(imageFile);
  }

  /// Dispose resources
  void dispose() {
    _classifier?.dispose();
    _classifier = null;
    _isInitialized = false;
  }
}

/// Result class for disease analysis
class DiseaseAnalysisResult {
  final String diseaseType;
  final double confidence;
  final bool isHealthy;
  final List<String> recommendations;
  final Map<String, double> analysisDetails;
  final bool isIrrelevant; // True if image is not relevant (confidence < 80%)

  DiseaseAnalysisResult({
    required this.diseaseType,
    required this.confidence,
    required this.isHealthy,
    required this.recommendations,
    required this.analysisDetails,
    this.isIrrelevant = false,
  });

  factory DiseaseAnalysisResult.fromJson(Map<String, dynamic> json) {
    return DiseaseAnalysisResult(
      diseaseType: json['disease_type'] ?? 'Unknown',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      isHealthy: json['is_healthy'] ?? false,
      recommendations: List<String>.from(json['recommendations'] ?? []),
      analysisDetails: Map<String, double>.from(json['analysis_details'] ?? {}),
      isIrrelevant: json['is_irrelevant'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'disease_type': diseaseType,
      'confidence': confidence,
      'is_healthy': isHealthy,
      'recommendations': recommendations,
      'analysis_details': analysisDetails,
      'is_irrelevant': isIrrelevant,
    };
  }
}

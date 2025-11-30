import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'chicken_disease_service.dart';
import 'gemini_chat_service.dart';

/// TensorFlow Lite image classifier for chicken disease detection
class TFLiteImageClassifier {
  static const String _modelPath = 'assets/model_quantized.tflite';
  static const String _labelsPath = 'assets/labels.txt';

  // Standard input size for most image classification models
  static const int inputSize = 224;

  // Model type detection - quantized models use uint8 (0-255), float models use float32 (0.0-1.0)
  bool _isQuantized =
      true; // Default to quantized since model name has "quantized"

  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isInitialized = false;
  GeminiChatService? _geminiService;

  /// Disease name mapping from model labels to display names
  static const Map<String, String> _diseaseNameMap = {
    'cocci': 'Coccidiosis',
    'healthy': 'Healthy',
    'ncd': 'Newcastle Disease',
    'salmo': 'Salmonella',
  };

  /// Set Gemini service for faeces detection
  void setGeminiService(GeminiChatService? geminiService) {
    _geminiService = geminiService;
  }

  /// Initialize the TFLite model and load labels
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load model
      final modelData = await rootBundle.load(_modelPath);
      final modelBytes = modelData.buffer.asUint8List();

      // Create interpreter
      _interpreter = Interpreter.fromBuffer(modelBytes);

      // Get model input/output details
      final inputTensors = _interpreter!.getInputTensors();
      final outputTensors = _interpreter!.getOutputTensors();

      print('✅ Model loaded successfully');
      print('📊 Input shape: ${inputTensors[0].shape}');
      print('📊 Output shape: ${outputTensors[0].shape}');
      print('📊 Input type: ${inputTensors[0].type}');

      // Detect if model is quantized (uint8) or float (float32)
      _isQuantized = inputTensors[0].type.toString().contains('uint8') ||
          inputTensors[0].type.toString().contains('Uint8');
      print(
          '📊 Model type: ${_isQuantized ? "Quantized (uint8)" : "Float (float32)"}');

      // Load labels
      await _loadLabels();
      print('✅ Labels loaded: $_labels');
      print('📋 Total labels: ${_labels.length}');

      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize TFLite model: $e');
    }
  }

  /// Load labels from assets
  Future<void> _loadLabels() async {
    try {
      final labelsData = await rootBundle.loadString(_labelsPath);
      _labels = labelsData
          .split('\n')
          .map((label) => label.trim())
          .where((label) => label.isNotEmpty)
          .toList();

      print('Labels loaded: $_labels');
    } catch (e) {
      throw Exception('Failed to load labels: $e');
    }
  }

  /// Classify a single image
  Future<DiseaseAnalysisResult> classifyImage(File imageFile) async {
    if (!_isInitialized || _interpreter == null) {
      throw Exception('Model not initialized. Call initialize() first.');
    }

    try {
      // First check if image is faeces
      if (_geminiService != null) {
        final isFeces = await _geminiService!.isFecesImage(imageFile);
 
        if (!isFeces) {
          print('❌ Image is NOT chicken faeces');
          // Return irrelevant result
          return DiseaseAnalysisResult(
            diseaseType: 'Unknown',
            confidence: 0.0,
            isHealthy: false,
            recommendations: [
              'Please upload an image of chicken faeces for accurate disease detection.',
              'The image should show chicken droppings/faeces clearly.',
            ],
            analysisDetails: {},
            isIrrelevant: true,
          );
        }
        print('✅ Image is chicken faeces, proceeding with analysis...');
      }

      print(
          '🖼️ Preprocessing image (EfficientNetB0: 224x224, preprocess_input [-1.0 to 1.0])...');
      // Preprocess image - returns Float32List [1, 224, 224, 3]
      final inputTensor = await _preprocessImage(imageFile);

      // Prepare output tensor
      final outputTensors = _interpreter!.getOutputTensors();
      final outputShape = outputTensors[0].shape;

      // Create output buffer: [1, 4] for 4 classes
      final outputSize = outputShape.reduce((a, b) => a * b);

      // TFLite expects List<List<double>> for output shape [1, 4]
      var output =
          List.generate(1, (_) => List<double>.filled(outputSize, 0.0));

      print('🤖 Running TFLite inference (EfficientNetB0)...');
      print('📊 Output buffer shape: [1, $outputSize]');
      print('📊 Input tensor length: ${inputTensor.length}');
      print('📊 Expected input size: ${1 * inputSize * inputSize * 3}');

      // Get input tensor info
      final inputTensors = _interpreter!.getInputTensors();
      final inputShape = inputTensors[0].shape;
      final inputType = inputTensors[0].type;
      print('📊 Model expects input shape: $inputShape');
      print('📊 Model expects input type: $inputType');

      // CRITICAL: Use nested List format - TFLite requires this for proper tensor shape
      // Convert Float32List to nested List format [1, 224, 224, 3]
      // This matches the notebook tensor structure: (None, 224, 224, 3) dtype=float32
      // Order: [batch, height, width, channels] = [1, 224, 224, 3]
      List<List<List<List<double>>>> inputNested = [];
      List<List<List<double>>> imageData = [];

      // Reconstruct nested structure from flat Float32List
      // The buffer is in row-major order: [R,G,B, R,G,B, ...] for each pixel
      int pixelIndex = 0;
      for (int i = 0; i < inputSize; i++) {
        // Height (rows)
        List<List<double>> row = [];
        for (int j = 0; j < inputSize; j++) {
          // Width (columns)
          // Each pixel has 3 channels: [R, G, B]
          List<double> pixel = [
            inputTensor[pixelIndex++], // Red
            inputTensor[pixelIndex++], // Green
            inputTensor[pixelIndex++], // Blue
          ];
          row.add(pixel);
        }
        imageData.add(row);
      }
      inputNested.add(imageData);

      print('📊 Input nested shape prepared: [1, $inputSize, $inputSize, 3]');
      print(
          '📊 First pixel in nested format: [${inputNested[0][0][0][0].toStringAsFixed(3)}, ${inputNested[0][0][0][1].toStringAsFixed(3)}, ${inputNested[0][0][0][2].toStringAsFixed(3)}]');

      // Run inference with nested format
      _interpreter!.run(inputNested, output);
      print('✅ Inference completed successfully');

      // Extract probabilities from output[0] (first batch)
      // Output shape is [1, 4], so output[0] contains [prob_cocci, prob_healthy, prob_ncd, prob_salmo]
      // Based on notebook: class_indices = {'cocci': 0, 'healthy': 1, 'ncd': 2, 'salmo': 3}
      // So output[0] = [prob_cocci, prob_healthy, prob_ncd, prob_salmo]
      final rawOutput = output[0];
      final outputType = outputTensors[0].type.toString();

      print('📊 Raw output from interpreter: $rawOutput');
      print('📊 Output shape: $outputShape');
      print('📊 Output type: $outputType');

      // Handle output based on type
      // For int4 quantized output, TFLite may return dequantized values
      // But we need to verify if they're probabilities or logits
      List<double> probabilities;

      // Check output type
      final isQuantized = outputType.toLowerCase().contains('int') ||
          outputType.toLowerCase().contains('uint');

      if (isQuantized) {
        print('📊 Quantized output detected: $outputType');
        // For quantized models with softmax, output might already be probabilities
        // But sometimes it's logits that need softmax
        final rawSum =
            rawOutput.map((e) => (e as num).toDouble()).reduce((a, b) => a + b);
        print('📊 Raw output sum: ${rawSum.toStringAsFixed(3)}');

        if (rawSum > 0.9 && rawSum < 1.1) {
          // Already probabilities
          probabilities = rawOutput.map((e) => (e as num).toDouble()).toList();
          print('📊 Using as probabilities (sum ~1.0)');
        } else {
          // Need softmax - values are logits
          print('📊 Applying softmax (treating as logits)');
          final expValues =
              rawOutput.map((e) => math.exp((e as num).toDouble())).toList();
          final expSum = expValues.reduce((a, b) => a + b);
          probabilities = expValues.map((e) => e / expSum).toList();
          print(
              '📊 After softmax, sum: ${probabilities.reduce((a, b) => a + b).toStringAsFixed(3)}');
        }
      } else {
        // Float output - should already be probabilities
        probabilities = rawOutput.map((e) => (e as num).toDouble()).toList();
        final probSum = probabilities.reduce((a, b) => a + b);
        print('📊 Float output, sum: ${probSum.toStringAsFixed(3)}');

        // If sum not ~1.0, apply softmax
        if (probSum < 0.9 || probSum > 1.1) {
          print('⚠️ Sum not ~1.0, applying softmax');
          final expValues = probabilities.map((e) => math.exp(e)).toList();
          final expSum = expValues.reduce((a, b) => a + b);
          probabilities = expValues.map((e) => e / expSum).toList();
        }
      }

      // Verify output is valid (should be 4 probabilities)
      if (probabilities.length != 4) {
        throw Exception('Expected 4 outputs, got ${probabilities.length}');
      }

      // DEBUG: Print probabilities with label names to verify order
      print('📊 DEBUG - Probabilities with labels (from notebook order):');
      print(
          '  Index 0 (cocci): ${(probabilities[0] * 100).toStringAsFixed(2)}%');
      print(
          '  Index 1 (healthy): ${(probabilities[1] * 100).toStringAsFixed(2)}%');
      print('  Index 2 (ncd): ${(probabilities[2] * 100).toStringAsFixed(2)}%');
      print(
          '  Index 3 (salmo): ${(probabilities[3] * 100).toStringAsFixed(2)}%');

      // Verify labels match notebook order
      if (_labels.length >= 4) {
        print(
            '📊 Labels order: ${_labels[0]}, ${_labels[1]}, ${_labels[2]}, ${_labels[3]}');
        print('📊 Expected: cocci, healthy, ncd, salmo');
        if (_labels[0] != 'cocci' ||
            _labels[1] != 'healthy' ||
            _labels[2] != 'ncd' ||
            _labels[3] != 'salmo') {
          print('⚠️ WARNING: Labels order mismatch!');
        }
      }

      // Post-process results - probabilities contains [prob_cocci, prob_healthy, prob_ncd, prob_salmo]
      final result = _postProcessResults(probabilities);
      print('✅ Classification complete: ${result.diseaseType}');
      return result;
    } catch (e, stackTrace) {
      print('❌ Image classification failed: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Image classification failed: $e');
    }
  }

  /// Preprocess image: decode, resize, normalize, convert to tensor
  /// EfficientNetB0 preprocessing: Uses tf.keras.applications.efficientnet.preprocess_input
  /// This scales pixels to [-1.0, 1.0] range: (pixel / 127.5) - 1.0
  /// Returns Float32List tensor: [1, 224, 224, 3] (batch, height, width, channels)
  Future<Float32List> _preprocessImage(File imageFile) async {
    // Read and decode image
    final imageBytes = await imageFile.readAsBytes();
    final image = img.decodeImage(imageBytes);

    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Resize image to model input size (224x224) - EfficientNetB0 standard
    final resizedImage = img.copyResize(
      image,
      width: inputSize,
      height: inputSize,
      interpolation: img.Interpolation.linear,
    );

    // Create Float32List buffer for input tensor [1, 224, 224, 3]
    // EfficientNetB0 preprocess_input: scales to [-1.0, 1.0] range
    // Formula: (pixel / 127.5) - 1.0
    var inputBytes = Float32List(1 * inputSize * inputSize * 3);
    var buffer = Float32List.view(inputBytes.buffer);
    int pixelIndex = 0;

    // Convert image pixels to buffer with EfficientNetB0 preprocessing
    // CRITICAL: Use preprocess_input formula: (pixel / 127.5) - 1.0
    // This gives range [-1.0, 1.0] instead of [0.0, 1.0]
    // Pixel order: row-major (height first, then width)
    // For EfficientNetB0: [batch, height, width, channels] = [1, 224, 224, 3]
    // So we iterate height (i) then width (j), then channels (RGB)
    bool debugPrinted = false;
    for (int i = 0; i < inputSize; i++) {
      for (int j = 0; j < inputSize; j++) {
        // getPixel(x, y) where x=column (width), y=row (height)
        final pixel = resizedImage.getPixel(j, i);

        // Sample first pixel for debugging
        if (!debugPrinted && i == 0 && j == 0) {
          print(
              '📊 DEBUG - Image size: ${resizedImage.width}x${resizedImage.height}');
          print(
              '📊 DEBUG - First pixel at (x=$j, y=$i) RGB: (${pixel.r}, ${pixel.g}, ${pixel.b})');
          final preprocessedR = (pixel.r / 127.5) - 1.0;
          final preprocessedG = (pixel.g / 127.5) - 1.0;
          final preprocessedB = (pixel.b / 127.5) - 1.0;
          print(
              '📊 DEBUG - Preprocessed: (${preprocessedR.toStringAsFixed(3)}, ${preprocessedG.toStringAsFixed(3)}, ${preprocessedB.toStringAsFixed(3)})');
          debugPrinted = true;
        }

        // EfficientNetB0 preprocess_input: (pixel / 127.5) - 1.0
        // This matches tf.keras.applications.efficientnet.preprocess_input
        // Store as RGB (Red, Green, Blue) - standard order
        buffer[pixelIndex++] = (pixel.r / 127.5) - 1.0; // Red channel
        buffer[pixelIndex++] = (pixel.g / 127.5) - 1.0; // Green channel
        buffer[pixelIndex++] = (pixel.b / 127.5) - 1.0; // Blue channel
      }
    }

    // DEBUG: Check buffer range and sample values
    final minVal = buffer.reduce((a, b) => a < b ? a : b);
    final maxVal = buffer.reduce((a, b) => a > b ? a : b);
    final avgVal = buffer.reduce((a, b) => a + b) / buffer.length;
    print('📊 DEBUG - Preprocessed buffer:');
    print('  Range: [$minVal, $maxVal] (expected: [-1.0, 1.0])');
    print('  Average: ${avgVal.toStringAsFixed(3)}');
    print(
        '  First 6 values: [${buffer[0].toStringAsFixed(3)}, ${buffer[1].toStringAsFixed(3)}, ${buffer[2].toStringAsFixed(3)}, ${buffer[3].toStringAsFixed(3)}, ${buffer[4].toStringAsFixed(3)}, ${buffer[5].toStringAsFixed(3)}]');

    // Return Float32List - TFLite will handle the shape [1, 224, 224, 3]
    // The buffer is already in correct format: sequential RGB values
    return inputBytes;
  }

  /// Post-process model output to get disease prediction
  /// Input: probabilities already extracted and normalized (sum to 1.0)
  DiseaseAnalysisResult _postProcessResults(List<double> probabilities) {
    // Probabilities are already in correct format (0.0-1.0, sum to 1.0)
    // No need to convert again - they're already processed

    // Find the index with highest probability
    int bestIndex = 0;
    double bestScore = probabilities[0];
    for (int i = 1; i < probabilities.length; i++) {
      if (probabilities[i] > bestScore) {
        bestIndex = i;
        bestScore = probabilities[i];
      }
    }

    // Since Gemini already verified it's faeces, trust the model prediction
    // No need for additional irrelevant detection - Gemini handles that
    final maxConfidence = bestScore;

    print('📊 Max confidence: ${(maxConfidence * 100).toStringAsFixed(1)}%');
    print(
        '📊 Best class: ${_labels[bestIndex]} (${_diseaseNameMap[_labels[bestIndex]] ?? _labels[bestIndex]})');
    print(
        '📊 All probabilities: ${probabilities.asMap().entries.map((e) => '${_labels[e.key]}: ${(e.value * 100).toStringAsFixed(1)}%').join(", ")}');

    // Since Gemini confirmed it's faeces, always mark as relevant
    final isIrrelevant = false;

    // Get label
    final labelKey =
        bestIndex < _labels.length ? _labels[bestIndex] : 'unknown';

    // Map to display name
    final diseaseName = _diseaseNameMap[labelKey] ?? labelKey;
    final isHealthy = diseaseName == 'Healthy';

    // Normalize confidence (ensure it's between 0 and 1)
    final confidence = bestScore.clamp(0.0, 1.0);

    // Create analysis details map
    final analysisDetails = <String, double>{};
    for (int i = 0; i < probabilities.length && i < _labels.length; i++) {
      final label = _labels[i];
      final displayName = _diseaseNameMap[label] ?? label;
      analysisDetails[displayName] = probabilities[i].clamp(0.0, 1.0);
    }

    // Get recommendations
    final recommendations = _getRecommendations(diseaseName);

    return DiseaseAnalysisResult(
      diseaseType: diseaseName,
      confidence: confidence,
      isHealthy: isHealthy,
      recommendations: recommendations,
      analysisDetails: analysisDetails,
      isIrrelevant: isIrrelevant,
    );
  }

  /// Get recommendations based on disease type
  List<String> _getRecommendations(String diseaseType) {
    switch (diseaseType) {
      case 'Healthy':
        return [
          'Continue current feeding routine',
          'Monitor for changes in appearance',
          'Maintain a clean, dry environment',
          'Regular health checkups recommended',
        ];

      case 'Coccidiosis':
        return [
          'Isolate affected birds immediately',
          'Consult a veterinarian for anticoccidial treatment',
          'Disinfect housing and improve litter management',
          'Ensure clean water and feed sources',
          'Consider medicated feed for prevention',
        ];

      case 'Newcastle Disease':
        return [
          'URGENT: Veterinary consultation required immediately',
          'Quarantine birds and restrict all movement',
          'Review vaccination status and biosecurity measures',
          'Report to local veterinary authorities if required',
          'Implement strict biosecurity protocols',
        ];

      case 'Salmonella':
        return [
          'Consult veterinarian immediately',
          'Review feed and water hygiene practices',
          'Enhance biosecurity and sanitation measures',
          'Monitor flock closely for systemic signs',
          'Consider antibiotic treatment under veterinary guidance',
        ];

      default:
        return [
          'Consult a veterinarian for appropriate diagnostics',
          'Monitor the bird closely for any changes',
          'Maintain good hygiene and biosecurity',
        ];
    }
  }

  /// Check if model is initialized
  bool get isInitialized => _isInitialized;

  /// Dispose resources
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
    _labels.clear();
  }
}

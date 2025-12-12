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
  static const String _modelPath = 'assets/models/models/final_model_float32.tflite';
  static const String _labelsPath = 'assets/labels.txt';

  // Model input size - 300x300 as per model contract
  int inputSize = 300; // Fixed to 300x300 as specified in model contract

  // Model type: Float32 model, pixel values 0.0-255.0 (NOT normalized)
  bool _isQuantized = false; // Float32 model

  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isInitialized = false;
  GeminiChatService? _geminiService;

  /// Disease name mapping from model labels to display names
  static const Map<String, String> _diseaseNameMap = {
    'cocci': 'Coccidiosis',
    'healthy': 'Healthy',
    'ncd': 'Newcastle Disease',
    'random': 'Random/Irrelevant',
    'salmo': 'Salmonella',
  };

  /// Set Gemini service for faeces detection
  void setGeminiService(GeminiChatService? geminiService) {
    _geminiService = geminiService;
  }

  /// Initialize the TFLite model and load labels
  Future<void> initialize() async {
    if (_isInitialized) {
      print('ℹ️ Model already initialized, skipping...');
      return;
    }

    print('🚀 ========== TFLITE MODEL INITIALIZATION STARTED ==========');
    print('📁 Model path: $_modelPath');
    print('📁 Labels path: $_labelsPath');

    try {
      print('📦 Step 1/4: Loading model file from assets...');
      final modelData = await rootBundle.load(_modelPath);
      final modelBytes = modelData.buffer.asUint8List();
      print(
          '✅ Model file loaded: ${(modelBytes.length / 1024 / 1024).toStringAsFixed(2)} MB');

      print('🔧 Step 2/4: Creating TFLite interpreter...');
      _interpreter = Interpreter.fromBuffer(modelBytes);
      print('✅ Interpreter created successfully');

      print('📐 Step 3/4: Analyzing model input/output tensors...');
      final inputTensors = _interpreter!.getInputTensors();
      final outputTensors = _interpreter!.getOutputTensors();

      print('✅ Model loaded successfully');
      print('📊 DETAILED MODEL INFORMATION:');
      print('   └─ Input tensor count: ${inputTensors.length}');
      print('   └─ Input shape: ${inputTensors[0].shape}');
      print('   └─ Input type: ${inputTensors[0].type}');
      print('   └─ Input name: ${inputTensors[0].name}');
      print('   └─ Output tensor count: ${outputTensors.length}');
      print('   └─ Output shape: ${outputTensors[0].shape}');
      print('   └─ Output type: ${outputTensors[0].type}');
      print('   └─ Output name: ${outputTensors[0].name}');

      // Verify input size matches model contract (300x300)
      final modelInputShape = inputTensors[0].shape;
      if (modelInputShape.length >= 3) {
        // Shape is [1, height, width, 3] or similar
        final detectedSize =
            modelInputShape[1]; // Get height (should equal width)
        if (detectedSize != inputSize) {
          print('   └─ ⚠️ Model shape indicates different size!');
          print('      └─ Model contract specifies: ${inputSize}x${inputSize}');
          print('      └─ Model tensor shape: ${detectedSize}x${detectedSize}');
          print('      └─ ⚠️ Using contract size: ${inputSize}x${inputSize}');
        } else {
          print('   └─ ✅ Input size matches model: ${inputSize}x${inputSize}');
        }
      }

      // Detect if model is quantized (uint8) or float (float32)
      _isQuantized = inputTensors[0].type.toString().contains('uint8') ||
          inputTensors[0].type.toString().contains('Uint8');
      print('📊 Model type detection:');
      print(
          '   └─ Detected type: ${_isQuantized ? "Quantized (uint8)" : "Float (float32)"}');
      print('   └─ Input size: $inputSize x $inputSize');
      print('   └─ Expected input format: [1, $inputSize, $inputSize, 3]');

      print('📋 Step 4/4: Loading class labels...');
      await _loadLabels();
      print('✅ Labels loaded successfully');
      print('📊 LABEL INFORMATION:');
      print('   └─ Total labels: ${_labels.length}');
      print('   └─ Label order: ${_labels.join(", ")}');
      print('   └─ Expected order: cocci, healthy, ncd, random, salmo');

      if (_labels.length >= 5) {
        final orderMatch = _labels[0] == 'cocci' &&
            _labels[1] == 'healthy' &&
            _labels[2] == 'ncd' &&
            _labels[3] == 'random' &&
            _labels[4] == 'salmo';
        print(
            '   └─ Order validation: ${orderMatch ? "✅ CORRECT" : "⚠️ MISMATCH"}');
      }

      _isInitialized = true;
      print('🎉 ========== MODEL INITIALIZATION COMPLETE ==========');
      print('');
    } catch (e, stackTrace) {
      print('❌ ========== MODEL INITIALIZATION FAILED ==========');
      print('❌ Error: $e');
      print('❌ Stack trace: $stackTrace');
      throw Exception('Failed to initialize TFLite model: $e');
    }
  }

  /// Load labels from assets
  Future<void> _loadLabels() async {
    try {
      print('   📖 Reading labels file from: $_labelsPath');
      final labelsData = await rootBundle.loadString(_labelsPath);
      print(
          '   📄 Labels file content length: ${labelsData.length} characters');

      _labels = labelsData
          .split('\n')
          .map((label) => label.trim())
          .where((label) => label.isNotEmpty)
          .toList();

      print('   ✅ Parsed ${_labels.length} labels');
      for (int i = 0; i < _labels.length; i++) {
        print(
            '      [$i] "${_labels[i]}" → ${_diseaseNameMap[_labels[i]] ?? "Unknown"}');
      }
    } catch (e, stackTrace) {
      print('   ❌ Failed to load labels: $e');
      print('   ❌ Stack trace: $stackTrace');
      throw Exception('Failed to load labels: $e');
    }
  }

  /// Classify a single image
  Future<DiseaseAnalysisResult> classifyImage(File imageFile) async {
    print('');
    print('🔍 ========== IMAGE CLASSIFICATION STARTED ==========');
    print('📸 Image file: ${imageFile.path}');
    print('📏 Image size: ${await imageFile.length()} bytes');

    if (!_isInitialized || _interpreter == null) {
      print('❌ Model not initialized!');
      throw Exception('Model not initialized. Call initialize() first.');
    }

    try {
      // First check if image is faeces
      if (_geminiService != null) {
        print(
            '🔍 Step 1/5: Validating image with Gemini (faeces detection)...');
        final isFeces = await _geminiService!.isFecesImage(imageFile);

        if (!isFeces) {
          print('❌ Image validation FAILED: Image is NOT chicken faeces');
          print(
              '⚠️ Returning irrelevant result - user should upload faeces image');
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
        print('✅ Image validation PASSED: Image is chicken faeces');
        print('   └─ Proceeding with TFLite disease classification...');
      } else {
        print('⚠️ Gemini service not available, skipping faeces validation');
      }

      print('🖼️ Step 2/5: Preprocessing image...');
      print(
          '   └─ Target size: ${inputSize}x$inputSize (from model specification)');
      print('   └─ Preprocessing: Stretch resize to 300x300, RGB format');
      print('   └─ Normalization: NONE - pixel values 0.0-255.0 Float32');
      print('   └─ ⚠️ CRITICAL: Do NOT divide by 255, model handles normalization internally');
      // Preprocess image - returns Float32List [1, 300, 300, 3]
      final inputTensor = await _preprocessImage(imageFile);
      print('✅ Image preprocessing completed');

      print('📊 Step 3/5: Preparing inference...');
      // Prepare output tensor
      final outputTensors = _interpreter!.getOutputTensors();
      final outputShape = outputTensors[0].shape;

      // Create output buffer: [1, 5] for 5 classes (cocci, healthy, ncd, random, salmo)
      final outputSize = outputShape.reduce((a, b) => a * b);
      print('   └─ Model output size: $outputSize classes (expected: 5)');

      // TFLite expects List<List<double>> for output shape [1, 4]
      var output =
          List.generate(1, (_) => List<double>.filled(outputSize, 0.0));

      print('   └─ Output buffer created: [1, $outputSize]');
      print('   └─ Input tensor length: ${inputTensor.length}');
      print('   └─ Expected input size: ${1 * inputSize * inputSize * 3}');
      print(
          '   └─ Validation: ${inputTensor.length == 1 * inputSize * inputSize * 3 ? "✅ CORRECT" : "❌ MISMATCH"}');

      // Get input tensor info
      final inputTensors = _interpreter!.getInputTensors();
      final inputShape = inputTensors[0].shape;
      final inputType = inputTensors[0].type;
      print('   └─ Model expects input shape: $inputShape');
      print('   └─ Model expects input type: $inputType');
      print('✅ Inference preparation completed');

      print('🔄 Step 4/5: Converting to nested tensor format...');
      // CRITICAL: Use nested List format - TFLite requires this for proper tensor shape
      // Convert Float32List to nested List format [1, 224, 224, 3]
      // This matches the notebook tensor structure: (None, 224, 224, 3) dtype=float32
      // Order: [batch, height, width, channels] = [1, 224, 224, 3]
      print('   └─ Converting flat Float32List to nested List format...');
      print('   └─ Target shape: [1, $inputSize, $inputSize, 3]');
      print('   └─ Format: [batch, height, width, channels]');

      List<List<List<List<double>>>> inputNested = [];
      List<List<List<double>>> imageData = [];

      // Reconstruct nested structure from flat Float32List
      // The buffer is in row-major order: [R,G,B, R,G,B, ...] for each pixel
      int pixelIndex = 0;
      final stopwatch = Stopwatch()..start();
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
      stopwatch.stop();

      print('   └─ Conversion completed in ${stopwatch.elapsedMilliseconds}ms');
      print('   └─ Nested shape: [1, $inputSize, $inputSize, 3]');
      print(
          '   └─ First pixel RGB: [${inputNested[0][0][0][0].toStringAsFixed(3)}, ${inputNested[0][0][0][1].toStringAsFixed(3)}, ${inputNested[0][0][0][2].toStringAsFixed(3)}]');
      print('✅ Tensor conversion completed');

      print('🤖 Running TFLite model inference...');
      final inferenceStart = Stopwatch()..start();
      _interpreter!.run(inputNested, output);
      inferenceStart.stop();
      print(
          '✅ Inference completed successfully in ${inferenceStart.elapsedMilliseconds}ms');

      print('📊 Step 5/5: Processing model output...');
      // Extract probabilities from output[0] (first batch)
      // Output shape is [1, 4], so output[0] contains [prob_cocci, prob_healthy, prob_ncd, prob_salmo]
      // Based on notebook: class_indices = {'cocci': 0, 'healthy': 1, 'ncd': 2, 'salmo': 3}
      // So output[0] = [prob_cocci, prob_healthy, prob_ncd, prob_salmo]
      final rawOutput = output[0];
      final outputType = outputTensors[0].type.toString();

      print('   └─ Raw output from interpreter: $rawOutput');
      print('   └─ Output shape: $outputShape');
      print('   └─ Output type: $outputType');
      print('   └─ Output length: ${rawOutput.length} (expected: 4)');

      // Handle output based on type
      // For int4 quantized output, TFLite may return dequantized values
      // But we need to verify if they're probabilities or logits
      List<double> probabilities;

      // Check output type
      final isQuantized = outputType.toLowerCase().contains('int') ||
          outputType.toLowerCase().contains('uint');

      print('   └─ Output type analysis:');
      print('      └─ Is quantized: $isQuantized');
      print('      └─ Type string: $outputType');

      if (isQuantized) {
        print('   └─ 🔍 Quantized output detected: $outputType');
        // For quantized models with softmax, output might already be probabilities
        // But sometimes it's logits that need softmax
        final rawSum =
            rawOutput.map((e) => (e as num).toDouble()).reduce((a, b) => a + b);
        print('   └─ Raw output sum: ${rawSum.toStringAsFixed(6)}');

        if (rawSum > 0.9 && rawSum < 1.1) {
          // Already probabilities
          probabilities = rawOutput.map((e) => (e as num).toDouble()).toList();
          print('   └─ ✅ Using as probabilities (sum ~1.0, no softmax needed)');
        } else {
          // Need softmax - values are logits
          print('   └─ ⚠️ Applying softmax (treating as logits)');
          final expValues =
              rawOutput.map((e) => math.exp((e as num).toDouble())).toList();
          final expSum = expValues.reduce((a, b) => a + b);
          probabilities = expValues.map((e) => e / expSum).toList();
          print(
              '   └─ ✅ After softmax, sum: ${probabilities.reduce((a, b) => a + b).toStringAsFixed(6)}');
        }
      } else {
        // Float output - should already be probabilities
        print('   └─ 🔍 Float output detected: $outputType');
        probabilities = rawOutput.map((e) => (e as num).toDouble()).toList();
        final probSum = probabilities.reduce((a, b) => a + b);
        print('   └─ Raw probabilities sum: ${probSum.toStringAsFixed(6)}');

        // If sum not ~1.0, apply softmax
        if (probSum < 0.9 || probSum > 1.1) {
          print('   └─ ⚠️ Sum not ~1.0, applying softmax normalization');
          final expValues = probabilities.map((e) => math.exp(e)).toList();
          final expSum = expValues.reduce((a, b) => a + b);
          probabilities = expValues.map((e) => e / expSum).toList();
          print(
              '   └─ ✅ After softmax, sum: ${probabilities.reduce((a, b) => a + b).toStringAsFixed(6)}');
        } else {
          print('   └─ ✅ Probabilities already normalized (sum ~1.0)');
        }
      }

      // Verify output is valid (model outputs 5 classes: cocci, healthy, ncd, random, salmo)
      if (probabilities.length != 5) {
        print(
            '❌ ERROR: Expected 5 outputs, got ${probabilities.length}');
        throw Exception(
            'Expected 5 outputs, got ${probabilities.length}');
      }

      // CRITICAL: Log ALL 5 classes before processing
      print('   └─ 📊 ALL MODEL OUTPUTS (5 classes with softmax applied):');
      for (int i = 0; i < probabilities.length && i < _labels.length; i++) {
        final label = i < _labels.length ? _labels[i] : 'unknown';
        print('      [$i] $label: ${(probabilities[i] * 100).toStringAsFixed(2)}%');
      }

      print('   └─ ✅ Output validation passed: ${probabilities.length} classes');

      // DEBUG: Print probabilities with label names to verify order
      print('📊 DEBUG - Final probabilities after processing:');
      for (int i = 0; i < probabilities.length && i < _labels.length; i++) {
        print('  Index $i (${_labels[i]}): ${(probabilities[i] * 100).toStringAsFixed(2)}%');
      }

      // Verify labels match notebook order
      if (_labels.length >= 5) {
        print(
            '📊 Labels order: ${_labels[0]}, ${_labels[1]}, ${_labels[2]}, ${_labels[3]}, ${_labels[4]}');
        print('📊 Expected: cocci, healthy, ncd, random, salmo');
        if (_labels[0] != 'cocci' ||
            _labels[1] != 'healthy' ||
            _labels[2] != 'ncd' ||
            _labels[3] != 'random' ||
            _labels[4] != 'salmo') {
          print('⚠️ WARNING: Labels order mismatch!');
        }
      }

      // Post-process results - probabilities contains [prob_cocci, prob_healthy, prob_ncd, prob_salmo]
      final result = _postProcessResults(probabilities);
      print('✅ Classification complete: ${result.diseaseType}');
      return result;
    } catch (e, stackTrace) {
      print('❌ ========== CLASSIFICATION FAILED ==========');
      print('❌ Error: $e');
      print('❌ Stack trace: $stackTrace');
      print('');
      throw Exception('Image classification failed: $e');
    }
  }

  /// Preprocess image: decode, resize, convert to tensor
  /// Model contract: 300x300 RGB, Float32 values 0.0-255.0 (NO normalization)
  /// Returns Float32List tensor: [1, 300, 300, 3] (batch, height, width, channels)
  Future<Float32List> _preprocessImage(File imageFile) async {
    print('   └─ Step 2.1: Reading image file...');
    // Read and decode image
    final imageBytes = await imageFile.readAsBytes();
    print('      └─ Image bytes read: ${imageBytes.length} bytes');

    final image = img.decodeImage(imageBytes);

    if (image == null) {
      print('      └─ ❌ Failed to decode image');
      throw Exception('Failed to decode image');
    }
    print('      └─ ✅ Image decoded: ${image.width}x${image.height} pixels');

    print('   └─ Step 2.2: Resizing image to $inputSize x $inputSize (STRETCH)...');
    print('      └─ ⚠️ CRITICAL: Using STRETCH resize (not center crop) to match training');
    // Resize image to model input size (300x300) - STRETCH to match training
    final resizedImage = img.copyResize(
      image,
      width: inputSize,
      height: inputSize,
      interpolation: img.Interpolation.linear,
    );
    print(
        '      └─ ✅ Image resized: ${resizedImage.width}x${resizedImage.height}');

    print('   └─ Step 2.3: Converting pixels to Float32 (0.0-255.0 range)...');
    print('      └─ ⚠️ CRITICAL: NO normalization - pixel values stay in 0.0-255.0 range');
    print('      └─ Model handles normalization internally via EfficientNetB3 layers');
    // Create Float32List buffer for input tensor [1, 300, 300, 3]
    // Model contract: Float32 values 0.0-255.0 (NOT normalized, NOT divided by 255)
    var inputBytes = Float32List(1 * inputSize * inputSize * 3);
    var buffer = Float32List.view(inputBytes.buffer);
    int pixelIndex = 0;

    // Convert image pixels to buffer WITHOUT normalization
    // CRITICAL: Keep pixel values in 0.0-255.0 range (Float32)
    // Do NOT divide by 255, do NOT normalize to [-1.0, 1.0]
    // Pixel order: row-major (height first, then width)
    // Format: [batch, height, width, channels] = [1, 300, 300, 3]
    // So we iterate height (i) then width (j), then channels (RGB)
    bool debugPrinted = false;
    final preprocessStart = Stopwatch()..start();
    for (int i = 0; i < inputSize; i++) {
      for (int j = 0; j < inputSize; j++) {
        // getPixel(x, y) where x=column (width), y=row (height)
        final pixel = resizedImage.getPixel(j, i);

        // Sample first pixel for debugging
        if (!debugPrinted && i == 0 && j == 0) {
          print('      └─ Sample pixel at (x=$j, y=$i):');
          print(
              '         └─ Original RGB: (${pixel.r}, ${pixel.g}, ${pixel.b})');
          print(
              '         └─ Float32 RGB: (${pixel.r.toDouble()}, ${pixel.g.toDouble()}, ${pixel.b.toDouble()})');
          debugPrinted = true;
        }

        // Store as RGB Float32 values in 0.0-255.0 range (NO normalization)
        // This matches the training pipeline: tf.image.decode_image + tf.cast(..., tf.float32)
        buffer[pixelIndex++] = pixel.r.toDouble(); // Red channel (0-255)
        buffer[pixelIndex++] = pixel.g.toDouble(); // Green channel (0-255)
        buffer[pixelIndex++] = pixel.b.toDouble(); // Blue channel (0-255)
      }
    }
    preprocessStart.stop();
    print(
        '      └─ ✅ Conversion completed in ${preprocessStart.elapsedMilliseconds}ms');
    print('      └─ Total pixels processed: ${inputSize * inputSize}');

    // DEBUG: Check buffer range and sample values
    final minVal = buffer.reduce((a, b) => a < b ? a : b);
    final maxVal = buffer.reduce((a, b) => a > b ? a : b);
    final avgVal = buffer.reduce((a, b) => a + b) / buffer.length;
    print('   └─ Step 2.4: Validating preprocessed buffer...');
    print('      └─ Buffer size: ${buffer.length} values');
    print('      └─ Value range: [$minVal, $maxVal] (expected: [0.0, 255.0])');
    print(
        '      └─ Range validation: ${minVal >= 0.0 && maxVal <= 255.0 ? "✅ CORRECT" : "⚠️ OUT OF RANGE"}');
    print('      └─ Average value: ${avgVal.toStringAsFixed(6)}');
    print(
        '      └─ First 6 values: [${buffer[0].toStringAsFixed(3)}, ${buffer[1].toStringAsFixed(3)}, ${buffer[2].toStringAsFixed(3)}, ${buffer[3].toStringAsFixed(3)}, ${buffer[4].toStringAsFixed(3)}, ${buffer[5].toStringAsFixed(3)}]');

    // Return Float32List - TFLite will handle the shape [1, 300, 300, 3]
    // The buffer is already in correct format: sequential RGB values in 0.0-255.0 range
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

    print('      └─ 🎯 Finding best prediction...');
    print(
        '         └─ Max confidence: ${(maxConfidence * 100).toStringAsFixed(2)}%');
    print('         └─ Best class index: $bestIndex');
    print('         └─ Best class label: "${_labels[bestIndex]}"');
    print(
        '         └─ Best class display: "${_diseaseNameMap[_labels[bestIndex]] ?? _labels[bestIndex]}"');
    print('      └─ 📊 All class probabilities:');
    for (int i = 0; i < probabilities.length && i < _labels.length; i++) {
      final label = _labels[i];
      final displayName = _diseaseNameMap[label] ?? label;
      final isBest = i == bestIndex;
      print(
          '         ${isBest ? "🏆" : "  "} [$i] $label → ${displayName}: ${(probabilities[i] * 100).toStringAsFixed(2)}%');
    }


    // Get label
    final labelKey =
        bestIndex < _labels.length ? _labels[bestIndex] : 'unknown';

    // Map to display name
    final diseaseName = _diseaseNameMap[labelKey] ?? labelKey;
    final isHealthy = diseaseName == 'Healthy';
    
    // Check if image is irrelevant (random class)
    final isIrrelevant = labelKey == 'random';

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

    // If random class is detected, mark as irrelevant
    final finalIsIrrelevant = isIrrelevant || (labelKey == 'random' && confidence > 0.5);
    
    return DiseaseAnalysisResult(
      diseaseType: diseaseName,
      confidence: confidence,
      isHealthy: isHealthy,
      recommendations: recommendations,
      analysisDetails: analysisDetails,
      isIrrelevant: finalIsIrrelevant,
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

      case 'Random/Irrelevant':
        return [
          'Please upload an image of chicken faeces for accurate disease detection.',
          'The image should show chicken droppings/faeces clearly.',
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

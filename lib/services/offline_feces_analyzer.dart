import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as img;

import 'chicken_disease_service.dart';
import 'tflite_image_classifier.dart';

/// Analyzer for chicken faeces images.
/// Uses TFLite model if available, falls back to heuristic analysis.
class OfflineFecesAnalyzer {
  TFLiteImageClassifier? _tfliteClassifier;
  bool _tfliteAvailable = false;
  static const int sampleSize = 224;
  static const double eps = 1e-9;

  /// Initialize TFLite classifier if available
  Future<void> initializeTFLite() async {
    try {
      _tfliteClassifier = TFLiteImageClassifier();
      await _tfliteClassifier!.initialize();
      _tfliteAvailable = true;
    } catch (e) {
      print('TFLite not available, using heuristic analyzer: $e');
      _tfliteAvailable = false;
    }
  }

  Future<DiseaseAnalysisResult> analyze(File imageFile) async {
    // Try TFLite first if available
    if (_tfliteAvailable && _tfliteClassifier != null) {
      try {
        return await _tfliteClassifier!.classifyImage(imageFile);
      } catch (e) {
        print('TFLite analysis failed, falling back to heuristic: $e');
        // Fall through to heuristic analysis
      }
    }

    // Fallback to heuristic analysis
    return _heuristicAnalyze(imageFile);
  }

  /// Heuristic analysis (fallback method)
  Future<DiseaseAnalysisResult> _heuristicAnalyze(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('Could not decode image');
    }

    final resized =
        img.copyResize(decoded, width: sampleSize, height: sampleSize);

    final features = _extractFeatures(resized);
    final scores = _scoreDiseases(features);

    // Pick best class
    final labels = [
      'Healthy',
      'Coccidiosis',
      'Newcastle Disease',
      'Salmonella',
      'E.coli'
    ];
    int bestIdx = 0;
    double bestScore = scores[0];
    for (int i = 1; i < scores.length; i++) {
      if (scores[i] > bestScore) {
        bestIdx = i;
        bestScore = scores[i];
      }
    }

    // Normalize scores to sum to 1 for a pseudo-confidence
    final double sum = scores.fold(0.0, (a, b) => a + max(b, 0));
    final probs = [for (final s in scores) (max(s, 0) / (sum + eps))];
    
    final confidence = probs[bestIdx].clamp(0.0, 1.0);
    // Check if irrelevant (confidence < 80%)
    final isIrrelevant = confidence < 0.8;

    return DiseaseAnalysisResult(
      diseaseType: labels[bestIdx],
      confidence: confidence,
      isHealthy: labels[bestIdx] == 'Healthy',
      recommendations: _recommendations(labels[bestIdx]),
      analysisDetails: {
        for (int i = 0; i < labels.length; i++) labels[i]: probs[i],
      },
      isIrrelevant: isIrrelevant,
    );
  }

  Map<String, double> _extractFeatures(img.Image im) {
    // Simple features:
    // - Mean HSV (h, s, v)
    // - Brownish ratio (faeces typical hues)
    // - Greenish ratio (possible bile/intestinal issues)
    // - Red ratio (blood traces)
    // - Texture roughness (Sobel edge density)
    // - Spot count (connected components over threshold)
    final int w = im.width;
    final int h = im.height;

    double sumH = 0, sumS = 0, sumV = 0;
    int brownish = 0, greenish = 0, reddish = 0;

    // Edge magnitude via simple Sobel
    int edgeCount = 0;

    for (int y = 1; y < h - 1; y++) {
      for (int x = 1; x < w - 1; x++) {
        final c = im.getPixel(x, y);
        final r = c.r.toDouble();
        final g = c.g.toDouble();
        final b = c.b.toDouble();

        final hsv = _rgbToHsv(r, g, b);
        sumH += hsv[0];
        sumS += hsv[1];
        sumV += hsv[2];

        // crude color buckets
        final hDeg = hsv[0] * 360.0;
        if (hDeg > 15 && hDeg < 45 && hsv[2] > 0.2) brownish++;
        if (hDeg > 60 && hDeg < 180 && hsv[1] > 0.2) greenish++;
        if ((hDeg < 10 || hDeg > 350) && hsv[1] > 0.2 && hsv[2] > 0.2)
          reddish++;

        // Sobel edge
        final gx = _luma(im.getPixel(x + 1, y)) - _luma(im.getPixel(x - 1, y));
        final gy = _luma(im.getPixel(x, y + 1)) - _luma(im.getPixel(x, y - 1));
        final mag = (gx.abs() + gy.abs());
        if (mag > 40) {
          edgeCount++;
        }
      }
    }

    final total = (w - 2) * (h - 2);
    final meanH = sumH / total;
    final meanS = sumS / total;
    final meanV = sumV / total;
    final brownRatio = brownish / total;
    final greenRatio = greenish / total;
    final redRatio = reddish / total;
    final edgeDensity = edgeCount / total;

    return {
      'meanH': meanH,
      'meanS': meanS,
      'meanV': meanV,
      'brownRatio': brownRatio,
      'greenRatio': greenRatio,
      'redRatio': redRatio,
      'edgeDensity': edgeDensity,
    };
  }

  List<double> _scoreDiseases(Map<String, double> f) {
    // Heuristic scoring (0..1). Tune as needed from your dataset.
    final healthy = (f['brownRatio']! > 0.25 &&
            f['redRatio']! < 0.02 &&
            f['edgeDensity']! < 0.12)
        ? 0.8
        : 0.3;

    final coccidiosis = (f['redRatio']! > 0.03) ? 0.8 : 0.2;

    final newcastle =
        (f['greenRatio']! > 0.10 && f['meanS']! > 0.35) ? 0.7 : 0.25;

    final salmonella =
        (f['meanV']! < 0.35 && f['edgeDensity']! > 0.15) ? 0.7 : 0.25;

    final ecoli =
        (f['greenRatio']! > 0.06 && f['edgeDensity']! > 0.12) ? 0.65 : 0.25;

    return [healthy, coccidiosis, newcastle, salmonella, ecoli];
  }

  List<double> _rgbToHsv(double r, double g, double b) {
    r /= 255.0;
    g /= 255.0;
    b /= 255.0;
    final maxc = max(r, max(g, b));
    final minc = min(r, min(g, b));
    final v = maxc;
    final d = maxc - minc;
    final s = maxc == 0 ? 0.0 : d / (maxc + eps);
    double h = 0.0;
    if (d != 0) {
      if (maxc == r) {
        h = (g - b) / d + (g < b ? 6 : 0);
      } else if (maxc == g) {
        h = (b - r) / d + 2;
      } else {
        h = (r - g) / d + 4;
      }
      h /= 6;
    }
    return [h, s, v];
  }

  int _luma(img.Pixel pixel) {
    final r = pixel.r;
    final g = pixel.g;
    final b = pixel.b;
    return ((0.299 * r) + (0.587 * g) + (0.114 * b)).round();
  }

  List<String> _recommendations(String disease) {
    switch (disease) {
      case 'Healthy':
        return [
          'Continue current feeding routine',
          'Monitor for changes in faeces appearance',
          'Maintain a clean, dry environment',
        ];
      case 'Coccidiosis':
        return [
          'Isolate affected birds immediately',
          'Consult a veterinarian for anticoccidial treatment',
          'Disinfect housing; improve litter management',
        ];
      case 'Newcastle Disease':
        return [
          'Urgent veterinary consultation required',
          'Quarantine birds and restrict movement',
          'Review vaccination status and biosecurity',
        ];
      case 'Salmonella':
        return [
          'Consult veterinarian; review feed and water hygiene',
          'Enhance biosecurity and sanitation',
          'Monitor flock closely for systemic signs',
        ];
      case 'E.coli':
        return [
          'Improve sanitation and bedding quality',
          'Check water quality; consider probiotic support',
          'Veterinary guidance for targeted therapy',
        ];
      default:
        return ['Consult a veterinarian for appropriate diagnostics and care'];
    }
  }
}

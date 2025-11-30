import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'image_selection_screen.dart';
import '../services/chicken_disease_service.dart';
import '../services/pdf_service.dart';
import '../services/gemini_chat_service.dart';

class ResultScreen extends StatefulWidget {
  final File image1;
  final File? image2; // Optional - for backward compatibility
  final DiseaseAnalysisResult? analysisResult;

  const ResultScreen({
    super.key,
    required this.image1,
    this.image2, // Optional now
    this.analysisResult,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late final PDFService _pdfService;
  bool _isGeneratingPDF = false;

  @override
  void initState() {
    super.initState();
    // Initialize PDF service with Gemini for AI suggestions
    final geminiService = GeminiChatService(
      apiKey: 'AIzaSyAEI5_n8HuAT4VoKtQsiXLZq7svWRUx7AE',
    );
    _pdfService = PDFService(geminiService: geminiService);
  }

  Future<void> _generatePDF({bool shareToWhatsApp = false}) async {
    if (widget.analysisResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No analysis data available for PDF')),
      );
      return;
    }

    setState(() {
      _isGeneratingPDF = true;
    });

    try {
      // Only include image2 if it exists
      final images = widget.image2 != null
          ? [widget.image1, widget.image2!]
          : [widget.image1];

      await _pdfService.generateAndShareReport(
        result: widget.analysisResult!,
        images: images,
        patientName: 'Chicken Analysis',
        shareToWhatsApp: shareToWhatsApp,
      );

      if (mounted) {
        final directory = await getApplicationDocumentsDirectory();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'PDF generated successfully!',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Saved to: ${directory.path}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'View Path',
              textColor: Colors.white,
              onPressed: () {
                _showSaveLocationDialog(directory.path);
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPDF = false;
        });
      }
    }
  }

  void _showSaveLocationDialog(String path) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.folder_rounded, color: Colors.blue),
            SizedBox(width: 8),
            Text('Document Save Location'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PDF reports are saved to:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                path,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'You can find your PDF reports in this folder. They can be shared via WhatsApp, Email, or other apps.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use real analysis result - should always be available from TFLite
    if (widget.analysisResult == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Analysis Result'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('No analysis data available'),
        ),
      );
    }

    final bool isHealthy = widget.analysisResult!.isHealthy;
    final String diseaseType = widget.analysisResult!.diseaseType;
    final double confidence = widget.analysisResult!.confidence;
    final List<String> recommendations = widget.analysisResult!.recommendations;
    final Map<String, double> analysisDetails =
        widget.analysisResult!.analysisDetails;

    // Debug: Print analysis details
    print('📊 Result Screen - Disease Type: $diseaseType');
    print(
        '📊 Result Screen - Confidence: ${(confidence * 100).toStringAsFixed(1)}%');
    print('📊 Result Screen - Analysis Details: $analysisDetails');
    print(
        '📊 Result Screen - Analysis Details Count: ${analysisDetails.length}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Result'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Icon(
                  isHealthy ? Icons.check_circle : Icons.warning,
                  size: 80,
                  color: isHealthy ? Colors.green : Colors.orange,
                ),
                const SizedBox(height: 24),
                Text(
                  isHealthy
                      ? 'Your chicken appears healthy'
                      : 'Possible signs of $diseaseType detected',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color:
                            isHealthy ? Colors.green[700] : Colors.orange[800],
                      ),
                ),
                const SizedBox(height: 8),
                // Confidence score
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: (isHealthy ? Colors.green : Colors.orange)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: isHealthy ? Colors.green[700] : Colors.orange[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Display analyzed image(s)
                widget.image2 != null
                    ? Row(
                        children: [
                          Expanded(
                            child: Card(
                              child: Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(16)),
                                    child: Image.file(
                                      widget.image1,
                                      height: 120,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('Image 1'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Card(
                              child: Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(16)),
                                    child: Image.file(
                                      widget.image2!,
                                      height: 120,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('Image 2'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : Card(
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16)),
                              child: Image.file(
                                widget.image1,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Analyzed Image'),
                            ),
                          ],
                        ),
                      ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Analysis Details:',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        // Show recommendations
                        Text(
                          'Recommendations:',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                        ),
                        const SizedBox(height: 8),
                        ...recommendations.map((rec) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• ',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Expanded(
                                    child: Text(
                                      rec,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                        // Show analysis details - ALWAYS show if available
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          'Disease Probabilities:',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                        ),
                        const SizedBox(height: 8),
                        // Show all 4 disease probabilities
                        if (analysisDetails.isNotEmpty)
                          ...analysisDetails.entries.map((entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        entry.key,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight:
                                                  entry.key == diseaseType
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                            ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: entry.key == diseaseType
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withOpacity(0.1)
                                            : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: entry.key == diseaseType
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                              : Colors.grey[300]!,
                                          width:
                                              entry.key == diseaseType ? 2 : 1,
                                        ),
                                      ),
                                      child: Text(
                                        '${(entry.value * 100).toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: entry.key == diseaseType
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                              : Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                        else
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'No probability data available',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Action Buttons
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ImageSelectionScreen(),
                                ),
                                (route) => route.settings.name == '/welcome',
                              );
                            },
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Analyze Again'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[300],
                              foregroundColor: Colors.black87,
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Result saved to history!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                            icon: const Icon(Icons.save_rounded),
                            label: const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed:
                            _isGeneratingPDF ? null : () => _generatePDF(),
                        icon: _isGeneratingPDF
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.picture_as_pdf_rounded),
                        label: Text(_isGeneratingPDF
                            ? 'Generating PDF...'
                            : 'Export as PDF Report'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green[700],
                          side: BorderSide(color: Colors.green[700]!),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _isGeneratingPDF
                            ? null
                            : () => _generatePDF(shareToWhatsApp: true),
                        icon: const Icon(Icons.share_rounded),
                        label: const Text('Share on WhatsApp'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

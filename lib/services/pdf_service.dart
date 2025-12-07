import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'chicken_disease_service.dart';
import 'gemini_chat_service.dart';

/// Service for generating PDF reports
class PDFService {
  final GeminiChatService? _geminiService;

  PDFService({GeminiChatService? geminiService})
      : _geminiService = geminiService;

  /// Generate and share PDF report for disease analysis
  Future<String> generateAndShareReport({
    required DiseaseAnalysisResult result,
    required List<File> images,
    String? patientName,
    bool shareToWhatsApp = false,
  }) async {
    try {
      // Get AI-powered suggestions from Gemini if available
      List<String> finalRecommendations = result.recommendations;
      DiseaseDetails? diseaseDetails;
      
      final geminiService = _geminiService;
      if (geminiService != null && geminiService.isInitialized) {
        try {
          // Get recommendations
          final aiSuggestions = await geminiService.getDiseaseSuggestions(
            diseaseType: result.diseaseType,
            confidence: result.confidence,
            isHealthy: result.isHealthy,
          );
          if (aiSuggestions.isNotEmpty) {
            // Clean recommendations: remove **, icons, emojis, markdown
            finalRecommendations = aiSuggestions
                .map((rec) {
                  return rec
                      .replaceAll(RegExp(r'\*\*'), '') // Remove **
                      .replaceAll(RegExp(r'\*'), '') // Remove single *
                      .replaceAll(
                          RegExp(r'[✅⚠️🚨💩🐔👁️📸❌]'), '') // Remove emojis
                      .replaceAll(RegExp(r'[^\x00-\x7F]'),
                          '') // Remove all non-ASCII (emojis, special chars)
                      .trim();
                })
                .where((rec) => rec.isNotEmpty)
                .toList();
          }
          
          // Get detailed disease information (only for diseases, not healthy)
          if (!result.isHealthy) {
            try {
              diseaseDetails = await geminiService.getDiseaseDetails(
                diseaseType: result.diseaseType,
                confidence: result.confidence,
                isHealthy: result.isHealthy,
              );
            } catch (e) {
              print('Failed to get disease details: $e');
            }
          }
        } catch (e) {
          print('Failed to get Gemini suggestions: $e');
          // Use default recommendations
        }
      }

      // Also clean default recommendations
      finalRecommendations = finalRecommendations
          .map((rec) {
            return rec
                .replaceAll(RegExp(r'\*\*'), '') // Remove **
                .replaceAll(RegExp(r'\*'), '') // Remove single *
                .replaceAll(RegExp(r'[✅⚠️🚨💩🐔👁️📸❌]'), '') // Remove emojis
                .replaceAll(RegExp(r'[^\x00-\x7F]'), '') // Remove all non-ASCII
                .trim();
          })
          .where((rec) => rec.isNotEmpty)
          .toList();

      // Create result with AI suggestions
      final enhancedResult = DiseaseAnalysisResult(
        diseaseType: result.diseaseType,
        confidence: result.confidence,
        isHealthy: result.isHealthy,
        recommendations: finalRecommendations,
        analysisDetails: result.analysisDetails,
        isIrrelevant: result.isIrrelevant,
      );

      final pdf = await _createPDF(enhancedResult, images, patientName, diseaseDetails);

      // Save PDF to file
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'Poultry_Doctor_Report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final filePath = path.join(directory.path, fileName);
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      // Share via WhatsApp if requested, otherwise show print dialog
      if (shareToWhatsApp) {
        await Share.shareXFiles(
          [XFile(filePath)],
          text:
              'Poultry Doctor - Disease Analysis Report\n\nDisease: ${result.diseaseType}\nConfidence: ${(result.confidence * 100).toStringAsFixed(1)}%',
        );
      } else {
        // Show print/share dialog
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save(),
        );
      }

      return filePath; // Return path for future use
    } catch (e) {
      throw Exception('Failed to generate PDF: $e');
    }
  }

  /// Get save location info
  Future<String> getSaveLocationInfo() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      return directory.path;
    } catch (e) {
      return 'Unable to determine save location';
    }
  }

  /// Create PDF document
  Future<pw.Document> _createPDF(
    DiseaseAnalysisResult result,
    List<File> images,
    String? patientName,
    DiseaseDetails? diseaseDetails,
  ) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // Header
            _buildHeader(dateFormat.format(now)),
            pw.SizedBox(height: 20),

            // Patient Info
            if (patientName != null)
              _buildPatientInfo(patientName, dateFormat.format(now)),

            // Analysis Result
            _buildAnalysisResult(result),
            pw.SizedBox(height: 20),

            // Images Section
            if (images.isNotEmpty) _buildImagesSection(images),
            pw.SizedBox(height: 20),

            // Recommendations
            _buildRecommendations(result.recommendations),
            pw.SizedBox(height: 20),

            // Disease Details (Diagnosis, Medication, Vaccine, Care)
            if (diseaseDetails != null && !result.isHealthy)
              _buildDiseaseDetailsSection(diseaseDetails),
            if (diseaseDetails != null && !result.isHealthy)
              pw.SizedBox(height: 20),

            // Analysis Details
            if (result.analysisDetails.isNotEmpty)
              _buildAnalysisDetails(result.analysisDetails),

            pw.SizedBox(height: 30),

            // Footer
            _buildFooter(),
          ];
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildHeader(String date) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFF2E7D32), // green700
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Poultry Doctor',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'AI-Powered Disease Detection Report',
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                date,
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPatientInfo(String name, String date) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Patient Information',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Text('Name: ',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(name),
              pw.Spacer(),
              pw.Text('Date: ',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(date),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildAnalysisResult(DiseaseAnalysisResult result) {
    final statusColor = result.isHealthy
        ? const PdfColor.fromInt(0xFF4CAF50) // green
        : const PdfColor.fromInt(0xFFFF9800); // orange
    final statusText = result.isHealthy ? 'HEALTHY' : 'DISEASE DETECTED';
    final bgColor = result.isHealthy
        ? const PdfColor.fromInt(0xFFE8F5E9) // light green
        : const PdfColor.fromInt(0xFFFFF3E0); // light orange

    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: bgColor,
        border: pw.Border.all(color: statusColor, width: 2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: statusColor,
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(5)),
                ),
                child: pw.Text(
                  statusText,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              pw.Spacer(),
              pw.Text(
                'Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 15),
          pw.Text(
            'Disease Type: ${result.diseaseType}',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildImagesSection(List<File> images) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Analysis Images',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
          children: images.take(2).map((image) {
            return pw.Expanded(
              child: pw.Container(
                margin: const pw.EdgeInsets.symmetric(horizontal: 5),
                child: pw.Column(
                  children: [
                    pw.Image(
                      pw.MemoryImage(image.readAsBytesSync()),
                      fit: pw.BoxFit.cover,
                      height: 150,
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Image ${images.indexOf(image) + 1}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  pw.Widget _buildRecommendations(List<String> recommendations) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFE3F2FD), // blue50
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Recommendations',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          ...recommendations.map((rec) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 5),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Expanded(
                      child: pw.Text(
                        rec,
                        style: pw.TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  pw.Widget _buildAnalysisDetails(Map<String, double> details) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF5F5F5), // grey100
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Disease Probability Breakdown',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          ...details.entries.map((entry) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 5),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      entry.key,
                      style: pw.TextStyle(fontSize: 11),
                    ),
                    pw.Text(
                      '${(entry.value * 100).toStringAsFixed(1)}%',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  pw.Widget _buildDiseaseDetailsSection(DiseaseDetails details) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF3E5F5), // purple50
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(
          color: const PdfColor.fromInt(0xFF9C27B0), // purple500
          width: 1,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Detailed Disease Information',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor.fromInt(0xFF9C27B0),
            ),
          ),
          pw.SizedBox(height: 15),
          
          // Diagnosis
          _buildDetailSubsection('Diagnosis', details.diagnosis),
          pw.SizedBox(height: 12),
          
          // Medication
          _buildDetailSubsection('Medication', details.medication),
          pw.SizedBox(height: 12),
          
          // Vaccines
          _buildDetailSubsection('Vaccines', details.vaccines),
          pw.SizedBox(height: 12),
          
          // Care Instructions
          _buildDetailSubsection('Care Instructions', details.careInstructions),
        ],
      ),
    );
  }

  pw.Widget _buildDetailSubsection(String title, dynamic content) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor.fromInt(0xFF7B1FA2),
            ),
          ),
          pw.SizedBox(height: 6),
          if (content is String)
            pw.Text(
              content,
              style: const pw.TextStyle(fontSize: 10),
            )
          else if (content is List<String>)
            ...content.map((item) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 3),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('• ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Expanded(
                        child: pw.Text(
                          item,
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  pw.Widget _buildFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFEEEEEE), // grey200
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'Disclaimer',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'This report is generated by AI and should not replace professional veterinary consultation. '
            'For critical cases, please consult a qualified veterinarian immediately.',
            style: pw.TextStyle(
              fontSize: 9,
              fontStyle: pw.FontStyle.italic,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Generated by Poultry Doctor App',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey700,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }
}

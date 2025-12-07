import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image/image.dart' as img;

/// Simple wrapper around Gemini chat with streaming responses.
class GeminiChatService {
  final String apiKey;
  final String modelName;

  late final GenerativeModel _model;
  late final ChatSession _chat;
  bool _initialized = false;

  GeminiChatService({
    required this.apiKey,
    this.modelName = 'gemini-2.5-flash',
  }) {
    _model = GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      systemInstruction: Content.system(
        'You are Poultry Doctor, a helpful assistant for poultry health. '
        'Provide concise, safe, and practical guidance about chicken diseases, '
        'symptoms, prevention, and care. Avoid giving veterinary diagnoses; '
        'recommend consulting a vet for critical cases. '
        'When asked about this app, you can assist with steps to upload photos and interpret results.',
      ),
    );
    _chat = _model.startChat();
    _initialized = true;
  }

  bool get isInitialized => _initialized;

  /// Sends a user message and returns a stream of generated text chunks.
  Stream<String> sendMessageStream(String message) {
    if (!_initialized) {
      return Stream.error(StateError('GeminiChatService is not initialized'));
    }

    final controller = StreamController<String>();
    final buffer = StringBuffer();

    () async {
      try {
        final response = _chat.sendMessageStream(
          Content.text(message),
        );

        await for (final chunk in response) {
          final text = chunk.text;
          if (text != null && text.isNotEmpty) {
            buffer.write(text);
            controller.add(text);
          }
        }
        await controller.close();
      } catch (e, st) {
        controller.addError(e, st);
        await controller.close();
      }
    }();

    return controller.stream;
  }

  /// Returns the whole assistant message once completed.
  Future<String> sendMessage(String message) async {
    if (!_initialized) throw StateError('GeminiChatService is not initialized');
    final response = await _chat.sendMessage(Content.text(message));
    return response.text ?? '';
  }

  /// Get disease-specific treatment suggestions using Gemini
  Future<List<String>> getDiseaseSuggestions({
    required String diseaseType,
    required double confidence,
    required bool isHealthy,
  }) async {
    if (!_initialized) {
      return _getDefaultRecommendations(diseaseType);
    }

    try {
      final prompt = isHealthy
          ? 'Provide 5 practical recommendations for maintaining healthy chickens. Keep each recommendation concise (one line). Format as a numbered list. Do not use any markdown formatting, asterisks, or emojis. Use plain text only.'
          : 'For a chicken diagnosed with $diseaseType (confidence: ${(confidence * 100).toStringAsFixed(1)}%), provide 5 specific, actionable treatment and care recommendations. Include immediate actions, medication if needed, isolation procedures, and follow-up care. Keep each recommendation concise (one line). Format as a numbered list. Do not use any markdown formatting, asterisks, or emojis. Use plain text only.';

      final response = await sendMessage(prompt);
      
      // Parse response into list
      final suggestions = response
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .where((line) => RegExp(r'^\d+[\.\)]\s*').hasMatch(line.trim()))
          .map((line) => line.replaceFirst(RegExp(r'^\d+[\.\)]\s*'), '').trim())
          .where((line) => line.isNotEmpty)
          .take(5)
          .toList();

      return suggestions.isNotEmpty
          ? suggestions
          : _getDefaultRecommendations(diseaseType);
    } catch (e) {
      print('Gemini suggestions failed: $e');
      return _getDefaultRecommendations(diseaseType);
    }
  }

  /// Get detailed disease information including diagnosis, medication, vaccine, and care
  Future<DiseaseDetails> getDiseaseDetails({
    required String diseaseType,
    required double confidence,
    required bool isHealthy,
  }) async {
    if (!_initialized || isHealthy) {
      return DiseaseDetails(
        diagnosis: 'Your chicken appears to be in good health.',
        medication: ['No medication required for healthy birds'],
        vaccines: ['Continue regular vaccination schedule as per veterinary advice'],
        careInstructions: [
          'Maintain clean and dry environment',
          'Provide balanced nutrition',
          'Regular health monitoring',
          'Ensure proper ventilation',
        ],
      );
    }

    try {
      final prompt = '''
For a chicken diagnosed with $diseaseType (confidence: ${(confidence * 100).toStringAsFixed(1)}%), provide comprehensive information in the following format:

DIAGNOSIS:
[Provide a brief 2-3 sentence explanation of what this disease is and what it means for the chicken]

MEDICATION:
[List 3-5 specific medications or treatments, one per line, with dosage if applicable. Format as numbered list without numbers]

VACCINES:
[List 2-4 relevant vaccines or vaccination schedules, one per line. Format as numbered list without numbers]

CARE INSTRUCTIONS:
[List 5-7 detailed care instructions covering isolation, environment, feeding, monitoring, etc., one per line. Format as numbered list without numbers]

IMPORTANT: 
- Do not use markdown formatting, asterisks, emojis, or special characters
- Use plain text only
- Each section should start with the section name followed by colon
- List items should be on separate lines
- Be specific and practical
''';

      final response = await sendMessage(prompt);
      
      return _parseDiseaseDetails(response, diseaseType);
    } catch (e) {
      print('Failed to get disease details from Gemini: $e');
      return _getDefaultDiseaseDetails(diseaseType);
    }
  }

  DiseaseDetails _parseDiseaseDetails(String response, String diseaseType) {
    try {
      // Split response into sections
      final lines = response.split('\n').where((l) => l.trim().isNotEmpty).toList();
      
      String diagnosis = '';
      List<String> medication = [];
      List<String> vaccines = [];
      List<String> careInstructions = [];
      
      String currentSection = '';
      
      for (final line in lines) {
        final trimmed = line.trim();
        
        if (trimmed.toUpperCase().startsWith('DIAGNOSIS:')) {
          currentSection = 'diagnosis';
          diagnosis = trimmed.substring('DIAGNOSIS:'.length).trim();
        } else if (trimmed.toUpperCase().startsWith('MEDICATION:')) {
          currentSection = 'medication';
        } else if (trimmed.toUpperCase().startsWith('VACCINES:')) {
          currentSection = 'vaccines';
        } else if (trimmed.toUpperCase().startsWith('CARE INSTRUCTIONS:') || 
                   trimmed.toUpperCase().startsWith('CARE:')) {
          currentSection = 'care';
        } else if (trimmed.isNotEmpty) {
          // Remove numbering and special characters
          final cleanLine = trimmed
              .replaceFirst(RegExp(r'^\d+[\.\)]\s*'), '')
              .replaceAll(RegExp(r'[^\x00-\x7F]'), '')
              .replaceAll(RegExp(r'\*\*'), '')
              .replaceAll(RegExp(r'\*'), '')
              .trim();
          
          if (cleanLine.isNotEmpty) {
            switch (currentSection) {
              case 'diagnosis':
                if (diagnosis.isEmpty) {
                  diagnosis = cleanLine;
                } else {
                  diagnosis += ' $cleanLine';
                }
                break;
              case 'medication':
                medication.add(cleanLine);
                break;
              case 'vaccines':
                vaccines.add(cleanLine);
                break;
              case 'care':
                careInstructions.add(cleanLine);
                break;
            }
          }
        }
      }
      
      // Ensure we have at least default values
      if (diagnosis.isEmpty) {
        diagnosis = 'Disease detected: $diseaseType. Please consult a veterinarian for proper diagnosis and treatment.';
      }
      if (medication.isEmpty) {
        medication = ['Consult veterinarian for appropriate medication'];
      }
      if (vaccines.isEmpty) {
        vaccines = ['Follow vaccination schedule as advised by veterinarian'];
      }
      if (careInstructions.isEmpty) {
        careInstructions = ['Isolate affected birds', 'Maintain clean environment', 'Monitor closely'];
      }
      
      return DiseaseDetails(
        diagnosis: diagnosis,
        medication: medication,
        vaccines: vaccines,
        careInstructions: careInstructions,
      );
    } catch (e) {
      print('Error parsing disease details: $e');
      return _getDefaultDiseaseDetails(diseaseType);
    }
  }

  DiseaseDetails _getDefaultDiseaseDetails(String diseaseType) {
    switch (diseaseType) {
      case 'Coccidiosis':
        return DiseaseDetails(
          diagnosis: 'Coccidiosis is a parasitic disease caused by protozoa that affects the intestinal tract of chickens, leading to diarrhea, weight loss, and reduced growth.',
          medication: [
            'Amprolium (0.012-0.024% in feed for 5-7 days)',
            'Sulfadimethoxine (0.05% in water for 3-5 days)',
            'Toltrazuril (7 mg/kg body weight)',
            'Consult veterinarian for proper dosage',
          ],
          vaccines: [
            'Live attenuated coccidiosis vaccines available for day-old chicks',
            'Administer at 1-3 days of age via spray or gel',
            'Requires proper management for vaccine to work effectively',
          ],
          careInstructions: [
            'Isolate affected birds immediately to prevent spread',
            'Maintain clean, dry litter and replace frequently',
            'Ensure adequate ventilation to reduce moisture',
            'Provide clean, fresh water at all times',
            'Monitor feed intake and body weight daily',
            'Disinfect housing and equipment thoroughly',
            'Avoid overcrowding to reduce stress',
          ],
        );
      case 'Newcastle Disease':
        return DiseaseDetails(
          diagnosis: 'Newcastle Disease is a highly contagious viral disease that can cause severe respiratory, nervous, and digestive symptoms in chickens. It can be fatal if not properly managed.',
          medication: [
            'No specific antiviral treatment available',
            'Supportive care with antibiotics for secondary infections',
            'Vitamin supplements to boost immune system',
            'Fluid therapy for dehydrated birds',
            'Consult veterinarian immediately for proper care',
          ],
          vaccines: [
            'Live vaccines (B1, LaSota) - administer at 1-3 days old',
            'Inactivated vaccines - booster at 4-6 weeks',
            'Annual revaccination recommended',
            'Follow proper vaccination schedule as per veterinary advice',
          ],
          careInstructions: [
            'URGENT: Isolate all affected birds immediately',
            'Quarantine entire flock and restrict movement',
            'Report to local veterinary authorities if required',
            'Maintain strict biosecurity measures',
            'Provide supportive care and comfortable environment',
            'Monitor for respiratory distress and provide ventilation',
            'Dispose of dead birds properly and disinfect all equipment',
          ],
        );
      case 'Salmonella':
        return DiseaseDetails(
          diagnosis: 'Salmonellosis is a bacterial infection that can affect both chickens and humans. It causes diarrhea, reduced egg production, and can be a public health concern.',
          medication: [
            'Antibiotics: Enrofloxacin (10-15 mg/kg for 5 days)',
            'Ampicillin (20-40 mg/kg for 5-7 days)',
            'Trimethoprim-sulfamethoxazole as per veterinary prescription',
            'Probiotics to restore gut flora after treatment',
            'Consult veterinarian for proper antibiotic selection',
          ],
          vaccines: [
            'Salmonella vaccines available for breeder flocks',
            'Administer as per manufacturer guidelines',
            'Regular vaccination helps prevent infection',
            'Follow biosecurity measures alongside vaccination',
          ],
          careInstructions: [
            'Isolate infected birds to prevent spread',
            'Maintain strict hygiene and sanitation',
            'Disinfect feed and water containers daily',
            'Control rodents and insects that can carry bacteria',
            'Practice good biosecurity and limit visitors',
            'Monitor egg production and quality',
            'Wash hands thoroughly after handling birds',
          ],
        );
      default:
        return DiseaseDetails(
          diagnosis: 'Disease detected: $diseaseType. Please consult a veterinarian for proper diagnosis and treatment plan.',
          medication: ['Consult veterinarian for appropriate medication'],
          vaccines: ['Follow vaccination schedule as advised by veterinarian'],
          careInstructions: [
            'Isolate affected birds',
            'Maintain clean environment',
            'Monitor closely for changes',
            'Consult veterinarian immediately',
          ],
        );
    }
  }

  /// Default recommendations if Gemini fails
  List<String> _getDefaultRecommendations(String diseaseType) {
    switch (diseaseType) {
      case 'Healthy':
        return [
          'Continue current feeding routine',
          'Monitor for changes in appearance',
          'Maintain a clean, dry environment',
        ];
      case 'Coccidiosis':
        return [
          'Isolate affected birds immediately',
          'Consult a veterinarian for anticoccidial treatment',
          'Disinfect housing and improve litter management',
        ];
      case 'Newcastle Disease':
        return [
          'URGENT: Veterinary consultation required immediately',
          'Quarantine birds and restrict all movement',
          'Review vaccination status and biosecurity measures',
        ];
      case 'Salmonella':
        return [
          'Consult veterinarian immediately',
          'Review feed and water hygiene practices',
          'Enhance biosecurity and sanitation measures',
        ];
      default:
        return [
          'Consult a veterinarian for appropriate diagnostics',
          'Monitor the bird closely for any changes',
          'Maintain good hygiene and biosecurity',
        ];
    }
  }

  /// Check if image is chicken faeces using Gemini Vision API
  /// Returns true if image appears to be chicken faeces, false otherwise
  Future<bool> isFecesImage(File imageFile) async {
    if (!_initialized) {
      print('⚠️ Gemini not initialized, assuming image is faeces');
      return true; // Default to true to allow TFLite to process
    }

    // List of API keys to try (fallback mechanism)
    final apiKeys = [
      apiKey, // Primary key
      'AIzaSyAxFNLu3aEO3wpjhMqEHowTv-7GIwNs5ZM', // Fallback key
    ];

    // Read and convert image to JPEG format to ensure compatibility
    // This is especially important for camera images which may be in different formats
    Uint8List imageBytes;
    try {
      final originalBytes = await imageFile.readAsBytes();

      // Decode the image (handles any format: JPEG, PNG, etc.)
      final decodedImage = img.decodeImage(originalBytes);

      if (decodedImage == null) {
        print(
            '❌ Failed to decode image, defaulting to allow TFLite processing');
        return true;
      }

      // Encode as JPEG to ensure consistent format for Gemini API
      // This ensures camera images (which might be PNG or other formats) work correctly
      imageBytes = Uint8List.fromList(img.encodeJpg(decodedImage, quality: 90));
      print('📸 Image converted to JPEG format for Gemini check');
    } catch (e) {
      print(
          '❌ Failed to process image for Gemini: $e, defaulting to allow TFLite processing');
      return true;
    }

    // Try each API key until one works
    for (int i = 0; i < apiKeys.length; i++) {
      try {
        // Create a new model instance for vision (without chat session)
        final visionModel = GenerativeModel(
          model: modelName,
          apiKey: apiKeys[i],
          systemInstruction: Content.system(
            'You are an expert at identifying chicken faeces (chicken droppings/chicken poop/chicken waste) images. '
            'Chicken faeces can be in various forms: solid droppings, liquid droppings, or mixed. '
            'They may appear brown, green, white, or have different colors. '
            'If the image shows ANY form of chicken droppings, faeces, poop, or waste material from chickens, respond "yes". '
            'Only respond "no" if the image clearly shows something completely unrelated like a person, building, document, or non-chicken-related object. '
            'Respond with ONLY "yes" or "no" - no explanations.',
          ),
        );

        // Send image with prompt using Part API
        final prompt =
            'Does this image show chicken faeces, chicken droppings, chicken poop, or chicken waste? This includes any form of chicken excrement - solid, liquid, or mixed. Answer only "yes" if it shows chicken waste/droppings, or "no" if it shows something completely different like a person, document, or unrelated object. Answer only "yes" or "no".';

        // Create content with text and image parts - now using JPEG format
        final response = await visionModel.generateContent([
          Content.multi([
            TextPart(prompt),
            DataPart('image/jpeg', imageBytes),
          ]),
        ]);
        final responseText = response.text?.toLowerCase().trim() ?? '';

        print(
            '🔍 Gemini check result: ${responseText.substring(0, responseText.length > 50 ? 50 : responseText.length)}...');

        // Check if response indicates faeces
        final isFeces = responseText.contains('yes') &&
            !responseText.contains('no') &&
            !responseText.contains('not');

        if (isFeces) {
          print('✅ Gemini confirmed: Image is chicken faeces');
        } else {
          print('❌ Gemini confirmed: Image is NOT chicken faeces');
        }

        return isFeces;
      } catch (e, stackTrace) {
        print('❌ Gemini Vision check failed with Key ${i + 1}: $e');
        if (i < apiKeys.length - 1) {
          print('🔄 Trying fallback API key...');
          continue; // Try next key
        } else {
          print('❌ All API keys failed, defaulting to allow TFLite processing');
          print('Stack trace: $stackTrace');
          // On error with all keys, default to true to allow TFLite processing
          return true;
        }
      }
    }

    // Should not reach here, but just in case
    return true;
  }

  void dispose() {
    // nothing to dispose currently; placeholder for future resources
  }
}

/// Detailed disease information structure
class DiseaseDetails {
  final String diagnosis;
  final List<String> medication;
  final List<String> vaccines;
  final List<String> careInstructions;

  DiseaseDetails({
    required this.diagnosis,
    required this.medication,
    required this.vaccines,
    required this.careInstructions,
  });
}

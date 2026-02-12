import 'package:google_generative_ai/google_generative_ai.dart';
import 'config.dart'; // Import the config file
import '../utils/app_logger.dart';

class AIService {
  late final GenerativeModel _model;

  AIService() {
    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: AppConfig.geminiApiKey,
    );
  }

  /// Generate creative message suggestions for time capsules
  Future<String> suggestMessage({
    required String context,
    String? recipientName,
    String? unlockType,
  }) async {
    try {
      final prompt = _buildPrompt(context, recipientName, unlockType);
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      return response.text ??
          'Unable to generate suggestion. Please try again.';
    } catch (e) {
      AppLogger.error('Error generating AI suggestion', e);
      return 'AI suggestion unavailable. Please try again later.';
    }
  }

  /// Enhance existing message with AI improvements
  Future<String> enhanceMessage(String originalMessage) async {
    try {
      final prompt =
          '''
Enhance this time capsule message to make it more heartfelt, memorable, and engaging. 
Keep the core sentiment but improve the writing style. Keep it concise (under 200 words).

Original message: "$originalMessage"

Enhanced version:''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      return response.text ?? originalMessage;
    } catch (e) {
      AppLogger.error('Error enhancing message', e);
      return originalMessage;
    }
  }

  /// Generate caption for uploaded images
  Future<String> generateImageCaption(String imageContext) async {
    try {
      final prompt =
          '''
Generate a short, creative caption (1-2 sentences) for a photo being added to a time capsule.
Context: $imageContext

Caption:''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      return response.text ?? 'A special moment captured in time.';
    } catch (e) {
      AppLogger.error('Error generating caption', e);
      return 'A special moment captured in time.';
    }
  }

  String _buildPrompt(
    String context,
    String? recipientName,
    String? unlockType,
  ) {
    final recipient = recipientName ?? 'someone special';
    final unlock = unlockType ?? 'future time';

    return '''
Write a heartfelt, creative message for a time capsule being sent to $recipient.
The capsule will unlock at: $unlock

Additional context: $context

Requirements:
- Be warm, personal, and memorable
- 100-150 words
- Include emotions, hopes, or memories
- Make it feel like a letter from the heart
- Don't use generic phrases

Message:''';
  }
}

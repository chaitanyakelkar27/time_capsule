import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/app_logger.dart';

class AIService {
  static const String _apiUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _apiKey = String.fromEnvironment('GROQ_API_KEY');
  static const String _model = String.fromEnvironment(
    'GROQ_MODEL',
    defaultValue: 'llama-3.1-8b-instant',
  );

  /// Generate creative message suggestions for time capsules
  Future<String> suggestMessage({
    required String context,
    String? recipientName,
    String? unlockType,
  }) async {
    final prompt = _buildPrompt(context, recipientName, unlockType);
    return _generateText(
      prompt: prompt,
      maxTokens: 300,
      temperature: 0.85,
      fallbackMessage: 'Unable to generate suggestion. Please try again.',
    );
  }

  /// Enhance existing message with AI improvements
  Future<String> enhanceMessage(String originalMessage) async {
    final prompt =
        '''
Enhance this time capsule message to make it more heartfelt, memorable, and engaging. 
Keep the core sentiment but improve the writing style. Keep it concise (under 200 words).

Original message: "$originalMessage"

Enhanced version:''';

    return _generateText(
      prompt: prompt,
      maxTokens: 260,
      temperature: 0.7,
      fallbackMessage: originalMessage,
    );
  }

  /// Generate caption for uploaded images
  Future<String> generateImageCaption(String imageContext) async {
    final prompt =
        '''
Generate a short, creative caption (1-2 sentences) for a photo being added to a time capsule.
Context: $imageContext

Caption:''';

    return _generateText(
      prompt: prompt,
      maxTokens: 80,
      temperature: 0.9,
      fallbackMessage: 'A special moment captured in time.',
    );
  }

  Future<String> _generateText({
    required String prompt,
    required int maxTokens,
    required double temperature,
    required String fallbackMessage,
  }) async {
    if (_apiKey.isEmpty) {
      AppLogger.warning('GROQ_API_KEY is missing. AI features are disabled.');
      return fallbackMessage;
    }

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'system',
              'content':
                  'You write warm, clear text for a digital time capsule app.',
            },
            {'role': 'user', 'content': prompt},
          ],
          'temperature': temperature,
          'max_tokens': maxTokens,
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        AppLogger.error(
          'Groq API error [${response.statusCode}]: ${response.body}',
        );
        return fallbackMessage;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = body['choices'];
      if (choices is! List || choices.isEmpty) {
        return fallbackMessage;
      }

      final message = choices.first['message'];
      final content = message is Map<String, dynamic>
          ? message['content'] as String?
          : null;

      final text = content?.trim();
      return (text == null || text.isEmpty) ? fallbackMessage : text;
    } catch (e) {
      AppLogger.error('Groq generation failed', e);
      return fallbackMessage;
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

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/app_logger.dart';

class AIService {
  static const String _provider = String.fromEnvironment(
    'AI_PROVIDER',
    defaultValue: 'auto',
  );

  static const String _grokApiUrl = 'https://api.x.ai/v1/chat/completions';
  static const String _groqApiUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  static const String _grokApiKey = String.fromEnvironment('GROK_API_KEY');
  static const String _xaiApiKey = String.fromEnvironment('XAI_API_KEY');
  static const String _groqApiKey = String.fromEnvironment('GROQ_API_KEY');

  static const String _grokModel = String.fromEnvironment(
    'GROK_MODEL',
    defaultValue: 'grok-2-latest',
  );
  static const String _groqModel = String.fromEnvironment(
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
    return _generateText(prompt: prompt, maxTokens: 300, temperature: 0.85);
  }

  /// Enhance existing message with AI improvements
  Future<String> enhanceMessage(String originalMessage) async {
    final prompt =
        '''
Enhance this time capsule message to make it more heartfelt, memorable, and engaging. 
Keep the core sentiment but improve the writing style. Keep it concise (under 200 words).

Original message: "$originalMessage"

Enhanced version:''';

    return _generateText(prompt: prompt, maxTokens: 260, temperature: 0.7);
  }

  /// Generate caption for uploaded images
  Future<String> generateImageCaption(String imageContext) async {
    final prompt =
        '''
Generate a short, creative caption (1-2 sentences) for a photo being added to a time capsule.
Context: $imageContext

Caption:''';

    return _generateText(prompt: prompt, maxTokens: 80, temperature: 0.9);
  }

  Future<String> _generateText({
    required String prompt,
    required int maxTokens,
    required double temperature,
  }) async {
    final endpoint = _resolveEndpoint();

    try {
      final response = await http.post(
        Uri.parse(endpoint.apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${endpoint.apiKey}',
        },
        body: jsonEncode({
          'model': endpoint.model,
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
        final errorMessage = _extractApiErrorMessage(response.body);
        AppLogger.error(
          '${endpoint.providerName} API error [${response.statusCode}]: ${response.body}',
        );
        throw AIServiceException(
          '${endpoint.providerName} request failed (${response.statusCode})${errorMessage == null ? '' : ': $errorMessage'}',
        );
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = body['choices'];
      if (choices is! List || choices.isEmpty) {
        throw AIServiceException(
          '${endpoint.providerName} returned an empty response.',
        );
      }

      final message = choices.first['message'];
      final content = message is Map<String, dynamic>
          ? message['content'] as String?
          : null;

      final text = content?.trim();
      if (text == null || text.isEmpty) {
        throw AIServiceException(
          '${endpoint.providerName} returned no generated text.',
        );
      }

      return text;
    } on AIServiceException {
      rethrow;
    } catch (e) {
      AppLogger.error('AI generation failed', e);
      throw AIServiceException(
        'AI generation failed. Please check your API settings and internet connection.',
      );
    }
  }

  _AIEndpoint _resolveEndpoint() {
    final configuredProvider = _provider.trim().toLowerCase();
    final grokKey = _grokApiKey.isNotEmpty ? _grokApiKey : _xaiApiKey;

    if (configuredProvider == 'grok') {
      if (grokKey.isEmpty) {
        throw AIServiceException(
          'GROK_API_KEY is missing. Rebuild with --dart-define=GROK_API_KEY=your_key',
        );
      }
      return _AIEndpoint(
        providerName: 'Grok',
        apiUrl: _grokApiUrl,
        apiKey: grokKey,
        model: _grokModel,
      );
    }

    if (configuredProvider == 'groq') {
      if (_groqApiKey.isEmpty) {
        throw AIServiceException(
          'GROQ_API_KEY is missing. Rebuild with --dart-define=GROQ_API_KEY=your_key',
        );
      }
      return _AIEndpoint(
        providerName: 'Groq',
        apiUrl: _groqApiUrl,
        apiKey: _groqApiKey,
        model: _groqModel,
      );
    }

    if (grokKey.isNotEmpty) {
      return _AIEndpoint(
        providerName: 'Grok',
        apiUrl: _grokApiUrl,
        apiKey: grokKey,
        model: _grokModel,
      );
    }

    if (_groqApiKey.isNotEmpty) {
      return _AIEndpoint(
        providerName: 'Groq',
        apiUrl: _groqApiUrl,
        apiKey: _groqApiKey,
        model: _groqModel,
      );
    }

    throw AIServiceException(
      'AI is not configured. Add GROK_API_KEY or GROQ_API_KEY with --dart-define.',
    );
  }

  String? _extractApiErrorMessage(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is Map<String, dynamic>) {
          final message = error['message'];
          if (message is String && message.trim().isNotEmpty) {
            return message.trim();
          }
        }
      }
    } catch (_) {
      // Keep null when response is not JSON.
    }

    return null;
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

class _AIEndpoint {
  const _AIEndpoint({
    required this.providerName,
    required this.apiUrl,
    required this.apiKey,
    required this.model,
  });

  final String providerName;
  final String apiUrl;
  final String apiKey;
  final String model;
}

class AIServiceException implements Exception {
  const AIServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

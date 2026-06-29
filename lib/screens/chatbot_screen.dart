import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_styles.dart';
import '../core/services/user_service.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser, required this.timestamp});
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final List<ChatMessage> _messages = [];
  GenerativeModel? _model;
  ChatSession? _chat;

  @override
  void initState() {
    super.initState();
    final profile = UserProfile();
    _messages.add(
      ChatMessage(
        text: "Bonjour ${profile.firstName} ! 👋 Je suis votre Assistant RH IA. Comment puis-je vous aider aujourd'hui ?",
        isUser: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
    );
    _initGemini();
  }

  void _initGemini() {
    const apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: 'AIzaSyA5scstYpphX_-5_-FMrw9rYJ3cz4UHMdA');
    if (apiKey.isNotEmpty) {
      _model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
      );
      
      final systemContext = Content.text("Tu es l'assistant RH de l'application RUThere (dont l'école/bureau se trouve à IAI Cameroun). Réponds toujours de manière polie, professionnelle et concise en français concernant la gestion du temps, des congés et des présences.");
      
      _chat = _model!.startChat(history: [
        Content.model([TextPart("Bonjour, je suis l'assistant RH de RUThere. Comment puis-je vous aider ?")]),
        Content.text("Règles: " + systemContext.parts.first.toString()),
        Content.model([TextPart("Bien reçu. J'agirai en tant qu'assistant RH de RUThere.")]),
      ]);
    }
  }

  bool _isTyping = false;

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userText = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _messages.add(ChatMessage(text: userText, isUser: true, timestamp: DateTime.now()));
      _isTyping = true;
    });
    
    _scrollToBottom();

    if (_chat == null) {
      // Fallback si pas de clé API
      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(
            text: "Désolé, la clé API Gemini n'est pas configurée. Veuillez l'ajouter dans les variables d'environnement (GEMINI_API_KEY).",
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
        _scrollToBottom();
      });
      return;
    }

    try {
      final response = await _chat!.sendMessage(Content.text(userText));
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          text: response.text ?? "Désolé, je n'ai pas pu générer de réponse.",
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          text: _fallbackResponse(userText, e),
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
    }
  }

  String _fallbackResponse(String userText, Object error) {
    final err = error.toString();
    final query = userText.toLowerCase();

    // Surcharge temporaire ou quota dépassé → réponse hors-ligne
    if (err.contains('503') || err.contains('UNAVAILABLE') ||
        err.contains('429') || err.contains('quota') ||
        err.contains('RESOURCE_EXHAUSTED')) {
      if (query.contains('congé') || query.contains('conge') || query.contains('vacance')) {
        return "Pour soumettre une demande de congé, rendez-vous dans l'onglet **Congés** et appuyez sur \"Nouvelle demande\". Votre manager recevra une notification et pourra l'approuver depuis son tableau de bord.";
      } else if (query.contains('pointage') || query.contains('pointer') || query.contains('entrée') || query.contains('sortie')) {
        return "Pour enregistrer votre présence, appuyez sur le bouton central de l'application. Vous devez vous trouver dans un rayon de 500 m autour d'IAI Cameroun pour que le pointage soit validé.";
      } else if (query.contains('statistic') || query.contains('stat') || query.contains('heure')) {
        return "Vos statistiques de présence sont disponibles dans l'onglet **Statistiques**. Vous y trouverez votre historique de pointages et votre taux de présence.";
      } else if (query.contains('solde') || query.contains('jour') || query.contains('droit')) {
        return "Votre solde de congés payés est affiché en haut de l'écran **Congés**. Vous démarrez avec 24 jours par an.";
      }
      return "Je suis temporairement indisponible en raison d'une forte demande. Réessayez dans quelques secondes. En attendant, consultez les onglets **Congés** et **Statistiques** pour vos informations RH.";
    }

    // Erreur réseau
    if (err.contains('SocketException') || err.contains('network') || err.contains('connection')) {
      return "Impossible de contacter l'assistant IA. Vérifiez votre connexion Internet et réessayez.";
    }

    // Erreur générique — ne pas exposer les détails techniques
    return "Une erreur s'est produite. Réessayez dans un instant.";
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC), // Fond très clair et propre
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Assistant IA', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
                Text('En ligne', style: TextStyle(color: Colors.green, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(24),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator().animate().fadeIn();
                }
                final msg = _messages[index];
                return _buildMessageBubble(msg)
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.1, end: 0);
              },
            ),
          ),
          
          // Zone de saisie
          Container(
            padding: const EdgeInsets.all(20).copyWith(bottom: 20 + MediaQuery.of(context).padding.bottom),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F2F5),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Posez votre question...',
                        hintStyle: TextStyle(color: AppColors.textSecondary),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7A3FF3).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: msg.isUser ? const Color(0xFF7A3FF3) : Colors.white,
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: msg.isUser ? const Radius.circular(0) : const Radius.circular(20),
            bottomLeft: msg.isUser ? const Radius.circular(20) : const Radius.circular(0),
          ),
          boxShadow: msg.isUser ? [] : AppStyles.softShadow,
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            color: msg.isUser ? Colors.white : AppColors.textPrimary,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20).copyWith(bottomLeft: const Radius.circular(0)),
          boxShadow: AppStyles.softShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.circle, size: 8, color: AppColors.textSecondary).animate(onPlay: (c) => c.repeat()).fade(duration: 500.ms),
            const SizedBox(width: 4),
            const Icon(Icons.circle, size: 8, color: AppColors.textSecondary).animate(onPlay: (c) => c.repeat()).fade(duration: 500.ms, delay: 200.ms),
            const SizedBox(width: 4),
            const Icon(Icons.circle, size: 8, color: AppColors.textSecondary).animate(onPlay: (c) => c.repeat()).fade(duration: 500.ms, delay: 400.ms),
          ],
        ),
      ),
    );
  }
}

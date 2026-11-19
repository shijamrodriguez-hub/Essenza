import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Declaración simplificada para evitar errores de copiado en los símbolos
  List<dynamic> _messages = [];
  bool _isLoading = false;
  late Box _assistantBox;

  // Reemplaza con tu API Key real de OpenAI
  static const String _apiKey = dotenv.env['AI_API_URL'] ?? '';
  @override
  void initState() {
    super.initState();
    _initHiveAndLoadMessages();
  }

  Future<void> _initHiveAndLoadMessages() async {
    _assistantBox = await Hive.openBox('assistant_box');
    
    final dynamic savedMessages = _assistantBox.get('chat_history');
    if (savedMessages != null && savedMessages is List) {
      setState(() {
        _messages = List<dynamic>.from(savedMessages);
      });
    }
    _scrollToBottom();
  }

  Future<void> _saveMessagesToHive() async {
    await _assistantBox.put('chat_history', _messages);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? customPrompt]) async {
    final text = customPrompt ?? _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    if (customPrompt == null) {
      _controller.clear();
    }

    setState(() {
      _messages.add({'sender': 'user', 'text': text});
      _isLoading = true;
    });
    await _saveMessagesToHive();
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content': 'Eres Essenza IA, un asistente agrónomo experto en sistemas de riego automatizado con ESP32, Bluetooth Low Energy (BLE) y desarrollo en Flutter. '
                         'Responde siempre de forma práctica, técnica, clara y amable a los productores agrícolas. '
                         'Si te preguntan por códigos, errores de compilación o hardware, dales soluciones directas y precisas.'
            },
            {
              'role': 'user',
              'content': '[Contexto del sistema]: El usuario está gestionando su sistema de riego inteligente, usando una app en Flutter conectada por Bluetooth a un ESP32 (llamado ESP32_Riego) y almacenando datos localmente con Hive.\n\n'
                         'Pregunta del usuario: $text',
            },
          ],
          'temperature': 0.3,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final responseText = data['choices'][0]['message']['content']?.trim() ?? 'No se pudo obtener respuesta del asistente.';

        if (mounted) {
          setState(() {
            _messages.add({'sender': 'ai', 'text': responseText});
          });
          await _saveMessagesToHive();
        }
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error']?['message'] ?? 'Error desconocido';
        throw Exception('Error ${response.statusCode}: $errorMessage');
      }
    } catch (e) {
      print('Error detallado de OpenAI: $e');
      if (mounted) {
        setState(() {
          _messages.add({
            'sender': 'ai',
            'text': 'Hubo un error al conectar con el asistente agrícola: $e',
          });
        });
        await _saveMessagesToHive();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _clearChatHistory() async {
    setState(() {
      _messages.clear();
    });
    await _assistantBox.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Historial de chat limpiado.')),
    );
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
      backgroundColor: const Color(0xFFF7FAF5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1B4332),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundImage: AssetImage('assets/images/Avatar_Essenza.png'),
            ),
            const SizedBox(width: 10),
            const Text(
              'Asistente agrícola',
              style: TextStyle(
                color: Color(0xFF1B4332),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: Color(0xFF1B4332)),
            tooltip: 'Borrar historial',
            onPressed: _clearChatHistory,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF165631), Color(0xFF2E7D32)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2E7D32).withOpacity(0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Hola 👋',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  '¿En qué puedo ayudarte hoy?',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Impulsado por GPT-4o-mini (Guardado Offline).',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const CircleAvatar(
                              radius: 36,
                              backgroundImage: AssetImage('assets/images/Avatar_Essenza.png'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_messages.isEmpty) ...[
                      const Text(
                        'Preguntas sugeridas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF183A25),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildSuggestionCard('¿Según los datos registrados, cómo puedo mejorar el riego en ellos?'),
                      _buildSuggestionCard('¿Qué clima se espera para las próximas semanas?'),
                      _buildSuggestionCard('¿Qué puedo implementarle a los cultivos para una próxima cosecha?'),
                      _buildSuggestionCard('¿Cómo puedo solucionar las alertas que tengo en el riego?'),
                    ] else ...[
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index] as Map;
                          final isUser = msg['sender'] == 'user';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (!isUser) ...[
                                  const CircleAvatar(
                                    radius: 14,
                                    backgroundImage: AssetImage('assets/images/Avatar_Essenza.png'),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.70,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isUser ? const Color(0xFF2E7D32) : Colors.white,
                                      borderRadius: BorderRadius.circular(18).copyWith(
                                        bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(18),
                                        bottomLeft: !isUser ? const Radius.circular(0) : const Radius.circular(18),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.03),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      msg['text'] ?? '',
                                      style: TextStyle(
                                        color: isUser ? Colors.white : const Color(0xFF1B4332),
                                        fontSize: 14,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      if (_isLoading)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 14,
                                backgroundImage: AssetImage('assets/images/Avatar_Essenza.png'),
                              ),
                              const SizedBox(width: 8),
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Essenza IA está pensando...',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Escribe tu duda agrícola...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF7FAF5),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: _isLoading ? null : () => _sendMessage(),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        color: Color(0xFF2E7D32),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(String text) {
    return GestureDetector(
      onTap: () => _sendMessage(text),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.chat_bubble_outline_rounded,
              color: Color(0xFF2E7D32),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1B4332),
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
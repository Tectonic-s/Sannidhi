import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import 'package:sannidhi/core/constants/app_theme.dart';

// Replace with your actual Gemini API key
const _kApiKey = 'YOUR_GEMINI_API_KEY';

const _kSystemPrompt = '''
You are "Thunai", a bilingual (Tamil & English) temple assistant for 
Marudamalai Murugan Temple, Coimbatore, Tamil Nadu.

Key facts you know:
- Temple deity: Lord Murugan (Marudamalai Andavar)
- Location: Marudamalai Hill, 15 km from Coimbatore city
- Pambatti Siddhar Cave: Sacred cave on the hill, open 6 AM – 12 PM & 4 PM – 8 PM
- Pooja timings: Thiruvanandal 6:00 AM, Kalasanthi 8:00 AM, Uchikalam 12:00 PM, 
  Sayarakshai 6:00 PM, Ardhajamam 8:30 PM
- Dress code: Traditional attire preferred; men – dhoti/veshti; women – saree/salwar
- Girivalam (hill circumambulation): ~4 km path, best done early morning or evening
- Annadhanam: Free meals served 11:30 AM – 3:00 PM daily at Hilltop Mandapam
- Battery cars: Available for elderly/disabled from Adivaram to hilltop, free of charge
- Shuttle bus: Runs from Main Bus Stand & City Center to Temple Entrance, ₹50–₹75
- Special darshan: ₹50 for priority queue; VIP Abhishekam: ₹250
- 80G tax exemption available on all trust donations
- Trust registration: Marudamalai Devasthanam Trust, PAN: AAATM1234F (demo)
- Emergency: Temple police 0422-2690100, First-aid post near Adivaram entrance

Answer concisely. If asked in Tamil, reply in Tamil. If in English, reply in English.
Keep answers under 100 words unless a detailed explanation is requested.
''';

class AiAssistantDialog extends StatefulWidget {
  final bool isTamil;
  const AiAssistantDialog({super.key, this.isTamil = false});

  @override
  State<AiAssistantDialog> createState() => _AiAssistantDialogState();
}

class _AiAssistantDialogState extends State<AiAssistantDialog> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_Message> _messages = [];
  bool _loading = false;
  late final GenerativeModel _model;
  late final ChatSession _chat;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _kApiKey,
      systemInstruction: Content.system(_kSystemPrompt),
    );
    _chat = _model.startChat();
    _messages.add(_Message(
      text: widget.isTamil
          ? 'வணக்கம்! மருதமலை முருகன் கோயில் பற்றி என்னவேணுமானாலும் கேளுங்கள் — பூஜை நேரம், தரிசனம், வசதிகள் அல்லது வழிகாட்டல். 🙏'
          : 'Vanakkam! 🙏 I am Thunai. Ask me anything about Marudamalai Temple — timings, darshan, facilities, or directions.',
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;
    _controller.clear();
    setState(() {
      _messages.add(_Message(text: text, isUser: true));
      _loading = true;
    });
    _scrollToBottom();

    try {
      final response = await _chat.sendMessage(Content.text(text));
      final reply = response.text ?? 'Sorry, I could not process that.';
      setState(() {
        _messages.add(_Message(text: reply, isUser: false));
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _messages.add(_Message(
          text: widget.isTamil
              ? 'இணைப்பு கிடைக்கவில்லை. உங்கள் இணைய இணைப்பை சரிபார்த்து மீண்டும் முயற்சிக்கவும்.'
              : 'Unable to connect. Please check your internet connection and try again.',
          isUser: false,
        ));
        _loading = false;
      });
    }
    _scrollToBottom();
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
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            _header(),
            Expanded(child: _messageList()),
            if (_loading) _typingIndicator(),
            _inputBar(),
          ],
        ),
      ),
    );
  }

  Widget _header() => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
        decoration: const BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.accentColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.auto_awesome,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Thunai',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                Text('AI கோயில் உதவியாளர்',
                    style:
                        TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );

  Widget _messageList() => ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _messages.length,
        itemBuilder: (_, i) => _MessageBubble(message: _messages[i]),
      );

  Widget _typingIndicator() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            const _TypingDot(delay: 0),
            const SizedBox(width: 4),
            const _TypingDot(delay: 200),
            const SizedBox(width: 4),
            const _TypingDot(delay: 400),
            const SizedBox(width: 8),
            Text(widget.isTamil ? 'சிந்திக்கிறேன்…' : 'Thinking…',
                style:
                    const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
      );

  Widget _inputBar() => Container(
        padding: EdgeInsets.fromLTRB(
            16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: widget.isTamil
                      ? 'பூஜை நேரம், தரிசனம், வசதிகள் பற்றி கேளுங்கள்…'
                      : 'Ask about timings, darshan, facilities…',
                  hintStyle: const TextStyle(fontSize: 13),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                        color: AppTheme.primaryColor, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _loading
                      ? Colors.grey.shade300
                      : AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      );
}

class _Message {
  final String text;
  final bool isUser;

  const _Message({required this.text, required this.isUser});
}

class _MessageBubble extends StatelessWidget {
  final _Message message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment:
          message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: message.isUser
              ? AppTheme.primaryColor
              : Colors.grey.shade100,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isUser ? 16 : 4),
            bottomRight: Radius.circular(message.isUser ? 4 : 16),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            fontSize: 13,
            color: message.isUser ? Colors.white : AppTheme.textPrimary,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _TypingDot extends StatefulWidget {
  final int delay;

  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppTheme.primaryColor,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

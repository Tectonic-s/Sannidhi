import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sannidhi/core/constants/api_keys.dart';
import 'package:sannidhi/core/constants/app_theme.dart';
import 'package:sannidhi/core/widgets/micro_animations.dart';
import 'package:sannidhi/data/repositories/mock_crowd_repository.dart';
import 'package:sannidhi/data/services/temple_knowledge_base.dart';

const _kDartDefineApiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

class AiAssistantDialog extends StatefulWidget {
  final bool isTamil;
  final MockCrowdRepository? crowdRepository;

  const AiAssistantDialog({
    super.key,
    this.isTamil = false,
    this.crowdRepository,
  });

  @override
  State<AiAssistantDialog> createState() => _AiAssistantDialogState();
}

class _AiAssistantDialogState extends State<AiAssistantDialog> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_Message> _messages = [];
  bool _loading = false;
  String _activeApiKey = '';
  GenerativeModel? _model;
  ChatSession? _chat;
  late final MockCrowdRepository _crowdRepo;

  @override
  void initState() {
    super.initState();
    _crowdRepo = widget.crowdRepository ?? MockCrowdRepository();
    _initGemini();
    _messages.add(_Message(
      text: widget.isTamil
          ? 'வணக்கம்! 🙏 நான் துணை (Thunai AI). மருதமலை முருகன் கோயில் பற்றி என்னவேணுமானாலும் கேளுங்கள் — திருவிழாக்கள் ஏன் சிறப்பு வாய்ந்தது, பூஜை நேரம், கூட்ட நிலவரம், குடும்ப செலவு கணக்கீடு, அல்லது கோயில் வசதிகள்.'
          : 'Vanakkam! 🙏 I am Thunai, your AI temple companion for Marudamalai. Ask me anything — why festivals are celebrated, mythological lore, visit costs for your family, pooja timings, live crowds, or facilities.',
      isUser: false,
    ));
  }

  Future<void> _initGemini() async {
    final prefs = await SharedPreferences.getInstance();
    final savedKey = (prefs.getString('gemini_api_key') ?? '').trim();
    final codeKey = ApiKeys.geminiApiKey.trim();

    // Priority: Saved user key -> Git-ignored ApiKeys.geminiApiKey -> dart-define
    String key = '';
    if (savedKey.isNotEmpty) {
      key = savedKey;
    } else if (codeKey.isNotEmpty &&
        codeKey != 'YOUR_GEMINI_API_KEY_HERE' &&
        codeKey != 'PASTE_YOUR_GEMINI_API_KEY_HERE') {
      key = codeKey;
    } else if (_kDartDefineApiKey.isNotEmpty) {
      key = _kDartDefineApiKey;
    }

    setState(() {
      _activeApiKey = key;
    });

    if (key.isNotEmpty) {
      try {
        _model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: key,
          systemInstruction: Content.system(
            TempleKnowledgeBase.buildComprehensiveSystemPrompt(crowdRepo: _crowdRepo),
          ),
        );
        _chat = _model!.startChat();
      } catch (e) {
        debugPrint('[THUNAI AI] Model init error: $e');
        _model = null;
        _chat = null;
      }
    } else {
      _model = null;
      _chat = null;
    }
  }

  void _restartChat() {
    setState(() {
      _messages.clear();
      _messages.add(_Message(
        text: widget.isTamil
            ? 'வணக்கம்! 🙏 நான் துணை (Thunai AI). மருதமலை முருகன் கோயில் பற்றி என்னவேணுமானாலும் கேளுங்கள் — திருவிழாக்கள் ஏன் சிறப்பு வாய்ந்தது, பூஜை நேரம், கூட்ட நிலவரம், குடும்ப செலவு கணக்கீடு, அல்லது கோயில் வசதிகள்.'
            : 'Vanakkam! 🙏 I am Thunai, your AI temple companion for Marudamalai. Ask me anything — why festivals are celebrated, mythological lore, visit costs for your family, pooja timings, live crowds, or facilities.',
        isUser: false,
      ));
      _loading = false;
    });
    if (_model != null) {
      _chat = _model!.startChat();
    }
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

    // 0. Fast-path: Greetings and identity queries should NEVER trigger verbose festival lore or network delays
    final cleanInput = text.trim().toLowerCase().replaceAll(RegExp(r'[^\w\s\u0B80-\u0BFF]'), '');
    final inputWords = cleanInput.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    const greetingSet = {'hi', 'hello', 'hey', 'vanakkam', 'வணக்கம்'};
    final isQuickGreeting = inputWords.isNotEmpty &&
        inputWords.length <= 3 &&
        inputWords.any((w) => greetingSet.contains(w)) &&
        !cleanInput.contains('when') &&
        !cleanInput.contains('festival') &&
        !cleanInput.contains('pooja') &&
        !cleanInput.contains('cost') &&
        !cleanInput.contains('timing') &&
        !cleanInput.contains('எப்போது') &&
        !cleanInput.contains('திருவிழா') &&
        !cleanInput.contains('பூஜை');

    final isQuickIdentity = cleanInput == 'who are you' ||
        cleanInput.contains('who are you') ||
        cleanInput.contains('who created you') ||
        cleanInput.contains('யார் நீ') ||
        cleanInput.contains('உன் பெயர்') ||
        cleanInput.contains('what is thunai') ||
        cleanInput.contains('what can you do');

    if (isQuickGreeting || isQuickIdentity) {
      await Future.delayed(const Duration(milliseconds: 250));
      final greetingReply = _matchLocalTempleKnowledge(text);
      if (mounted) {
        setState(() {
          _messages.add(_Message(text: greetingReply, isUser: false));
          _loading = false;
        });
      }
      _scrollToBottom();
      return;
    }

    // 1. If Gemini AI is active and configured, query Gemini
    if (_chat != null) {
      try {
        final response = await _chat!.sendMessage(Content.text(text));
        final reply = response.text;
        if (reply != null && reply.trim().isNotEmpty) {
          if (mounted) {
            setState(() {
              _messages.add(_Message(text: reply.trim(), isUser: false));
              _loading = false;
            });
          }
          _scrollToBottom();
          return;
        }
      } catch (e) {
        debugPrint('[THUNAI AI ERROR] $e');
        // Gracefully fallback to intelligent on-device engine
      }
    }

    // 2. State-of-the-art On-Device Temple Intelligence Engine
    await Future.delayed(const Duration(milliseconds: 350));
    final fallbackReply = _matchLocalTempleKnowledge(text);
    if (mounted) {
      setState(() {
        _messages.add(_Message(text: fallbackReply, isUser: false));
        _loading = false;
      });
    }
    _scrollToBottom();
  }

  String _matchLocalTempleKnowledge(String query) {
    final q = query.toLowerCase();
    final isTamil = widget.isTamil || _containsTamil(query);
    final now = DateTime.now();

    // ─── 00. Warm Greetings & Conversational Identity (Highest Priority) ─────
    final cleanPunct = q.replaceAll(RegExp(r'[^\w\s\u0B80-\u0BFF]'), ' ').trim();
    final words = cleanPunct.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

    const greetingWords = {'hi', 'hello', 'hey', 'vanakkam', 'வணக்கம்'};
    final isJustGreeting = words.isNotEmpty &&
        words.length <= 3 &&
        words.any((w) => greetingWords.contains(w)) &&
        !q.contains('when') &&
        !q.contains('date') &&
        !q.contains('festival') &&
        !q.contains('pooja') &&
        !q.contains('cost') &&
        !q.contains('timing') &&
        !q.contains('எப்போது') &&
        !q.contains('திருவிழா') &&
        !q.contains('பூஜை');

    final isIdentityQuery = q == 'who are you' ||
        q.contains('who are you') ||
        q.contains('who created you') ||
        q.contains('யார் நீ') ||
        q.contains('உன் பெயர்') ||
        q.contains('what is thunai') ||
        q.contains('what can you do');

    if (isJustGreeting || isIdentityQuery) {
      if (isTamil) {
        return 'வணக்கம்! 🙏 நான் துணை AI (Thunai) — மருதமலை அருள்மிகு சுப்பிரமணியசுவாமி திருக்கோயிலின் அதிகாரப்பூர்வ டிஜிட்டல் வழிகாட்டி.\n\n'
            'நான் உங்களுக்கு எவ்வாறு உதவ முடியும்? என்னிடம் நீங்கள் கேட்கலாம்:\n'
            '• ⏰ "கோயில் பூஜை நேரங்கள் & நடை திறக்கும் நேரம்?" (5 கால பூஜைகள்)\n'
            '• 🎟️ "விரைவு தரிசன பாஸ் & குடும்ப தரிசன செலவு எவ்வளவு?"\n'
            '• 🍚 "இலவச அன்னதானம் நேரம் & இடம்?" (11:30 AM – 3:00 PM)\n'
            '• 🏍️ "மாலை 5 மணிக்கு மேல் பைக் போகலாமா?" (இருசக்கர வாகன பாதுகாப்பு விதி)\n'
            '• 🚌 "மின்சார பேருந்து மற்றும் பேட்டரி கார் வசதிகள்?"\n'
            '• 🪔 "மாலை 6 மணி சிறப்பு பாராயணம் எங்கு நடக்கும்?"\n\n'
            'உங்கள் கேள்வியை தட்டச்சு செய்யவும் அல்லது கீழே உள்ள குறிப்புகளைத் தொடவும்!';
      } else {
        return 'Vanakkam! 🙏 I am Thunai AI — your dedicated bilingual companion for Arulmigu Subramaniyaswami Temple, Marudamalai.\n\n'
            'How can I help you today? Here are some popular questions you can ask me:\n'
            '• ⏰ "What are the pooja and darshan timings?" (5 Kaalam schedule)\n'
            '• 🎟️ "How much does a quick visit cost for a family of 4?" (Pass arithmetic)\n'
            '• 🍚 "When and where is free Annadhanam served?" (11:30 AM – 3:00 PM)\n'
            '• 🏍️ "Are two-wheelers allowed to the hilltop after 5 PM?" (Safety rule)\n'
            '• 🚌 "How does the hilltop electric bus & senior buggy operate?"\n'
            '• 🪔 "Tell me about the special recitations at 6 PM" (Daily parayanam)\n\n'
            'Feel free to type any query or tap one of the suggestion chips below!';
      }
    }

    // ─── 0A. Two-Wheeler Hilltop 5:00 PM Safety Restriction Rule ──────────────
    if ((q.contains('wheeler') ||
            q.contains('bike') ||
            q.contains('two wheeler') ||
            q.contains('2 wheeler') ||
            q.contains('motorcycle') ||
            q.contains('scooter') ||
            q.contains('பைக்') ||
            q.contains('இருசக்கர') ||
            q.contains('வாகனம்')) &&
        (q.contains('5') ||
            q.contains('top') ||
            q.contains('hill') ||
            q.contains('travel') ||
            q.contains('allow') ||
            q.contains('rule') ||
            q.contains('safety') ||
            q.contains('அனுமதி') ||
            q.contains('பாதுகாப்பு') ||
            q.contains('செல்லலாமா') ||
            q.contains('மலை'))) {
      if (isTamil) {
        return '⚠️ இருசக்கர வாகன மலைப்பாதை பாதுகாப்பு விதிமுறை (Safety Regulation):\n\n'
            '• முக்கிய விதி: பக்தர்கள் பாதுகாப்பு கருதி, மாலை 5:00 மணிக்கு மேல் இருசக்கர வாகனங்கள் (பைக், ஸ்கூட்டர்) மலைப்பாதையில் மேலே செல்ல அனுமதி இல்லை.\n'
            '• காரணம்: கொண்டை ஊசி வளைவுகள், மாலையில் மங்கும் வெளிச்சம் மற்றும் அடர்ந்த வனப்பகுதியில் வனவிலங்குகள் நடமாட்டம் ஆகியவற்றால் விபத்துகளைத் தவிர்க்க இந்த விதி அமலில் உள்ளது.\n'
            '• மாற்று வழி: மாலை 5:00 மணிக்கு மேல் வரும் பக்தர்கள் தங்கள் வாகனங்களை அடிவாரம் பிரதான பார்க்கிங்கில் நிறுத்திவிட்டு, கோயில் மின்சார பேருந்து (₹20) மூலமாகவோ அல்லது 830 படிகள் வழியாகவோ மலை உச்சிக்கு செல்லலாம்.\n'
            '• பகல் நேர அனுமதி: காலை 6:00 மணி முதல் மாலை 5:00 மணி வரை மட்டுமே தலைக்கவசம் (ஹெல்மெட்) அணிந்து செல்ல அனுமதிக்கப்படும்.';
      } else {
        return '⚠️ Two-Wheeler Hilltop Travel Restriction (Safety Regulation):\n\n'
            '• Strict Rule: For safety purposes, two-wheelers are strictly NOT allowed for travel to the hilltop after 5:00 PM.\n'
            '• Reason: Sharp hairpin ghat curves, declining visibility after dusk, and wildlife movements near the reserve forest.\n'
            '• Alternative: Devotees arriving after 5:00 PM can safely park at the Adivaram main parking terminal and take the temple electric shuttle buses (₹20 per passenger) or climb the illuminated 830 stone steps.\n'
            '• Daytime Access: Two-wheelers are allowed between 6:00 AM and 5:00 PM only, with mandatory helmets.';
      }
    }

    // ─── 0B. Daily 6:00 PM Special Recitations (Parayanam) ─────────────────────
    if ((q.contains('recitation') ||
            q.contains('parayanam') ||
            q.contains('chant') ||
            q.contains('kavasam') ||
            q.contains('kanda sashti') ||
            q.contains('பாராயணம்') ||
            q.contains('கவசம்') ||
            q.contains('பாடல்')) &&
        (q.contains('6') ||
            q.contains('time') ||
            q.contains('daily') ||
            q.contains('everyday') ||
            q.contains('special') ||
            q.contains('நேரம்') ||
            q.contains('சிறப்பு') ||
            q.contains('மாலையில்'))) {
      if (isTamil) {
        return '🪔 திருக்கோயில் தினசரி சிறப்பு கூட்டுப் பாராயணம் (மாலை 6:00 மணி):\n\n'
            '• நேரம்: தினமும் மாலை 6:00 மணிக்கு கோயில் மகா மண்டபத்தில் சிறப்பு கூட்டுப் பாராயணம் நடைபெறும்.\n'
            '• பாராயண நூல்கள்: கந்த சஷ்டி கவசம், சண்முக கவசம், திருப்புகழ் மற்றும் போற்றி பாடல்கள் பக்தர்கள் அனைவரும் ஒன்றுகூடி பக்தியுடன் பாராயணம் செய்கின்றனர்.\n'
            '• சாயரட்சை தீபாராதனை: மாலை 6:00 மணி சாயரட்சை பூஜையுடன் இணைந்து தீப அலங்காரத்துடன் இந்த பாராயணம் நடப்பதால் ஆன்மீக அதிர்வுகள் நிறைந்திருக்கும்.\n'
            '• அனுமதி: அனைத்து பக்தர்களும் இலவசமாக இதில் கலந்து கொண்டு முருகப்பெருமானின் அருள் பெறலாம்.';
      } else {
        return '🪔 Temple Daily Special Recitations & Sacred Parayanam (6:00 PM):\n\n'
            '• Schedule: Special community recitations take place everyday at 6:00 PM in the temple Maha Mandapam.\n'
            '• Sacred Chants: Devotees congregate to chant Sri Kanda Sashti Kavasam, Shanmuga Kavasam, Thiruppugazh hymns, and Murugan Potri.\n'
            '• Sunset Synergy: Synchronized with the grand evening Sayarakshai Deeparadhana illumination, filling the hilltop with divine vibrations.\n'
            '• Open Participation: Free and warmly open to all visiting pilgrims and families.';
      }
    }



    // ─── 0D. How to Reach Marudamalai / Route & Directions ────────────────────
    if (q.contains('how to reach') ||
        q.contains('how to go') ||
        q.contains('route') ||
        q.contains('direction') ||
        q.contains('distance') ||
        q.contains('airport') ||
        q.contains('railway') ||
        q.contains('எப்படி செல்வது') ||
        q.contains('வழி') ||
        q.contains('தூரம்')) {
      if (isTamil) {
        return '🗺️ மருதமலை திருக்கோயிலுக்கு செல்லும் வழிகள் (Travel Guide):\n\n'
            '• கோவை காந்திபுரம் மத்திய பேருந்து நிலையம்: ~13 கி.மீ (நகர பேருந்து தடம் 70, 70A ஒவ்வொரு 10 நிமிடத்திற்கும் புறப்படும்; கட்டணம் ~₹15-₹20).\n'
            '• கோவை ரயில்வே சந்திப்பு (Coimbatore Junction): ~14 கி.மீ (பேருந்து தடம் 70 அல்லது டாக்ஸி/ஆட்டோ மூலம் 30-40 நிமிட பயணம்).\n'
            '• கோவை உக்கடம் பேருந்து நிலையம்: ~15 கி.மீ (வடவள்ளி வழியாக நேரடி பேருந்துகள்).\n'
            '• கோவை சர்வதேச விமான நிலையம் (CJB): ~25 கி.மீ (அவிநாசி சாலை & தொண்டாமுத்தூர் வழி, டாக்ஸியில் ~45 நிமிடங்கள்).\n'
            '• அடிவாரம் வளைவில் இருந்து மலை உச்சிக்கு கோயில் மின்சார பேருந்து (₹20) அல்லது 830 படிகள் வழி நடைபயணம்.';
      } else {
        return '🗺️ How to Reach Marudamalai Temple (Travel & Directions):\n\n'
            '• From Gandhipuram Central Bus Stand: ~13 km (Direct City Buses 70 & 70A depart every 10 mins; fare ~₹15–₹20).\n'
            '• From Coimbatore Junction Railway Station (CBE): ~14 km (~30–40 mins ride via city bus 70 or cab/auto).\n'
            '• From Ukkadam Bus Stand: ~15 km (Direct buses via Vadavalli route).\n'
            '• From Coimbatore International Airport (CJB): ~25 km (~45 mins taxi ride via Avinashi Road & Vadavalli).\n'
            '• Adivaram to Hilltop Sanctum: Temple electric shuttle buses (₹20 per person) run every 15 mins, or climb the 830 scenic stone steps.';
      }
    }

    // ─── 0E. Offerings: Prasadam, Tonsure (Mottai), Ear-Piercing ─────────────
    if (q.contains('prasadam') ||
        q.contains('mottai') ||
        q.contains('tonsure') ||
        q.contains('hair') ||
        q.contains('ear piercing') ||
        q.contains('kaadhu') ||
        q.contains('பிரசாதம்') ||
        q.contains('மொட்டை') ||
        q.contains('காது')) {
      if (isTamil) {
        return '🪔 திருக்கோயில் பிரசாதம் & நேர்த்திக்கடன் விபரம்:\n\n'
            '• பஞ்சாமிர்தம்: ₹40 (மருதமலை சிறப்பு மூலிகைக் கலவை பஞ்சாமிர்த பாட்டில்)\n'
            '• திருப்பதி லட்டு (2 எண்ணிக்கை): ₹20\n'
            '• புளியோதரை & சர்க்கரைப் பொங்கல்: தலா ₹30\n'
            '• முடி காணிக்கை (மொட்டை): அடிவாரம் படி 1 அருகில் உள்ள மொட்டை மண்டபத்தில் காலை 6:00 முதல் மாலை 5:00 வரை (டோக்கன் ₹30).\n'
            '• காது குத்துதல்: கோயில் பாரம்பரிய மண்டபத்தில் தினமும் நடைபெறும்.';
      } else {
        return '🪔 Temple Prasadam Stalls & Devotional Offerings:\n\n'
            '• Panchamirtham Bottle: ₹40 (Specially prepared herbal recipe unique to Marudamalai Murugan)\n'
            '• Temple Laddu (pack of 2): ₹20\n'
            '• Puliyodharai (Tamarind Rice) / Sakkarai Pongal: ₹30 each\n'
            '• Tonsure / Hair Offering (Mottai): Dedicated tonsure hall at Adivaram near Step 1, open 6:00 AM – 5:00 PM (Token ₹30).\n'
            '• Ear Piercing (Kaadhu Kuthal): Traditional hall available daily for infant blessings.';
      }
    }

    // ─── 0F. Rules: Photography, Mobile Phones, Luggage & Footwear ───────────
    if (q.contains('camera') ||
        q.contains('photo') ||
        q.contains('phone') ||
        q.contains('mobile') ||
        q.contains('luggage') ||
        q.contains('cloakroom') ||
        q.contains('locker') ||
        q.contains('footwear') ||
        q.contains('chappal') ||
        q.contains('புகைப்படம்') ||
        q.contains('காலணி') ||
        q.contains('செருப்பு')) {
      if (isTamil) {
        return '📋 கோயில் விதிமுறைகள் & வசதிகள்:\n\n'
            '• புகைப்படம் & செல்போன்: கோயில் பிரகாரத்தில் செல்போன் அனுமதிக்கப்படும்; ஆனால் கருவறை மற்றும் மூலவர் சன்னதிக்குள் புகைப்படம் எடுக்க கடுமையான தடை உண்டு.\n'
            '• காலணி வைப்பகம்: அடிவாரம் மற்றும் மலை உச்சி நுழைவாயிலில் இலவச காலணி வைப்பு மையம் (Free Footwear Counter) உள்ளது.\n'
            '• உடைமைப் பாதுகாப்பு (Cloakroom): அடிவாரம் தகவல் மையம் அருகே பேக்குகள் மற்றும் உடைமைகளுக்கான லாக்கர் வசதி உண்டு.\n'
            '• தூய்மை: மலைப்பாதை முழுவதும் பிளாஸ்டிக் பயன்பாடு தடை செய்யப்பட்டுள்ளது; குப்பைகளை குப்பைத்தொட்டியில் மட்டுமே போடவும்.';
      } else {
        return '📋 Temple Regulations & Essential Conveniences:\n\n'
            '• Photography & Mobiles: Mobile phones are permitted in the outer courtyard, but photography is STRICTLY prohibited inside the inner sanctum.\n'
            '• Free Footwear Stand: Safe shoe/chappal drop counters are available at both Adivaram and the Hilltop entrance (100% Free).\n'
            '• Luggage Cloakroom & Lockers: Available near the Adivaram Help Desk for pilgrims traveling with heavy backpacks and bags.\n'
            '• Eco-Zone: Marudamalai is a zero-plastic sacred zone. Please use dedicated trash bins along the steps.';
      }
    }

    // ─── 1. Group / Family Cost & Visit Math Guidance ─────────────────────────
    final numMatch = RegExp(
      r'(?:family of|group of|for|cost for|visit for|குடும்பம்|நபர்கள்)\s*(\d+)|(\d+)\s*(?:people|persons|members|devotees|family|நபர்கள்|பேர்|பேருக்கு)',
    ).firstMatch(q);

    int groupSize = 0;
    if (numMatch != null) {
      final rawNum = numMatch.group(1) ?? numMatch.group(2);
      if (rawNum != null) {
        groupSize = int.tryParse(rawNum) ?? 0;
      }
    }
    if (groupSize == 0 &&
        (q.contains('cost') ||
            q.contains('price') ||
            q.contains('visit') ||
            q.contains('family') ||
            q.contains('செலவு') ||
            q.contains('கட்டணம்'))) {
      final standaloneMatch = RegExp(r'\b(\d{1,3})\b').firstMatch(q);
      if (standaloneMatch != null) {
        final val = int.tryParse(standaloneMatch.group(1) ?? '0') ?? 0;
        if (val > 1 && val <= 100) {
          groupSize = val;
        }
      }
    }

    if (groupSize > 0 &&
        (q.contains('cost') ||
            q.contains('much') ||
            q.contains('quick') ||
            q.contains('visit') ||
            q.contains('family') ||
            q.contains('ticket') ||
            q.contains('pass') ||
            q.contains('விலை') ||
            q.contains('செலவு') ||
            q.contains('கட்டணம்') ||
            q.contains('விரைவு'))) {
      final n = groupSize;
      final specialTickets = n * 50;
      final busTotal = n * 20;
      final quickTotal = specialTickets + busTotal;
      final vipTickets = n * 250;
      final vipTotal = vipTickets + busTotal;

      if (isTamil) {
        return '🏛️ $n பேர் கொண்ட குடும்பத்திற்கு மருதமலை தரிசன செலவு விபரம்:\n\n'
            '⚡ 1. விரைவு தரிசனம் (பரிந்துரைக்கப்படுவது):\n'
            '• சிறப்பு தரிசன டிக்கெட் ($n × ₹50): ₹$specialTickets\n'
            '• மின்சார பேருந்து கட்டணம் ($n × ₹20): ₹$busTotal\n'
            '• மொத்தம்: ₹$quickTotal (மதிப்பிடப்பட்ட நேரம்: ~25-35 நிமிடம்)\n\n'
            '👑 2. வி.ஐ.பி தரிசனம் (நேரடி அனுமதி):\n'
            '• வி.ஐ.பி பாஸ் ($n × ₹250): ₹$vipTickets\n'
            '• மின்சார பேருந்து ($n × ₹20): ₹$busTotal\n'
            '• மொத்தம்: ₹$vipTotal (நேரம்: < 15 நிமிடம், சிறப்பு அபிஷேகம் & பஞ்சாமிர்தம்)\n\n'
            '🌿 3. பொது / இலவச தரிசனம்:\n'
            '• பொது தரிசனம்: ₹0 (இலவசம்)\n'
            '• மின்சார பேருந்து: ₹$busTotal (அல்லது 830 படிகள் வழி நடந்தால் ₹0)\n'
            '• மொத்தம்: ₹$busTotal (நேரம்: ~60-90 நிமிடம்)\n\n'
            '💡 விவேகமான வழிகாட்டல்:\n'
            '• 60+ வயது முதியோர்கள் மற்றும் மாற்றுத்திறனாளிகளுக்கு அடிவாரத்திலிருந்து பேட்டரி கார் 100% இலவசம்!\n'
            '• கூட்ட நெரிசலைத் தவிர்க்க செயலியில் "Bookings" பகுதியில் 7 நாட்களுக்கு முன்பே பாஸ்களை முன்பதிவு செய்யலாம்.\n'
            '• காலை 8:30 மணிக்கு முன் சென்றால் மலை மீது அமைதியான தரிசனம் கிடைக்கும்.';
      } else {
        return '🏛️ Visit Cost Estimation for a family of $n to Marudamalai Temple:\n\n'
            '⚡ 1. Recommended Quick Visit (Special Priority):\n'
            '• Special Darshan Pass ($n × ₹50): ₹$specialTickets\n'
            '• Electric Bus ($n × ₹20): ₹$busTotal\n'
            '• Total Cost: ₹$quickTotal (Est. queue wait: ~25–35 mins)\n\n'
            '👑 2. VIP Direct Access Visit:\n'
            '• VIP Darshan Pass ($n × ₹250): ₹$vipTickets\n'
            '• Electric Bus ($n × ₹20): ₹$busTotal\n'
            '• Total Cost: ₹$vipTotal (Wait: < 15 mins, includes Panchamirtham prasad)\n\n'
            '🌿 3. Budget / Free Darshan Visit:\n'
            '• General Darshan: Free (₹0)\n'
            '• Electric Bus ($n × ₹20): ₹$busTotal (or ₹0 if climbing the 830 steps)\n'
            '• Total Cost: ₹$busTotal (Est. time: ~60–90 mins)\n\n'
            '💡 Thoughtful Pilgrim Tips:\n'
            '• Senior citizens (60+) and differently-abled pilgrims ride free battery buggy cars!\n'
            '• You can book passes up to 7 days ahead in the app\'s "Bookings" tab.\n'
            '• Arriving before 8:30 AM ensures fresh hilltop breeze and quick sanctum entry.';
      }
    }

    // ─── 2. Rich Festival Intelligence (Significance, Lore & Dates) ───────────
    final isAskingWhySpecial = q.contains('why') ||
        q.contains('special') ||
        q.contains('significance') ||
        q.contains('important') ||
        q.contains('story') ||
        q.contains('legend') ||
        q.contains('meaning') ||
        q.contains('celebrat') ||
        q.contains('history') ||
        q.contains('ஏன்') ||
        q.contains('சிறப்பு') ||
        q.contains('முக்கியத்துவம்') ||
        q.contains('வரலாறு') ||
        q.contains('கதை') ||
        q.contains('தத்துவம்');

    final isAskingWhen = q.contains('when') ||
        q.contains('date') ||
        q.contains('which day') ||
        q.contains('calendar') ||
        q.contains('day') ||
        q.contains('எப்போது') ||
        q.contains('நாள்') ||
        q.contains('தேதி') ||
        q.contains('கிழமை');

    const genericWords = {
      'pooja',
      'festival',
      'darshan',
      'temple',
      'start',
      'day',
      'பூஜை',
      'திருவிழா',
      'தரிசனம்',
      'தொடக்கம்',
      'பண்டிகை',
    };

    FestivalLore? bestFestival;
    int bestScore = 0;

    for (final fest in TempleKnowledgeBase.festivalsLore) {
      final nameLower = fest.nameEn.toLowerCase();
      final tamilLower = fest.nameTa.toLowerCase();

      final rawWords = [
        nameLower,
        tamilLower,
        ...nameLower.split(RegExp(r'[\s\(\)&]+')),
        ...tamilLower.split(RegExp(r'[\s\(\)&]+')),
      ].where((k) => k.length >= 4 && !genericWords.contains(k)).toList();

      final festKeywords = <String>{...rawWords};
      for (final w in rawWords) {
        if (w.length >= 5) {
          festKeywords.add(w.substring(0, w.length - 1));
        }
      }

      for (final kw in festKeywords) {
        final matches = q.contains(kw);
        if (matches && kw.length > bestScore) {
          bestScore = kw.length;
          bestFestival = fest;
        }
      }
    }

    if (bestFestival != null) {
      final fest = bestFestival;
      final fDate = DateTime.tryParse(fest.date) ?? now;
      final diff = fDate.difference(DateTime(now.year, now.month, now.day)).inDays;
      final countdownEn = diff == 0 ? 'Today!' : (diff == 1 ? 'Tomorrow!' : 'in $diff days');
      final countdownTa = diff == 0 ? 'இன்று!' : (diff == 1 ? 'நாளை!' : 'இன்னும் $diff நாட்களில்');

      // Check weekday
      const enWeekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      const taWeekdays = ['திங்கள்', 'செவ்வாய்', 'புதன்', 'வியாழன்', 'வெள்ளி', 'சனி', 'ஞாயிறு'];
      final dayIndex = fDate.weekday - 1;
      final dayEn = enWeekdays[dayIndex];
      final dayTa = taWeekdays[dayIndex];

      // If devotee specifically asked why it is special or for spiritual meaning
      if (isAskingWhySpecial) {
        if (isTamil) {
          return '🪔 ${fest.nameTa} (${fest.nameEn}) ஏன் இவ்வளவு சிறப்பு வாய்ந்தது?:\n\n'
              '✨ ஆன்மீக தத்துவமும் புராணச் சிறப்பும்:\n'
              '${fest.whySpecialTa}\n\n'
              '🌟 மருதமலையில் நடைபெறும் விசேஷ வழிபாடுகள்:\n'
              '${fest.ritualsTa}\n\n'
              '💡 பக்தர்களுக்கான தரிசன வழிகாட்டல்:\n'
              '${fest.devoteeTipsTa}\n\n'
              '📅 திருநாள் தேதி: ${fest.date} ($countdownTa, $dayTa, ${fest.tamilMonth} மாதம், ${fest.nakshatra} நட்சத்திரம்)';
        } else {
          return '🪔 Why ${fest.nameEn} (${fest.nameTa}) is Revered & Special:\n\n'
              '✨ Spiritual Significance & Sacred Lore:\n'
              '${fest.whySpecialEn}\n\n'
              '🌟 Special Observances at Marudamalai:\n'
              '${fest.ritualsEn}\n\n'
              '💡 Practical Pilgrim Tips:\n'
              '${fest.devoteeTipsEn}\n\n'
              '📅 Festival Date: ${fest.date} ($countdownEn, $dayEn • Tamil Month: ${fest.tamilMonth}, Star: ${fest.nakshatra})';
        }
      }

      // If devotee asked when it is or for date
      if (isAskingWhen) {
        if (isTamil) {
          return '🪔 ${fest.nameTa} (${fest.nameEn}):\n\n'
              '• நாள்: ${fest.date} ($countdownTa, $dayTa)\n'
              '• தமிழ் மாதம்: ${fest.tamilMonth} • நட்சத்திரம்: ${fest.nakshatra}\n'
              '• சுருக்க விபரம்: ${fest.oneLinerTa}\n'
              '• முக்கிய வழிபாடு: ${fest.ritualsTa}\n\n'
              '💡 "${fest.nameTa} ஏன் சிறப்பு?" என்று கேட்டால் இதன் ஆன்மீக வரலாற்றை விரிவாகக் கூறுகிறேன்!';
        } else {
          return '🪔 ${fest.nameEn} (${fest.nameTa}):\n\n'
              '• Date: ${fest.date} ($countdownEn, $dayEn)\n'
              '• Tamil Calendar: ${fest.tamilMonth} month • Nakshatra: ${fest.nakshatra}\n'
              '• Overview: ${fest.oneLinerEn}\n'
              '• Rituals: ${fest.ritualsEn}\n\n'
              '💡 Tip: Ask me "Why is ${fest.nameEn} special?" to discover its mythological significance and Marudamalai rituals!';
        }
      }

      // Default comprehensive answer for this festival
      if (isTamil) {
        return '🪔 ${fest.nameTa} (${fest.nameEn}):\n\n'
            '• நாள்: ${fest.date} ($countdownTa, $dayTa - ${fest.tamilMonth})\n'
            '• புராணச் சிறப்பு: ${fest.whySpecialTa}\n\n'
            '• சிறப்பு பூஜை: ${fest.ritualsTa}\n'
            '• தரிசன குறிப்பு: ${fest.devoteeTipsTa}';
      } else {
        return '🪔 ${fest.nameEn} (${fest.nameTa}):\n\n'
            '• Date: ${fest.date} ($countdownEn, $dayEn - ${fest.tamilMonth})\n'
            '• Sacred Significance: ${fest.whySpecialEn}\n\n'
            '• Key Rituals: ${fest.ritualsEn}\n'
            '• Pilgrim Advice: ${fest.devoteeTipsEn}';
      }
    }

    // General upcoming festival list
    if (q.contains('festival') ||
        q.contains('திருவிழா') ||
        q.contains('பண்டிகை') ||
        q.contains('utsavam') ||
        q.contains('உற்சவம்')) {
      final upcoming = TempleKnowledgeBase.festivalsLore.where((f) {
        final d = DateTime.tryParse(f.date);
        if (d == null) return false;
        return !d.isBefore(DateTime(now.year, now.month, now.day));
      }).take(4).toList();

      final buffer = StringBuffer();
      if (isTamil) {
        buffer.writeln('🎉 மருதமலையில் அடுத்து வரும் முக்கிய திருவிழாக்கள்:\n');
        for (final f in upcoming) {
          final fDate = DateTime.tryParse(f.date) ?? now;
          final diff = fDate.difference(DateTime(now.year, now.month, now.day)).inDays;
          final countStr = diff == 0 ? 'இன்று!' : (diff == 1 ? 'நாளை!' : '$diff நாட்களில்');
          buffer.writeln('• ${f.nameTa} (${f.nameEn}): ${f.date} ($countStr)\n  ${f.oneLinerTa}\n');
        }
        buffer.write('💡 ஏதேனும் குறிப்பிட்ட விழாவைப் பற்றி "தைப்பூசம் ஏன் சிறப்பு?" அல்லது "கந்த சஷ்டி வரலாறு" என்று கேளுங்கள்!');
      } else {
        buffer.writeln('🎉 Upcoming Verified Festivals at Marudamalai:\n');
        for (final f in upcoming) {
          final fDate = DateTime.tryParse(f.date) ?? now;
          final diff = fDate.difference(DateTime(now.year, now.month, now.day)).inDays;
          final countStr = diff == 0 ? 'Today!' : (diff == 1 ? 'Tomorrow!' : 'in $diff days');
          buffer.writeln('• ${f.nameEn} (${f.nameTa}): ${f.date} ($countStr)\n  ${f.oneLinerEn}\n');
        }
        buffer.write('💡 Ask me "Why is Thaipusam special?" or "Tell me about Karthigai Deepam" to hear the sacred lore!');
      }
      return buffer.toString();
    }

    // ─── 3. Best Visiting Time & Live Crowd Guidance ──────────────────────────
    if (q.contains('what time') ||
        q.contains('which time') ||
        q.contains('when should') ||
        q.contains('best time') ||
        q.contains('crowd') ||
        q.contains('கூட்டம்') ||
        q.contains('எப்போது வரலாம்') ||
        q.contains('நேரத்தில் செல்லலாம்') ||
        q.contains('rush')) {
      final crowd = _crowdRepo.getCrowdData();
      final statusUpper = crowd.status.toUpperCase();
      final waitMin = crowd.estimatedWaitMinutes;
      final insideCount = crowd.currentVisitors;

      if (isTamil) {
        return '⏰ மருதமலை தரிசன நேரம் & நேரலை கூட்ட வழிகாட்டல்:\n\n'
            '📊 தற்போதைய நேரலை கூட்ட நிலவரம்:\n'
            '• நிலை: $statusUpper (~$insideCount பக்தர்கள் மலையில் உள்ளனர்)\n'
            '• வரிசை காத்திருப்பு நேரம்: ~$waitMin நிமிடங்கள்\n\n'
            '✨ பரிந்துரைக்கப்படும் அமைதியான தரிசன நேரங்கள்:\n'
            '• அதிகாலை: காலை 6:00 – 8:30 (குளிர்ந்த மலைக்காற்று, விஸ்வரூப தரிசனம், குறைந்த காத்திருப்பு < 15 நிமிடம்)\n'
            '• பிற்பகல்: மாலை 3:30 – 5:00 (சாயரட்சை தீபாராதனைக்கு முந்தைய அமைதியான இடைவெளி)\n\n'
            '⚠️ அதிக நெரிசல் நேரங்கள்:\n'
            '• காலை 9:30 – பிற்பகல் 1:00 (உச்சிக்கால நண்பகல் பூஜை)\n'
            '• மாலை 5:30 – இரவு 8:00 (சாயரட்சை பூஜை & தீப அலங்காரம்)\n'
            '• செவ்வாய்க்கிழமை, கிருத்திகை, சஷ்டி மற்றும் வார இறுதி நாட்களில் 2 மடங்கு கூட்டம் இருக்கும்.';
      } else {
        return '⏰ Best Time to Visit Marudamalai & Crowd Guidance (Live Telemetry):\n\n'
            '📊 Real-time Live Hill Telemetry:\n'
            '• Current Crowd Status: $statusUpper (~$insideCount visitors on hill)\n'
            '• Estimated Queue Wait: ~$waitMin minutes\n\n'
            '✨ Recommended Calm Hours (< 15 mins queue):\n'
            '• Early Morning: 6:00 AM – 8:30 AM (Serene mountain breeze, Viswaroopa darshan, quiet sanctum)\n'
            '• Late Afternoon: 3:30 PM – 5:00 PM (Peaceful window before sunset rush)\n\n'
            '⚠️ Peak / Rush Hours:\n'
            '• 9:30 AM – 1:00 PM (Uchikalam Noon Pooja)\n'
            '• 5:30 PM – 8:00 PM (Sunset Sayarakshai Deeparadhana illumination)\n'
            '• Tuesdays, Krittika nakshatra, Sashti tithi, and weekends experience double crowd turnout.';
      }
    }

    // ─── 4. Daily 5 Kaalam Pooja Timings ─────────────────────────────────────
    if (q.contains('timing') ||
        q.contains('time') ||
        q.contains('நேரம்') ||
        q.contains('பூஜை') ||
        q.contains('pooja') ||
        q.contains('schedule')) {
      if (isTamil) {
        return '🪔 மருதமலை தினசரி 5 கால மகா பூஜை அட்டவணை:\n\n'
            '1. காலை 6:00 — திருவனந்தல் (பள்ளி எழுச்சி & விஸ்வரூப தரிசனம்)\n'
            '2. காலை 8:00 — காலசந்தி பூஜை (மூலவர் அபிஷேகம் & பொங்கல் நைவேத்தியம்)\n'
            '3. நண்பகல் 12:00 — உச்சிக்கால பூஜை (ராஜ அலங்காரம் & மகா தீபாராதனை)\n'
            '4. மாலை 6:00 — சாயரட்சை பூஜை (ஆயிரக்கணக்கான விளக்குகளுடன் தீபாராதனை)\n'
            '5. இரவு 8:30 — அர்த்தஜாம பூஜை (பள்ளியறை சேவை & பால் நைவேத்தியம்)\n\n'
            'கோயில் நடை காலை 6:00 மணி முதல் இரவு 8:30 மணி வரை தொடர்ச்சியாக திறந்திருக்கும்.';
      } else {
        return '🪔 Daily 5 Kaalam Pooja Schedule at Marudamalai:\n\n'
            '1. 6:00 AM — Thiruvanandal Pooja (Viswaroopa Darshan & milk prasad)\n'
            '2. 8:00 AM — Kalasanthi Pooja (Herbal abhishekam & sweet pongal)\n'
            '3. 12:00 PM (Noon) — Uchikalam Pooja (Full floral alankaram & Maha Deepam)\n'
            '4. 6:00 PM — Sayarakshai Pooja (Sunset grand illumination)\n'
            '5. 8:30 PM — Ardhajamam Pooja (Palliyarai night closing with divine lullaby)\n\n'
            'The main sanctum remains open continuously from 6:00 AM to 8:30 PM daily.';
      }
    }

    // ─── 5. Darshan Passes & Advance Booking ──────────────────────────────────
    if (q.contains('darshan') ||
        q.contains('தரிசனம்') ||
        q.contains('ticket') ||
        q.contains('pass') ||
        q.contains('booking') ||
        q.contains('advance') ||
        q.contains('முன்பதிவு')) {
      if (isTamil) {
        return '🎟️ மருதமலை தரிசன பாஸ்கள் & முன்பதிவு விபரம்:\n\n'
            '• பொது தரிசனம்: ₹0 (இலவசம், காத்திருப்பு: ~45-90 நிமிடம்)\n'
            '• சிறப்பு விரைவு தரிசனம்: ₹50 (காத்திருப்பு: ~15-30 நிமிடம், விபூதி & மலர் பிரசாதம்)\n'
            '• வி.ஐ.பி நேரடி தரிசனம்: ₹250 (காத்திருப்பு: < 10 நிமிடம், சிறப்பு அபிஷேகம் & பஞ்சாமிர்தம்)\n\n'
            '📅 முன்பதிவு வசதி:\n'
            'செயலியின் "Bookings" பகுதியில் 7 நாட்களுக்கு முன்பே தரிசன பாஸ்களையும் மின்சார பேருந்து டிக்கெட்டுகளையும் முன்பதிவு செய்து கொள்ளலாம்!';
      } else {
        return '🎟️ Darshan Passes & Advance Booking Information:\n\n'
            '• General Darshan: Free (₹0, wait: ~45–90 mins)\n'
            '• Special Priority Darshan: ₹50 (wait: ~15–30 mins, includes prasadam & flower)\n'
            '• VIP Direct Access Darshan: ₹250 (wait: < 10 mins, close viewing & Panchamirtham)\n\n'
            '📅 Advance Booking:\n'
            'You can book both darshan passes and electric bus seats up to 7 days ahead directly in the app\'s "Bookings" tab!';
      }
    }

    // ─── 6. Pambatti Siddhar Cave & Temple History ────────────────────────────
    if (q.contains('siddhar') ||
        q.contains('cave') ||
        q.contains('சித்தர்') ||
        q.contains('குகை') ||
        q.contains('பாம்பாட்டி') ||
        q.contains('history') ||
        q.contains('வரலாறு')) {
      if (isTamil) {
        return '🐍 பாம்பாட்டி சித்தர் குகை & மருதமலை புனித வரலாறு:\n\n'
            '• 18 சித்தர்களில் ஒருவரான பாம்பாட்டி சித்தர் இம்மலையில் உள்ள இயற்கை குகையில் பல ஆண்டுகள் தவம் புரிந்தார்.\n'
            '• முருகப்பெருமான் சித்தருக்கு நாக வடிவில் பிரத்யட்சமாகி அருள்பாலித்தார். இக்குகையில் சித்தர் நடுகல்லும் நாகர் சிலையும் உள்ளன.\n'
            '• குகை திறக்கும் நேரம்: காலை 6:00 – நண்பகல் 12:00 & மாலை 4:00 – இரவு 8:00.\n'
            '• மருத மரங்கள் நிறைந்த மலை என்பதால் "மருதமலை" எனப் பெயர் பெற்றது. இங்குள்ள மருத தீர்த்தம் தோல் நோய்களைத் தீர்க்கும் மூலிகை குணம் கொண்டது.\n'
            '• அருணகிரிநாதர் தன் திருப்புகழில் மருதமலை முருகனை சிறப்பித்துப் பாடியுள்ளார்.';
      } else {
        return '🐍 Pambatti Siddhar Cave & Temple Heritage:\n\n'
            '• Pambatti Siddhar, one of the venerated 18 Tamil Siddhars, lived and meditated in this natural rock cave atop Marudamalai.\n'
            '• Lord Murugan appeared before him in the divine form of a snake (Pambu). The cave houses the sacred Samadhi shrine and serpent idol.\n'
            '• Visiting Hours: 6:00 AM – 12:00 PM & 4:00 PM – 8:00 PM daily.\n'
            '• Heritage: Dating to the 12th century, the hill is named after the sacred Marudham trees. Holy springs like Marudha Theertham possess rare Ayurvedic curative minerals.\n'
            '• Glorified by Saint Arunagirinathar in the celebrated Thiruppugazh hymns.';
      }
    }

    // ─── 7. Facilities: Drinking Water, Parking, Food, Medical ────────────────
    if (q.contains('water') ||
        q.contains('தண்ணீர்') ||
        q.contains('குடிநீர்') ||
        q.contains('dispenser')) {
      return isTamil
          ? '💧 சுத்திகரிக்கப்பட்ட குளிர்ந்த குடிநீர் (RO Chilled Water) வசதிகள்:\n\n'
              '• 200-வது படி: படிக்கட்டு ஓய்வு மண்டபத்தின் இடதுபுறம்\n'
              '• 500-வது படி: நடுப்பகுதி ஓய்வு மண்டபத்தின் வலதுபுறம்\n'
              '• 830-வது படி: மலை உச்சி மூலவர் முகப்பு வாயில் அருகில்\n'
              'அனைத்து குடிநீர் மையங்களும் பக்தர்களுக்கு 100% இலவசம்!'
          : '💧 Purified RO Chilled Drinking Water Dispensers:\n\n'
              '• Step 200: Left side of stairway rest shelter\n'
              '• Step 500: Right side of midway rest shelter\n'
              '• Step 830: Near the hilltop sanctum main gate\n'
              'All drinking water stations are 100% free for all pilgrims!';
    }

    if (q.contains('food') ||
        q.contains('annadhanam') ||
        q.contains('சாப்பாடு') ||
        q.contains('அன்னதானம்') ||
        q.contains('உணவு') ||
        q.contains('meal')) {
      return isTamil
          ? '🍚 அருள்மிகு அன்னதானம் (இலவச உணவு):\n\n'
              '• நேரம்: தினமும் நண்பகல் 11:30 முதல் பிற்பகல் 3:00 மணி வரை\n'
              '• இடம்: மலை உச்சி அன்னதான மண்டபம் (Hilltop Dining Hall)\n'
              '• உணவு: சாதம், சாம்பார், கூட்டு, ரசம், மோர் மற்றும் பாயாசம் அடங்கிய முழுமையான அறுசுவை சைவ உணவு.\n'
              'முன்பதிவு தேவையில்லை; அனைத்து பக்தர்களுக்கும் அனுமதி உண்டு!'
          : '🍚 Temple Annadhanam (Free Vegetarian Meals):\n\n'
              '• Timings: Daily from 11:30 AM to 3:00 PM\n'
              '• Location: Hilltop Annadhanam Mandapam Dining Hall\n'
              '• Menu: Unlimited 4-course meal with rice, piping hot sambar, kootu, rasam, buttermilk & sweet payasam.\n'
              'No token or ticket needed; completely open to all pilgrims!';
    }

    if (q.contains('parking') ||
        q.contains('வாகனம்') ||
        q.contains('கார்') ||
        q.contains('bike') ||
        q.contains('ev')) {
      return isTamil
          ? '🚗 வாகன நிறுத்துமிடம் & EV சார்ஜிங் (Parking):\n\n'
              '• அடிவாரம் பிரதான பார்க்கிங்: அடிவார வளைவுக்கு எதிரே 24 மணி நேரமும் திறந்திருக்கும் (500+ கார்கள் மற்றும் பேருந்துகள்).\n'
              '• மின்சார வாகன (EV) ஃபாஸ்ட் சார்ஜிங் நிலையங்கள் உள்ளன.\n'
              '• இருசக்கர வாகனங்களுக்கு மலைப்பாதை தொடக்கத்தில் நிழற்கூடம் மற்றும் ஹெல்மெட் லாக்கர் வசதி உண்டு.'
          : '🚗 Temple Parking & EV Charging Facilities:\n\n'
              '• Adivaram Main Parking: Directly opposite main Adivaram Archway gate. Open 24/7 with capacity for 500+ cars and buses.\n'
              '• Fast EV Charging stations available for electric cars & two-wheelers.\n'
              '• Covered two-wheeler parking bay with helmet lockers near Girivalam checkpoint.';
    }

    if (q.contains('bus') ||
        q.contains('shuttle') ||
        q.contains('பேருந்து') ||
        q.contains('transport') ||
        q.contains('battery car') ||
        q.contains('buggy')) {
      return isTamil
          ? '🚌 போக்குவரத்து வசதிகள்:\n\n'
              '• மலை உச்சி மின்சார பேருந்து: ஒரு நபருக்கு ₹20 (அடிவாரத்திலிருந்து 15 நிமிடத்திற்கு ஒருமுறை புறப்படும்).\n'
              '• முதியோர் & மாற்றுத்திறனாளிகள்: அடிவாரம் வளைவில் இருந்து மலை உச்சிக்கு பேட்டரி கார் 100% இலவசம்!\n'
              '• படிக்கட்டுகள்: 830 படிகள் (~30-45 நிமிட நடைப்பயணம்).\n'
              '• நகர பேருந்து: கோவை காந்திபுரம் & உக்கடத்திலிருந்து சன்னதி ஷட்டில் பேருந்துகள் உண்டு.'
          : '🚌 Transportation & Accessibility:\n\n'
              '• Hilltop Electric Bus: ₹20 per passenger each way (departs every 15 mins from Adivaram Terminal).\n'
              '• Battery Buggy Cars: 100% Free for senior citizens (60+) and differently-abled pilgrims.\n'
              '• Stone Steps: 830 steps (~30–45 mins walk, covered rest shelters at steps 200, 500, 830).\n'
              '• City Shuttles: Direct buses from Gandhipuram & Ukkadam Bus Stands (₹50–₹75).';
    }

    if (q.contains('dress') || q.contains('உடை') || q.contains('ஆடை')) {
      return isTamil
          ? '👔 உடைக் கட்டுப்பாடு (Dress Code):\n\n'
              '• ஆண்கள்: பாரம்பரிய வேஷ்டி, சட்டை, அல்லது பைஜாமா.\n'
              '• பெண்கள்: சேலை, சுடிதார், அல்லது தாவணி.\n'
              '• ஜீன்ஸ், ஷார்ட்ஸ், டீ-சர்ட் போன்ற நவீன உடைகளுக்கு கருவறை தரிசனத்தில் அனுமதி இல்லை.'
          : '👔 Temple Dress Code Guidelines:\n\n'
              '• Men: Traditional Dhoti, Kurta, or Formal Pants (Upper cloth or shirt required).\n'
              '• Women: Saree, Salwar Kameez, or Half-Saree with dupatta.\n'
              '• Shorts, bermudas, and sleeveless tops are strictly prohibited near the sanctum.';
    }

    if (q.contains('help') ||
        q.contains('emergency') ||
        q.contains('police') ||
        q.contains('medical') ||
        q.contains('அவசரம்') ||
        q.contains('உதவி') ||
        q.contains('phone')) {
      return isTamil
          ? '🚨 அவசர உதவி & மருத்துவ எண்கள்:\n\n'
              '• திருக்கோயில் கட்டணமில்லா உதவி: 1800-425-0101\n'
              '• கோயில் காவல் நிலையம்: 0422-2690100\n'
              '• முதலுதவி & ஆம்புலன்ஸ்: 108 (அடிவாரம் நுழைவாயிலில் 24 மணி நேர மருத்துவ மையம் உள்ளது).'
          : '🚨 Emergency & Medical Helplines:\n\n'
              '• Temple Toll-Free: 1800-425-0101\n'
              '• Temple Police Outpost: 0422-2690100\n'
              '• Ambulance / First Aid: 108 (24/7 primary health post at Adivaram gate).';
    }

    // Default intelligent fallback invitation
    return isTamil
        ? 'வணக்கம்! 🙏 நான் மருதமலை துணை AI (Thunai AI). என்னிடம் நீங்கள் கேட்கலாம்:\n\n'
            '• "தைப்பூசம் ஏன் சிறப்பு?" அல்லது "கந்த சஷ்டி வரலாறு என்ன?" (புராணச் சிறப்பு)\n'
            '• "அடுத்த திருவிழா எப்போது?" (நாள்காட்டி அட்டவணை)\n'
            '• "8 பேர் கொண்ட குடும்பத்திற்கு தரிசன செலவு எவ்வளவு?" (₹ கட்டணக் கணக்கீடு)\n'
            '• "இப்போது கூட்டம் எப்படி உள்ளது?" (நேரலை கூட்ட நிலவரம் & உகந்த நேரம்)\n'
            '• "படிக்கட்டுகளில் குடிநீர் எங்கு கிடைக்கும்?" (கோயில் வசதிகள்)'
        : 'Vanakkam! 🙏 I am Thunai AI, your Marudamalai companion. You can ask me:\n\n'
            '• "Why is Thaipusam special?" or "Tell me about Skanda Sashti" (Sacred lore & mythology)\n'
            '• "When is the next festival?" (Verified dates & countdowns)\n'
            '• "How much will it cost for a family of 6?" (Exact ₹ arithmetic & guidance)\n'
            '• "What is the best time to visit?" (Live crowd status & calm hours)\n'
            '• "Where can I find drinking water while climbing?" (Facility locations)';
  }

  bool _containsTamil(String text) {
    for (final rune in text.runes) {
      if (rune >= 0x0B80 && rune <= 0x0BFF) return true;
    }
    return false;
  }

  void _showApiKeyDialog() {
    final keyController = TextEditingController(text: _activeApiKey);
    final isDark = AppTheme.isDark(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, color: AppColors.goldAccent),
            const SizedBox(width: 8),
            Text(
              widget.isTamil ? 'Gemini AI சாவி' : 'Gemini AI Configuration',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimaryOf(ctx),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isTamil
                  ? 'Google AI Studio-விலிருந்து பெறப்பட்ட Gemini API Key-ஐ (AIzaSy...) உள்ளிடவும். சாவி இல்லாவிட்டாலும் உள்ளமைந்த துணை AI இயங்கும்:'
                  : 'Enter your Gemini API key from Google AI Studio (starts with AIzaSy...). Thunai also includes full on-device temple intelligence without a key:',
              style: TextStyle(
                fontSize: 12.5,
                color: AppTheme.textSecondaryOf(ctx),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: keyController,
              obscureText: true,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textPrimaryOf(ctx),
              ),
              decoration: InputDecoration(
                hintText: 'AIzaSy...',
                hintStyle: TextStyle(
                  color: isDark ? const Color(0xFF64748B) : Colors.grey,
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF141414) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.borderColor(ctx)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              widget.isTamil ? 'ரத்து' : 'Cancel',
              style: TextStyle(color: AppTheme.textSecondaryOf(ctx)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final newKey = keyController.text.trim();
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('gemini_api_key', newKey);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              _initGemini();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      widget.isTamil
                          ? 'AI நிலை வெற்றிகரமாக புதுப்பிக்கப்பட்டது!'
                          : 'AI settings updated successfully!',
                    ),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: Text(widget.isTamil ? 'சேமி' : 'Save'),
          ),
        ],
      ),
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
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.96,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: AppTheme.borderColor(context))),
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
        padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
        decoration: const BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Row(
          children: [
            BreathingGlow(
              glowColor: AppTheme.accentColor,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.accentColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Thunai',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _showApiKeyDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: _chat != null && _activeApiKey.isNotEmpty
                                ? const Color(0xFF15803D)
                                : const Color(0xFFD97706),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _chat != null && _activeApiKey.isNotEmpty
                                    ? Icons.bolt
                                    : Icons.psychology,
                                color: Colors.white,
                                size: 11,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _chat != null && _activeApiKey.isNotEmpty
                                    ? 'Gemini Live'
                                    : 'On-Device AI',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    widget.isTamil ? 'துணை AI • கோயில் வழிகாட்டி' : 'Full In-App AI Knowledge',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 20),
              tooltip: widget.isTamil ? 'உரையாடலை மீண்டும் தொடங்கு' : 'Restart Chat',
              onPressed: _restartChat,
            ),
            IconButton(
              icon: const Icon(Icons.key, color: Colors.white70, size: 20),
              tooltip: 'Configure Gemini API Key',
              onPressed: _showApiKeyDialog,
            ),
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
            Text(
              widget.isTamil ? 'துணை பதிலளிக்கிறது...' : 'Thunai is thinking...',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppTheme.textSecondaryOf(context),
              ),
            ),
          ],
        ),
      );

  Widget _quickSuggestionsBar() {
    final isTamil = widget.isTamil;
    final suggestions = isTamil
        ? [
            ('🏍️ பைக் அனுமதி 5PM', 'மாலை 5 மணிக்கு மேல் இருசக்கர வாகனம் மலைக்கு செல்லலாமா?'),
            ('🪔 மாலை 6PM பாராயணம்', 'மாலை 6 மணிக்கு நடைபெறும் சிறப்பு பாராயணம் பற்றி கூறுங்கள்'),
            ('⏰ பூஜை நேரங்கள்', 'கோயில் பூஜை நேரங்கள் என்னென்ன?'),
            ('🍚 இலவச அன்னதானம்', 'இலவச அன்னதானம் எப்போது எங்கு கிடைக்கும்?'),
            ('🎟️ விரைவு தரிசனம்', 'தரிசன டிக்கெட் மற்றும் கட்டண விபரம் என்ன?'),
            ('🚌 மின்சார பேருந்து', 'மலை உச்சிக்கு பேருந்து வசதி உள்ளதா?'),
            ('🐍 பாம்பாட்டி சித்தர்', 'பாம்பாட்டி சித்தர் குகை வரலாறு என்ன?'),
            ('💧 குடிநீர் வசதி', 'படிக்கட்டுகளில் குடிநீர் எங்கு கிடைக்கும்?'),
          ]
        : [
            ('🏍️ 2-Wheeler 5PM Rule', 'Are two wheelers allowed to the hilltop after 5 PM?'),
            ('🪔 6PM Recitations', 'Tell me about the special recitations at 6 PM'),
            ('⏰ Daily Pooja Times', 'What are the daily pooja timings?'),
            ('🍚 Free Annadhanam', 'When and where is free Annadhanam served?'),
            ('🎟️ Darshan Passes', 'What are the darshan tickets and pass costs?'),
            ('🚌 Electric Bus', 'How does the hilltop electric bus shuttle work?'),
            ('🐍 Pambatti Siddhar', 'Tell me about Pambatti Siddhar cave history'),
            ('💧 Drinking Water', 'Where can I find drinking water while climbing?'),
          ];

    return Container(
      height: 36,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 6),
        itemBuilder: (ctx, i) {
          final item = suggestions[i];
          return ActionChip(
            visualDensity: VisualDensity.compact,
            backgroundColor: AppTheme.isDark(context) ? const Color(0xFF27272A) : const Color(0xFFF1F5F9),
            side: BorderSide(color: AppTheme.borderColor(context), width: 0.8),
            label: Text(
              item.$1,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryOf(context),
              ),
            ),
            onPressed: () {
              _controller.text = item.$2;
              _send();
            },
          );
        },
      ),
    );
  }

  Widget _inputBar() => Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(top: BorderSide(color: AppTheme.borderColor(context))),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _quickSuggestionsBar(),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      style: TextStyle(color: AppTheme.textPrimaryOf(context)),
                      decoration: InputDecoration(
                        hintText: widget.isTamil
                            ? 'கேள்வி கேட்கவும் (எ.கா: பைக் அனுமதி, பூஜை நேரம்)...'
                            : 'Ask about 2-wheeler rule, 6PM chants, pooja...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondaryOf(context),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: AppTheme.borderColor(context)),
                        ),
                        filled: true,
                        fillColor: AppTheme.isDark(context)
                            ? const Color(0xFF18181B)
                            : const Color(0xFFF4F4F5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: AppTheme.primaryColor),
                    onPressed: _send,
                  ),
                ],
              ),
            ],
          ),
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
    final isDark = AppTheme.isDark(context);
    final bg = message.isUser
        ? AppTheme.primaryColor
        : (isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6));
    final textColor = message.isUser
        ? Colors.white
        : (isDark ? const Color(0xFFF4F4F5) : const Color(0xFF1F2937));

    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isUser ? 16 : 4),
            bottomRight: Radius.circular(message.isUser ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: textColor,
            fontSize: 13.5,
            height: 1.45,
            letterSpacing: 0.1,
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

class _TypingDotState extends State<_TypingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _anim.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          color: AppTheme.primaryColor,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

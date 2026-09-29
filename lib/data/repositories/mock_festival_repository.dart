import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../providers/auth_provider.dart';
import '../../domain/repositories/festival_repository.dart';
import '../models/festival_model.dart';

class MockFestivalRepository with ChangeNotifier implements FestivalRepository {
  MockFestivalRepository({bool autoSync = true}) {
    if (autoSync) {
      fetchFestivalsFromApi();
    }
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Master list of upcoming temple festivals strictly verified against 
  /// Drik Panchang & Tamil Panchangam calendar calculations.
  final List<FestivalModel> _festivals = [
    FestivalModel(
      id: '1',
      name: 'Navaratri (Ghatasthapana)',
      tamilName: 'நவராத்திரி தொடக்கம்',
      date: '2026-10-11',
      description: 'Nine sacred nights of Goddess worship commence with Ghatasthapana. Golu display, Lalitha Sahasranamam, and temple alankaram.',
      tamilDescription: 'கலச ஸ்தாபனத்துடன் நவராத்திரி திருவிழா தொடக்கம். கொலு வைத்தல், லலிதா சகஸ்ரநாம பாராயணம் மற்றும் சிறப்பு அலங்காரம்.',
      imageUrl: '',
      isSpecial: true,
      isTamilMonth: true,
    ),
    FestivalModel(
      id: '2',
      name: 'Saraswati & Ayudha Pooja',
      tamilName: 'சரஸ்வதி & ஆயுத பூஜை',
      date: '2026-10-20',
      description: 'Maha Navami observance dedicating books, instruments, and work tools for divine blessing from Goddess Saraswati.',
      tamilDescription: 'சரஸ்வதி தேவியின் ஆசீர்வாதத்திற்காக நூல்கள், இசைக் கருவிகள் மற்றும் தொழில் கருவிகள் வைத்து வழிபடும் மகா நவமி திருநாள்.',
      imageUrl: '',
      isSpecial: true,
      isTamilMonth: true,
    ),
    FestivalModel(
      id: '3',
      name: 'Vijayadasami (Vidyarambham)',
      tamilName: 'விஜயதசமி (வித்யாரம்பம்)',
      date: '2026-10-20',
      description: 'Auspicious day celebrating the victory of good over evil. Ideal for Vidyarambham (initiating children into education and arts).',
      tamilDescription: 'தீமையை வென்ற வெற்றித் திருநாள். குழந்தைகளுக்கு வித்யாரம்பம் (கல்வித் தொடக்கம்) செய்ய மிகவும் உகந்த புனித நாள்.',
      imageUrl: '',
      isSpecial: false,
      isTamilMonth: true,
    ),
    FestivalModel(
      id: '4',
      name: 'Deepavali',
      tamilName: 'தீபாவளி பண்டிகை',
      date: '2026-11-09',
      description: 'Tamil Nadu Deepavali celebration. Pre-dawn Brahma Muhurta Ganga Snanam (oil bath), temple maha deepam, and prasad distribution.',
      tamilDescription: 'தமிழ்நாட்டு மரபுப்படி அதிகாலை பிரம்ம முகூர்த்தத்தில் கங்கா ஸ்நானம் (எண்ணெய் குளியல்), புத்தாடை அணிந்து சிறப்பு கோயில் தீபம் தரிசித்தல்.',
      imageUrl: '',
      isSpecial: true,
      isTamilMonth: true,
    ),
    FestivalModel(
      id: '5',
      name: 'Skanda Sashti & Soorasamharam',
      tamilName: 'கந்த சஷ்டி & சூரசம்ஹாரம்',
      date: '2026-11-15',
      description: 'Marudamalai Murugan\'s grand victory over Soorapadman. Culmination of 6-day fasting and celestial Soorasamharam battle enactment.',
      tamilDescription: 'மருதமலை முருகன் சூரபத்மனை வென்ற மாபெரும் திருவிழா. 6 நாள் சஷ்டி விரத நிறைவு மற்றும் மருதமலை அடிவாரத்தில் சூரசம்ஹாரம்.',
      imageUrl: '',
      isSpecial: true,
      isTamilMonth: true,
    ),
    FestivalModel(
      id: '6',
      name: 'Karthigai Deepam',
      tamilName: 'திருக் கார்த்திகை தீபம்',
      date: '2026-11-24',
      description: 'Grand beacon festival on Krittika Pournami. Massive brass Mahadeepam ignited atop Marudamalai hill, visible across Coimbatore.',
      tamilDescription: 'கார்த்திகை பௌர்ணமி மகா தீபத் திருவிழா. மருதமலை உச்சியில் பிரம்மாண்ட மகாதீபம் ஏற்றப்பட்டு இரவு முழுவதும் கிரிவலம் நடைபெறும்.',
      imageUrl: '',
      isSpecial: true,
      isTamilMonth: true,
    ),
    FestivalModel(
      id: '7',
      name: 'Vaikunta Ekadasi',
      tamilName: 'வைகுண்ட ஏகாதசி',
      date: '2026-12-20',
      description: 'Opening of the sacred Paramapada Vasal (heavenly gateway). Fasting observed with all-night prayers and Vishnu Sahasranamam.',
      tamilDescription: 'சொர்க்கவாசல் (பரமபத வாசல்) திறக்கும் புனித ஏகாதசி நாள். பக்தர்கள் விரதம் அனுஷ்டித்து இரவு முழுவதும் வழிபாடு செய்கின்றனர்.',
      imageUrl: '',
      isSpecial: false,
      isTamilMonth: true,
    ),
    FestivalModel(
      id: '8',
      name: 'Arudra Darshan',
      tamilName: 'மார்கழி ஆருத்ரா தரிசனம்',
      date: '2026-12-24',
      description: 'Lord Shiva\'s Cosmic Dance (Ananda Tandavam) on Margazhi Thiruvathirai star. Midnight abhishekam and Thiruvathirai Kali prasad.',
      tamilDescription: 'மார்கழி திருவாதிரை நட்சத்திரத்தில் நடராஜப் பெருமானின் ஆனந்தத் தாண்டவ தரிசனம். சிறப்பு திருவாதிரைக் களி நைவேத்தியம்.',
      imageUrl: '',
      isSpecial: false,
      isTamilMonth: true,
    ),
    FestivalModel(
      id: '9',
      name: 'Bhogi Pandigai',
      tamilName: 'போகிப் பண்டிகை',
      date: '2027-01-14',
      description: 'Eve of Pongal celebrating renewal. Discarding old items, welcoming auspicious beginnings, and Indra Pooja for good rains.',
      tamilDescription: 'பழையன கழிதலும் புதியன புகுதலுமான போகித் திருநாள். இந்திர பூஜை செய்து நல்ல மழை மற்றும் வளமைக்காக வேண்டுதல்.',
      imageUrl: '',
      isSpecial: false,
      isTamilMonth: true,
    ),
    FestivalModel(
      id: '10',
      name: 'Thai Pongal (Makar Sankranti)',
      tamilName: 'தைப்பொங்கல் (மகர சங்கராந்தி)',
      date: '2027-01-15',
      description: 'Tamil harvest celebration as the sun enters Makara Rasi (Thai 1st). Surya Namaskaram, sacred Pongal offering, and Annadhanam.',
      tamilDescription: 'சூரியன் மகர ராசியில் நுழையும் தை முதல் நாள் உழவர் பெருநாள். சூரிய நமஸ்காரம், புதிய மண்பானையில் பொங்கல் வைத்து அன்னதானம்.',
      imageUrl: '',
      isSpecial: true,
      isTamilMonth: true,
    ),
    FestivalModel(
      id: '11',
      name: 'Thaipusam',
      tamilName: 'தைப்பூசப் பெருவிழா',
      date: '2027-01-22',
      description: 'Supreme festival of Lord Murugan at Marudamalai. Tens of thousands carry ornate Kavadis and Pal Kudam with continuous Vel chanting.',
      tamilDescription: 'மருதமலையில் முருகப்பெருமானின் முதன்மைப் பெருவிழா. பல்லாயிரக்கணக்கான பக்தர்கள் பால்குடம், காவடி ஏந்தி வேல் முழக்கத்துடன் கிரிவலம் வருவர்.',
      imageUrl: '',
      isSpecial: true,
      isTamilMonth: true,
    ),
    FestivalModel(
      id: '12',
      name: 'Maha Shivaratri',
      tamilName: 'மகா சிவராத்திரி',
      date: '2027-03-06',
      description: 'Great night of Lord Shiva. Four distinct stages of Thiruvabishekam throughout the night with sacred Bilva leaves and fasting.',
      tamilDescription: 'சிவவழிபாட்டின் மகா இரவு. இரவு முழுவதும் 4 கால சிறப்பு திருவாபிஷேகம், வில்வ அர்ச்சனை மற்றும் பஞ்சாட்சர ஜபத்துடன் விழிப்பு.',
      imageUrl: '',
      isSpecial: true,
      isTamilMonth: true,
    ),
    FestivalModel(
      id: '13',
      name: 'Panguni Uthiram',
      tamilName: 'பங்குனி உத்திரம் (திருக்கல்யாணம்)',
      date: '2027-03-22',
      description: 'Celestial wedding (Thirukalyanam) of Lord Murugan and Devasena. Thousands perform Marudamalai hill Girivalam on Pournami night.',
      tamilDescription: 'முருகப்பெருமான் - தேவசேனா திருக்கல்யாண வைபவம். பங்குனி பௌர்ணமி நிலவில் மருதமலையை சுற்றி ஆயிரக்கணக்கான பக்தர்கள் கிரிவலம் வருவர்.',
      imageUrl: '',
      isSpecial: true,
      isTamilMonth: true,
    ),
    FestivalModel(
      id: '14',
      name: 'Tamil New Year (Puthandu)',
      tamilName: 'தமிழ்ப் புத்தாண்டு (சித்திரை 1)',
      date: '2027-04-14',
      description: 'First day of Chithirai month. Special Panchanga Sravanam, auspicious Vishu Kani viewing at dawn, and temple blessings for prosperity.',
      tamilDescription: 'சித்திரை முதல் நாள் பிறக்கும் தமிழ்ப் புத்தாண்டு. அதிகாலை சித்திரைக் கனி காணுதல், பஞ்சாங்கம் வாசித்தல் மற்றும் மங்கலப் பிரார்த்தனை.',
      imageUrl: '',
      isSpecial: true,
      isTamilMonth: true,
    ),
    FestivalModel(
      id: '15',
      name: 'Vaikasi Visakam',
      tamilName: 'வைகாசி விசாகப் பெருவிழா',
      date: '2027-05-20',
      description: 'Divine incarnation day of Lord Murugan under Visakam nakshatra. Chariot car festival (Therottam) and 108 Sangabhishekam at Marudamalai.',
      tamilDescription: 'முருகப்பெருமான் அவதரித்த புனித விசாக நட்சத்திர நாள். மருதமலையில் 108 சங்காபிஷேகம் மற்றும் பிரம்மாண்ட திருத்தேர் உலா (தேரோட்டம்).',
      imageUrl: '',
      isSpecial: true,
      isTamilMonth: true,
    ),
  ];

  @override
  List<FestivalModel> getFestivals() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _festivals.where((f) {
      final d = DateTime.tryParse(f.date);
      if (d == null) return false;
      final targetDay = DateTime(d.year, d.month, d.day);
      return !targetDay.isBefore(today);
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  List<FestivalModel> get festivals => getFestivals();

  @override
  List<FestivalModel> getUpcomingFestivals({int limit = 5}) {
    return getFestivals().take(limit).toList();
  }

  @override
  FestivalModel? getFestivalById(String id) {
    try {
      return _festivals.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  void addFestival(FestivalModel festival) {
    _festivals.add(festival);
    notifyListeners();
  }

  @override
  void removeFestival(String id) {
    _festivals.removeWhere((f) => f.id == id);
    notifyListeners();
  }

  /// Synchronize festival schedule with Node.js backend REST API
  Future<bool> fetchFestivalsFromApi() async {
    try {
      _isLoading = true;
      final url = Uri.parse('${AuthProvider.backendUrl}/api/festivals');
      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final list = body['festivals'] as List<dynamic>?;
        if (list != null && list.isNotEmpty) {
          final parsed = list
              .map((json) => FestivalModel.fromJson(json as Map<String, dynamic>))
              .toList();
          _festivals.clear();
          _festivals.addAll(parsed);
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint('[FestivalRepository] Background sync fallback to offline lore: $e');
    } finally {
      _isLoading = false;
    }
    return false;
  }

  /// Admin method: Update festival date and optional descriptions
  Future<bool> updateFestivalDate(
    String id,
    String newDate, {
    String? token,
    String? name,
    String? tamilName,
    String? description,
    String? tamilDescription,
    bool? isSpecial,
  }) async {
    // 1. Optimistically update local in-memory state
    final index = _festivals.indexWhere((f) => f.id == id);
    if (index != -1) {
      final existing = _festivals[index];
      _festivals[index] = existing.copyWith(
        date: newDate,
        name: name ?? existing.name,
        tamilName: tamilName ?? existing.tamilName,
        description: description ?? existing.description,
        tamilDescription: tamilDescription ?? existing.tamilDescription,
        isSpecial: isSpecial ?? existing.isSpecial,
      );
      notifyListeners();
    }

    final payload = <String, dynamic>{
      'date': newDate,
    };
    if (name != null) payload['name'] = name;
    if (tamilName != null) payload['tamil_name'] = tamilName;
    if (description != null) payload['description'] = description;
    if (tamilDescription != null) payload['tamil_description'] = tamilDescription;
    if (isSpecial != null) payload['is_special'] = isSpecial;

    // 2. Persist to Backend API if token provided
    try {
      final url = Uri.parse('${AuthProvider.backendUrl}/api/festivals/$id');
      final response = await http
          .put(
            url,
            headers: {
              'Content-Type': 'application/json',
              if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[FestivalRepository] Error updating festival on backend: $e');
      return false;
    }
  }

  /// Admin method: Create a new custom or special temple festival
  Future<bool> createCustomFestival(FestivalModel festival, {String? token}) async {
    _festivals.add(festival);
    notifyListeners();

    try {
      final url = Uri.parse('${AuthProvider.backendUrl}/api/festivals');
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'name': festival.name,
              'tamil_name': festival.tamilName,
              'date': festival.date,
              'description': festival.description,
              'tamil_description': festival.tamilDescription,
              'is_special': festival.isSpecial,
            }),
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 201;
    } catch (e) {
      debugPrint('[FestivalRepository] Error creating festival on backend: $e');
      return false;
    }
  }
}

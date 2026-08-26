import 'package:flutter/material.dart';
import '../../domain/repositories/festival_repository.dart';
import '../models/festival_model.dart';

class MockFestivalRepository with ChangeNotifier implements FestivalRepository {
  final List<FestivalModel> _festivals = [
    FestivalModel(
      id: '1',
      name: 'Thai Pongal',
      tamilName: 'தைப்பொங்கல்',
      date: '2026-01-14',
      description: 'Harvest festival marking the sun\'s entry into Capricorn. Special annadhanam and surya pooja.',
      tamilDescription: 'சூரியன் மகர ராசியில் நுழையும் அறுவடைத் திருவிழா. சிறப்பு அன்னதானம் மற்றும் சூரிய பூஜை.',
      imageUrl: '',
      isSpecial: true,
      isTamilMonth: true,
    ),
    FestivalModel(
      id: '2',
      name: 'Thaipusam',
      tamilName: 'தைப்பூசம்',
      date: '2026-02-02',
      description: 'Lord Murugan\'s festival. Kavadi procession and special Thiruvabishekam at Marudamalai.',
      tamilDescription: 'முருகப்பெருமானின் திருவிழா. மருதமலையில் கவடி ஊர்வலம் மற்றும் சிறப்பு திருவாபிஷேகம்.',
      imageUrl: '',
      isSpecial: true,
      isTamilMonth: true,
    ),
    FestivalModel(
      id: '3',
      name: 'Maha Shivaratri',
      tamilName: 'மகா சிவராத்திரி',
      date: '2026-02-17',
      description: 'All-night vigil with special Thiruvabishekam every 3 hours. Fasting observed by devotees.',
      tamilDescription: 'ஒவ்வொரு 3 மணி நேரத்திற்கும் சிறப்பு திருவாபிஷேகத்துடன் இரவு முழுவதும் விழிப்பு. பக்தர்கள் விரதம் அனுஷ்டிக்கின்றனர்.',
      imageUrl: '',
      isSpecial: true,
      isTamilMonth: true,
    ),
    FestivalModel(
      id: '4',
      name: 'Panguni Uthiram',
      tamilName: 'பங்குனி உத்திரம்',
      date: '2026-04-02',
      description: 'Celestial wedding of Lord Murugan with Devasena. Thirukalyanam and Girivalam procession.',
      tamilDescription: 'முருகப்பெருமானுக்கும் தேவசேனைக்கும் திருக்கல்யாணம். திருக்கல்யாணம் மற்றும் கிரிவல ஊர்வலம்.',
      imageUrl: '',
      isSpecial: true,
      isTamilMonth: true,
    ),
    FestivalModel(
      id: '5',
      name: 'Tamil New Year',
      tamilName: 'தமிழ் புத்தாண்டு',
      date: '2026-04-14',
      description: 'Tamil New Year (Puthandu). Special pooja and blessings for the new year Sarvajit.',
      tamilDescription: 'தமிழ் புத்தாண்டு (புத்தாண்டு). சர்வஜித் ஆண்டிற்கான சிறப்பு பூஜை மற்றும் ஆசீர்வாதம்.',
      imageUrl: '',
      isSpecial: true,
      isTamilMonth: true,
    ),
    FestivalModel(
      id: '6',
      name: 'Vaikasi Visakam',
      tamilName: 'வைகாசி விசாகம்',
      date: '2026-06-07',
      description: 'Birth star of Lord Murugan. Grand chariot procession and special alankaram.',
      tamilDescription: 'முருகப்பெருமானின் பிறந்த நட்சத்திரம். பெரும் தேர் ஊர்வலம் மற்றும் சிறப்பு அலங்காரம்.',
      imageUrl: '',
      isSpecial: true,
      isTamilMonth: true,
    ),
    FestivalModel(
      id: '7',
      name: 'Aadi Perukku',
      tamilName: 'ஆடி பெருக்கு',
      date: '2026-08-03',
      description: 'Celebration of rivers and water bodies. Special offerings to river Kaveri.',
      tamilDescription: 'ஆறுகள் மற்றும் நீர்நிலைகளை கொண்டாடும் திருவிழா. காவேரி நதிக்கு சிறப்பு நைவேத்தியம்.',
      imageUrl: '',
      isSpecial: false,
      isTamilMonth: true,
    ),
    FestivalModel(
      id: '8',
      name: 'Krishna Janmashtami',
      tamilName: 'கிருஷ்ண ஜந்மாஷ்டமி',
      date: '2026-08-22',
      description: 'Celebration of Lord Krishna\'s birth. Midnight pooja and uriyadi.',
      tamilDescription: 'கிருஷ்ணப் பெருமானின் பிறந்தநாள் கொண்டாட்டம். நள்ளிரவு பூஜை மற்றும் உரியடி.',
      imageUrl: '',
      isSpecial: true,
      isTamilMonth: false,
    ),
    FestivalModel(
      id: '9',
      name: 'Vinayagar Chaturthi',
      tamilName: 'விநாயகர் சதுர்த்தி',
      date: '2026-08-30',
      description: 'Lord Vinayagar\'s birthday. Special kozhukattai offering and procession.',
      tamilDescription: 'விநாயகப் பெருமானின் பிறந்தநாள். சிறப்பு கொழுக்கட்டை நைவேத்தியம் மற்றும் ஊர்வலம்.',
      imageUrl: '',
      isSpecial: true,
      isTamilMonth: false,
    ),
    FestivalModel(
      id: '10',
      name: 'Navaratri',
      tamilName: 'நவராத்திரி',
      date: '2026-10-09',
      description: 'Nine nights of Goddess worship. Golu display and special Saraswati pooja.',
      tamilDescription: 'தேவி வழிபாட்டிற்கான ஒன்பது இரவுகள். கொலு வைத்தல் மற்றும் சிறப்பு சரஸ்வதி பூஜை.',
      imageUrl: '',
      isSpecial: true,
      isTamilMonth: false,
    ),
    FestivalModel(
      id: '11',
      name: 'Saraswati Pooja',
      tamilName: 'சரஸ்வதி பூஜை',
      date: '2026-10-17',
      description: 'Books and instruments placed before Goddess Saraswati for blessings.',
      tamilDescription: 'சரஸ்வதி தேவியின் ஆசீர்வாதத்திற்காக நூல்கள் மற்றும் கருவிகள் வைக்கப்படுகின்றன.',
      imageUrl: '',
      isSpecial: false,
      isTamilMonth: false,
    ),
    FestivalModel(
      id: '12',
      name: 'Deepavali',
      tamilName: 'தீபாவளி',
      date: '2026-11-08',
      description: 'Festival of lights. Oil bath before sunrise, fireworks and special temple deepam.',
      tamilDescription: 'விளக்குகளின் திருவிழா. சூரிய உதயத்திற்கு முன் எண்ணெய் குளியல், பட்டாசு மற்றும் சிறப்பு கோயில் தீபம்.',
      imageUrl: '',
      isSpecial: true,
      isTamilMonth: false,
    ),
    FestivalModel(
      id: '13',
      name: 'Karthigai Deepam',
      tamilName: 'கார்த்திகை தீபம்',
      date: '2026-11-30',
      description: 'Festival of lamps. Thousands of lamps lit at the temple. Sacred to Lord Murugan.',
      tamilDescription: 'விளக்கு திருவிழா. கோயிலில் ஆயிரக்கணக்கான விளக்குகள் ஏற்றப்படுகின்றன. முருகப்பெருமானுக்கு புனிதமானது.',
      imageUrl: '',
      isSpecial: true,
      isTamilMonth: true,
    ),
    FestivalModel(
      id: '14',
      name: 'Arudra Darshan',
      tamilName: 'ஆருத்ரா தரிசனம்',
      date: '2026-12-25',
      description: 'Lord Shiva as Nataraja is worshipped. Special thiruvannamalai deepam.',
      tamilDescription: 'நடராஜராக சிவபெருமான் வழிபடப்படுகிறார். சிறப்பு திருவண்ணாமலை தீபம்.',
      imageUrl: '',
      isSpecial: false,
      isTamilMonth: true,
    ),
  ];

  @override
  List<FestivalModel> getFestivals() => _festivals;

  @override
  List<FestivalModel> getUpcomingFestivals({int limit = 5}) {
    final now = DateTime.now();
    final upcoming = _festivals
        .where((f) => DateTime.parse(f.date).isAfter(now))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return upcoming.take(limit).toList();
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
}

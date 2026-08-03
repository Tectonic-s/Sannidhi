import 'package:flutter/material.dart';
import '../../domain/repositories/festival_repository.dart';
import '../models/festival_model.dart';

class MockFestivalRepository with ChangeNotifier implements FestivalRepository {
  final List<FestivalModel> _festivals = [
    FestivalModel(
      id: '1',
      name: 'Panguni Uthiram',
      date: '2025-03-22',
      description: 'Special abhishekam and alankaram for all deities',
      imageUrl: '',
      isSpecial: true,
      isTamilMonth: true,
      tamilName: 'பங்குனி உத்திரம்',
    ),
    FestivalModel(
      id: '2',
      name: 'Thai Pongal',
      date: '2025-01-15',
      description: 'Harvest festival with special offerings',
      imageUrl: '',
      isSpecial: true,
      isTamilMonth: true,
      tamilName: 'தைப்பொங்கல்',
    ),
    FestivalModel(
      id: '3',
      name: 'Krishna Janmashtami',
      date: '2025-08-16',
      description: "Celebration of Lord Krishna's birth",
      imageUrl: '',
      isSpecial: true,
      tamilName: 'கிருஷ்ண ஜந்மாஷ்டமி',
    ),
    FestivalModel(
      id: '4',
      name: 'Navaratri',
      date: '2025-10-02',
      description: 'Nine nights of worship and celebration',
      imageUrl: '',
      isSpecial: true,
      tamilName: 'நவராத்திரி',
    ),
    FestivalModel(
      id: '5',
      name: 'Deepavali',
      date: '2025-10-20',
      description: 'Festival of lights with special decorations',
      imageUrl: '',
      isSpecial: true,
      tamilName: 'தீபாவளி',
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

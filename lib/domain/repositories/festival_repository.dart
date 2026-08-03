import '../../data/models/festival_model.dart';

abstract class FestivalRepository {
  List<FestivalModel> getFestivals();
  List<FestivalModel> getUpcomingFestivals({int limit = 5});
  FestivalModel? getFestivalById(String id);
  void addFestival(FestivalModel festival);
  void removeFestival(String id);
}

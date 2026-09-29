import 'package:flutter/material.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/micro_animations.dart';

class _Facility {
  final String nameEn;
  final String nameTa;
  final String detailEn;
  final String detailTa;
  final String categoryKey;
  final String categoryNameEn;
  final String categoryNameTa;
  final IconData icon;
  final Color color;
  final String locationEn;
  final String locationTa;

  const _Facility({
    required this.nameEn,
    required this.nameTa,
    required this.detailEn,
    required this.detailTa,
    required this.categoryKey,
    required this.categoryNameEn,
    required this.categoryNameTa,
    required this.icon,
    required this.color,
    required this.locationEn,
    required this.locationTa,
  });

  String name(bool isTamil) => isTamil ? nameTa : nameEn;
  String detail(bool isTamil) => isTamil ? detailTa : detailEn;
  String category(bool isTamil) => isTamil ? categoryNameTa : categoryNameEn;
  String location(bool isTamil) => isTamil ? locationTa : locationEn;
}

const _facilities = [
  // 1. Parking Facilities
  _Facility(
    nameEn: 'Adivaram Main Parking (Car & Bus)',
    nameTa: 'அடிவாரம் பிரதான வாகன நிறுத்துமிடம் (கார் & பேருந்து)',
    detailEn: 'Open 24 hours • Ample space with EV charging stations',
    detailTa: '24 மணி நேரமும் திறந்திருக்கும் • மின்சார வாகன சார்ஜிங் வசதி உண்டு',
    categoryKey: 'parking',
    categoryNameEn: 'Parking',
    categoryNameTa: 'வாகனம்',
    icon: Icons.local_parking_rounded,
    color: Color(0xFF0288D1),
    locationEn: 'Directly opposite to Main Adivaram Archway Gate',
    locationTa: 'அடிவார பிரதான நுழைவு வளைவுக்கு நேர் எதிரே',
  ),
  _Facility(
    nameEn: 'Hill Road Two-Wheeler Bay',
    nameTa: 'மலைப் பாதை இருசக்கர வாகன நிறுத்துமிடம்',
    detailEn: 'Covered parking bay for bikes & scooters with helmet lockers',
    detailTa: 'ஹெல்மெட் பாதுகாப்பு பெட்டகங்களுடன் கூடிய நிழல் கூடம்',
    categoryKey: 'parking',
    categoryNameEn: 'Parking',
    categoryNameTa: 'வாகனம்',
    icon: Icons.two_wheeler_rounded,
    color: Color(0xFF0288D1),
    locationEn: 'Near Girivalam Path starting checkpoint',
    locationTa: 'கிரிவலப் பாதை தொடக்க சோதனைச் சாவடி அருகில்',
  ),

  // 2. RO Water
  _Facility(
    nameEn: 'RO Chilled Water — Step 200',
    nameTa: 'சுத்திகரிக்கப்பட்ட குடிநீர் — 200-வது படி',
    detailEn: 'Free purified cold drinking water station',
    detailTa: 'இலவச சுத்திகரிக்கப்பட்ட குளிர்ந்த குடிநீர் வசதி',
    categoryKey: 'water',
    categoryNameEn: 'Water',
    categoryNameTa: 'குடிநீர்',
    icon: Icons.water_drop_rounded,
    color: Color(0xFF0288D1),
    locationEn: 'Left side of stairway rest shelter at Step 200',
    locationTa: '200-வது படி ஓய்வு மண்டபத்தின் இடதுபுறம்',
  ),
  _Facility(
    nameEn: 'RO Chilled Water — Step 500',
    nameTa: 'சுத்திகரிக்கப்பட்ட குடிநீர் — 500-வது படி',
    detailEn: 'Free purified cold drinking water station',
    detailTa: 'இலவச சுத்திகரிக்கப்பட்ட குளிர்ந்த குடிநீர் வசதி',
    categoryKey: 'water',
    categoryNameEn: 'Water',
    categoryNameTa: 'குடிநீர்',
    icon: Icons.water_drop_rounded,
    color: Color(0xFF0288D1),
    locationEn: 'Right side of stairway rest shelter at Step 500',
    locationTa: '500-வது படி ஓய்வு மண்டபத்தின் வலதுபுறம்',
  ),
  _Facility(
    nameEn: 'RO Chilled Water — Step 830',
    nameTa: 'சுத்திகரிக்கப்பட்ட குடிநீர் — 830-வது படி',
    detailEn: 'Purified water dispenser near hilltop sanctum entry',
    detailTa: 'மலைக்கோவில் சன்னதி நுழைவு அருகே தூய குடிநீர் வசதி',
    categoryKey: 'water',
    categoryNameEn: 'Water',
    categoryNameTa: 'குடிநீர்',
    icon: Icons.water_drop_rounded,
    color: Color(0xFF0288D1),
    locationEn: 'Near hilltop entrance arch at Step 830',
    locationTa: 'மலைக்கோவில் நுழைவு வளைவு அருகே (830-வது படி)',
  ),

  // 3. Medical
  _Facility(
    nameEn: 'Free Medical & Emergency First-Aid Post',
    nameTa: 'இலவச மருத்துவ மற்றும் முதலுதவி மையம்',
    detailEn: 'Open 24 hours • Doctor on duty, oxygen & ambulance',
    detailTa: '24 மணி நேரமும் இயங்கும் • மருத்துவர், ஆக்ஸிஜன் & ஆம்புலன்ஸ் தயார்',
    categoryKey: 'medical',
    categoryNameEn: 'Medical',
    categoryNameTa: 'மருத்துவம்',
    icon: Icons.local_hospital_rounded,
    color: Color(0xFFDC2626),
    locationEn: 'Adivaram entrance, ground floor room 4',
    locationTa: 'அடிவார நுழைவு வாயில், தரைத்தளம் அறை எண் 4',
  ),

  // 4. Food / Annadhanam
  _Facility(
    nameEn: 'Sri Annadhanam Free Dining Hall',
    nameTa: 'ஸ்ரீ அன்னதான கூடம்',
    detailEn: '11:30 AM – 3:00 PM daily • Free divine meals for all',
    detailTa: 'தினமும் காலை 11:30 முதல் மாலை 3:00 வரை • இலவச உணவு',
    categoryKey: 'food',
    categoryNameEn: 'Food',
    categoryNameTa: 'உணவு',
    icon: Icons.restaurant_rounded,
    color: Color(0xFF16A34A),
    locationEn: 'Hilltop Mandapam — follow green signboards',
    locationTa: 'மலை மண்டபம் — பச்சை நிற வழிகாட்டி பலகையை பின்தொடரவும்',
  ),

  // 5. Amenities
  _Facility(
    nameEn: 'Battery Car Boarding Station',
    nameTa: 'மின்சார வாகன ஏறுமிடம்',
    detailEn: 'Free eco-friendly transit for elderly & differently-abled',
    detailTa: 'முதியோர்கள் மற்றும் மாற்றுத்திறனாளிகளுக்கு கட்டணமில்லா சேவை',
    categoryKey: 'amenities',
    categoryNameEn: 'Amenities',
    categoryNameTa: 'வசதிகள்',
    icon: Icons.electric_car_rounded,
    color: Color(0xFF7C3AED),
    locationEn: 'Adivaram main gate — left side bay 1',
    locationTa: 'அடிவாரம் பிரதான நுழைவு வாசல் — இடதுபுறம் பே 1',
  ),
  _Facility(
    nameEn: 'Free Shoe Stand & Cloak Room',
    nameTa: 'இலவச காலணி & உடைமை பாதுகாப்பு மையம்',
    detailEn: 'Secure token-based footwear & baggage deposit — no charges',
    detailTa: 'டோக்கன் முறை காலணி & உடைமை வைப்பகம் — கட்டணமில்லை',
    categoryKey: 'amenities',
    categoryNameEn: 'Amenities',
    categoryNameTa: 'வசதிகள்',
    icon: Icons.checkroom_rounded,
    color: Color(0xFF7C3AED),
    locationEn: 'Adivaram main entry & hilltop entry gates',
    locationTa: 'அடிவாரம் நுழைவு வாசல் மற்றும் மலைக்கோவில் நுழைவு',
  ),
  _Facility(
    nameEn: 'Clean Restroom & Toilet Block',
    nameTa: 'சுத்தமான கழிப்பறை வளாகம்',
    detailEn: 'Regularly sanitized modern toilet & washroom facilities',
    detailTa: 'அடிக்கடி கிருமி நீக்கம் செய்யப்படும் நவீன கழிப்பறை வசதி',
    categoryKey: 'amenities',
    categoryNameEn: 'Amenities',
    categoryNameTa: 'வசதிகள்',
    icon: Icons.wc_rounded,
    color: Color(0xFF7C3AED),
    locationEn: 'Steps 100, 400, 700 & Hilltop North Wing',
    locationTa: '100, 400, 700-வது படிகள் மற்றும் மலைக்கோவில் வடக்கு பகுதி',
  ),
];

class _CategoryItem {
  final String key;
  final String nameEn;
  final String nameTa;

  const _CategoryItem({
    required this.key,
    required this.nameEn,
    required this.nameTa,
  });

  String name(bool isTamil) => isTamil ? nameTa : nameEn;
}

const _categories = [
  _CategoryItem(key: 'all', nameEn: 'All', nameTa: 'அனைத்தும்'),
  _CategoryItem(key: 'parking', nameEn: 'Parking', nameTa: 'வாகனம்'),
  _CategoryItem(key: 'water', nameEn: 'Drinking Water', nameTa: 'குடிநீர்'),
  _CategoryItem(key: 'medical', nameEn: 'Medical', nameTa: 'மருத்துவம்'),
  _CategoryItem(key: 'food', nameEn: 'Food / Prasadam', nameTa: 'உணவு'),
  _CategoryItem(key: 'amenities', nameEn: 'Amenities', nameTa: 'வசதிகள்'),
];

class FacilityLocatorScreen extends StatefulWidget {
  final VoidCallback onToggleLocale;
  const FacilityLocatorScreen({super.key, required this.onToggleLocale});

  @override
  State<FacilityLocatorScreen> createState() => _FacilityLocatorScreenState();
}

class _FacilityLocatorScreenState extends State<FacilityLocatorScreen> {
  String _selectedKey = 'all';

  List<_Facility> get _filtered => _selectedKey == 'all'
      ? _facilities
      : _facilities.where((f) => f.categoryKey == _selectedKey).toList();

  @override
  Widget build(BuildContext context) {
    final isTamil = AppLocalizations.of(context).currentLocale == 'ta';

    return Scaffold(
      appBar: CustomAppBar(
        onToggleLocale: widget.onToggleLocale,
      ),
      body: Column(
        children: [
          // Subheader Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.borderColor(context),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0288D1).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.explore_rounded,
                    color: Color(0xFF0288D1),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isTamil ? 'கோவில் வசதிகள் & வழிகாட்டி' : 'Temple Facilities & Locator',
                        style: TextStyle(
                          fontSize: isTamil ? 16 : 15,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimaryOf(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isTamil
                            ? 'வாகனம், குடிநீர், மருத்துவம் & அன்னதான விவரங்கள்'
                            : 'Parking, RO water, emergency clinic & amenities',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppTheme.textSecondaryOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Horizontal Filter Bar
          _filterBar(isTamil),

          // Facilities List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 14,
                bottom: 110,
              ),
              itemCount: _filtered.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 10),
              itemBuilder: (_, i) => FadeSlideIn(
                delay: Duration(milliseconds: 25 * i.clamp(0, 10)),
                child: _FacilityCard(
                  facility: _filtered[i],
                  isTamil: isTamil,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterBar(bool isTamil) => Container(
        height: 52,
        color: Theme.of(context).cardColor,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          children: _categories.map((cat) {
            final isSel = cat.key == _selectedKey;
            return BouncingScaleTap(
              onTap: () => setState(() => _selectedKey = cat.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSel
                      ? AppTheme.primaryColor
                      : (AppTheme.isDark(context)
                          ? const Color(0xFF18181B)
                          : Colors.grey.shade100),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSel
                        ? AppTheme.primaryColor
                        : (AppTheme.isDark(context)
                            ? const Color(0xFF27272A)
                            : Colors.grey.shade300),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    cat.name(isTamil),
                    style: TextStyle(
                      fontSize: isTamil ? 13 : 12.5,
                      fontWeight: FontWeight.w700,
                      color: isSel ? Colors.white : AppTheme.textSecondaryOf(context),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
}

class _FacilityCard extends StatelessWidget {
  final _Facility facility;
  final bool isTamil;

  const _FacilityCard({
    required this.facility,
    required this.isTamil,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor(context)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: facility.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(facility.icon, color: facility.color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        facility.name(isTamil),
                        style: TextStyle(
                          fontSize: isTamil ? 14 : 13.5,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimaryOf(context),
                          height: 1.25,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: facility.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        facility.category(isTamil),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: facility.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  facility.detail(isTamil),
                  style: TextStyle(
                    fontSize: isTamil ? 12.5 : 12,
                    color: AppTheme.textSecondaryOf(context),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.location_on_rounded,
                        size: 13,
                        color: AppTheme.textSecondaryOf(context),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        facility.location(isTamil),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppTheme.textSecondaryOf(context),
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

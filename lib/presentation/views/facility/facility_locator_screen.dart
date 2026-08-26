import 'package:flutter/material.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/widgets/custom_app_bar.dart';

class _Facility {
  final String name;
  final String detail;
  final String category;
  final IconData icon;
  final Color color;
  final String location;

  const _Facility({
    required this.name,
    required this.detail,
    required this.category,
    required this.icon,
    required this.color,
    required this.location,
  });
}

const _facilities = [
  _Facility(
    name: 'RO Water Point — Step 200',
    detail: 'Free purified drinking water',
    category: 'Water',
    icon: Icons.water_drop,
    color: Color(0xFF0288D1),
    location: 'Left side of stairway at Step 200',
  ),
  _Facility(
    name: 'RO Water Point — Step 500',
    detail: 'Free purified drinking water',
    category: 'Water',
    icon: Icons.water_drop,
    color: Color(0xFF0288D1),
    location: 'Right side of stairway at Step 500',
  ),
  _Facility(
    name: 'RO Water Point — Step 830',
    detail: 'Free purified drinking water',
    category: 'Water',
    icon: Icons.water_drop,
    color: Color(0xFF0288D1),
    location: 'Near hilltop entrance at Step 830',
  ),
  _Facility(
    name: 'Free Medical & First-Aid Post',
    detail: 'Open 24 hours — doctor on duty',
    category: 'Medical',
    icon: Icons.local_hospital,
    color: Color(0xFFC62828),
    location: 'Near Adivaram entrance, ground floor',
  ),
  _Facility(
    name: 'Annadhanam Dining Hall',
    detail: '11:30 AM – 3:00 PM daily — free meals',
    category: 'Food',
    icon: Icons.restaurant,
    color: Color(0xFF2E7D32),
    location: 'Hilltop Mandapam, follow green signs',
  ),
  _Facility(
    name: 'Battery Car Boarding',
    detail: 'Free for elderly & disabled pilgrims',
    category: 'Amenities',
    icon: Icons.electric_car,
    color: Color(0xFF6A1B9A),
    location: 'Adivaram main gate — left side',
  ),
  _Facility(
    name: 'Free Shoe Stand',
    detail: 'Secure footwear deposit — no charge',
    category: 'Amenities',
    icon: Icons.checkroom,
    color: Color(0xFF6A1B9A),
    location: 'Adivaram entrance & hilltop entrance',
  ),
  _Facility(
    name: 'Toilet Block',
    detail: 'Clean facilities maintained by trust',
    category: 'Amenities',
    icon: Icons.wc,
    color: Color(0xFF6A1B9A),
    location: 'Steps 100, 400, 700 & hilltop',
  ),
];

const _categories = ['All', 'Water', 'Medical', 'Food', 'Amenities'];

class FacilityLocatorScreen extends StatefulWidget {
  final VoidCallback onToggleLocale;
  const FacilityLocatorScreen({super.key, required this.onToggleLocale});

  @override
  State<FacilityLocatorScreen> createState() => _FacilityLocatorScreenState();
}

class _FacilityLocatorScreenState extends State<FacilityLocatorScreen> {
  String _selected = 'All';

  List<_Facility> get _filtered => _selected == 'All'
      ? _facilities
      : _facilities.where((f) => f.category == _selected).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(onToggleLocale: widget.onToggleLocale),
      body: Column(
        children: [
          _filterBar(),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _filtered.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _FacilityCard(facility: _filtered[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterBar() => Container(
        height: 52,
        color: Colors.white,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: _categories.map((cat) {
            final isSel = cat == _selected;
            return GestureDetector(
              onTap: () => setState(() => _selected = cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isSel ? AppTheme.primaryColor : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(cat,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSel ? Colors.white : AppTheme.textSecondary)),
              ),
            );
          }).toList(),
        ),
      );
}

class _FacilityCard extends StatelessWidget {
  final _Facility facility;
  const _FacilityCard({required this.facility});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0D000000), blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: facility.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(facility.icon, color: facility.color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(facility.name,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 2),
                Text(facility.detail,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.location_on,
                      size: 12, color: AppTheme.textSecondary),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(facility.location,
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ]),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: facility.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(facility.category,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: facility.color)),
          ),
        ],
      ),
    );
  }
}

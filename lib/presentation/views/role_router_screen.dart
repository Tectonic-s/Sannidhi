import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../main.dart';
import 'admin/admin_dashboard_screen.dart';
import 'staff/gate_staff_screen.dart';

/// Routes the user to one of 3 completely distinct UIs based on their role:
/// 1. [GateStaffScreen]: For Gate Staff (Main screen is the QR pass scanner).
/// 2. [AdminDashboardScreen]: For Temple Admin (Live executive data dashboard).
/// 3. [MainNavigationScreen]: For Common Users / Devotees (Untouched 5-tab devotee UI).
class RoleRouterScreen extends StatelessWidget {
  final VoidCallback onToggleLocale;

  const RoleRouterScreen({
    super.key,
    required this.onToggleLocale,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final role = auth.currentUser?.role;

    if (role == UserRole.staff) {
      return GateStaffScreen(onToggleLocale: onToggleLocale);
    }

    if (role == UserRole.admin) {
      return AdminDashboardScreen(onToggleLocale: onToggleLocale);
    }

    // Default: Common User (Devotee) UI with all regular features
    return MainNavigationScreen(onToggleLocale: onToggleLocale);
  }
}

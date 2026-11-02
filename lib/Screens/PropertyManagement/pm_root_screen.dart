import 'package:flutter/material.dart';
import '../../model/property_management/pm_models.dart';
import '../../data/property_management/pm_store.dart';
import 'owner/owner_dashboard_screen.dart';
import 'tenant/tenant_dashboard_screen.dart';

/// Entry point for the "Property Management" bottom-nav tab. Shows the
/// Owner flow or the Tenant flow depending on PmStore.instance.role,
/// which is set from the temporary role-switch toggle in the Profile
/// page (see profile.dart) and persisted locally via SharedPreferences.
/// This role switch is a UI-only convenience, NOT real authorization -
/// see pm_store.dart's header comment.
class PmRootScreen extends StatefulWidget {
  const PmRootScreen({super.key});

  @override
  State<PmRootScreen> createState() => _PmRootScreenState();
}

class _PmRootScreenState extends State<PmRootScreen> {
  @override
  void initState() {
    super.initState();
    PmStore.instance.ensureRoleLoaded();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PmStore.instance,
      builder: (context, _) {
        return PmStore.instance.role == PmRole.owner
            ? const OwnerDashboardScreen()
            : const TenantDashboardScreen();
      },
    );
  }
}

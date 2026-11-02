import 'package:flutter/material.dart';
import '../../../model/property_management/pm_models.dart';
import '../../../data/property_management/pm_store.dart';
import '../../../custom_widget/property_management/pm_shared_widgets.dart';
import '../../../custom_widget/property_management/pm_forms.dart';
import 'tenant_flat_screen.dart';
import '../shared/agreement_screen.dart';
import '../shared/police_verification_screen.dart';
import '../shared/insurance_screen.dart';
import '../shared/utility_screen.dart';
import '../shared/vehicle_detail_screen.dart';

/// Tenant Dashboard (home of Tenant mode).
///
/// IMPORTANT: this app has no tenant login/auth yet - there is no way to
/// know "which flat is this phone's tenant". `PmStore.activeTenantFlat`
/// is a clearly-labelled, temporary stand-in: a "Switch flat (demo)"
/// picker lets you preview the Tenant experience for any flat in the
/// reference data. A real build needs tenant accounts tied to a flat by
/// the backend, never by this kind of client-side picker (working rule
/// #13 - a UI role/identity switch is never real security).
class TenantDashboardScreen extends StatelessWidget {
  const TenantDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PmStore.instance,
      builder: (context, _) {
        final store = PmStore.instance;
        final building = store.activeTenantBuilding;
        final flat = store.activeTenantFlat;
        final dueAmount = flat.monthlyRent;

        return Scaffold(
          backgroundColor: PmTheme.bg,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                const PmPreviewBanner(),
                const SizedBox(height: 14),
                _header(context, flat),
                const SizedBox(height: 18),
                if (dueAmount != null) _rentDueCard(context, flat, dueAmount) else _noRentCard(flat),
                const SizedBox(height: 18),
                _myHomeCard(building, flat),
                const SizedBox(height: 18),
                _quickGrid(context, building, flat),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _header(BuildContext context, PmFlat flat) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Property Management - Tenant',
                  style: TextStyle(color: PmTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text('Hello, ${flat.tenantName ?? 'Tenant'}',
                  style: TextStyle(color: PmTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: () => _showSwitchFlatSheet(context),
          icon: Icon(Icons.swap_horiz, color: PmTheme.textSecondary, size: 18),
          label: Text('Switch flat (demo)', style: TextStyle(color: PmTheme.textSecondary, fontSize: 12)),
        ),
        const PmThemeToggle(),
      ],
    );
  }

  Widget _rentDueCard(BuildContext context, PmFlat flat, int amount) {
    return PmHeroCard(
      label: 'Monthly rent due',
      value: pmFormatInr(amount),
      subtitle: 'Recorded received so far (demo): ${pmFormatInr(flat.recordedReceived)}',
      icon: Icons.receipt_long_outlined,
      trailing: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: pmNavy),
        onPressed: () => pmShowSheet(context, title: 'Report a payment', child: AddPaymentForm(flat: flat, asTenantReport: true)),
        child: const Text('Pay / Report'),
      ),
    );
  }

  Widget _noRentCard(PmFlat flat) {
    return PmGlassCard(
      child: Text(
        flat.status == FlatStatus.selfUse ? 'This is a self-use flat - no rent applies.' : 'Monthly rent is not on record for this flat.',
        style: TextStyle(color: PmTheme.textSecondary, fontSize: 13),
      ),
    );
  }

  Widget _myHomeCard(PmBuilding building, PmFlat flat) {
    return PmGlassCard(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [PmColors.building, Color(0xFF1B8A7E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.home_outlined, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${building.name} - Flat ${flat.flatNo}',
                    style: TextStyle(color: PmTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('Caretaker: ${building.caretaker ?? 'Not provided'}',
                    style: TextStyle(color: PmTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickGrid(BuildContext context, PmBuilding building, PmFlat flat) {
    final items = <(IconData, String, int, Color)>[
      (Icons.home_outlined, 'My Home', 0, PmColors.building),
      (Icons.receipt_long_outlined, 'Rent & Bills', 1, PmColors.rent),
      (Icons.people_outline, 'Family', 2, PmColors.tenant),
      (Icons.directions_car_outlined, 'Vehicles', 3, PmColors.vehicle),
      (Icons.folder_outlined, 'Documents', 4, PmColors.document),
      (Icons.build_outlined, 'Services & Notice', 5, PmColors.maintenance),
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.05,
      children: [
        for (final item in items)
          _tile(
            icon: item.$1,
            label: item.$2,
            color: item.$4,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TenantFlatScreen(building: building, flat: flat, initialTab: item.$3)),
            ),
          ),
        _tile(
          icon: Icons.description_outlined,
          label: 'Agreement',
          color: PmColors.agreement,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AgreementScreen(building: building, flat: flat, readOnly: true))),
        ),
        _tile(
          icon: Icons.verified_user_outlined,
          label: 'Police Verification',
          color: PmColors.verification,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PoliceVerificationScreen(building: building, flat: flat, readOnly: true))),
        ),
        _tile(
          icon: Icons.shield_outlined,
          label: 'Insurance',
          color: PmColors.insurance,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InsuranceScreen(building: building, flat: flat, readOnly: true))),
        ),
        _tile(
          icon: Icons.speed_outlined,
          label: 'Utility Bills',
          color: PmColors.utility,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UtilityScreen(building: building, flat: flat, asTenant: true))),
        ),
        _tile(
          icon: Icons.directions_car_filled_outlined,
          label: 'Vehicle Details',
          color: PmColors.vehicle,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VehicleDetailScreen(building: building, flat: flat))),
        ),
      ],
    );
  }

  Widget _tile({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color, color.withOpacity(0.6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center, maxLines: 2, style: TextStyle(color: PmTheme.textPrimary, fontSize: 10.5, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _showSwitchFlatSheet(BuildContext context) {
    final store = PmStore.instance;
    pmShowSheet(
      context,
      title: 'Switch flat (demo only)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'There is no tenant login yet, so use this to preview the Tenant '
            'view for any flat in the reference data.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 10),
          for (int bi = 0; bi < store.portfolio.buildings.length; bi++)
            for (int fi = 0; fi < store.portfolio.buildings[bi].flats.length; fi++)
              Builder(builder: (context) {
                final building = store.portfolio.buildings[bi];
                final flat = building.flats[fi];
                final accent = switch (flat.status) {
                  FlatStatus.rented => Colors.green,
                  FlatStatus.vacant => Colors.redAccent,
                  FlatStatus.selfUse => Colors.blueGrey,
                };
                // PmFlatCard (pm_shared_widgets.dart) - a proper card
                // with an image slot instead of a plain ListTile row,
                // even in this demo-only picker.
                return PmFlatCard(
                  title: '${building.name} - Flat ${flat.flatNo}',
                  subtitle: flat.tenantName ?? 'No tenant on record',
                  accent: accent,
                  light: true, // this sheet is always white - see PmFlatCard's doc comment
                  onTap: () {
                    store.setActiveTenantFlat(bi, fi);
                    Navigator.pop(context);
                  },
                );
              }),
        ],
      ),
    );
  }
}

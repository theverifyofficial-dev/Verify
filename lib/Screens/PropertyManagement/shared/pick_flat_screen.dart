import 'package:flutter/material.dart';
import '../../../model/property_management/pm_models.dart';
import '../../../data/property_management/pm_store.dart';
import '../../../custom_widget/property_management/pm_shared_widgets.dart';

/// Full "choose a flat" screen used by every Quick Action that needs a
/// flat picked first (Record Payment, Agreement, Police Verification,
/// Insurance, Utility Bills, Vehicle Details, etc.) - shows each flat as
/// a proper themed card (not a plain-text list in a bottom sheet).
/// `onPick` gets full control of what happens next: push a detail
/// screen, or pop back and open a form sheet.
class PickFlatScreen extends StatelessWidget {
  final String title;
  final List<MapEntry<PmBuilding, PmFlat>> flats;
  final void Function(BuildContext context, PmBuilding building, PmFlat flat) onPick;
  const PickFlatScreen({super.key, required this.title, required this.flats, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PmStore.instance,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: PmTheme.bg,
          appBar: AppBar(
            backgroundColor: PmTheme.bg,
            elevation: 0,
            title: Text(title, style: TextStyle(color: PmTheme.textPrimary, fontSize: 16)),
            iconTheme: IconThemeData(color: PmTheme.textPrimary),
            actions: const [PmThemeToggle(), SizedBox(width: 6)],
          ),
          body: SafeArea(
            child: flats.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: PmEmptyState(icon: Icons.door_front_door_outlined, message: 'No flats available for this yet.'),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: flats.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, idx) => _flatCard(context, flats[idx]),
                  ),
          ),
        );
      },
    );
  }

  Widget _flatCard(BuildContext context, MapEntry<PmBuilding, PmFlat> e) {
    final building = e.key;
    final flat = e.value;
    final statusLabel = switch (flat.status) {
      FlatStatus.rented => 'Rented',
      FlatStatus.vacant => 'Vacant',
      FlatStatus.selfUse => 'Self-use',
    };
    final statusColor = switch (flat.status) {
      FlatStatus.rented => Colors.green,
      FlatStatus.vacant => Colors.orange,
      FlatStatus.selfUse => Colors.blueGrey,
    };
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onPick(context, building, flat),
        child: PmGlassCard(
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [PmColors.building, PmColors.building.withOpacity(0.6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.door_front_door_outlined, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${building.name} - Flat ${flat.flatNo}',
                        style: TextStyle(color: PmTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(flat.tenantName ?? 'No tenant on record', style: TextStyle(color: PmTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              PmStatusBadge(label: statusLabel, color: statusColor),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: PmTheme.iconMuted),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../model/property_management/pm_models.dart';
import '../../../data/property_management/pm_store.dart';
import '../../../custom_widget/property_management/pm_shared_widgets.dart';

/// Full "choose a building" screen - same idea as [PickFlatScreen] but
/// for the Quick Actions that need a building picked first (Add Expense).
class PickBuildingScreen extends StatelessWidget {
  final String title;
  final List<PmBuilding> buildings;
  final void Function(BuildContext context, PmBuilding building) onPick;
  const PickBuildingScreen({super.key, required this.title, required this.buildings, required this.onPick});

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
            child: buildings.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: PmEmptyState(icon: Icons.apartment_outlined, message: 'No buildings available for this yet.'),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: buildings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, idx) => _buildingCard(context, buildings[idx]),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildingCard(BuildContext context, PmBuilding building) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onPick(context, building),
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
                child: const Icon(Icons.apartment_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(building.name, style: TextStyle(color: PmTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('${building.unitCount} flats - ${building.rentedCount} rented - ${building.vacantCount} vacant',
                        style: TextStyle(color: PmTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: PmTheme.iconMuted),
            ],
          ),
        ),
      ),
    );
  }
}

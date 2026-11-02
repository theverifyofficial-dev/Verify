import 'package:flutter/material.dart';
import '../../../model/property_management/pm_models.dart';
import '../../../data/property_management/pm_store.dart';
import '../../../custom_widget/property_management/pm_shared_widgets.dart';

/// Simple Reports & Insights - built with plain Containers (no new chart
/// dependency needed, per the "no new heavy dependencies" constraint).
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PmStore.instance,
      builder: (context, _) {
        final portfolio = PmStore.instance.portfolio;
        final maxRent = portfolio.buildings.fold<int>(
            1, (m, b) => b.scheduledRent > m ? b.scheduledRent : m);

        return Scaffold(
          backgroundColor: PmTheme.bg,
          appBar: AppBar(
            backgroundColor: PmTheme.bg,
            elevation: 0,
            title: Text('Reports & Insights', style: TextStyle(color: PmTheme.textPrimary)),
            iconTheme: IconThemeData(color: PmTheme.textPrimary),
            actions: const [PmThemeToggle(), SizedBox(width: 6)],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const PmPreviewBanner(),
                const SizedBox(height: 14),
                PmGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const PmSectionHeader(title: 'Portfolio summary'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          PmStatChip(label: 'Buildings', value: '${portfolio.buildingCount}', icon: Icons.apartment_outlined, color: PmColors.building),
                          PmStatChip(label: 'Units', value: '${portfolio.unitCount}', icon: Icons.door_front_door_outlined, color: PmColors.tenant),
                          PmStatChip(label: 'Rented', value: '${portfolio.rentedCount}', icon: Icons.check_circle_outline, color: PmColors.rent),
                          PmStatChip(label: 'Vacant', value: '${portfolio.vacantCount}', icon: Icons.meeting_room_outlined, color: PmColors.pending),
                          PmStatChip(label: 'Scheduled rent', value: pmFormatInr(portfolio.scheduledRentTotal), icon: Icons.account_balance_wallet_outlined, color: PmColors.rent),
                          PmStatChip(label: 'Vacant asking total', value: pmFormatInr(portfolio.vacantAskingRentTotal), icon: Icons.sell_outlined, color: PmColors.expense),
                          PmStatChip(label: 'Received (demo)', value: pmFormatInr(portfolio.recordedReceived), icon: Icons.check_circle_outline, color: PmColors.rent),
                          PmStatChip(label: 'Pending confirm (demo)', value: pmFormatInr(portfolio.pendingConfirmation), icon: Icons.hourglass_empty, color: PmColors.pending),
                          PmStatChip(label: 'Vehicles on record', value: '${portfolio.vehicleCount}', icon: Icons.directions_car_outlined, color: PmColors.vehicle),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                PmGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const PmSectionHeader(title: 'Scheduled rent by building'),
                      const SizedBox(height: 14),
                      for (final b in portfolio.buildings) _rentBar(b, maxRent),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                PmGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const PmSectionHeader(title: 'Occupancy by building'),
                      const SizedBox(height: 10),
                      for (final b in portfolio.buildings) _occupancyRow(b),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _rentBar(PmBuilding b, int maxRent) {
    final fraction = maxRent == 0 ? 0.0 : b.scheduledRent / maxRent;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(b.name, style: TextStyle(color: PmTheme.textPrimary, fontSize: 12.5)),
              Text(pmFormatInr(b.scheduledRent), style: TextStyle(color: PmTheme.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LayoutBuilder(
              builder: (context, constraints) => Stack(
                children: [
                  Container(height: 10, width: constraints.maxWidth, color: PmTheme.divider),
                  Container(
                    height: 10,
                    width: constraints.maxWidth * fraction.clamp(0.0, 1.0),
                    decoration: const BoxDecoration(
                      gradient: PmColors.heroGradient,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _occupancyRow(PmBuilding b) {
    final total = b.unitCount == 0 ? 1 : b.unitCount;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(b.name, style: TextStyle(color: PmTheme.textPrimary, fontSize: 12.5))),
          Text('${b.rentedCount}/${total} rented', style: TextStyle(color: PmTheme.textSecondary, fontSize: 12)),
          const SizedBox(width: 10),
          Text('${((b.rentedCount / total) * 100).round()}%',
              style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

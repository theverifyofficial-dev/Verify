import 'package:flutter/material.dart';
import '../../../model/property_management/pm_models.dart';
import '../../../data/property_management/pm_store.dart';
import '../../../custom_widget/property_management/pm_shared_widgets.dart';
import '../../../custom_widget/property_management/pm_forms.dart';
import 'flat_detail_screen.dart';

class BuildingDetailScreen extends StatefulWidget {
  final PmBuilding building;
  final PmFlat? openFlat; // if set, auto-opens this flat's detail on load

  const BuildingDetailScreen({super.key, required this.building, this.openFlat});

  @override
  State<BuildingDetailScreen> createState() => _BuildingDetailScreenState();
}

class _BuildingDetailScreenState extends State<BuildingDetailScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);

  @override
  void initState() {
    super.initState();
    if (widget.openFlat != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FlatDetailScreen(building: widget.building, flat: widget.openFlat!)),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PmStore.instance,
      builder: (context, _) {
        final b = widget.building;
        return Scaffold(
          backgroundColor: PmTheme.bg,
          appBar: AppBar(
            backgroundColor: PmTheme.bg,
            elevation: 0,
            title: Text(
              b.name,
              style: TextStyle(color: PmTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w800),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            iconTheme: IconThemeData(color: PmTheme.textPrimary),
            actions: [
              // "X Flats / Y Occupied" badge, matching the reference
              // design's top-right summary box.
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: PmTheme.cardSoft,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: PmTheme.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${b.unitCount} Flats', style: TextStyle(color: PmTheme.textPrimary, fontSize: 11.5, fontWeight: FontWeight.w700)),
                    Text('${b.rentedCount} Occupied', style: TextStyle(color: PmTheme.textSecondary, fontSize: 10)),
                  ],
                ),
              ),
              const PmThemeToggle(),
              const SizedBox(width: 6),
            ],
            bottom: PmPillTabBar(
              controller: _tabs,
              labels: const ['Flats', 'Overview', 'Expenses'],
              accent: PmColors.building,
            ),
          ),
          body: SafeArea(
            child: TabBarView(
              controller: _tabs,
              children: [_flatsTab(b), _overviewTab(b), _expensesTab(b)],
            ),
          ),
        );
      },
    );
  }

  Widget _flatsTab(PmBuilding b) {
    return Column(
      children: [
        const Padding(padding: EdgeInsets.all(16), child: PmPreviewBanner()),
        Expanded(
          child: b.flats.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: PmEmptyState(icon: Icons.door_front_door_outlined, message: 'No flats added yet.'),
                )
              : ListView.builder(
                  // Plain builder, not .separated - PmEntityCard already
                  // carries its own bottom margin for consistent spacing.
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: b.flats.length,
                  itemBuilder: (_, i) => _flatRow(b.flats[i]),
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => pmShowSheet(context, title: 'Add flat', child: AddFlatForm(building: b)),
              icon: Icon(Icons.add, color: PmTheme.textPrimary),
              label: Text('Add flat', style: TextStyle(color: PmTheme.textPrimary)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: PmTheme.divider),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _flatRow(PmFlat flat) {
    final statusLabel = switch (flat.status) {
      FlatStatus.rented => 'Occupied',
      FlatStatus.vacant => 'Vacant',
      FlatStatus.selfUse => 'Self-use',
    };
    final statusColor = switch (flat.status) {
      FlatStatus.rented => Colors.green,
      FlatStatus.vacant => Colors.redAccent,
      FlatStatus.selfUse => Colors.blueGrey,
    };
    final subtitle = flat.status == FlatStatus.vacant
        ? 'Available for Rent'
        : (flat.tenantName ?? 'No tenant on record');
    // PmFlatCard (pm_shared_widgets.dart) - a proper card with an image
    // slot (illustrated placeholder, since the app has no flat photo
    // storage) instead of a list row.
    return PmFlatCard(
      title: '${flat.floorLabel} - Flat ${flat.flatNo}${flat.bhk != null ? ' - ${flat.bhk}' : ''}',
      subtitle: subtitle,
      accent: statusColor,
      statusLabel: statusLabel,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FlatDetailScreen(building: widget.building, flat: flat))),
    );
  }

  Widget _overviewTab(PmBuilding b) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        PmGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PmSectionHeader(title: 'Building overview'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  PmStatChip(label: 'Units', value: '${b.unitCount}', icon: Icons.door_front_door_outlined, color: PmColors.tenant),
                  PmStatChip(label: 'Rented', value: '${b.rentedCount}', icon: Icons.check_circle_outline, color: PmColors.rent),
                  PmStatChip(label: 'Vacant', value: '${b.vacantCount}', icon: Icons.meeting_room_outlined, color: PmColors.pending),
                  PmStatChip(label: 'Self-use', value: '${b.selfUseCount}', icon: Icons.home_outlined, color: Colors.blueGrey),
                  PmStatChip(label: 'Scheduled rent', value: pmFormatInr(b.scheduledRent), icon: Icons.account_balance_wallet_outlined, color: PmColors.rent),
                  PmStatChip(label: 'Vehicles', value: '${b.vehicleCount}', icon: Icons.directions_car_outlined, color: PmColors.vehicle),
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
              const PmSectionHeader(title: 'Building details'),
              const SizedBox(height: 8),
              _detailLine('Caretaker', b.caretaker ?? 'Not provided'),
              _detailLine('Lift', b.hasLift == true ? 'Available' : (b.hasLift == false ? 'Not available' : 'Not provided')),
              _detailLine('Meter type', pmMeterLabel(b.meterType)),
              _detailLine('Parking capacity', b.parkingCapacity != null ? '${b.parkingCapacity}' : 'Not provided'),
              if (b.subMeterRatePerUnit != null) _detailLine('Sub-meter rate', '₹${b.subMeterRatePerUnit}/unit'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: PmTheme.textSecondary, fontSize: 12.5))),
          Text(value, style: TextStyle(color: PmTheme.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _expensesTab(PmBuilding b) {
    return Column(
      children: [
        Expanded(
          child: b.expenses.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: PmEmptyState(icon: Icons.receipt_long_outlined, message: 'No expenses logged yet.'),
                )
              : ListView.builder(
                  // Plain builder, not .separated - PmEntityCard already
                  // carries its own bottom margin for consistent spacing.
                  padding: const EdgeInsets.all(16),
                  itemCount: b.expenses.length,
                  itemBuilder: (_, i) {
                    final e = b.expenses[b.expenses.length - 1 - i];
                    return PmEntityCard(
                      icon: Icons.receipt_outlined,
                      accent: PmColors.expense,
                      title: e.title,
                      subtitle: pmDateLabel(e.date),
                      trailing: Text(
                        pmFormatInr(e.amount),
                        style: TextStyle(color: PmTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => pmShowSheet(context, title: 'Add expense', child: AddExpenseForm(building: b)),
              icon: Icon(Icons.add, color: PmTheme.textPrimary),
              label: Text('Add expense', style: TextStyle(color: PmTheme.textPrimary)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: PmTheme.divider),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

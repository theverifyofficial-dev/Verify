import 'package:flutter/material.dart';
import '../../../model/property_management/pm_models.dart';
import '../../../data/property_management/pm_store.dart';
import '../../../custom_widget/property_management/pm_shared_widgets.dart';
import '../../../custom_widget/property_management/pm_forms.dart';

/// Utility meter readings / bills log for one flat. Unlike Agreement /
/// Verification / Insurance, both owner and tenant can add an entry here
/// (a tenant self-reporting a meter reading is normal) - there is no
/// confirm/dispute step like rent payments, it's just a shared log.
class UtilityScreen extends StatelessWidget {
  final PmBuilding building;
  final PmFlat flat;
  final bool asTenant;
  const UtilityScreen({super.key, required this.building, required this.flat, this.asTenant = false});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PmStore.instance,
      builder: (context, _) {
        final sorted = [...flat.utilityRecords]..sort((a, b) => b.date.compareTo(a.date));
        return Scaffold(
          backgroundColor: PmTheme.bg,
          appBar: AppBar(
            backgroundColor: PmTheme.bg,
            elevation: 0,
            title: Text('Utility bills - Flat ${flat.flatNo}', style: TextStyle(color: PmTheme.textPrimary, fontSize: 16)),
            iconTheme: IconThemeData(color: PmTheme.textPrimary),
            actions: const [PmThemeToggle(), SizedBox(width: 6)],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const PmPreviewBanner(),
                      const SizedBox(height: 14),
                      PmGlassCard(
                        accent: PmColors.utility,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PmSectionHeader(title: 'Meter context', icon: Icons.speed_outlined, iconColor: PmColors.utility),
                            const SizedBox(height: 10),
                            _line('Meter type', pmMeterLabel(building.meterType)),
                            _line('Sub-meter rate', building.subMeterRatePerUnit != null ? '₹${building.subMeterRatePerUnit}/unit' : 'Not provided'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: sorted.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: PmEmptyState(icon: Icons.receipt_long_outlined, message: 'No meter readings or bills logged yet.'),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: sorted.length,
                          separatorBuilder: (_, __) => Divider(color: PmTheme.divider),
                          itemBuilder: (_, idx) => _row(sorted[idx]),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => pmShowSheet(
                        context,
                        title: 'Add reading / bill',
                        child: AddUtilityRecordForm(flat: flat, reportedByTenant: asTenant),
                      ),
                      icon: Icon(Icons.add, color: PmColors.utility),
                      label: Text('Add reading / bill', style: TextStyle(color: PmTheme.textPrimary)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: PmColors.utility.withOpacity(0.4)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _line(String label, String value) {
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

  Widget _row(PmUtilityRecord r) {
    final typeLabel = switch (r.type) {
      UtilityType.electricity => 'Electricity',
      UtilityType.water => 'Water',
      UtilityType.gas => 'Gas',
      UtilityType.other => 'Other',
    };
    final typeIcon = switch (r.type) {
      UtilityType.electricity => Icons.bolt_outlined,
      UtilityType.water => Icons.water_drop_outlined,
      UtilityType.gas => Icons.local_fire_department_outlined,
      UtilityType.other => Icons.receipt_long_outlined,
    };
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(typeIcon, color: PmColors.utility),
      title: Text(
        '$typeLabel${r.billAmount != null ? ' - ${pmFormatInr(r.billAmount!)}' : ''}',
        style: TextStyle(color: PmTheme.textPrimary, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${pmDateLabel(r.date)}'
        '${r.meterReading != null ? ' - reading ${r.meterReading}' : ''}'
        '${r.reportedByTenant ? ' - reported by tenant' : ''}',
        style: TextStyle(color: PmTheme.textMuted, fontSize: 11.5),
      ),
    );
  }
}

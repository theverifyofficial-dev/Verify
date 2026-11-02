import 'package:flutter/material.dart';
import '../../../model/property_management/pm_models.dart';
import '../../../data/property_management/pm_store.dart';
import '../../../custom_widget/property_management/pm_shared_widgets.dart';
import '../../../custom_widget/property_management/pm_forms.dart';

/// Insurance policy details for a flat - owner creates/updates, tenant
/// can only view. Manual record only, same as Agreement/Verification -
/// no backend/insurer integration exists yet.
class InsuranceScreen extends StatelessWidget {
  final PmBuilding building;
  final PmFlat flat;
  final bool readOnly;
  const InsuranceScreen({super.key, required this.building, required this.flat, this.readOnly = false});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PmStore.instance,
      builder: (context, _) {
        final i = flat.insurance;
        final status = i?.status ?? InsuranceStatus.none;
        final statusLabel = switch (status) {
          InsuranceStatus.none => 'No policy',
          InsuranceStatus.active => 'Active',
          InsuranceStatus.expired => 'Expired',
        };
        final statusColor = switch (status) {
          InsuranceStatus.none => Colors.blueGrey,
          InsuranceStatus.active => PmColors.rent,
          InsuranceStatus.expired => PmColors.overdue,
        };
        return Scaffold(
          backgroundColor: PmTheme.bg,
          appBar: AppBar(
            backgroundColor: PmTheme.bg,
            elevation: 0,
            title: Text('Insurance - Flat ${flat.flatNo}', style: TextStyle(color: PmTheme.textPrimary, fontSize: 16)),
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
                  accent: PmColors.insurance,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          PmSectionHeader(title: 'Insurance policy', icon: Icons.shield_outlined, iconColor: PmColors.insurance),
                          PmStatusBadge(label: statusLabel, color: statusColor),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (i == null || i.status == InsuranceStatus.none)
                        PmEmptyState(icon: Icons.shield_outlined, message: 'No insurance policy on file yet.')
                      else ...[
                        _line('Provider', i.provider ?? 'Not provided'),
                        _line('Policy number', i.policyNumber ?? 'Not provided'),
                        _line('Valid till', i.validTill != null ? pmDateLabel(i.validTill!) : 'Not provided'),
                        if (i.note != null) ...[
                          const SizedBox(height: 6),
                          Text(i.note!, style: TextStyle(color: PmTheme.textSecondary, fontSize: 12.5)),
                        ],
                      ],
                    ],
                  ),
                ),
                if (readOnly) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Only the owner can add or update insurance details. You can view them here any time.',
                    style: TextStyle(color: PmTheme.textMuted, fontSize: 11.5),
                  ),
                ] else ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => pmShowSheet(
                        context,
                        title: (i == null || i.status == InsuranceStatus.none) ? 'Add insurance policy' : 'Update insurance policy',
                        child: InsuranceForm(flat: flat),
                      ),
                      icon: Icon(Icons.edit_outlined, color: PmColors.insurance),
                      label: Text(
                        (i == null || i.status == InsuranceStatus.none) ? 'Add insurance policy' : 'Update insurance policy',
                        style: TextStyle(color: PmTheme.textPrimary),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: PmColors.insurance.withOpacity(0.4)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
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
}

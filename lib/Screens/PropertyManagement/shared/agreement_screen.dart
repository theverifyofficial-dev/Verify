import 'package:flutter/material.dart';
import '../../../model/property_management/pm_models.dart';
import '../../../data/property_management/pm_store.dart';
import '../../../custom_widget/property_management/pm_shared_widgets.dart';
import '../../../custom_widget/property_management/pm_forms.dart';

/// Rental Agreement - owner creates/updates, tenant can only view.
/// Manual record only - there is still no backend here, so this does not
/// generate, e-sign, or store a real legal document (see AgreementForm's
/// own note shown to the owner when filling it in).
class AgreementScreen extends StatelessWidget {
  final PmBuilding building;
  final PmFlat flat;
  final bool readOnly;
  const AgreementScreen({super.key, required this.building, required this.flat, this.readOnly = false});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PmStore.instance,
      builder: (context, _) {
        final a = flat.agreement;
        final statusLabel = switch (a?.status ?? AgreementStatus.notCreated) {
          AgreementStatus.notCreated => 'Not created',
          AgreementStatus.active => 'Active',
          AgreementStatus.expired => 'Expired',
        };
        final statusColor = switch (a?.status ?? AgreementStatus.notCreated) {
          AgreementStatus.notCreated => Colors.blueGrey,
          AgreementStatus.active => PmColors.rent,
          AgreementStatus.expired => PmColors.overdue,
        };
        return Scaffold(
          backgroundColor: PmTheme.bg,
          appBar: AppBar(
            backgroundColor: PmTheme.bg,
            elevation: 0,
            title: Text('Agreement - Flat ${flat.flatNo}', style: TextStyle(color: PmTheme.textPrimary, fontSize: 16)),
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
                  accent: PmColors.agreement,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          PmSectionHeader(title: 'Rental agreement', icon: Icons.description_outlined, iconColor: PmColors.agreement),
                          PmStatusBadge(label: statusLabel, color: statusColor),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (a == null || a.status == AgreementStatus.notCreated)
                        PmEmptyState(icon: Icons.description_outlined, message: 'No agreement on file yet.')
                      else ...[
                        _line('Start date', a.startDate != null ? pmDateLabel(a.startDate!) : 'Not provided'),
                        _line('End date', a.endDate != null ? pmDateLabel(a.endDate!) : 'Not provided'),
                        _line('Security deposit', a.securityDeposit != null ? pmFormatInr(a.securityDeposit!) : 'Not provided'),
                        _line('Notice period', a.noticePeriodDays != null ? '${a.noticePeriodDays} days' : 'Not provided'),
                        if (a.terms != null) ...[
                          const SizedBox(height: 6),
                          Text(a.terms!, style: TextStyle(color: PmTheme.textSecondary, fontSize: 12.5)),
                        ],
                      ],
                    ],
                  ),
                ),
                if (readOnly) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Only the owner can create or update the agreement. You can view it here any time.',
                    style: TextStyle(color: PmTheme.textMuted, fontSize: 11.5),
                  ),
                ] else ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => pmShowSheet(
                        context,
                        title: (a == null || a.status == AgreementStatus.notCreated) ? 'Create agreement' : 'Update agreement',
                        child: AgreementForm(flat: flat),
                      ),
                      icon: Icon(Icons.edit_outlined, color: PmColors.agreement),
                      label: Text(
                        (a == null || a.status == AgreementStatus.notCreated) ? 'Create agreement' : 'Update agreement',
                        style: TextStyle(color: PmTheme.textPrimary),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: PmColors.agreement.withOpacity(0.4)),
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

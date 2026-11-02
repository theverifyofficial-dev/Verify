import 'package:flutter/material.dart';
import '../../../model/property_management/pm_models.dart';
import '../../../data/property_management/pm_store.dart';
import '../../../custom_widget/property_management/pm_shared_widgets.dart';
import '../../../custom_widget/property_management/pm_forms.dart';

/// Police / tenant-ID verification status - owner sets/updates it, tenant
/// can only view. IMPORTANT: this is a manual record only. There is no
/// real government or police verification API behind it - no backend
/// exists yet, so nothing here is actually submitted anywhere. A future
/// milestone should connect this to a real tenant-verification service.
class PoliceVerificationScreen extends StatelessWidget {
  final PmBuilding building;
  final PmFlat flat;
  final bool readOnly;
  const PoliceVerificationScreen({super.key, required this.building, required this.flat, this.readOnly = false});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PmStore.instance,
      builder: (context, _) {
        final v = flat.policeVerification;
        final status = v?.status ?? VerificationStatus.notSubmitted;
        final statusLabel = switch (status) {
          VerificationStatus.notSubmitted => 'Not submitted',
          VerificationStatus.pending => 'Pending',
          VerificationStatus.verified => 'Verified',
          VerificationStatus.rejected => 'Rejected',
        };
        final statusColor = switch (status) {
          VerificationStatus.notSubmitted => Colors.blueGrey,
          VerificationStatus.pending => PmColors.pending,
          VerificationStatus.verified => PmColors.rent,
          VerificationStatus.rejected => PmColors.overdue,
        };
        return Scaffold(
          backgroundColor: PmTheme.bg,
          appBar: AppBar(
            backgroundColor: PmTheme.bg,
            elevation: 0,
            title: Text('Verification - Flat ${flat.flatNo}', style: TextStyle(color: PmTheme.textPrimary, fontSize: 16)),
            iconTheme: IconThemeData(color: PmTheme.textPrimary),
            actions: const [PmThemeToggle(), SizedBox(width: 6)],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const PmPreviewBanner(),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: PmColors.verification.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: PmColors.verification.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: PmColors.verification, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Manual record only - not connected to any real government/police verification API yet.',
                          style: TextStyle(color: PmTheme.textSecondary, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                PmGlassCard(
                  accent: PmColors.verification,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          PmSectionHeader(title: 'Tenant verification', icon: Icons.verified_user_outlined, iconColor: PmColors.verification),
                          PmStatusBadge(label: statusLabel, color: statusColor),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (v == null)
                        PmEmptyState(icon: Icons.verified_user_outlined, message: 'No verification record yet.')
                      else ...[
                        _line('ID type', v.idType ?? 'Not provided'),
                        _line('ID number', v.idNumber ?? 'Not provided'),
                        _line('Submitted on', v.submittedOn != null ? pmDateLabel(v.submittedOn!) : 'Not provided'),
                        _line('Verified on', v.verifiedOn != null ? pmDateLabel(v.verifiedOn!) : 'Not provided'),
                        if (v.remarks != null) ...[
                          const SizedBox(height: 6),
                          Text(v.remarks!, style: TextStyle(color: PmTheme.textSecondary, fontSize: 12.5)),
                        ],
                      ],
                    ],
                  ),
                ),
                if (readOnly) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Only the owner can update this status. You can view it here any time.',
                    style: TextStyle(color: PmTheme.textMuted, fontSize: 11.5),
                  ),
                ] else ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => pmShowSheet(context, title: 'Update verification status', child: PoliceVerificationForm(flat: flat)),
                      icon: Icon(Icons.edit_outlined, color: PmColors.verification),
                      label: Text('Update verification status', style: TextStyle(color: PmTheme.textPrimary)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: PmColors.verification.withOpacity(0.4)),
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

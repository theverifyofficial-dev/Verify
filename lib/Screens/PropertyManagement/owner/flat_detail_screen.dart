import 'package:flutter/material.dart';
import '../../../model/property_management/pm_models.dart';
import '../../../data/property_management/pm_store.dart';
import '../../../custom_widget/property_management/pm_shared_widgets.dart';
import '../../../custom_widget/property_management/pm_forms.dart';

/// Flat Details (Owner view) - Overview / Family / Rent & Payments /
/// Vehicles / Documents / Services & Notice, all for ONE flat. Every
/// Add action here writes into PmStore (in-memory only, see pm_store.dart
/// / pm_models.dart headers) - there is still no backend.
class FlatDetailScreen extends StatefulWidget {
  final PmBuilding building;
  final PmFlat flat;
  const FlatDetailScreen({super.key, required this.building, required this.flat});

  @override
  State<FlatDetailScreen> createState() => _FlatDetailScreenState();
}

class _FlatDetailScreenState extends State<FlatDetailScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 6, vsync: this);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PmStore.instance,
      builder: (context, _) {
        final f = widget.flat;
        final statusLabel = switch (f.status) {
          FlatStatus.rented => 'Occupied',
          FlatStatus.vacant => 'Vacant',
          FlatStatus.selfUse => 'Self-use',
        };
        final statusColor = switch (f.status) {
          FlatStatus.rented => Colors.green,
          FlatStatus.vacant => Colors.redAccent,
          FlatStatus.selfUse => Colors.blueGrey,
        };
        return Scaffold(
          backgroundColor: PmTheme.bg,
          appBar: AppBar(
            backgroundColor: PmTheme.bg,
            elevation: 0,
            title: Text(
              '${widget.building.name} - Flat ${f.flatNo}',
              style: TextStyle(color: PmTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            iconTheme: IconThemeData(color: PmTheme.textPrimary),
            actions: [
              PmStatusBadge(label: statusLabel, color: statusColor),
              const SizedBox(width: 10),
              const PmThemeToggle(),
              const SizedBox(width: 6),
            ],
          ),
          body: Column(
            children: [
              _contactHeader(f, statusColor),
              PmPillTabBar(
                controller: _tabs,
                isScrollable: true,
                accent: PmColors.building,
                labels: const [
                  'Details',
                  'Members',
                  'Rent & Payments',
                  'Vehicles',
                  'Documents',
                  'Services & Notice',
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _overviewTab(f),
                    _familyTab(f),
                    _rentTab(f),
                    _vehiclesTab(f),
                    _documentsTab(f),
                    _servicesTab(f),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Avatar + tenant name + role + phone + Call/WhatsApp/Message round
  /// buttons, matching the reference design's Flat Detail header. Sits
  /// above the tabs (not inside any one tab) since it's always-visible
  /// context, same as the reference screenshot.
  Widget _contactHeader(PmFlat f, Color statusColor) {
    final hasTenant = f.tenantName != null && f.tenantName!.trim().isNotEmpty;
    final roleLabel = hasTenant
        ? 'Primary Tenant'
        : (f.status == FlatStatus.vacant ? 'Available for Rent' : 'Self-use - no tenant');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
      child: Column(
        children: [
          PmInitialsAvatar(name: f.tenantName, color: statusColor, radius: 34, fallbackIcon: Icons.person_outline),
          const SizedBox(height: 10),
          Text(
            f.tenantName ?? 'No tenant on record',
            style: TextStyle(color: PmTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(roleLabel, style: TextStyle(color: PmTheme.textSecondary, fontSize: 12.5)),
          if (f.tenantPhone != null && f.tenantPhone!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.call_outlined, size: 13, color: PmTheme.textMuted),
                const SizedBox(width: 4),
                Text(f.tenantPhone!, style: TextStyle(color: PmTheme.textMuted, fontSize: 12)),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _contactButton(Icons.call_outlined, PmColors.verification, () => pmLaunchPhoneCall(context, f.tenantPhone)),
              const SizedBox(width: 18),
              _contactButton(Icons.chat_outlined, PmColors.rent, () => pmLaunchWhatsApp(context, f.tenantPhone)),
              const SizedBox(width: 18),
              _contactButton(Icons.sms_outlined, PmColors.tenant, () => pmLaunchSms(context, f.tenantPhone)),
            ],
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _contactButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: color.withOpacity(0.14),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _overviewTab(PmFlat f) {
    final statusLabel = switch (f.status) {
      FlatStatus.rented => 'Rented',
      FlatStatus.vacant => 'Vacant',
      FlatStatus.selfUse => 'Self-use',
    };
    final statusColor = switch (f.status) {
      FlatStatus.rented => Colors.green,
      FlatStatus.vacant => Colors.orange,
      FlatStatus.selfUse => Colors.blueGrey,
    };
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PmPreviewBanner(),
        const SizedBox(height: 14),
        PmGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Flat details', style: TextStyle(color: PmTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                  PmStatusBadge(label: statusLabel, color: statusColor),
                ],
              ),
              const SizedBox(height: 10),
              _line('Floor', f.floorLabel),
              _line('BHK', f.bhk ?? 'Not provided'),
              _line('Tenant', f.tenantName ?? 'Not provided'),
              _line('Monthly rent', f.monthlyRent != null ? pmFormatInr(f.monthlyRent!) : 'Not provided'),
              if (f.status == FlatStatus.vacant)
                _line('Asking rent', f.askingRent != null ? pmFormatInr(f.askingRent!) : 'Not provided'),
              _line('Furnished', f.furnished == true ? 'Yes' : (f.furnished == false ? 'No' : 'Not provided')),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _editTenantAndRent(f),
            icon: Icon(Icons.edit_outlined, color: PmTheme.textPrimary),
            label: Text('Update tenant / rent', style: TextStyle(color: PmTheme.textPrimary)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: PmTheme.divider),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
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

  void _editTenantAndRent(PmFlat f) {
    final tenantCtrl = TextEditingController(text: f.tenantName ?? '');
    final phoneCtrl = TextEditingController(text: f.tenantPhone ?? '');
    final rentCtrl = TextEditingController(text: f.monthlyRent?.toString() ?? '');
    pmShowSheet(
      context,
      title: 'Update tenant / rent',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: tenantCtrl,
            decoration: InputDecoration(
              labelText: 'Tenant name',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Tenant phone',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: rentCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Monthly rent (₹)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: pmNavy, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: () {
                PmStore.instance.updateTenantName(f, tenantCtrl.text.trim().isEmpty ? null : tenantCtrl.text.trim());
                PmStore.instance.updateTenantPhone(f, phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim());
                PmStore.instance.updateRent(f, int.tryParse(rentCtrl.text.trim()));
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _familyTab(PmFlat f) {
    return Column(
      children: [
        Expanded(
          child: f.familyMembers.isEmpty
              ? const Padding(padding: EdgeInsets.all(16), child: PmEmptyState(icon: Icons.people_outline, message: 'No family members added yet.'))
              : ListView.builder(
                  // Plain builder, not .separated - PmEntityCard already
                  // carries its own bottom margin for consistent spacing.
                  padding: const EdgeInsets.all(16),
                  itemCount: f.familyMembers.length,
                  itemBuilder: (_, i) {
                    final m = f.familyMembers[i];
                    return PmEntityCard(
                      icon: Icons.person_outline,
                      accent: PmColors.tenant,
                      title: m.name,
                      subtitle: m.relation,
                      details: m.phone != null ? [PmCardDetail(icon: Icons.call_outlined, text: m.phone!)] : null,
                    );
                  },
                ),
        ),
        _addButton('Add family member', () => pmShowSheet(context, title: 'Add family member', child: AddFamilyMemberForm(flat: f))),
      ],
    );
  }

  Widget _rentTab(PmFlat f) {
    final sorted = [...f.payments]..sort((a, b) => b.date.compareTo(a.date));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: PmGlassCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Received (demo)', style: TextStyle(color: PmTheme.textSecondary, fontSize: 11)),
                      Text(pmFormatInr(f.recordedReceived), style: TextStyle(color: PmColors.rentSoft, fontSize: 18, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pending confirm (demo)', style: TextStyle(color: PmTheme.textSecondary, fontSize: 11)),
                      Text(pmFormatInr(f.pendingConfirmation), style: TextStyle(color: PmColors.pending, fontSize: 18, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: sorted.isEmpty
              ? const Padding(padding: EdgeInsets.all(16), child: PmEmptyState(icon: Icons.receipt_long_outlined, message: 'No payments logged yet.'))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: sorted.length,
                  separatorBuilder: (_, __) => Divider(color: PmTheme.divider),
                  itemBuilder: (_, i) {
                    final p = sorted[i];
                    final isPending = p.status == PaymentStatus.pending;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(isPending ? Icons.hourglass_empty : Icons.check_circle_outline,
                          color: isPending ? Colors.amber : Colors.greenAccent),
                      title: Text(pmFormatInr(p.amount), style: TextStyle(color: PmTheme.textPrimary, fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '${pmDateLabel(p.date)} - ${pmPaymentMethodLabel(p.method)}${p.reportedByTenant ? ' - tenant reported' : ''}',
                        style: TextStyle(color: PmTheme.textMuted, fontSize: 11.5),
                      ),
                      trailing: isPending
                          ? TextButton(
                              onPressed: () => PmStore.instance.confirmPayment(f, p),
                              child: const Text('Confirm'),
                            )
                          : const PmStatusBadge(label: 'Confirmed', color: Colors.greenAccent),
                    );
                  },
                ),
        ),
        _addButton('Record payment', () => pmShowSheet(context, title: 'Record payment', child: AddPaymentForm(flat: f))),
      ],
    );
  }

  Widget _vehiclesTab(PmFlat f) {
    return Column(
      children: [
        Expanded(
          child: f.vehicles.isEmpty
              ? const Padding(padding: EdgeInsets.all(16), child: PmEmptyState(icon: Icons.directions_car_outlined, message: 'No vehicles on record.'))
              : ListView.builder(
                  // Plain builder, not .separated - PmEntityCard already
                  // carries its own bottom margin for consistent spacing.
                  padding: const EdgeInsets.all(16),
                  itemCount: f.vehicles.length,
                  itemBuilder: (_, i) {
                    final v = f.vehicles[i];
                    return PmEntityCard(
                      icon: v.type == 'Car' ? Icons.directions_car_outlined : Icons.two_wheeler_outlined,
                      accent: PmColors.vehicle,
                      title: v.model != null ? '${v.type} - ${v.model}' : v.type,
                      subtitle: v.note,
                    );
                  },
                ),
        ),
        _addButton('Add vehicle', () => pmShowSheet(context, title: 'Add vehicle', child: AddVehicleForm(flat: f))),
      ],
    );
  }

  Widget _documentsTab(PmFlat f) {
    return Column(
      children: [
        Expanded(
          child: f.documents.isEmpty
              ? const Padding(padding: EdgeInsets.all(16), child: PmEmptyState(icon: Icons.folder_outlined, message: 'No documents added yet.'))
              : ListView.builder(
                  // Plain builder, not .separated - PmEntityCard already
                  // carries its own bottom margin for consistent spacing.
                  padding: const EdgeInsets.all(16),
                  itemCount: f.documents.length,
                  itemBuilder: (_, i) {
                    final d = f.documents[i];
                    return PmEntityCard(
                      icon: Icons.description_outlined,
                      accent: PmColors.document,
                      title: d.title,
                      subtitle: '${d.type} - added ${pmDateLabel(d.addedOn)}',
                      details: [
                        PmCardDetail(
                          icon: d.sharedWithTenant ? Icons.visibility_outlined : Icons.lock_outline,
                          text: d.sharedWithTenant ? 'Shared with tenant' : 'Owner only',
                        ),
                      ],
                    );
                  },
                ),
        ),
        _addButton('Add document', () => pmShowSheet(context, title: 'Add document', child: AddDocumentForm(flat: f))),
      ],
    );
  }

  Widget _servicesTab(PmFlat f) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PmSectionHeader(title: 'Maintenance requests'),
        const SizedBox(height: 8),
        if (f.maintenanceRequests.isEmpty)
          const PmEmptyState(icon: Icons.build_outlined, message: 'No maintenance requests yet.')
        else
          for (final r in f.maintenanceRequests.reversed) _maintenanceRow(r),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => pmShowSheet(context, title: 'Raise maintenance request', child: AddMaintenanceForm(flat: f)),
            icon: Icon(Icons.add, color: PmTheme.textSecondary),
            label: Text('Raise request', style: TextStyle(color: PmTheme.textSecondary)),
          ),
        ),
        const SizedBox(height: 10),
        Divider(color: PmTheme.divider),
        const SizedBox(height: 10),
        const PmSectionHeader(title: 'Notice / move-out'),
        const SizedBox(height: 8),
        if (f.notice == null)
          const PmEmptyState(icon: Icons.event_busy_outlined, message: 'No notice on file.')
        else
          _noticeCard(f.notice!),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => pmShowSheet(context, title: 'Give notice', child: GiveNoticeForm(flat: f, raisedBy: NoticeRaisedBy.owner)),
            icon: Icon(Icons.add, color: PmTheme.textSecondary),
            label: Text('Give / update notice', style: TextStyle(color: PmTheme.textSecondary)),
          ),
        ),
      ],
    );
  }

  Widget _maintenanceRow(PmMaintenanceRequest r) {
    final color = switch (r.status) {
      MaintenanceStatus.open => Colors.redAccent,
      MaintenanceStatus.inProgress => Colors.amber,
      MaintenanceStatus.resolved => Colors.greenAccent,
    };
    final label = switch (r.status) {
      MaintenanceStatus.open => 'Open',
      MaintenanceStatus.inProgress => 'In progress',
      MaintenanceStatus.resolved => 'Resolved',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: PmGlassCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.title, style: TextStyle(color: PmTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 2),
                  if (r.description.isNotEmpty)
                    Text(r.description, style: TextStyle(color: PmTheme.textSecondary, fontSize: 11.5)),
                  const SizedBox(height: 2),
                  Text('Raised ${pmDateLabel(r.raisedOn)}${r.raisedByTenant ? ' by tenant' : ''}',
                      style: TextStyle(color: PmTheme.textMuted, fontSize: 10.5)),
                ],
              ),
            ),
            PopupMenuButton<MaintenanceStatus>(
              icon: PmStatusBadge(label: label, color: color),
              onSelected: (s) => PmStore.instance.updateMaintenanceStatus(r, s),
              itemBuilder: (_) => const [
                PopupMenuItem(value: MaintenanceStatus.open, child: Text('Open')),
                PopupMenuItem(value: MaintenanceStatus.inProgress, child: Text('In progress')),
                PopupMenuItem(value: MaintenanceStatus.resolved, child: Text('Resolved')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _noticeCard(PmNotice n) {
    final color = switch (n.status) {
      NoticeStatus.pending => Colors.amber,
      NoticeStatus.accepted => Colors.greenAccent,
      NoticeStatus.rejected => Colors.redAccent,
    };
    final label = switch (n.status) {
      NoticeStatus.pending => 'Pending',
      NoticeStatus.accepted => 'Accepted',
      NoticeStatus.rejected => 'Rejected',
    };
    return PmGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Proposed vacate: ${pmDateLabel(n.proposedVacateDate)}',
                  style: TextStyle(color: PmTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
              PmStatusBadge(label: label, color: color),
            ],
          ),
          if (n.reason != null) ...[
            const SizedBox(height: 4),
            Text(n.reason!, style: TextStyle(color: PmTheme.textSecondary, fontSize: 12)),
          ],
          Text('Raised by ${n.raisedBy == NoticeRaisedBy.tenant ? 'tenant' : 'owner'} on ${pmDateLabel(n.raisedOn)}',
              style: TextStyle(color: PmTheme.textMuted, fontSize: 10.5)),
          if (n.status == NoticeStatus.pending) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                TextButton(
                  onPressed: () => PmStore.instance.updateNoticeStatus(widget.flat, NoticeStatus.accepted),
                  child: const Text('Accept'),
                ),
                TextButton(
                  onPressed: () => PmStore.instance.updateNoticeStatus(widget.flat, NoticeStatus.rejected),
                  child: const Text('Reject'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _addButton(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(Icons.add, color: PmTheme.textPrimary),
          label: Text(label, style: TextStyle(color: PmTheme.textPrimary)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: PmTheme.divider),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}

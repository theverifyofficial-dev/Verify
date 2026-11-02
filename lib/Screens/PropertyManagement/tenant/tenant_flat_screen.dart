import 'package:flutter/material.dart';
import '../../../model/property_management/pm_models.dart';
import '../../../data/property_management/pm_store.dart';
import '../../../custom_widget/property_management/pm_shared_widgets.dart';
import '../../../custom_widget/property_management/pm_forms.dart';

/// Tenant's own flat - My Home / Rent & Bills / Family / Vehicles /
/// Documents / Services & Notice. Everything here is scoped to this ONE
/// flat only - a tenant must never see other flats, other tenants, or
/// the owner's portfolio-wide numbers (per the owner's explicit privacy
/// rule). Documents only show the ones the owner marked "shared with
/// tenant"; everything else stays owner-only.
class TenantFlatScreen extends StatefulWidget {
  final PmBuilding building;
  final PmFlat flat;
  final int initialTab;
  const TenantFlatScreen({super.key, required this.building, required this.flat, this.initialTab = 0});

  @override
  State<TenantFlatScreen> createState() => _TenantFlatScreenState();
}

class _TenantFlatScreenState extends State<TenantFlatScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 6, vsync: this, initialIndex: widget.initialTab);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PmStore.instance,
      builder: (context, _) {
        final b = widget.building;
        final f = widget.flat;
        return Scaffold(
          backgroundColor: PmTheme.bg,
          appBar: AppBar(
            backgroundColor: PmTheme.bg,
            elevation: 0,
            title: Text('${b.name} - Flat ${f.flatNo}', style: TextStyle(color: PmTheme.textPrimary, fontSize: 16)),
            iconTheme: IconThemeData(color: PmTheme.textPrimary),
            actions: const [PmThemeToggle(), SizedBox(width: 6)],
            bottom: TabBar(
              controller: _tabs,
              isScrollable: true,
              indicatorColor: PmColors.building,
              labelColor: PmTheme.textPrimary,
              unselectedLabelColor: PmTheme.textMuted,
              tabs: const [
                Tab(text: 'My Home'),
                Tab(text: 'Rent & Bills'),
                Tab(text: 'Family'),
                Tab(text: 'Vehicles'),
                Tab(text: 'Documents'),
                Tab(text: 'Services & Notice'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabs,
            children: [
              _myHomeTab(b, f),
              _rentTab(f),
              _familyTab(f),
              _vehiclesTab(f),
              _documentsTab(f),
              _servicesTab(f),
            ],
          ),
        );
      },
    );
  }

  Widget _myHomeTab(PmBuilding b, PmFlat f) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PmPreviewBanner(),
        const SizedBox(height: 14),
        PmGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PmSectionHeader(title: 'Property details'),
              const SizedBox(height: 8),
              _line('Building', b.name),
              _line('Flat', '${f.floorLabel} - ${f.flatNo}${f.bhk != null ? ' (${f.bhk})' : ''}'),
              _line('Furnished', f.furnished == true ? 'Yes' : (f.furnished == false ? 'No' : 'Not provided')),
            ],
          ),
        ),
        const SizedBox(height: 14),
        PmGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PmSectionHeader(title: 'Owner & caretaker'),
              const SizedBox(height: 8),
              _contactRow('Owner', PmStore.instance.portfolio.ownerName, null),
              _contactRow('Caretaker', b.caretaker ?? 'Not provided', null),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Phone numbers are not on record in this demo, so call/message are disabled.',
                    style: TextStyle(color: PmTheme.textMuted, fontSize: 10.5)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _contactRow(String role, String name, String? phone) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(color: PmTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                Text(role, style: TextStyle(color: PmTheme.textMuted, fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => pmShowSnack(context, 'No phone number on record for $role.'),
            icon: Icon(Icons.call_outlined, color: PmTheme.textMuted.withOpacity(0.6)),
          ),
          IconButton(
            onPressed: () => pmShowSnack(context, 'No phone number on record for $role.'),
            icon: Icon(Icons.chat_outlined, color: PmTheme.textMuted.withOpacity(0.6)),
          ),
        ],
      ),
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

  Widget _rentTab(PmFlat f) {
    final sorted = [...f.payments]..sort((a, b) => b.date.compareTo(a.date));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: PmGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Monthly rent', style: TextStyle(color: PmTheme.textSecondary, fontSize: 12)),
                Text(f.monthlyRent != null ? pmFormatInr(f.monthlyRent!) : 'Not on record',
                    style: TextStyle(color: PmTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('Recorded received (demo): ${pmFormatInr(f.recordedReceived)}',
                    style: TextStyle(color: PmTheme.textMuted, fontSize: 11.5)),
                Text('Pending confirmation (demo): ${pmFormatInr(f.pendingConfirmation)}',
                    style: TextStyle(color: PmTheme.textMuted, fontSize: 11.5)),
              ],
            ),
          ),
        ),
        Expanded(
          child: sorted.isEmpty
              ? const Padding(padding: EdgeInsets.all(16), child: PmEmptyState(icon: Icons.receipt_long_outlined, message: 'No payment history yet.'))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: sorted.length,
                  separatorBuilder: (_, __) => Divider(color: PmTheme.divider),
                  itemBuilder: (_, i) {
                    final p = sorted[i];
                    final pending = p.status == PaymentStatus.pending;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(pending ? Icons.hourglass_empty : Icons.check_circle_outline, color: pending ? Colors.amber : Colors.greenAccent),
                      title: Text(pmFormatInr(p.amount), style: TextStyle(color: PmTheme.textPrimary, fontWeight: FontWeight.w600)),
                      subtitle: Text('${pmDateLabel(p.date)} - ${pmPaymentMethodLabel(p.method)}', style: TextStyle(color: PmTheme.textMuted, fontSize: 11.5)),
                      trailing: PmStatusBadge(label: pending ? 'Awaiting owner' : 'Confirmed', color: pending ? Colors.amber : Colors.greenAccent),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: pmNavy, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: () => pmShowSheet(context, title: 'Report a payment', child: AddPaymentForm(flat: f, asTenantReport: true)),
              child: const Text('Report a payment'),
            ),
          ),
        ),
      ],
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
                    );
                  },
                ),
        ),
        _addButton('Add family member', () => pmShowSheet(context, title: 'Add family member', child: AddFamilyMemberForm(flat: f))),
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
                    );
                  },
                ),
        ),
        _addButton('Add vehicle', () => pmShowSheet(context, title: 'Add vehicle', child: AddVehicleForm(flat: f))),
      ],
    );
  }

  Widget _documentsTab(PmFlat f) {
    final shared = f.documents.where((d) => d.sharedWithTenant).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (shared.isEmpty)
          const PmEmptyState(icon: Icons.folder_outlined, message: 'The owner hasn\'t shared any documents with you yet.')
        else
          for (final d in shared)
            PmEntityCard(
              icon: Icons.description_outlined,
              accent: PmColors.document,
              title: d.title,
              subtitle: '${d.type} - added ${pmDateLabel(d.addedOn)}',
            ),
      ],
    );
  }

  Widget _servicesTab(PmFlat f) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PmSectionHeader(title: 'My requests'),
        const SizedBox(height: 8),
        if (f.maintenanceRequests.isEmpty)
          const PmEmptyState(icon: Icons.build_outlined, message: 'No requests raised yet.')
        else
          for (final r in f.maintenanceRequests.reversed) _maintenanceRow(r),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => pmShowSheet(context, title: 'Raise a request', child: AddMaintenanceForm(flat: f, raisedByTenant: true)),
            icon: Icon(Icons.add, color: PmTheme.textSecondary),
            label: Text('Raise a request', style: TextStyle(color: PmTheme.textSecondary)),
          ),
        ),
        const SizedBox(height: 10),
        Divider(color: PmTheme.divider),
        const SizedBox(height: 10),
        const PmSectionHeader(title: 'Give notice'),
        const SizedBox(height: 8),
        if (f.notice == null)
          const PmEmptyState(icon: Icons.event_busy_outlined, message: 'No notice on file.')
        else
          _noticeCard(f.notice!),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => pmShowSheet(context, title: 'Give notice', child: GiveNoticeForm(flat: f, raisedBy: NoticeRaisedBy.tenant)),
            icon: Icon(Icons.add, color: PmTheme.textSecondary),
            label: Text('Give notice to vacate', style: TextStyle(color: PmTheme.textSecondary)),
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
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.title, style: TextStyle(color: PmTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                  Text('Raised ${pmDateLabel(r.raisedOn)}', style: TextStyle(color: PmTheme.textMuted, fontSize: 10.5)),
                ],
              ),
            ),
            PmStatusBadge(label: label, color: color),
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
      NoticeStatus.pending => 'Pending owner response',
      NoticeStatus.accepted => 'Accepted',
      NoticeStatus.rejected => 'Rejected',
    };
    return PmGlassCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Proposed vacate: ${pmDateLabel(n.proposedVacateDate)}',
                    style: TextStyle(color: PmTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                if (n.reason != null) Text(n.reason!, style: TextStyle(color: PmTheme.textMuted, fontSize: 12)),
              ],
            ),
          ),
          PmStatusBadge(label: label, color: color),
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

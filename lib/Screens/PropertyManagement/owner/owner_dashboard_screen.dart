import 'package:flutter/material.dart';
import '../../../model/property_management/pm_models.dart';
import '../../../data/property_management/pm_store.dart';
import '../../../custom_widget/property_management/pm_shared_widgets.dart';
import '../../../custom_widget/property_management/pm_forms.dart';
import 'building_detail_screen.dart';
import 'reports_screen.dart';
import '../shared/police_verification_screen.dart';
import '../shared/utility_screen.dart';
import '../shared/vehicle_detail_screen.dart';
import '../shared/pick_flat_screen.dart';
import '../shared/pick_building_screen.dart';
import '../../MyData/my_data_service.dart';
import '../shared/pm_live_list_screens.dart';

/// Owner Dashboard (home of Owner mode). Uses the shared PM "theme pack"
/// (pm_shared_widgets.dart) - a gradient hero card for the headline
/// number, color-coded stat/action tiles (green=money, blue=tenants,
/// orange=vehicles/expenses, purple=reports), and colored attention rows
/// - so the screen reads at a glance instead of being flat white-on-navy.
///
/// Buildings/Flats/Agreements/Insurance are real, live data from the
/// owner's account, reached via the live Quick Actions (My Buildings,
/// Agreement, Insurance - see _quickActions() below) rather than shown
/// on the dashboard body itself. Everything else - the property
/// selector, Property overview stats, Police Verification/Utility
/// Bills/Vehicle Details, and the rest of Quick actions' pick-a-
/// flat/building CRUD flows - still reads from PmStore.instance.portfolio,
/// since there is no live backend equivalent yet for those deeper flows.
class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  int? _selectedBuildingIndex; // null = All properties
  bool _amountsHidden = false;
  bool _propertyOverviewExpanded = false;
  bool _quickActionsExpanded = false;

  // Live API data (Future Property / Under-Construction Flats / Live
  // Flats / Agreements / Insurance) - same service that used to back the
  // standalone "My Data" screen (Profile -> My Data, now removed), shown
  // directly on this dashboard instead. Scoped to the owner's own stored
  // mobile number, same as every other call site of this service.
  final MyDataService _apiService = MyDataService();

  PmPortfolio get _portfolio => PmStore.instance.portfolio;

  List<PmBuilding> get _visibleBuildings => _selectedBuildingIndex == null
      ? _portfolio.buildings
      : (_selectedBuildingIndex! < _portfolio.buildings.length
          ? [_portfolio.buildings[_selectedBuildingIndex!]]
          : _portfolio.buildings);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PmStore.instance,
      builder: (context, _) {
        final scopedUnit = _visibleBuildings.fold<int>(0, (s, b) => s + b.unitCount);
        final scopedRented = _visibleBuildings.fold<int>(0, (s, b) => s + b.rentedCount);
        final scopedVacant = _visibleBuildings.fold<int>(0, (s, b) => s + b.vacantCount);
        final scopedSelfUse = _visibleBuildings.fold<int>(0, (s, b) => s + b.selfUseCount);
        final scopedRent = _visibleBuildings.fold<int>(0, (s, b) => s + b.scheduledRent);
        final scopedVehicles = _visibleBuildings.fold<int>(0, (s, b) => s + b.vehicleCount);
        final scopedReceived = _visibleBuildings.fold<int>(0, (s, b) => s + b.recordedReceived);
        final scopedPending = _visibleBuildings.fold<int>(0, (s, b) => s + b.pendingConfirmation);

        return Scaffold(
          backgroundColor: PmTheme.bg,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async => Future.delayed(const Duration(milliseconds: 300)),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  const PmPreviewBanner(),
                  const SizedBox(height: 14),
                  _header(),
                  const SizedBox(height: 18),
                  PmHeroCard(
                    label: 'Scheduled monthly rent',
                    value: _amountsHidden ? '•••••' : pmFormatInr(scopedRent),
                    subtitle: 'What tenants are expected to pay - not confirmed income yet',
                    icon: Icons.account_balance_wallet_outlined,
                    trailing: IconButton(
                      onPressed: () => setState(() => _amountsHidden = !_amountsHidden),
                      icon: Icon(_amountsHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _financialStats(scopedReceived, scopedPending),
                  const SizedBox(height: 18),
                  // Temporarily disabled - re-enable when ready.
                  // _attentionNeeded(),
                  // const SizedBox(height: 18),
                  _propertyOverview(scopedUnit, scopedRented, scopedVacant, scopedSelfUse, scopedVehicles),
                  const SizedBox(height: 18),
                  _quickActions(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(gradient: PmColors.heroGradient, shape: BoxShape.circle),
              child: const Icon(Icons.apartment_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Property Management - Owner',
                      style: TextStyle(color: PmTheme.textMuted, fontSize: 11.5, fontWeight: FontWeight.w500)),
                  Text('Hello, ${_portfolio.ownerName.split(' ').first}',
                      style: TextStyle(color: PmTheme.textPrimary, fontSize: 21, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const PmThemeToggle(),
          ],
        ),
        const SizedBox(height: 12),
        _propertySelector(),
      ],
    );
  }

  Widget _propertySelector() {
    final chips = <Widget>[
      _chip('All properties', _selectedBuildingIndex == null, () => setState(() => _selectedBuildingIndex = null)),
      for (int i = 0; i < _portfolio.buildings.length; i++)
        _chip(_portfolio.buildings[i].name, _selectedBuildingIndex == i, () => setState(() => _selectedBuildingIndex = i)),
    ];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => chips[i],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected ? PmColors.heroGradient : null,
          color: selected ? null : PmTheme.cardBorder,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? Colors.transparent : PmTheme.divider),
        ),
        child: Text(label,
            style: TextStyle(color: selected ? Colors.white : PmTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _financialStats(int received, int pending) {
    // Single horizontal scrollable row instead of a Wrap - keeps all
    // three chips on one line and lets the row scroll sideways instead
    // of wrapping to a second line on narrow screens.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          PmStatChip(label: 'Received (demo)', value: _amountsHidden ? '•••••' : pmFormatInr(received), icon: Icons.check_circle_outline, color: PmColors.rent),
          const SizedBox(width: 10),
          PmStatChip(label: 'Pending confirm (demo)', value: _amountsHidden ? '•••••' : pmFormatInr(pending), icon: Icons.hourglass_empty, color: PmColors.pending),
          const SizedBox(width: 10),
          PmStatChip(label: 'Overdue', value: 'Not tracked yet', icon: Icons.warning_amber_outlined, color: PmColors.overdue),
        ],
      ),
    );
  }

  Widget _attentionNeeded() {
    final vacant = _portfolio.vacantFlats;
    final maintenance = _portfolio.openMaintenanceRequests;
    final notices = _portfolio.pendingNotices;
    final total = vacant.length + maintenance.length + notices.length;

    return PmGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PmSectionHeader(title: 'Attention needed', icon: Icons.notifications_active_outlined, iconColor: PmColors.pending),
          const SizedBox(height: 10),
          if (total == 0)
            Text('Nothing needs attention right now.', style: TextStyle(color: PmTheme.textMuted, fontSize: 13)),
          for (final v in vacant.take(2))
            PmAttentionRow(
              icon: Icons.meeting_room_outlined,
              level: PmAttentionLevel.warning,
              title: '${v.key.name} - Flat ${v.value.flatNo} is vacant',
              subtitle: v.value.askingRent != null ? 'Asking ${pmFormatInr(v.value.askingRent!)}/month' : 'Asking rent not provided',
              actionLabel: 'View',
              onTap: () => _openFlat(v.key, v.value),
            ),
          for (final m in maintenance.take(2))
            PmAttentionRow(
              icon: Icons.build_outlined,
              level: PmAttentionLevel.info,
              title: '${m.key.name} - Flat ${m.value.flatNo} has an open request',
              subtitle: m.value.maintenanceRequests.last.title,
              actionLabel: 'View',
              onTap: () => _openFlat(m.key, m.value),
            ),
          for (final n in notices.take(2))
            PmAttentionRow(
              icon: Icons.event_busy_outlined,
              level: PmAttentionLevel.critical,
              title: '${n.key.name} - Flat ${n.value.flatNo} has a pending notice',
              subtitle: 'Proposed vacate: ${pmDateLabel(n.value.notice!.proposedVacateDate)}',
              actionLabel: 'View',
              onTap: () => _openFlat(n.key, n.value),
            ),
        ],
      ),
    );
  }

  Widget _propertyOverview(int unit, int rented, int vacant, int selfUse, int vehicles) {
    final allChips = [
      PmStatChip(label: 'Buildings', value: '${_visibleBuildings.length}', icon: Icons.apartment_outlined, color: PmColors.building),
      PmStatChip(label: 'Units', value: '$unit', icon: Icons.door_front_door_outlined, color: PmColors.tenant),
      PmStatChip(label: 'Rented', value: '$rented', icon: Icons.check_circle_outline, color: PmColors.rent),
      PmStatChip(label: 'Vacant', value: '$vacant', icon: Icons.meeting_room_outlined, color: PmColors.pending),
      PmStatChip(label: 'Self-use', value: '$selfUse', icon: Icons.home_outlined, color: Colors.blueGrey),
      PmStatChip(label: 'Vehicles', value: '$vehicles', icon: Icons.directions_car_outlined, color: PmColors.vehicle),
    ];
    const visibleCount = 3;
    final hasMore = allChips.length > visibleCount;
    final shown = (_propertyOverviewExpanded || !hasMore) ? allChips : allChips.take(visibleCount).toList();
    return PmGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show More/Show Less sits in the header's top-right corner
          // instead of below the chips.
          PmSectionHeader(
            title: 'Property overview',
            icon: Icons.pie_chart_outline,
            iconColor: PmColors.building,
            trailing: hasMore
                ? PmShowMoreButton(
                    expanded: _propertyOverviewExpanded,
                    onTap: () => setState(() => _propertyOverviewExpanded = !_propertyOverviewExpanded),
                  )
                : null,
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 10, runSpacing: 10, children: shown),
        ],
      ),
    );
  }

  Widget _quickActions() {
    final allActions = [
      PmActionButton(icon: Icons.payments_outlined, label: 'Record\nPayment', color: PmColors.rent, onTap: _pickFlatThenRecordPayment),
      PmActionButton(icon: Icons.domain_add_outlined, label: 'Add\nProperty', color: PmColors.building, onTap: () {
        pmShowSheet(context, title: 'Add building', child: const AddBuildingForm());
      }),
      PmActionButton(
        icon: Icons.apartment_outlined,
        label: 'My\nBuildings',
        color: PmColors.building,
        live: true,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PmLiveRecordListScreen(
              title: 'My Buildings',
              icon: Icons.apartment_outlined,
              accent: PmColors.building,
              emptyMessage: 'No buildings found for your account yet.',
              fetch: _apiService.fetchFutureProperties,
              onTapRecord: (ctx, record) => Navigator.push(
                ctx,
                MaterialPageRoute(builder: (_) => PmBuildingFlatsScreen(building: record)),
              ),
            ),
          ),
        ),
      ),
      PmActionButton(icon: Icons.receipt_long_outlined, label: 'Add\nExpense', color: PmColors.expense, onTap: _pickBuildingThenAddExpense),
      PmActionButton(icon: Icons.bar_chart_outlined, label: 'Reports', color: PmColors.reports, onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
      }),
      PmActionButton(
        icon: Icons.description_outlined,
        label: 'Agreement',
        color: PmColors.agreement,
        live: true,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PmLiveRecordListScreen(
              title: 'Agreements',
              icon: Icons.description_outlined,
              accent: PmColors.agreement,
              emptyMessage: 'No agreements found.',
              fetch: _apiService.fetchAgreements,
            ),
          ),
        ),
      ),
      PmActionButton(
        icon: Icons.verified_user_outlined,
        label: 'Police\nVerification',
        color: PmColors.verification,
        onTap: () => _pickFlatThenOpen('Verification - choose flat', (context, b, f) => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PoliceVerificationScreen(building: b, flat: f)))),
      ),
      PmActionButton(
        icon: Icons.shield_outlined,
        label: 'Insurance',
        color: PmColors.insurance,
        live: true,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PmLiveRecordListScreen(
              title: 'Insurance',
              icon: Icons.shield_outlined,
              accent: PmColors.insurance,
              emptyMessage: 'No insurance details found.',
              fetch: _apiService.fetchInsurance,
            ),
          ),
        ),
      ),
      PmActionButton(
        icon: Icons.speed_outlined,
        label: 'Utility\nBills',
        color: PmColors.utility,
        onTap: () => _pickFlatThenOpen('Utility bills - choose flat', (context, b, f) => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => UtilityScreen(building: b, flat: f)))),
      ),
      PmActionButton(
        icon: Icons.directions_car_filled_outlined,
        label: 'Vehicle\nDetails',
        color: PmColors.vehicle,
        onTap: () => _pickFlatThenOpen('Vehicle details - choose flat', (context, b, f) => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => VehicleDetailScreen(building: b, flat: f)))),
      ),
    ];
    const visibleCount = 3;
    final hasMore = allActions.length > visibleCount;
    final shown = (_quickActionsExpanded || !hasMore) ? allActions : allActions.take(visibleCount).toList();
    return PmGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show More/Show Less sits in the header's top-right corner
          // instead of below the action buttons.
          PmSectionHeader(
            title: 'Quick actions',
            icon: Icons.bolt_outlined,
            iconColor: PmColors.rent,
            trailing: hasMore
                ? PmShowMoreButton(
                    expanded: _quickActionsExpanded,
                    onTap: () => setState(() => _quickActionsExpanded = !_quickActionsExpanded),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 10, runSpacing: 10, children: shown),
        ],
      ),
    );
  }

  void _pickFlatThenOpen(String title, void Function(BuildContext, PmBuilding, PmFlat) onPick) {
    final allFlats = <MapEntry<PmBuilding, PmFlat>>[];
    for (final b in _portfolio.buildings) {
      for (final f in b.flats) {
        allFlats.add(MapEntry(b, f));
      }
    }
    if (allFlats.isEmpty) {
      pmShowSnack(context, 'Add a flat first.');
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => PickFlatScreen(title: title, flats: allFlats, onPick: onPick)));
  }

  void _openFlat(PmBuilding building, PmFlat flat) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => BuildingDetailScreen(building: building, openFlat: flat)));
  }

  void _pickFlatThenRecordPayment() {
    final rentedFlats = <MapEntry<PmBuilding, PmFlat>>[];
    for (final b in _portfolio.buildings) {
      for (final f in b.flats) {
        if (f.status == FlatStatus.rented) rentedFlats.add(MapEntry(b, f));
      }
    }
    if (rentedFlats.isEmpty) {
      pmShowSnack(context, 'No rented flats to record a payment against yet.');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PickFlatScreen(
          title: 'Record payment - choose flat',
          flats: rentedFlats,
          onPick: (context, building, flat) {
            Navigator.pop(context);
            pmShowSheet(context, title: 'Record payment', child: AddPaymentForm(flat: flat));
          },
        ),
      ),
    );
  }

  void _pickBuildingThenAddExpense() {
    if (_portfolio.buildings.isEmpty) {
      pmShowSnack(context, 'Add a building first.');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PickBuildingScreen(
          title: 'Add expense - choose building',
          buildings: _portfolio.buildings,
          onPick: (context, building) {
            Navigator.pop(context);
            pmShowSheet(context, title: 'Add expense', child: AddExpenseForm(building: building));
          },
        ),
      ),
    );
  }
}

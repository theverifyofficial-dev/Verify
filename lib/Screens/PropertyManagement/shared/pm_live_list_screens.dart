import 'package:flutter/material.dart';

import '../../../model/my_data_models.dart';
import '../../MyData/my_data_service.dart';
import '../../../custom_widget/property_management/pm_shared_widgets.dart';

/// Full-page screens for the live "My Data" API categories, reached from
/// Owner Dashboard Quick Actions ("My Buildings", "Agreement",
/// "Insurance") rather than shown wholesale on the dashboard itself -
/// see pm_shared_widgets.dart for PmSmartRecordCard/PmApiRecordHeroHeader
/// (the shared presentation these screens are built from) and
/// my_data_models.dart/my_data_service.dart for the data layer.

/// Generic full-page list for one live API category - used directly for
/// Agreements/Insurance, and as the entry point for My Buildings before
/// drilling into [PmBuildingFlatsScreen]. Themed top bar (not a bare
/// AppBar, to match the rest of this module), pull-to-refresh, and
/// [PmSmartRecordCard] rows. Tapping a record pushes
/// [PmApiRecordDetailScreen] unless [onTapRecord] overrides that (My
/// Buildings uses the override to drill into that building's flats
/// instead of a flat field dump).
class PmLiveRecordListScreen extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color accent;
  final String emptyMessage;
  final Future<List<DataRecord>> Function() fetch;
  final void Function(BuildContext context, DataRecord record)? onTapRecord;

  const PmLiveRecordListScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.accent,
    required this.emptyMessage,
    required this.fetch,
    this.onTapRecord,
  });

  @override
  State<PmLiveRecordListScreen> createState() => _PmLiveRecordListScreenState();
}

class _PmLiveRecordListScreenState extends State<PmLiveRecordListScreen> {
  late Future<List<DataRecord>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.fetch();
  }

  Future<void> _refresh() async {
    final next = widget.fetch();
    setState(() => _future = next);
    await next;
  }

  void _openRecord(DataRecord record) {
    if (widget.onTapRecord != null) {
      widget.onTapRecord!(context, record);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PmApiRecordDetailScreen(
          record: record,
          sectionTitle: widget.title,
          icon: widget.icon,
          accent: widget.accent,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PmTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            pmLiveTopBar(context, title: widget.title, icon: widget.icon, accent: widget.accent),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                color: widget.accent,
                child: FutureBuilder<List<DataRecord>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(color: widget.accent));
                    }
                    if (snapshot.hasError) {
                      return pmLiveMessageList(
                        icon: snapshot.error is MissingOwnerNumberException ? Icons.lock_outline : Icons.wifi_off_rounded,
                        message: snapshot.error is MissingOwnerNumberException
                            ? 'Please log in again to load this.'
                            : "Couldn't load this - pull down to retry.",
                      );
                    }
                    final data = snapshot.data ?? const [];
                    if (data.isEmpty) {
                      return pmLiveMessageList(icon: widget.icon, message: widget.emptyMessage);
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      itemCount: data.length,
                      itemBuilder: (context, i) => PmSmartRecordCard(
                        record: data[i],
                        accent: widget.accent,
                        fallbackIcon: widget.icon,
                        onTap: () => _openRecord(data[i]),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Drill-down screen reached by tapping a building in the live "My
/// Buildings" list - a hero header for the building itself (reusing
/// [PmApiRecordHeroHeader], the same header the flat/agreement/insurance
/// detail page uses), then that building's flats fetched from the Live
/// Flats and Under-Construction Flats endpoints below it.
///
/// Neither flats endpoint takes a "which building" query parameter -
/// both are scoped to the owner only - so this makes a best-effort
/// attempt to keep only the flats that look like they belong to this
/// building (matching the building's own name against each flat's raw
/// fields) and is upfront about it when that match can't be made
/// confidently, rather than silently showing an empty "no flats" list
/// when the real reason is that the API doesn't link them at all.
class PmBuildingFlatsScreen extends StatefulWidget {
  final DataRecord building;
  const PmBuildingFlatsScreen({super.key, required this.building});

  @override
  State<PmBuildingFlatsScreen> createState() => _PmBuildingFlatsScreenState();
}

class _PmBuildingFlatsScreenState extends State<PmBuildingFlatsScreen> {
  final MyDataService _service = MyDataService();
  late Future<List<LiveFlatRecord>> _liveFuture;
  late Future<List<UnderFuturePropertyFlatRecord>> _underConstructionFuture;

  @override
  void initState() {
    super.initState();
    _liveFuture = _service.fetchLiveFlats();
    _underConstructionFuture = _service.fetchUnderFutureFlats();
  }

  Future<void> _refresh() async {
    final live = _service.fetchLiveFlats();
    final underConstruction = _service.fetchUnderFutureFlats();
    setState(() {
      _liveFuture = live;
      _underConstructionFuture = underConstruction;
    });
    await Future.wait([live, underConstruction]);
  }

  /// Keeps only flats whose raw fields contain the building's own title
  /// somewhere, scoping them to the building that was tapped. If NONE of
  /// the owner's flats match for a non-empty list - meaning the API
  /// likely isn't returning a building-identifying field this heuristic
  /// can find, not that this specific building simply has none - keeps
  /// every flat instead and flags that in [_ScopedFlats.confident] so
  /// the UI can disclose it.
  _ScopedFlats<T> _scopedTo<T extends DataRecord>(List<T> flats) {
    final needle = widget.building.title.trim().toLowerCase();
    if (needle.isEmpty || flats.isEmpty) return _ScopedFlats(flats, true);
    final matched = flats.where((f) {
      return f.raw.values.any((v) => v != null && v.toString().toLowerCase().contains(needle));
    }).toList();
    if (matched.isNotEmpty) return _ScopedFlats(matched, true);
    return _ScopedFlats(flats, false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PmTheme.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: PmColors.building,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              PmApiRecordHeroHeader(
                record: widget.building,
                sectionTitle: 'My Buildings',
                icon: Icons.apartment_outlined,
                accent: PmColors.building,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _flatGroup(
                      title: 'Live Flats',
                      icon: Icons.home_work_outlined,
                      accent: PmColors.rent,
                      future: _liveFuture,
                      emptyMessage: 'No live flats found for your account yet.',
                    ),
                    const SizedBox(height: 20),
                    _flatGroup(
                      title: 'Flats Under Construction',
                      icon: Icons.construction_outlined,
                      accent: PmColors.pending,
                      future: _underConstructionFuture,
                      emptyMessage: 'No under-construction flats found for your account yet.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _flatGroup<T extends DataRecord>({
    required String title,
    required IconData icon,
    required Color accent,
    required Future<List<T>> future,
    required String emptyMessage,
  }) {
    return FutureBuilder<List<T>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PmSectionHeader(title: title, icon: icon, iconColor: accent),
              const SizedBox(height: 10),
              Center(child: CircularProgressIndicator(strokeWidth: 2, color: accent)),
            ],
          );
        }
        if (snapshot.hasError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PmSectionHeader(title: title, icon: icon, iconColor: accent),
              const SizedBox(height: 10),
              Text("Couldn't load this.", style: TextStyle(color: PmTheme.textSecondary, fontSize: 12.5)),
            ],
          );
        }
        // Explicit <T> on both sides - without it, type inference for
        // _scopedTo's own generic parameter can't settle on T from an
        // ambiguous `const []` here and falls back to the DataRecord
        // bound, which a plain List<dynamic> doesn't satisfy.
        final scoped = _scopedTo<T>(snapshot.data ?? <T>[]);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PmSectionHeader(title: title, icon: icon, iconColor: accent),
            if (!scoped.confident) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: PmColors.pending.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: PmColors.pending.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 13, color: PmColors.pending),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "Couldn't confirm which flats belong to this building yet - showing all your flats here.",
                        style: TextStyle(color: PmColors.pending, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            if (scoped.flats.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(emptyMessage, style: TextStyle(color: PmTheme.textMuted, fontSize: 12.5)),
              )
            else
              for (final flat in scoped.flats)
                PmSmartRecordCard(
                  record: flat,
                  accent: accent,
                  fallbackIcon: icon,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PmApiRecordDetailScreen(record: flat, sectionTitle: title, icon: icon, accent: accent),
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}

class _ScopedFlats<T> {
  final List<T> flats;
  final bool confident;
  const _ScopedFlats(this.flats, this.confident);
}

/// Shared themed top bar for the live list screens - back button, icon
/// badge, title, and a LIVE pill - used instead of a bare AppBar so
/// these pages read like the rest of this PmTheme-driven module.
Widget pmLiveTopBar(BuildContext context, {required String title, required IconData icon, required Color accent}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
    child: Row(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: accent.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(Icons.arrow_back, color: accent, size: 18),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: accent.withOpacity(0.14), shape: BoxShape.circle),
          child: Icon(icon, color: accent, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(title, style: TextStyle(color: PmTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: PmColors.rent.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
          child: Text('LIVE', style: TextStyle(color: PmColors.rent, fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        ),
      ],
    ),
  );
}

/// Shared "nothing to show" state for the live list screens - wrapped in
/// a scrollable list (not a bare Center) so RefreshIndicator's
/// pull-to-refresh gesture still works from an empty/error state.
Widget pmLiveMessageList({required IconData icon, required String message}) {
  return ListView(
    children: [
      const SizedBox(height: 120),
      Icon(icon, size: 36, color: PmTheme.iconMuted),
      const SizedBox(height: 10),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(message, textAlign: TextAlign.center, style: TextStyle(color: PmTheme.textSecondary, fontSize: 13)),
      ),
    ],
  );
}

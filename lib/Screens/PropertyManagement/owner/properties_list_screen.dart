import 'package:flutter/material.dart';
import '../../../model/property_management/pm_models.dart';
import '../../../data/property_management/pm_store.dart';
import '../../../custom_widget/property_management/pm_shared_widgets.dart';
import '../../../custom_widget/property_management/pm_forms.dart';
import 'building_detail_screen.dart';

class PropertiesListScreen extends StatefulWidget {
  const PropertiesListScreen({super.key});

  @override
  State<PropertiesListScreen> createState() => _PropertiesListScreenState();
}

class _PropertiesListScreenState extends State<PropertiesListScreen> {
  String _query = '';

  // Same accent rotation as the Owner Dashboard's My Buildings grid, so
  // a given building reads with the same color wherever it's shown.
  static const _buildingAccents = [PmColors.building, Color(0xFFB084F5), Color(0xFF4F9DFF), Color(0xFFFF9F43)];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PmStore.instance,
      builder: (context, _) {
        final buildings = PmStore.instance.portfolio.buildings
            .where((b) => b.name.toLowerCase().contains(_query.toLowerCase()))
            .toList();

        return Scaffold(
          backgroundColor: PmTheme.bg,
          appBar: AppBar(
            backgroundColor: PmTheme.bg,
            elevation: 0,
            title: Text('My Properties', style: TextStyle(color: PmTheme.textPrimary)),
            iconTheme: IconThemeData(color: PmTheme.textPrimary),
            actions: const [PmThemeToggle(), SizedBox(width: 6)],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PmPreviewBanner(),
                  const SizedBox(height: 12),
                  TextField(
                    style: TextStyle(color: PmTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search building or flat...',
                      hintStyle: TextStyle(color: PmTheme.textMuted),
                      prefixIcon: Icon(Icons.search, color: PmTheme.iconMuted),
                      filled: true,
                      fillColor: PmTheme.cardBorder,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: buildings.isEmpty
                        ? PmEmptyState(
                            icon: Icons.apartment_outlined,
                            message: 'No properties found.',
                          )
                        : ListView.separated(
                            itemCount: buildings.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (_, i) => PmBuildingSummaryCard(
                              building: buildings[i],
                              accent: _buildingAccents[i % _buildingAccents.length],
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BuildingDetailScreen(building: buildings[i]))),
                            ),
                          ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => pmShowSheet(context, title: 'Add building', child: const AddBuildingForm()),
                      icon: Icon(Icons.add, color: PmColors.building),
                      label: Text('List a new property', style: TextStyle(color: PmTheme.textPrimary)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: PmTheme.divider),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

}

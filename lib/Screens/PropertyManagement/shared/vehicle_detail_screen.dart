import 'package:flutter/material.dart';
import '../../../model/property_management/pm_models.dart';
import '../../../data/property_management/pm_store.dart';
import '../../../custom_widget/property_management/pm_shared_widgets.dart';
import '../../../custom_widget/property_management/pm_forms.dart';

/// Upgraded Vehicle section - same underlying `flat.vehicles` list as the
/// simple Vehicles tab (so data never forks into two copies), but with
/// registration number / color fields and per-vehicle editing. Both
/// owner and tenant can add a vehicle or fill in/correct its details.
class VehicleDetailScreen extends StatelessWidget {
  final PmBuilding building;
  final PmFlat flat;
  const VehicleDetailScreen({super.key, required this.building, required this.flat});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PmStore.instance,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: PmTheme.bg,
          appBar: AppBar(
            backgroundColor: PmTheme.bg,
            elevation: 0,
            title: Text('Vehicles - Flat ${flat.flatNo}', style: TextStyle(color: PmTheme.textPrimary, fontSize: 16)),
            iconTheme: IconThemeData(color: PmTheme.textPrimary),
            actions: const [PmThemeToggle(), SizedBox(width: 6)],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: flat.vehicles.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: PmEmptyState(icon: Icons.directions_car_outlined, message: 'No vehicles on record.'),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: flat.vehicles.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, idx) => _vehicleCard(context, flat.vehicles[idx]),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => pmShowSheet(context, title: 'Add vehicle', child: AddVehicleForm(flat: flat)),
                      icon: Icon(Icons.add, color: PmColors.vehicle),
                      label: Text('Add vehicle', style: TextStyle(color: PmTheme.textPrimary)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: PmColors.vehicle.withOpacity(0.4)),
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

  Widget _vehicleCard(BuildContext context, PmVehicle v) {
    return PmGlassCard(
      accent: PmColors.vehicle,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [PmColors.vehicle, PmColors.vehicle.withOpacity(0.6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              shape: BoxShape.circle,
            ),
            child: Icon(v.type == 'Car' ? Icons.directions_car_outlined : Icons.two_wheeler_outlined, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(v.model != null ? '${v.type} - ${v.model}' : v.type, style: TextStyle(color: PmTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                _line('Reg. number', v.regNumber ?? 'Not provided'),
                _line('Color', v.color ?? 'Not provided'),
                if (v.note != null) _line('Note', v.note!),
              ],
            ),
          ),
          TextButton(
            onPressed: () => pmShowSheet(context, title: 'Edit vehicle details', child: EditVehicleDetailsForm(vehicle: v)),
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$label: ', style: TextStyle(color: PmTheme.textMuted, fontSize: 11.5)),
          Expanded(child: Text(value, style: TextStyle(color: PmTheme.textSecondary, fontSize: 11.5))),
        ],
      ),
    );
  }
}

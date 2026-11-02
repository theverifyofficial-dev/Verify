import 'package:flutter/material.dart';
import '../../model/property_management/pm_models.dart';
import '../../data/property_management/pm_store.dart';
import 'pm_shared_widgets.dart';

/// Every "Add"/"Update" form used across the Property Management module.
/// Each form is a small StatefulWidget meant to be opened with
/// `pmShowSheet(context, title: '...', child: SomeForm(...))`. On submit
/// they call a PmStore method (in-memory only - see pm_store.dart) and
/// pop themselves. Kept in one file since they share the same simple
/// pattern and are small individually.

InputDecoration _pmDec(String label, {String? hint}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );
}

Widget _pmSubmitButton(String label, VoidCallback onPressed) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: pmNavy,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    ),
  );
}

Future<DateTime?> _pmPickDate(BuildContext context, DateTime initial) {
  final now = DateTime.now();
  return showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(now.year - 3),
    lastDate: DateTime(now.year + 3),
  );
}

// =====================================================================
// Add Payment
// =====================================================================
class AddPaymentForm extends StatefulWidget {
  final PmFlat flat;
  final bool asTenantReport;
  const AddPaymentForm({super.key, required this.flat, this.asTenantReport = false});

  @override
  State<AddPaymentForm> createState() => _AddPaymentFormState();
}

class _AddPaymentFormState extends State<AddPaymentForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  PaymentMethod _method = PaymentMethod.cash;
  DateTime _date = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.asTenantReport)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'This records that you paid - the owner still needs to confirm it '
                'before it counts as received.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ),
          TextFormField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: _pmDec('Amount (₹)'),
            validator: (v) => (v == null || int.tryParse(v) == null) ? 'Enter a valid amount' : null,
          ),
          const SizedBox(height: 12),
          InputDecorator(
            decoration: _pmDec('Payment method'),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<PaymentMethod>(
                value: _method,
                isExpanded: true,
                items: PaymentMethod.values
                    .map((m) => DropdownMenuItem(value: m, child: Text(pmPaymentMethodLabel(m))))
                    .toList(),
                onChanged: (v) => setState(() => _method = v ?? _method),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date'),
            subtitle: Text(pmDateLabel(_date)),
            trailing: const Icon(Icons.calendar_today_outlined, size: 18),
            onTap: () async {
              final picked = await _pmPickDate(context, _date);
              if (picked != null) setState(() => _date = picked);
            },
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: _noteCtrl,
            decoration: _pmDec('Note (optional)'),
          ),
          const SizedBox(height: 18),
          _pmSubmitButton('Save payment', () {
            if (!_formKey.currentState!.validate()) return;
            PmStore.instance.addPayment(
              widget.flat,
              PmPayment(
                amount: int.parse(_amountCtrl.text),
                date: _date,
                method: _method,
                status: widget.asTenantReport ? PaymentStatus.pending : PaymentStatus.confirmed,
                reportedByTenant: widget.asTenantReport,
                note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
              ),
            );
            Navigator.pop(context);
            pmShowSnack(context, 'Payment saved (demo - not sent to any backend).');
          }),
        ],
      ),
    );
  }
}

// =====================================================================
// Add Family Member
// =====================================================================
class AddFamilyMemberForm extends StatefulWidget {
  final PmFlat flat;
  const AddFamilyMemberForm({super.key, required this.flat});

  @override
  State<AddFamilyMemberForm> createState() => _AddFamilyMemberFormState();
}

class _AddFamilyMemberFormState extends State<AddFamilyMemberForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _relation = 'Spouse';

  static const _relations = ['Self', 'Spouse', 'Son', 'Daughter', 'Parent', 'Other'];

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nameCtrl,
            decoration: _pmDec('Name'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
          ),
          const SizedBox(height: 12),
          InputDecorator(
            decoration: _pmDec('Relation'),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _relation,
                isExpanded: true,
                items: _relations.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (v) => setState(() => _relation = v ?? _relation),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: _pmDec('Phone (optional)'),
          ),
          const SizedBox(height: 18),
          _pmSubmitButton('Add family member', () {
            if (!_formKey.currentState!.validate()) return;
            PmStore.instance.addFamilyMember(
              widget.flat,
              FamilyMember(
                name: _nameCtrl.text.trim(),
                relation: _relation,
                phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
              ),
            );
            Navigator.pop(context);
          }),
        ],
      ),
    );
  }
}

// =====================================================================
// Add Vehicle
// =====================================================================
class AddVehicleForm extends StatefulWidget {
  final PmFlat flat;
  const AddVehicleForm({super.key, required this.flat});

  @override
  State<AddVehicleForm> createState() => _AddVehicleFormState();
}

class _AddVehicleFormState extends State<AddVehicleForm> {
  final _modelCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _regCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  String _type = 'Car';

  static const _types = ['Car', 'Scooter', 'Bike', 'Other'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InputDecorator(
          decoration: _pmDec('Vehicle type'),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _type,
              isExpanded: true,
              items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(controller: _modelCtrl, decoration: _pmDec('Model (optional)')),
        const SizedBox(height: 12),
        TextFormField(controller: _regCtrl, decoration: _pmDec('Registration number (optional)')),
        const SizedBox(height: 12),
        TextFormField(controller: _colorCtrl, decoration: _pmDec('Color (optional)')),
        const SizedBox(height: 12),
        TextFormField(controller: _noteCtrl, decoration: _pmDec('Note (optional)')),
        const SizedBox(height: 18),
        _pmSubmitButton('Add vehicle', () {
          PmStore.instance.addVehicle(
            widget.flat,
            PmVehicle(
              type: _type,
              model: _modelCtrl.text.trim().isEmpty ? null : _modelCtrl.text.trim(),
              note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
              regNumber: _regCtrl.text.trim().isEmpty ? null : _regCtrl.text.trim(),
              color: _colorCtrl.text.trim().isEmpty ? null : _colorCtrl.text.trim(),
            ),
          );
          Navigator.pop(context);
        }),
      ],
    );
  }
}

// =====================================================================
// Edit Vehicle Details (registration number / color / note) - used from
// the upgraded Vehicle section to fill in details on vehicles that were
// added before these fields existed, or to correct them later.
// =====================================================================
class EditVehicleDetailsForm extends StatefulWidget {
  final PmVehicle vehicle;
  const EditVehicleDetailsForm({super.key, required this.vehicle});

  @override
  State<EditVehicleDetailsForm> createState() => _EditVehicleDetailsFormState();
}

class _EditVehicleDetailsFormState extends State<EditVehicleDetailsForm> {
  late final _regCtrl = TextEditingController(text: widget.vehicle.regNumber ?? '');
  late final _colorCtrl = TextEditingController(text: widget.vehicle.color ?? '');
  late final _noteCtrl = TextEditingController(text: widget.vehicle.note ?? '');

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(controller: _regCtrl, decoration: _pmDec('Registration number (optional)')),
        const SizedBox(height: 12),
        TextFormField(controller: _colorCtrl, decoration: _pmDec('Color (optional)')),
        const SizedBox(height: 12),
        TextFormField(controller: _noteCtrl, decoration: _pmDec('Note (optional)')),
        const SizedBox(height: 18),
        _pmSubmitButton('Save details', () {
          PmStore.instance.updateVehicleDetails(
            widget.vehicle,
            regNumber: _regCtrl.text.trim().isEmpty ? null : _regCtrl.text.trim(),
            color: _colorCtrl.text.trim().isEmpty ? null : _colorCtrl.text.trim(),
            note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          );
          Navigator.pop(context);
        }),
      ],
    );
  }
}

// =====================================================================
// Add Document
// =====================================================================
class AddDocumentForm extends StatefulWidget {
  final PmFlat flat;
  const AddDocumentForm({super.key, required this.flat});

  @override
  State<AddDocumentForm> createState() => _AddDocumentFormState();
}

class _AddDocumentFormState extends State<AddDocumentForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  String _type = 'Agreement';
  bool _shared = false;

  static const _types = ['Agreement', 'Police Verification', 'Insurance', 'Other'];

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This demo only records that a document exists and its name - '
            'actual file upload/storage needs a backend (future milestone).',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _titleCtrl,
            decoration: _pmDec('Document name'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
          ),
          const SizedBox(height: 12),
          InputDecorator(
            decoration: _pmDec('Type'),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _type,
                isExpanded: true,
                items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
            ),
          ),
          const SizedBox(height: 4),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Shared with tenant'),
            value: _shared,
            onChanged: (v) => setState(() => _shared = v),
          ),
          const SizedBox(height: 14),
          _pmSubmitButton('Add document', () {
            if (!_formKey.currentState!.validate()) return;
            PmStore.instance.addDocument(
              widget.flat,
              PmDocument(
                title: _titleCtrl.text.trim(),
                type: _type,
                addedOn: DateTime.now(),
                sharedWithTenant: _shared,
              ),
            );
            Navigator.pop(context);
          }),
        ],
      ),
    );
  }
}

// =====================================================================
// Add Maintenance Request
// =====================================================================
class AddMaintenanceForm extends StatefulWidget {
  final PmFlat flat;
  final bool raisedByTenant;
  const AddMaintenanceForm({super.key, required this.flat, this.raisedByTenant = false});

  @override
  State<AddMaintenanceForm> createState() => _AddMaintenanceFormState();
}

class _AddMaintenanceFormState extends State<AddMaintenanceForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _titleCtrl,
            decoration: _pmDec('What needs attention?', hint: 'e.g. Leaking tap'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: _pmDec('Details (optional)'),
          ),
          const SizedBox(height: 18),
          _pmSubmitButton('Raise request', () {
            if (!_formKey.currentState!.validate()) return;
            PmStore.instance.addMaintenanceRequest(
              widget.flat,
              PmMaintenanceRequest(
                title: _titleCtrl.text.trim(),
                description: _descCtrl.text.trim(),
                raisedOn: DateTime.now(),
                raisedByTenant: widget.raisedByTenant,
              ),
            );
            Navigator.pop(context);
          }),
        ],
      ),
    );
  }
}

// =====================================================================
// Give Notice
// =====================================================================
class GiveNoticeForm extends StatefulWidget {
  final PmFlat flat;
  final NoticeRaisedBy raisedBy;
  const GiveNoticeForm({super.key, required this.flat, required this.raisedBy});

  @override
  State<GiveNoticeForm> createState() => _GiveNoticeFormState();
}

class _GiveNoticeFormState extends State<GiveNoticeForm> {
  final _reasonCtrl = TextEditingController();
  DateTime _vacateDate = DateTime.now().add(const Duration(days: 30));

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Proposed vacate date'),
          subtitle: Text(pmDateLabel(_vacateDate)),
          trailing: const Icon(Icons.calendar_today_outlined, size: 18),
          onTap: () async {
            final picked = await _pmPickDate(context, _vacateDate);
            if (picked != null) setState(() => _vacateDate = picked);
          },
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _reasonCtrl,
          decoration: _pmDec('Reason (optional)'),
        ),
        const SizedBox(height: 18),
        _pmSubmitButton('Send notice', () {
          PmStore.instance.setNotice(
            widget.flat,
            PmNotice(
              proposedVacateDate: _vacateDate,
              reason: _reasonCtrl.text.trim().isEmpty ? null : _reasonCtrl.text.trim(),
              raisedBy: widget.raisedBy,
              raisedOn: DateTime.now(),
            ),
          );
          Navigator.pop(context);
        }),
      ],
    );
  }
}

// =====================================================================
// Add Building (List a new property)
// =====================================================================
class AddBuildingForm extends StatefulWidget {
  const AddBuildingForm({super.key});

  @override
  State<AddBuildingForm> createState() => _AddBuildingFormState();
}

class _AddBuildingFormState extends State<AddBuildingForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _caretakerCtrl = TextEditingController();
  final _parkingCtrl = TextEditingController();
  bool? _hasLift;
  MeterType _meterType = MeterType.unknown;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nameCtrl,
            decoration: _pmDec('Building name'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a building name' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(controller: _caretakerCtrl, decoration: _pmDec('Caretaker (optional)')),
          const SizedBox(height: 12),
          InputDecorator(
            decoration: _pmDec('Meter type'),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<MeterType>(
                value: _meterType,
                isExpanded: true,
                items: MeterType.values
                    .map((m) => DropdownMenuItem(value: m, child: Text(pmMeterLabel(m))))
                    .toList(),
                onChanged: (v) => setState(() => _meterType = v ?? _meterType),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _parkingCtrl,
            keyboardType: TextInputType.number,
            decoration: _pmDec('Parking capacity (optional)'),
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Has lift?'),
            value: _hasLift ?? false,
            onChanged: (v) => setState(() => _hasLift = v),
          ),
          const SizedBox(height: 14),
          _pmSubmitButton('Add building', () {
            if (!_formKey.currentState!.validate()) return;
            PmStore.instance.addBuilding(
              PmBuilding(
                name: _nameCtrl.text.trim(),
                caretaker: _caretakerCtrl.text.trim().isEmpty ? null : _caretakerCtrl.text.trim(),
                hasLift: _hasLift,
                meterType: _meterType,
                parkingCapacity: int.tryParse(_parkingCtrl.text.trim()),
              ),
            );
            Navigator.pop(context);
          }),
        ],
      ),
    );
  }
}

// =====================================================================
// Add Flat
// =====================================================================
class AddFlatForm extends StatefulWidget {
  final PmBuilding building;
  const AddFlatForm({super.key, required this.building});

  @override
  State<AddFlatForm> createState() => _AddFlatFormState();
}

class _AddFlatFormState extends State<AddFlatForm> {
  final _formKey = GlobalKey<FormState>();
  final _flatNoCtrl = TextEditingController();
  final _floorCtrl = TextEditingController();
  final _bhkCtrl = TextEditingController();
  final _tenantCtrl = TextEditingController();
  final _tenantPhoneCtrl = TextEditingController();
  final _rentCtrl = TextEditingController();
  final _askingCtrl = TextEditingController();
  FlatStatus _status = FlatStatus.vacant;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _flatNoCtrl,
            decoration: _pmDec('Flat number'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a flat number' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(controller: _floorCtrl, decoration: _pmDec('Floor', hint: 'e.g. Ground, First')),
          const SizedBox(height: 12),
          TextFormField(controller: _bhkCtrl, decoration: _pmDec('BHK (optional)')),
          const SizedBox(height: 12),
          InputDecorator(
            decoration: _pmDec('Status'),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<FlatStatus>(
                value: _status,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: FlatStatus.rented, child: Text('Rented')),
                  DropdownMenuItem(value: FlatStatus.vacant, child: Text('Vacant')),
                  DropdownMenuItem(value: FlatStatus.selfUse, child: Text('Self-use')),
                ],
                onChanged: (v) => setState(() => _status = v ?? _status),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_status == FlatStatus.rented) ...[
            TextFormField(controller: _tenantCtrl, decoration: _pmDec('Tenant name (optional)')),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tenantPhoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: _pmDec('Tenant phone (optional)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _rentCtrl,
              keyboardType: TextInputType.number,
              decoration: _pmDec('Monthly rent (₹)'),
            ),
          ],
          if (_status == FlatStatus.vacant)
            TextFormField(
              controller: _askingCtrl,
              keyboardType: TextInputType.number,
              decoration: _pmDec('Asking rent (₹, optional)'),
            ),
          const SizedBox(height: 14),
          _pmSubmitButton('Add flat', () {
            if (!_formKey.currentState!.validate()) return;
            PmStore.instance.addFlat(
              widget.building,
              PmFlat(
                flatNo: _flatNoCtrl.text.trim(),
                floorLabel: _floorCtrl.text.trim().isEmpty ? 'Not specified' : _floorCtrl.text.trim(),
                bhk: _bhkCtrl.text.trim().isEmpty ? null : _bhkCtrl.text.trim(),
                tenantName: _tenantCtrl.text.trim().isEmpty ? null : _tenantCtrl.text.trim(),
                tenantPhone: _tenantPhoneCtrl.text.trim().isEmpty ? null : _tenantPhoneCtrl.text.trim(),
                monthlyRent: int.tryParse(_rentCtrl.text.trim()),
                status: _status,
                askingRent: int.tryParse(_askingCtrl.text.trim()),
              ),
            );
            Navigator.pop(context);
          }),
        ],
      ),
    );
  }
}

// =====================================================================
// Add Expense
// =====================================================================
class AddExpenseForm extends StatefulWidget {
  final PmBuilding building;
  const AddExpenseForm({super.key, required this.building});

  @override
  State<AddExpenseForm> createState() => _AddExpenseFormState();
}

class _AddExpenseFormState extends State<AddExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _titleCtrl,
            decoration: _pmDec('Expense title', hint: 'e.g. Lift repair'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: _pmDec('Amount (₹)'),
            validator: (v) => (v == null || int.tryParse(v) == null) ? 'Enter a valid amount' : null,
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date'),
            subtitle: Text(pmDateLabel(_date)),
            trailing: const Icon(Icons.calendar_today_outlined, size: 18),
            onTap: () async {
              final picked = await _pmPickDate(context, _date);
              if (picked != null) setState(() => _date = picked);
            },
          ),
          const SizedBox(height: 14),
          _pmSubmitButton('Add expense', () {
            if (!_formKey.currentState!.validate()) return;
            PmStore.instance.addExpense(
              widget.building,
              PmExpense(title: _titleCtrl.text.trim(), amount: int.parse(_amountCtrl.text), date: _date),
            );
            Navigator.pop(context);
          }),
        ],
      ),
    );
  }
}

// =====================================================================
// Agreement (owner fills/updates - tenant views only)
// =====================================================================
class AgreementForm extends StatefulWidget {
  final PmFlat flat;
  const AgreementForm({super.key, required this.flat});

  @override
  State<AgreementForm> createState() => _AgreementFormState();
}

class _AgreementFormState extends State<AgreementForm> {
  late final _depositCtrl =
      TextEditingController(text: widget.flat.agreement?.securityDeposit?.toString() ?? '');
  late final _noticeCtrl =
      TextEditingController(text: widget.flat.agreement?.noticePeriodDays?.toString() ?? '');
  late final _termsCtrl = TextEditingController(text: widget.flat.agreement?.terms ?? '');
  late DateTime? _startDate = widget.flat.agreement?.startDate;
  late DateTime? _endDate = widget.flat.agreement?.endDate;
  late AgreementStatus _status = widget.flat.agreement?.status ?? AgreementStatus.active;

  static const _statusLabels = {
    AgreementStatus.notCreated: 'Not created',
    AgreementStatus.active: 'Active',
    AgreementStatus.expired: 'Expired',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'This is a manual record for your own tracking only - it does not '
          'generate, sign, or store a real legal document (future milestone).',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        const SizedBox(height: 10),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Start date'),
          subtitle: Text(_startDate != null ? pmDateLabel(_startDate!) : 'Not set'),
          trailing: const Icon(Icons.calendar_today_outlined, size: 18),
          onTap: () async {
            final picked = await _pmPickDate(context, _startDate ?? DateTime.now());
            if (picked != null) setState(() => _startDate = picked);
          },
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('End date'),
          subtitle: Text(_endDate != null ? pmDateLabel(_endDate!) : 'Not set'),
          trailing: const Icon(Icons.calendar_today_outlined, size: 18),
          onTap: () async {
            final picked = await _pmPickDate(context, _endDate ?? DateTime.now());
            if (picked != null) setState(() => _endDate = picked);
          },
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _depositCtrl,
          keyboardType: TextInputType.number,
          decoration: _pmDec('Security deposit (₹, optional)'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _noticeCtrl,
          keyboardType: TextInputType.number,
          decoration: _pmDec('Notice period (days, optional)'),
        ),
        const SizedBox(height: 12),
        InputDecorator(
          decoration: _pmDec('Status'),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<AgreementStatus>(
              value: _status,
              isExpanded: true,
              items: _statusLabels.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _status = v ?? _status),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _termsCtrl,
          maxLines: 3,
          decoration: _pmDec('Terms / notes (optional)'),
        ),
        const SizedBox(height: 18),
        _pmSubmitButton('Save agreement', () {
          PmStore.instance.setAgreement(
            widget.flat,
            PmAgreement(
              startDate: _startDate,
              endDate: _endDate,
              securityDeposit: int.tryParse(_depositCtrl.text.trim()),
              noticePeriodDays: int.tryParse(_noticeCtrl.text.trim()),
              terms: _termsCtrl.text.trim().isEmpty ? null : _termsCtrl.text.trim(),
              status: _status,
            ),
          );
          Navigator.pop(context);
          pmShowSnack(context, 'Agreement saved (demo - not a legal document).');
        }),
      ],
    );
  }
}

// =====================================================================
// Police Verification (owner fills/updates - tenant views only)
// =====================================================================
class PoliceVerificationForm extends StatefulWidget {
  final PmFlat flat;
  const PoliceVerificationForm({super.key, required this.flat});

  @override
  State<PoliceVerificationForm> createState() => _PoliceVerificationFormState();
}

class _PoliceVerificationFormState extends State<PoliceVerificationForm> {
  late final _idNumberCtrl = TextEditingController(text: widget.flat.policeVerification?.idNumber ?? '');
  late final _remarksCtrl = TextEditingController(text: widget.flat.policeVerification?.remarks ?? '');
  late String _idType = widget.flat.policeVerification?.idType ?? 'Aadhaar';
  late DateTime? _submittedOn = widget.flat.policeVerification?.submittedOn;
  late VerificationStatus _status = widget.flat.policeVerification?.status ?? VerificationStatus.pending;

  static const _idTypes = ['Aadhaar', 'Passport', 'Voter ID', 'Driving Licence', 'Other'];
  static const _statusLabels = {
    VerificationStatus.notSubmitted: 'Not submitted',
    VerificationStatus.pending: 'Pending',
    VerificationStatus.verified: 'Verified',
    VerificationStatus.rejected: 'Rejected',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Manual tracking only - this does not call any government or '
          'police verification API (no backend integration exists yet).',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        const SizedBox(height: 10),
        InputDecorator(
          decoration: _pmDec('ID type'),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _idType,
              isExpanded: true,
              items: _idTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _idType = v ?? _idType),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(controller: _idNumberCtrl, decoration: _pmDec('ID number (optional)')),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Submitted on'),
          subtitle: Text(_submittedOn != null ? pmDateLabel(_submittedOn!) : 'Not set'),
          trailing: const Icon(Icons.calendar_today_outlined, size: 18),
          onTap: () async {
            final picked = await _pmPickDate(context, _submittedOn ?? DateTime.now());
            if (picked != null) setState(() => _submittedOn = picked);
          },
        ),
        const SizedBox(height: 8),
        InputDecorator(
          decoration: _pmDec('Status'),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<VerificationStatus>(
              value: _status,
              isExpanded: true,
              items: _statusLabels.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _status = v ?? _status),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(controller: _remarksCtrl, maxLines: 2, decoration: _pmDec('Remarks (optional)')),
        const SizedBox(height: 18),
        _pmSubmitButton('Save verification status', () {
          PmStore.instance.setPoliceVerification(
            widget.flat,
            PmPoliceVerification(
              idType: _idType,
              idNumber: _idNumberCtrl.text.trim().isEmpty ? null : _idNumberCtrl.text.trim(),
              submittedOn: _submittedOn,
              verifiedOn: _status == VerificationStatus.verified ? DateTime.now() : widget.flat.policeVerification?.verifiedOn,
              status: _status,
              remarks: _remarksCtrl.text.trim().isEmpty ? null : _remarksCtrl.text.trim(),
            ),
          );
          Navigator.pop(context);
          pmShowSnack(context, 'Verification status saved (demo - manual record only).');
        }),
      ],
    );
  }
}

// =====================================================================
// Insurance (owner fills/updates - tenant views only)
// =====================================================================
class InsuranceForm extends StatefulWidget {
  final PmFlat flat;
  const InsuranceForm({super.key, required this.flat});

  @override
  State<InsuranceForm> createState() => _InsuranceFormState();
}

class _InsuranceFormState extends State<InsuranceForm> {
  late final _providerCtrl = TextEditingController(text: widget.flat.insurance?.provider ?? '');
  late final _policyCtrl = TextEditingController(text: widget.flat.insurance?.policyNumber ?? '');
  late final _noteCtrl = TextEditingController(text: widget.flat.insurance?.note ?? '');
  late DateTime? _validTill = widget.flat.insurance?.validTill;
  late InsuranceStatus _status = widget.flat.insurance?.status ?? InsuranceStatus.active;

  static const _statusLabels = {
    InsuranceStatus.none: 'No policy',
    InsuranceStatus.active: 'Active',
    InsuranceStatus.expired: 'Expired',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(controller: _providerCtrl, decoration: _pmDec('Insurance provider (optional)')),
        const SizedBox(height: 12),
        TextFormField(controller: _policyCtrl, decoration: _pmDec('Policy number (optional)')),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Valid till'),
          subtitle: Text(_validTill != null ? pmDateLabel(_validTill!) : 'Not set'),
          trailing: const Icon(Icons.calendar_today_outlined, size: 18),
          onTap: () async {
            final picked = await _pmPickDate(context, _validTill ?? DateTime.now());
            if (picked != null) setState(() => _validTill = picked);
          },
        ),
        const SizedBox(height: 8),
        InputDecorator(
          decoration: _pmDec('Status'),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<InsuranceStatus>(
              value: _status,
              isExpanded: true,
              items: _statusLabels.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _status = v ?? _status),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(controller: _noteCtrl, decoration: _pmDec('Note (optional)')),
        const SizedBox(height: 18),
        _pmSubmitButton('Save insurance details', () {
          PmStore.instance.setInsurance(
            widget.flat,
            PmInsurancePolicy(
              provider: _providerCtrl.text.trim().isEmpty ? null : _providerCtrl.text.trim(),
              policyNumber: _policyCtrl.text.trim().isEmpty ? null : _policyCtrl.text.trim(),
              validTill: _validTill,
              status: _status,
              note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
            ),
          );
          Navigator.pop(context);
        }),
      ],
    );
  }
}

// =====================================================================
// Add Utility Record (meter reading / bill) - both owner and tenant can
// log one; `reportedByTenant` is set by the caller based on who opened it.
// =====================================================================
class AddUtilityRecordForm extends StatefulWidget {
  final PmFlat flat;
  final bool reportedByTenant;
  const AddUtilityRecordForm({super.key, required this.flat, this.reportedByTenant = false});

  @override
  State<AddUtilityRecordForm> createState() => _AddUtilityRecordFormState();
}

class _AddUtilityRecordFormState extends State<AddUtilityRecordForm> {
  final _readingCtrl = TextEditingController();
  final _billCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  UtilityType _type = UtilityType.electricity;
  DateTime _date = DateTime.now();

  static const _typeLabels = {
    UtilityType.electricity: 'Electricity',
    UtilityType.water: 'Water',
    UtilityType.gas: 'Gas',
    UtilityType.other: 'Other',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InputDecorator(
          decoration: _pmDec('Utility type'),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<UtilityType>(
              value: _type,
              isExpanded: true,
              items: _typeLabels.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Reading date'),
          subtitle: Text(pmDateLabel(_date)),
          trailing: const Icon(Icons.calendar_today_outlined, size: 18),
          onTap: () async {
            final picked = await _pmPickDate(context, _date);
            if (picked != null) setState(() => _date = picked);
          },
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _readingCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _pmDec('Meter reading (optional)'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _billCtrl,
          keyboardType: TextInputType.number,
          decoration: _pmDec('Bill amount (₹, optional)'),
        ),
        const SizedBox(height: 12),
        TextFormField(controller: _noteCtrl, decoration: _pmDec('Note (optional)')),
        const SizedBox(height: 18),
        _pmSubmitButton('Save reading / bill', () {
          PmStore.instance.addUtilityRecord(
            widget.flat,
            PmUtilityRecord(
              type: _type,
              date: _date,
              meterReading: double.tryParse(_readingCtrl.text.trim()),
              billAmount: int.tryParse(_billCtrl.text.trim()),
              note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
              reportedByTenant: widget.reportedByTenant,
            ),
          );
          Navigator.pop(context);
        }),
      ],
    );
  }
}

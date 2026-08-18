class PropertyVisitModel {
  final int id;
  final String visitFee;
  final String gst;
  final String gatewayFee;
  final String total;
  final String budget;
  final String preferredLocation;
  final String requirements;
  final String paymentStatus;
  final String visitingStatus;
  final String createdAt;
  final String familyStructure;
  final String familyMember;
  final String shiftingDate;
  final String fieldWorkerName;
  final String vehicleType;
  final String furnishing;

  PropertyVisitModel({
    required this.id,
    required this.visitFee,
    required this.gst,
    required this.gatewayFee,
    required this.total,
    required this.budget,
    required this.preferredLocation,
    required this.requirements,
    required this.paymentStatus,
    required this.visitingStatus,
    required this.createdAt,
    required this.familyStructure,
    required this.familyMember,
    required this.shiftingDate,
    required this.fieldWorkerName,
    required this.vehicleType,
    required this.furnishing,
  });

  factory PropertyVisitModel.fromJson(Map<String, dynamic> json) {

    String parseDate(dynamic value) {
      if (value == null) return "";

      if (value is Map) {
        return value["date"] ?? "";
      }

      return value.toString();
    }

    return PropertyVisitModel(
      id: json["id"] ?? 0,
      visitFee: (json["visit_fee"] ?? '').toString(),
      gst: (json["gst"] ?? '').toString(),
      gatewayFee: (json["gateway_fee"] ?? '').toString(),
      total: (json["total"] ?? '').toString(),
      budget: (json["budget"] ?? '').toString(),
      preferredLocation: json["preferred_location"] ?? "",
      requirements: json["requirements"] ?? "",
      paymentStatus: json["payment_status"] ?? "",
      visitingStatus: json["visiting_status"] ?? "",
      createdAt: parseDate(json["created_at"]),
      familyStructure: json["family_structure"] ?? "",
      familyMember: (json["family_member"] ?? '').toString(),
      shiftingDate: json["shifting_date"] ?? "",
      fieldWorkerName: json["feild_workar_name"] ?? "",
      vehicleType: json["vehicle_type"] ?? "",
      furnishing: json["furnishing"] ?? "",
    );
  }
}
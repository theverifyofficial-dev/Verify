class PropertyVisitModel {
  final int id;
  final String propertyId;
  final String bhk;
  final String visitFee;
  final String gst;
  final String gatewayFee;
  final String total;
  final String budget;
  final String preferredLocation;
  final String visitDate;
  final String visitTime;
  final String requirements;
  final String paymentStatus;
  final String visitingStatus;
  final String createdAt;

  PropertyVisitModel({
    required this.id,
    required this.propertyId,
    required this.bhk,
    required this.visitFee,
    required this.gst,
    required this.gatewayFee,
    required this.total,
    required this.budget,
    required this.preferredLocation,
    required this.visitDate,
    required this.visitTime,
    required this.requirements,
    required this.paymentStatus,
    required this.visitingStatus,
    required this.createdAt,
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
      propertyId: json["property_id"].toString(),
      bhk: json["bhk"] ?? "",
      visitFee: json["visit_fee"].toString(),
      gst: json["gst"].toString(),
      gatewayFee: json["gateway_fee"].toString(),
      total: json["total"].toString(),
      budget: json["budget"].toString(),
      preferredLocation: json["preferred_location"] ?? "",
      visitDate: parseDate(json["visit_date"]),
      visitTime: json["visit_time"] ?? "",
      requirements: json["requirements"] ?? "",
      paymentStatus: json["payment_status"] ?? "",
      visitingStatus: json["visiting_status"] ?? "",
      createdAt: parseDate(json["created_at"]),
    );
  }
}

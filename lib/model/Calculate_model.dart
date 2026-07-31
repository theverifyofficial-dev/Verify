class BookingCalculationModel {
  final bool status;
  final String propertyId;
  final String bhk;
  final double visitFee;
  final double gst;
  final double gatewayFee;
  final double total;

  BookingCalculationModel({
    required this.status,
    required this.propertyId,
    required this.bhk,
    required this.visitFee,
    required this.gst,
    required this.gatewayFee,
    required this.total,
  });

  factory BookingCalculationModel.fromJson(Map<String, dynamic> json) {
    return BookingCalculationModel(
      status: json["status"],
      propertyId: json["property_id"].toString(),
      bhk: json["bhk"],
      visitFee: (json["visit_fee"] as num).toDouble(),
      gst: (json["gst"] as num).toDouble(),
      gatewayFee: (json["gateway_fee"] as num).toDouble(),
      total: (json["total"] as num).toDouble(),
    );
  }
}
class Reservation {
  String reserverName;
  String reserverPhone;
  int seatsReserved;
  String paymentMethod;
  String? reserverEmail; // optional to handle both branches

  Reservation({
    required this.reserverName,
    required this.reserverPhone,
    required this.seatsReserved,
    required this.paymentMethod,
    this.reserverEmail,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      reserverName: json['reserverName'] ?? '',
      reserverPhone: json['reserverPhone'] ?? '',
      seatsReserved: (json['seatsReserved'] ?? 1).toInt(),
      paymentMethod: json['paymentMethod'] ?? '',
      reserverEmail: json['reserverEmail'], // optional
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reserverName': reserverName,
      'reserverPhone': reserverPhone,
      'seatsReserved': seatsReserved,
      'paymentMethod': paymentMethod,
      'reserverEmail': reserverEmail,
    };
  }

  bool isValid() {
    return reserverName.isNotEmpty &&
        reserverPhone.length == 8 &&
        int.tryParse(reserverPhone) != null &&
        seatsReserved > 0;
  }
}

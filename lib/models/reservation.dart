class Reservation {
  String reserverName;
  String reserverPhone;
  int seatsReserved;
  String paymentMethod;

  Reservation({
    required this.reserverName,
    required this.reserverPhone,
    required this.seatsReserved,
    required this.paymentMethod,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      reserverName: json['reserverName'],
      reserverPhone: json['reserverPhone'],
      seatsReserved: json['seatsReserved'],
      paymentMethod: json['paymentMethod'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reserverName': reserverName,
      'reserverPhone': reserverPhone,
      'seatsReserved': seatsReserved,
      'paymentMethod': paymentMethod,
    };
  }

  bool isValid() {
    return reserverName.isNotEmpty &&
        reserverPhone.length == 8 &&
        int.tryParse(reserverPhone) != null &&
        seatsReserved > 0;
  }
}

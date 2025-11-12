class PaymentService {
  static Future<bool> processCreditCardPayment(String cardNumber, String expiryDate, String cvv) async {

    if (cardNumber.length < 16 || !expiryDate.contains('/') || cvv.length != 3) {
      return false;
    }
    return true;
  }
}
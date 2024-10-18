class Vehicle {
  final String registrationNumber;
  final String driver;
  final int maxPassengers = 4;
  List<String> passengers = [];

  Vehicle({required this.registrationNumber, required this.driver});

  int get availableSeats => maxPassengers - passengers.length;

  bool bookSeat(String passengerName) {
    if (passengers.length < maxPassengers) {
      passengers.add(passengerName);
      return true;
    }
    return false;
  }

  bool get isFull => passengers.length >= maxPassengers;
}

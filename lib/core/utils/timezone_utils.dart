const Duration wibOffset = Duration(hours: 7);

DateTime toWib(DateTime value) => value.toUtc().add(wibOffset);

DateTime wibMidnightUtc(int year, int month, int day) {
  return DateTime.utc(year, month, day).subtract(wibOffset);
}

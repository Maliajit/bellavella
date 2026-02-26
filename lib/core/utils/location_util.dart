class LocationUtil {
  static String? currentAddress;
  static String? currentSubAddress;

  static bool hasLocation() {
    return currentAddress != null && currentAddress!.isNotEmpty;
  }

  static void setLocation(String address, String subAddress) {
    currentAddress = address;
    currentSubAddress = subAddress;
  }
}

/// Uganda Districts List
/// Official 12 districts used throughout the app
class UgandaDistricts {
  // Official 12 districts from districtinformation.xlsx
  static const List<String> allDistricts = [
    'BUGIRI',
    'BUGWERI',
    'BUYENDE',
    'IGANGA',
    'JINJA',
    'JINJA CITY',
    'KALIRO',
    'KAMULI',
    'LUUKA',
    'MAYUGE',
    'NAMAYINGO',
    'NAMUTUMBA',
  ];

  // Same as allDistricts for consistency
  static const List<String> popularDistricts = allDistricts;

  /// Get districts list for dropdown/selection
  static List<String> getDistricts({bool popularOnly = false}) {
    return allDistricts; // Always return the same 12 districts
  }

  /// Check if a district exists
  static bool isValidDistrict(String district) {
    return allDistricts.contains(district);
  }
}

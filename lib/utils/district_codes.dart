/// District Code Mapping for User ID Generation
/// Source: districtinformation.xlsx (official district data)
/// 
/// This mapping ensures consistent 3-letter district codes for User IDs
/// Format: ROLE + DISTRICT_CODE + NUMBER
/// Example: SHGJIN025 (SHG user from JINJA, user #25)

class DistrictCodes {
  /// Official district names from districtinformation.xlsx
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

  /// District to 3-letter code mapping
  static const Map<String, String> districtToCode = {
    'BUGIRI': 'BUG',
    'BUGWERI': 'BUW',
    'BUYENDE': 'BUY',
    'IGANGA': 'IGA',
    'JINJA': 'JIN',
    'JINJA CITY': 'JCI',
    'KALIRO': 'KAL',
    'KAMULI': 'KAM',
    'LUUKA': 'LUU',
    'MAYUGE': 'MAY',
    'NAMAYINGO': 'NAM',
    'NAMUTUMBA': 'NAU',
  };

  /// Reverse mapping: 3-letter code to district name
  static const Map<String, String> codeToDistrict = {
    'BUG': 'BUGIRI',
    'BUW': 'BUGWERI',
    'BUY': 'BUYENDE',
    'IGA': 'IGANGA',
    'JIN': 'JINJA',
    'JCI': 'JINJA CITY',
    'KAL': 'KALIRO',
    'KAM': 'KAMULI',
    'LUU': 'LUUKA',
    'MAY': 'MAYUGE',
    'NAM': 'NAMAYINGO',
    'NAU': 'NAMUTUMBA',
  };

  /// Get 3-letter code for a district name
  /// Returns 'UGA' as default if district not found
  static String getCode(String? districtName) {
    if (districtName == null || districtName.isEmpty) {
      return 'UGA'; // Default code
    }
    
    final upperName = districtName.toUpperCase().trim();
    return districtToCode[upperName] ?? 'UGA';
  }

  /// Get district name from 3-letter code
  static String? getDistrictName(String code) {
    final upperCode = code.toUpperCase().trim();
    return codeToDistrict[upperCode];
  }

  /// Check if a district name is valid
  static bool isValidDistrict(String? districtName) {
    if (districtName == null || districtName.isEmpty) {
      return false;
    }
    return allDistricts.contains(districtName.toUpperCase().trim());
  }

  /// Check if a district code is valid
  static bool isValidCode(String? code) {
    if (code == null || code.isEmpty) {
      return false;
    }
    return codeToDistrict.containsKey(code.toUpperCase().trim());
  }
}

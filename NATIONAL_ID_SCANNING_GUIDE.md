# 📸 National ID Photo Scanning & Verification

## Overview

This feature allows users to scan their Uganda National ID card and automatically extract and verify:
- ✅ Date of Birth
- ✅ Sex/Gender
- ✅ Surname (Family Name)
- ✅ Given Name (First Name)
- ✅ NIN Number (National Identification Number)

The extracted data is then matched against user-provided information to ensure identity verification.

---

## Implementation Approach

### **Option A: Firebase ML Kit (Recommended)**

**Advantages:**
- ✅ Works offline after initial download
- ✅ Free for most use cases
- ✅ High accuracy for text recognition
- ✅ No API costs
- ✅ Privacy-friendly (on-device processing)

**Dependencies:**
```yaml
dependencies:
  google_mlkit_text_recognition: ^0.13.1  # OCR text extraction
  image_picker: ^1.0.4  # Already installed
```

**Implementation:**

```dart
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class NationalIDScanner {
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  
  /// Scans National ID photo and extracts text
  Future<Map<String, String?>> scanNationalID() async {
    // 1. Pick image from camera or gallery
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 90,
    );
    
    if (image == null) {
      throw Exception('No image selected');
    }
    
    // 2. Process image with ML Kit
    final inputImage = InputImage.fromFilePath(image.path);
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
    
    // 3. Extract fields from recognized text
    final extractedData = _extractIDFields(recognizedText.text);
    
    // 4. Clean up
    await textRecognizer.close();
    
    return extractedData;
  }
  
  /// Extracts structured data from OCR text
  Map<String, String?> _extractIDFields(String ocrText) {
    final lines = ocrText.split('\n');
    
    String? nin;
    String? surname;
    String? givenName;
    String? dateOfBirth;
    String? sex;
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      // Extract NIN (format: CM12AB34CD56EF78 or similar)
      if (RegExp(r'[CA][A-Z0-9]{13}').hasMatch(line)) {
        nin = RegExp(r'[CA][A-Z0-9]{13}').firstMatch(line)?.group(0);
      }
      
      // Extract Surname (usually labeled "SURNAME:" or "FAMILY NAME:")
      if (line.toUpperCase().contains('SURNAME') || 
          line.toUpperCase().contains('FAMILY NAME')) {
        // Next line or after colon
        surname = _extractFieldValue(line, lines, i);
      }
      
      // Extract Given Name
      if (line.toUpperCase().contains('GIVEN NAME') ||
          line.toUpperCase().contains('FIRST NAME')) {
        givenName = _extractFieldValue(line, lines, i);
      }
      
      // Extract Date of Birth (format: DD-MMM-YYYY)
      if (line.toUpperCase().contains('DATE OF BIRTH') ||
          line.toUpperCase().contains('DOB')) {
        dateOfBirth = _extractFieldValue(line, lines, i);
      }
      
      // Extract Sex/Gender
      if (line.toUpperCase().contains('SEX:') || 
          line.toUpperCase().contains('GENDER:')) {
        sex = _extractFieldValue(line, lines, i);
        // Normalize: "M" or "MALE" → "Male", "F" or "FEMALE" → "Female"
        if (sex != null) {
          if (sex.toUpperCase().startsWith('M')) {
            sex = 'Male';
          } else if (sex.toUpperCase().startsWith('F')) {
            sex = 'Female';
          }
        }
      }
    }
    
    return {
      'nin': nin,
      'surname': surname,
      'givenName': givenName,
      'dateOfBirth': dateOfBirth,
      'sex': sex,
    };
  }
  
  /// Helper to extract field value from line or next line
  String? _extractFieldValue(String currentLine, List<String> allLines, int index) {
    // Try to get value after colon in same line
    if (currentLine.contains(':')) {
      final parts = currentLine.split(':');
      if (parts.length > 1) {
        final value = parts[1].trim();
        if (value.isNotEmpty) {
          return value;
        }
      }
    }
    
    // If not found, check next line
    if (index + 1 < allLines.length) {
      return allLines[index + 1].trim();
    }
    
    return null;
  }
}
```

---

### **Verification Logic**

```dart
class IDVerificationService {
  /// Verifies scanned ID data against user-provided data
  static IDVerificationResult verifyIDData({
    required Map<String, String?> scannedData,
    required String userProvidedNIN,
    required String userProvidedSurname,
    required String userProvidedGivenName,
    required DateTime userProvidedDOB,
    required String userProvidedSex,
  }) {
    final issues = <String>[];
    
    // 1. Verify NIN matches
    final scannedNIN = scannedData['nin'];
    if (scannedNIN == null) {
      issues.add('Could not read NIN from ID photo. Please rescan.');
    } else {
      final cleanScannedNIN = NINValidator.cleanNIN(scannedNIN);
      final cleanUserNIN = NINValidator.cleanNIN(userProvidedNIN);
      
      if (cleanScannedNIN != cleanUserNIN) {
        issues.add('NIN mismatch: Scanned ($cleanScannedNIN) ≠ Provided ($cleanUserNIN)');
      }
    }
    
    // 2. Verify Surname matches
    final scannedSurname = scannedData['surname'];
    if (scannedSurname == null) {
      issues.add('Could not read Surname from ID photo.');
    } else if (!NINValidator.namesMatch(scannedSurname, userProvidedSurname)) {
      final similarity = NINValidator.calculateNameSimilarity(
        scannedSurname, 
        userProvidedSurname,
      );
      
      if (similarity >= 0.7) {
        issues.add('Surname similar but not exact match. Please verify.');
      } else {
        issues.add('Surname mismatch: "$scannedSurname" ≠ "$userProvidedSurname"');
      }
    }
    
    // 3. Verify Given Name matches
    final scannedGivenName = scannedData['givenName'];
    if (scannedGivenName == null) {
      issues.add('Could not read Given Name from ID photo.');
    } else if (!NINValidator.namesMatch(scannedGivenName, userProvidedGivenName)) {
      final similarity = NINValidator.calculateNameSimilarity(
        scannedGivenName,
        userProvidedGivenName,
      );
      
      if (similarity >= 0.7) {
        issues.add('Given Name similar but not exact match. Please verify.');
      } else {
        issues.add('Given Name mismatch: "$scannedGivenName" ≠ "$userProvidedGivenName"');
      }
    }
    
    // 4. Verify Date of Birth matches
    final scannedDOB = scannedData['dateOfBirth'];
    if (scannedDOB == null) {
      issues.add('Could not read Date of Birth from ID photo.');
    } else {
      // Parse scanned DOB (format: DD-MMM-YYYY or similar)
      try {
        final parsedDOB = _parseDateOfBirth(scannedDOB);
        if (parsedDOB != userProvidedDOB) {
          issues.add('Date of Birth mismatch: ${_formatDate(parsedDOB)} ≠ ${_formatDate(userProvidedDOB)}');
        }
      } catch (e) {
        issues.add('Could not parse Date of Birth from ID: $scannedDOB');
      }
    }
    
    // 5. Verify Sex/Gender matches
    final scannedSex = scannedData['sex'];
    if (scannedSex == null) {
      issues.add('Could not read Sex/Gender from ID photo.');
    } else if (scannedSex.toLowerCase() != userProvidedSex.toLowerCase()) {
      issues.add('Sex/Gender mismatch: "$scannedSex" ≠ "$userProvidedSex"');
    }
    
    return IDVerificationResult(
      ninMatches: scannedNIN != null && issues.where((e) => e.contains('NIN')).isEmpty,
      surnameMatches: scannedSurname != null && issues.where((e) => e.contains('Surname')).isEmpty,
      givenNameMatches: scannedGivenName != null && issues.where((e) => e.contains('Given Name')).isEmpty,
      dobMatches: scannedDOB != null && issues.where((e) => e.contains('Date of Birth')).isEmpty,
      sexMatches: scannedSex != null && issues.where((e) => e.contains('Sex')).isEmpty,
      scannedData: scannedData,
      issues: issues,
    );
  }
  
  static DateTime _parseDateOfBirth(String dobString) {
    // Handle formats like: "15-JAN-1990", "15/01/1990", "15 Jan 1990"
    // Implement robust date parsing
    // For now, simplified version:
    return DateTime.parse(dobString); // Adjust based on actual format
  }
  
  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-'
           '${_getMonthName(date.month)}-'
           '${date.year}';
  }
  
  static String _getMonthName(int month) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
                    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return months[month - 1];
  }
}

class IDVerificationResult {
  final bool ninMatches;
  final bool surnameMatches;
  final bool givenNameMatches;
  final bool dobMatches;
  final bool sexMatches;
  final Map<String, String?> scannedData;
  final List<String> issues;
  
  IDVerificationResult({
    required this.ninMatches,
    required this.surnameMatches,
    required this.givenNameMatches,
    required this.dobMatches,
    required this.sexMatches,
    required this.scannedData,
    required this.issues,
  });
  
  bool get allFieldsMatch => 
      ninMatches && surnameMatches && givenNameMatches && dobMatches && sexMatches;
  
  bool get hasCriticalMismatch => issues.any((issue) => 
      issue.contains('NIN mismatch') || 
      issue.contains('Surname mismatch') ||
      issue.contains('Date of Birth mismatch'));
  
  String get verificationStatus {
    if (allFieldsMatch) return 'Verified';
    if (hasCriticalMismatch) return 'Failed';
    if (issues.isEmpty) return 'Partial';
    return 'Issues Found';
  }
}
```

---

### **UI Integration Example**

```dart
class IDVerificationScreen extends StatefulWidget {
  @override
  _IDVerificationScreenState createState() => _IDVerificationScreenState();
}

class _IDVerificationScreenState extends State<IDVerificationScreen> {
  final _scanner = NationalIDScanner();
  bool _isScanning = false;
  IDVerificationResult? _verificationResult;
  
  Future<void> _scanAndVerifyID() async {
    setState(() {
      _isScanning = true;
    });
    
    try {
      // 1. Scan ID photo
      final scannedData = await _scanner.scanNationalID();
      
      // 2. Get user-provided data (from form)
      final userNIN = 'CM12AB34CD56EF78'; // From user input
      final userSurname = 'MUSOKE';
      final userGivenName = 'JAMES';
      final userDOB = DateTime(1990, 5, 15);
      final userSex = 'Male';
      
      // 3. Verify data
      final result = IDVerificationService.verifyIDData(
        scannedData: scannedData,
        userProvidedNIN: userNIN,
        userProvidedSurname: userSurname,
        userProvidedGivenName: userGivenName,
        userProvidedDOB: userDOB,
        userProvidedSex: userSex,
      );
      
      setState(() {
        _verificationResult = result;
      });
      
      // 4. Show results
      if (result.allFieldsMatch) {
        _showSuccessDialog();
      } else {
        _showErrorDialog(result.issues);
      }
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error scanning ID: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }
  
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('ID Verified!'),
          ],
        ),
        content: const Text(
          'All information matches your National ID card. '
          'Your identity has been successfully verified.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Proceed to next step
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
  
  void _showErrorDialog(List<String> issues) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 32),
            SizedBox(width: 12),
            Text('Verification Failed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The following issues were found:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...issues.map((issue) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: Colors.red)),
                  Expanded(child: Text(issue)),
                ],
              ),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify National ID')),
      body: Center(
        child: _isScanning
            ? const CircularProgressIndicator()
            : ElevatedButton.icon(
                onPressed: _scanAndVerifyID,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Scan National ID'),
              ),
      ),
    );
  }
}
```

---

## Alternative: Third-Party OCR APIs

### **Google Cloud Vision API**
- Very high accuracy
- Costs money ($1.50 per 1000 images)
- Requires internet connection
- Better for production with budget

### **AWS Textract**
- Enterprise-grade OCR
- Similar pricing to Google
- Structured data extraction

---

## Testing Checklist

- [ ] Test with clear, well-lit ID photos
- [ ] Test with slightly blurry photos
- [ ] Test with different lighting conditions
- [ ] Test with damaged/old IDs
- [ ] Verify NIN extraction accuracy
- [ ] Verify name matching logic
- [ ] Verify date parsing for different formats
- [ ] Test error handling for unreadable IDs
- [ ] Test camera permissions on Android
- [ ] Test gallery selection as fallback

---

## Privacy & Security Considerations

1. **Data Storage**: Do NOT store ID photos permanently
2. **Encryption**: Encrypt extracted data in transit
3. **Permissions**: Request camera permission with clear explanation
4. **User Consent**: Inform users why ID scanning is needed
5. **Data Retention**: Delete ID photos after verification
6. **Compliance**: Follow Uganda Data Protection Act requirements

---

## Implementation Timeline

**Phase 8 Feature** - To be implemented after Firebase authentication is complete:

1. **Week 1**: Add ML Kit dependencies and basic OCR
2. **Week 2**: Implement field extraction logic
3. **Week 3**: Build verification matching algorithms
4. **Week 4**: Create UI and test with real IDs
5. **Week 5**: Polish error handling and edge cases

---

## Notes

- This feature requires **Phase 8** (Firebase Authentication) to be complete first
- User must be logged in to perform ID verification
- Verification results should be saved to user's Firestore profile
- Consider adding manual verification fallback for low-quality scans

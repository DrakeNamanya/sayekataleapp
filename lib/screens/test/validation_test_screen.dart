import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../utils/nin_validator.dart';
import '../../utils/uganda_business_validators.dart';
import '../../models/user.dart';

/// Test screen for validation updates
/// Tests NIN, TIN, and Business Registration validators
class ValidationTestScreen extends StatefulWidget {
  const ValidationTestScreen({super.key});

  @override
  State<ValidationTestScreen> createState() => _ValidationTestScreenState();
}

class _ValidationTestScreenState extends State<ValidationTestScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _ninController = TextEditingController();
  final _tinController = TextEditingController();
  final _businessRegController = TextEditingController();
  
  // Validation results
  String? _ninResult;
  String? _ninType;
  String? _tinResult;
  String? _tinEntityType;
  String? _businessRegResult;
  Sex? _selectedSex;
  
  // Test results
  final List<TestResult> _testResults = [];

  @override
  void dispose() {
    _ninController.dispose();
    _tinController.dispose();
    _businessRegController.dispose();
    super.dispose();
  }

  void _validateNIN() {
    setState(() {
      final error = NINValidator.validateNIN(_ninController.text);
      if (error == null) {
        _ninResult = '✅ Valid NIN';
        _ninType = NINValidator.getNINType(_ninController.text);
      } else {
        _ninResult = '❌ $error';
        _ninType = null;
      }
    });
  }

  void _validateTIN() {
    setState(() {
      final error = UgandaBusinessValidators.validateTIN(_tinController.text);
      if (error == null) {
        _tinResult = '✅ Valid TIN';
        _tinEntityType = UgandaBusinessValidators.getTINEntityType(_tinController.text);
      } else {
        _tinResult = '❌ $error';
        _tinEntityType = null;
      }
    });
  }

  void _validateBusinessReg() {
    setState(() {
      final error = UgandaBusinessValidators.validateBusinessReg(_businessRegController.text);
      if (error == null) {
        _businessRegResult = '✅ Valid Business Registration';
      } else {
        _businessRegResult = '❌ $error';
      }
    });
  }

  void _runAllTests() {
    _testResults.clear();
    
    // Test 1: NIN with alphanumeric characters
    _testResults.add(_testNIN('CM12AB34CD56EF78', shouldPass: true, description: 'Alphanumeric NIN (Citizen)'));
    _testResults.add(_testNIN('AF98XY76ZW54QR32', shouldPass: true, description: 'Alphanumeric NIN (Foreign Resident)'));
    _testResults.add(_testNIN('CM9010000000123', shouldPass: true, description: 'Numeric NIN (backward compatible)'));
    _testResults.add(_testNIN('XM1234567890123', shouldPass: false, description: 'Invalid first letter'));
    _testResults.add(_testNIN('CM12AB34CD', shouldPass: false, description: 'Too short'));
    
    // Test 2: TIN validation
    _testResults.add(_testTIN('1000123456', shouldPass: true, expectedType: 'Business/Company'));
    _testResults.add(_testTIN('2000123456', shouldPass: true, expectedType: 'Individual Taxpayer'));
    _testResults.add(_testTIN('3000123456', shouldPass: true, expectedType: 'Government Entity'));
    _testResults.add(_testTIN('0000123456', shouldPass: false, description: 'Invalid first digit'));
    _testResults.add(_testTIN('100012345', shouldPass: false, description: 'Too short'));
    _testResults.add(_testTIN('100012345A', shouldPass: false, description: 'Contains letters'));
    
    // Test 3: Business Registration
    _testResults.add(_testBusinessReg('80034730481569', shouldPass: true, description: 'From URSB certificate'));
    _testResults.add(_testBusinessReg('8003473048156', shouldPass: false, description: 'Too short (13 digits)'));
    _testResults.add(_testBusinessReg('8003473048156A', shouldPass: false, description: 'Contains letters'));
    
    setState(() {});
    
    // Show summary
    final passed = _testResults.where((r) => r.passed).length;
    final total = _testResults.length;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Test Results: $passed/$total passed'),
        backgroundColor: passed == total ? AppTheme.successColor : AppTheme.warningColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  TestResult _testNIN(String value, {required bool shouldPass, String? description}) {
    final error = NINValidator.validateNIN(value);
    final actuallyPassed = error == null;
    final type = actuallyPassed ? NINValidator.getNINType(value) : null;
    
    return TestResult(
      name: 'NIN: $value',
      description: description ?? '',
      expectedPass: shouldPass,
      actualPass: actuallyPassed,
      passed: actuallyPassed == shouldPass,
      details: actuallyPassed ? 'Type: $type' : 'Error: $error',
    );
  }

  TestResult _testTIN(String value, {required bool shouldPass, String? expectedType, String? description}) {
    final error = UgandaBusinessValidators.validateTIN(value);
    final actuallyPassed = error == null;
    final type = actuallyPassed ? UgandaBusinessValidators.getTINEntityType(value) : null;
    
    bool correctType = true;
    if (expectedType != null && type != null) {
      correctType = type == expectedType;
    }
    
    return TestResult(
      name: 'TIN: $value',
      description: description ?? (expectedType ?? ''),
      expectedPass: shouldPass,
      actualPass: actuallyPassed,
      passed: actuallyPassed == shouldPass && correctType,
      details: actuallyPassed ? 'Type: $type${correctType ? '' : ' (Expected: $expectedType)'}' : 'Error: $error',
    );
  }

  TestResult _testBusinessReg(String value, {required bool shouldPass, String? description}) {
    final error = UgandaBusinessValidators.validateBusinessReg(value);
    final actuallyPassed = error == null;
    
    return TestResult(
      name: 'Business Reg: $value',
      description: description ?? '',
      expectedPass: shouldPass,
      actualPass: actuallyPassed,
      passed: actuallyPassed == shouldPass,
      details: actuallyPassed ? 'Valid' : 'Error: $error',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation Tests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: _runAllTests,
            tooltip: 'Run All Tests',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Card(
                color: AppTheme.primaryColor.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(Icons.verified_user, size: 48, color: AppTheme.primaryColor),
                      const SizedBox(height: 8),
                      const Text(
                        'Validation Updates Test',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Test the new NIN, TIN, and Business Registration validators',
                        style: TextStyle(color: Colors.grey[700]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // NIN Test Section
              _buildSectionHeader('1. National ID Number (NIN)', Icons.badge),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ninController,
                decoration: InputDecoration(
                  labelText: 'NIN',
                  hintText: 'e.g., CM12AB34CD56EF78',
                  prefixIcon: const Icon(Icons.badge),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.check_circle_outline),
                    onPressed: _validateNIN,
                  ),
                ),
                textCapitalization: TextCapitalization.characters,
                onChanged: (_) => _validateNIN(),
              ),
              if (_ninResult != null) ...[
                const SizedBox(height: 8),
                _buildResultCard(_ninResult!, _ninType),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildTestButton('CM12AB34CD56EF78', _ninController, _validateNIN),
                  _buildTestButton('CM9010000000123', _ninController, _validateNIN),
                ],
              ),
              const SizedBox(height: 24),

              // TIN Test Section
              _buildSectionHeader('2. Tax Identification Number (TIN)', Icons.assignment),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tinController,
                decoration: InputDecoration(
                  labelText: 'TIN',
                  hintText: 'e.g., 1000123456',
                  prefixIcon: const Icon(Icons.assignment),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.check_circle_outline),
                    onPressed: _validateTIN,
                  ),
                ),
                keyboardType: TextInputType.number,
                maxLength: 10,
                onChanged: (_) => _validateTIN(),
              ),
              if (_tinResult != null) ...[
                const SizedBox(height: 8),
                _buildResultCard(_tinResult!, _tinEntityType),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildTestButton('1000123456', _tinController, _validateTIN),
                  _buildTestButton('2000123456', _tinController, _validateTIN),
                ],
              ),
              const SizedBox(height: 24),

              // Business Registration Test Section
              _buildSectionHeader('3. Business Registration Number', Icons.business_center),
              const SizedBox(height: 12),
              TextFormField(
                controller: _businessRegController,
                decoration: InputDecoration(
                  labelText: 'Business Registration',
                  hintText: 'e.g., 80034730481569',
                  prefixIcon: const Icon(Icons.business_center),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.check_circle_outline),
                    onPressed: _validateBusinessReg,
                  ),
                ),
                keyboardType: TextInputType.number,
                maxLength: 14,
                onChanged: (_) => _validateBusinessReg(),
              ),
              if (_businessRegResult != null) ...[
                const SizedBox(height: 8),
                _buildResultCard(_businessRegResult!, null),
              ],
              const SizedBox(height: 8),
              _buildTestButton('80034730481569', _businessRegController, _validateBusinessReg),
              const SizedBox(height: 24),

              // Sex Selection Test
              _buildSectionHeader('4. Sex/Gender Selection', Icons.person),
              const SizedBox(height: 12),
              DropdownButtonFormField<Sex>(
                value: _selectedSex,
                decoration: const InputDecoration(
                  labelText: 'Sex',
                  prefixIcon: Icon(Icons.person),
                ),
                items: Sex.values.map((sex) {
                  return DropdownMenuItem<Sex>(
                    value: sex,
                    child: Text(sex.displayName),
                  );
                }).toList(),
                onChanged: (Sex? value) {
                  setState(() {
                    _selectedSex = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              Card(
                color: Colors.blue.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Sex options: ${Sex.values.map((s) => s.displayName).join(', ')}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Test Results Section
              if (_testResults.isNotEmpty) ...[
                _buildSectionHeader('Test Results', Icons.assignment_turned_in),
                const SizedBox(height: 12),
                ..._testResults.map((result) => _buildTestResultCard(result)),
                const SizedBox(height: 16),
                _buildSummaryCard(),
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _runAllTests,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Run All Tests'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(String result, String? additionalInfo) {
    final isValid = result.startsWith('✅');
    return Card(
      color: isValid ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isValid ? Colors.green[700] : Colors.red[700],
              ),
            ),
            if (additionalInfo != null) ...[
              const SizedBox(height: 4),
              Text(
                additionalInfo,
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(String value, TextEditingController controller, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: () {
        controller.text = value;
        onPressed();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[200],
        foregroundColor: Colors.black87,
      ),
      child: Text(value, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildTestResultCard(TestResult result) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: result.passed 
          ? Colors.green.withOpacity(0.1) 
          : Colors.red.withOpacity(0.1),
      child: ListTile(
        leading: Icon(
          result.passed ? Icons.check_circle : Icons.cancel,
          color: result.passed ? Colors.green : Colors.red,
        ),
        title: Text(
          result.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result.description.isNotEmpty)
              Text(result.description, style: const TextStyle(fontSize: 12)),
            Text(result.details, style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: Text(
          result.passed ? 'PASS' : 'FAIL',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: result.passed ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final passed = _testResults.where((r) => r.passed).length;
    final total = _testResults.length;
    final percentage = (passed / total * 100).toStringAsFixed(0);
    final allPassed = passed == total;
    
    return Card(
      color: allPassed ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              allPassed ? Icons.check_circle : Icons.warning,
              size: 48,
              color: allPassed ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 8),
            Text(
              '$passed / $total Tests Passed',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$percentage% Success Rate',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TestResult {
  final String name;
  final String description;
  final bool expectedPass;
  final bool actualPass;
  final bool passed;
  final String details;

  TestResult({
    required this.name,
    required this.description,
    required this.expectedPass,
    required this.actualPass,
    required this.passed,
    required this.details,
  });
}

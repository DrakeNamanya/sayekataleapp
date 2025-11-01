import 'package:flutter/material.dart';
import '../../models/uganda_location_data.dart';
import '../../utils/app_theme.dart';

/// Location Statistics Screen
/// Displays comprehensive statistics about the Uganda location database
class LocationStatisticsScreen extends StatelessWidget {
  const LocationStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = UgandaLocationData.getStatistics();
    final districts = UgandaLocationData.getDistricts();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Database Statistics'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary Statistics Card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, color: AppTheme.primaryColor, size: 32),
                      const SizedBox(width: 12),
                      const Text(
                        'Database Summary',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  _buildStatRow('Districts', stats['districts']!, Icons.location_city),
                  const SizedBox(height: 16),
                  _buildStatRow('Subcounties', stats['subcounties']!, Icons.account_balance),
                  const SizedBox(height: 16),
                  _buildStatRow('Parishes', stats['parishes']!, Icons.church),
                  const SizedBox(height: 16),
                  _buildStatRow('Villages', stats['villages']!, Icons.home),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Districts List
          const Text(
            'Available Districts',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: districts.map((district) {
                final subcounties = UgandaLocationData.getSubcounties(district);
                int parishCount = 0;
                int villageCount = 0;
                
                for (var subcounty in subcounties) {
                  final parishes = UgandaLocationData.getParishes(district, subcounty);
                  parishCount += parishes.length;
                  for (var parish in parishes) {
                    final villages = UgandaLocationData.getVillages(district, subcounty, parish);
                    villageCount += villages.length;
                  }
                }

                return ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                    child: Icon(Icons.location_city, color: AppTheme.primaryColor, size: 20),
                  ),
                  title: Text(
                    district,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    '${subcounties.length} Subcounties • $parishCount Parishes • $villageCount Villages',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  children: subcounties.map((subcounty) {
                    final parishes = UgandaLocationData.getParishes(district, subcounty);
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.only(left: 72, right: 16),
                      leading: Icon(Icons.arrow_right, color: AppTheme.accentColor, size: 20),
                      title: Text(subcounty),
                      subtitle: Text('${parishes.length} parishes'),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // Info Card
          Card(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      const Text(
                        'About This Database',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'This comprehensive location database covers major districts across Uganda with their respective administrative divisions. The hierarchical structure ensures accurate location filtering for all users.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Data Structure:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'District → Subcounty/Town → Parish → Village',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, int value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

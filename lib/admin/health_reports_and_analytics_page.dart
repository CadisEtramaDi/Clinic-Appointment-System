import 'package:flutter/material.dart';
import 'package:clinic/utils/app_theme.dart';
import 'package:clinic/services/patient_record_management_service.dart';

class HealthReportsAndAnalyticsPage extends StatefulWidget {
  const HealthReportsAndAnalyticsPage({super.key});

  @override
  State<HealthReportsAndAnalyticsPage> createState() =>
      _HealthReportsAndAnalyticsPageState();
}

class _HealthReportsAndAnalyticsPageState
    extends State<HealthReportsAndAnalyticsPage> {
  final _service = PatientRecordManagementService();
  late Future<Map<String, dynamic>> _dataQualityReport;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  late Future<Map<String, dynamic>> _activityReport;

  @override
  void initState() {
    super.initState();
    _dataQualityReport = _service.generateDataQualityReport();
    _activityReport = _service.generateActivityReport(
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  void _updateActivityReport() {
    setState(() {
      _activityReport = _service.generateActivityReport(
        startDate: _startDate,
        endDate: _endDate,
      );
    });
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _updateActivityReport();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Health Reports & Analytics',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Data Quality Report Section
            Text(
              'Data Quality Report',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: AppTheme.fontSizeXL,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingMD),
            FutureBuilder<Map<String, dynamic>>(
              future: _dataQualityReport,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(color: AppTheme.errorColor),
                    ),
                  );
                }

                final report = snapshot.data ?? {};
                final totalRecords = report['totalRecords'] ?? 0;
                final completeRecords = report['completeRecords'] ?? 0;
                final completePercentage =
                    report['completePercentage'] ?? '0.00';
                final missingFieldsFrequency =
                    report['missingFieldsFrequency'] as Map<String, int>? ?? {};

                return Column(
                  children: [
                    _buildStatisticsCard(
                      'Total Records',
                      totalRecords.toString(),
                      Icons.folder,
                      AppTheme.primaryColor,
                    ),
                    const SizedBox(height: AppTheme.spacingMD),
                    _buildStatisticsCard(
                      'Complete Records',
                      completeRecords.toString(),
                      Icons.check_circle,
                      AppTheme.successColor,
                    ),
                    const SizedBox(height: AppTheme.spacingMD),
                    _buildStatisticsCard(
                      'Completion Rate',
                      '$completePercentage%',
                      Icons.trending_up,
                      AppTheme.successColor,
                    ),
                    const SizedBox(height: AppTheme.spacingLG),
                    if (missingFieldsFrequency.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingLG),
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor,
                          borderRadius: BorderRadius.circular(
                            AppTheme.borderRadiusMedium,
                          ),
                          border: Border.all(color: AppTheme.neutral200),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Most Common Missing Fields',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingMD),
                            ...missingFieldsFrequency.entries
                                .toList()
                                .asMap()
                                .entries
                                .map((entry) {
                                  return _buildFieldFrequencyRow(
                                    entry.value.key,
                                    entry.value.value,
                                    totalRecords > 0
                                        ? ((entry.value.value / totalRecords) *
                                                  100)
                                              .toStringAsFixed(1)
                                        : '0.0',
                                  );
                                }),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppTheme.spacing3XL),
            // Activity Report Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Activity Report',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: AppTheme.fontSizeXL,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: _selectDateRange,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMD,
                      vertical: AppTheme.spacingSM,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        AppTheme.borderRadiusSmall,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: AppTheme.iconSizeSmall,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: AppTheme.spacingXS),
                        Text(
                          'Select Range',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: AppTheme.fontSizeSM,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMD),
            Text(
              '${_startDate.toString().split(' ')[0]} to ${_endDate.toString().split(' ')[0]}',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: AppTheme.fontSizeSM,
              ),
            ),
            const SizedBox(height: AppTheme.spacingMD),
            FutureBuilder<Map<String, dynamic>>(
              future: _activityReport,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(color: AppTheme.errorColor),
                    ),
                  );
                }

                final report = snapshot.data ?? {};
                final totalActions = report['totalActions'] ?? 0;
                final actionBreakdown =
                    report['actionBreakdown'] as Map<String, int>? ?? {};
                final adminActions =
                    report['adminActions'] as Map<String, int>? ?? {};

                return Column(
                  children: [
                    _buildStatisticsCard(
                      'Total Actions',
                      totalActions.toString(),
                      Icons.history,
                      AppTheme.primaryColor,
                    ),
                    const SizedBox(height: AppTheme.spacingLG),
                    if (actionBreakdown.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingLG),
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor,
                          borderRadius: BorderRadius.circular(
                            AppTheme.borderRadiusMedium,
                          ),
                          border: Border.all(color: AppTheme.neutral200),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Actions Breakdown',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingMD),
                            ...actionBreakdown.entries.map(
                              (entry) =>
                                  _buildActionRow(entry.key, entry.value),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: AppTheme.spacingLG),
                    if (adminActions.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingLG),
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor,
                          borderRadius: BorderRadius.circular(
                            AppTheme.borderRadiusMedium,
                          ),
                          border: Border.all(color: AppTheme.neutral200),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Admin Actions',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingMD),
                            ...adminActions.entries.map(
                              (entry) => _buildAdminRow(entry.key, entry.value),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(color: AppTheme.neutral200),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: AppTheme.fontSizeMD,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSM),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: AppTheme.fontSize3XL,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMD),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
            ),
            child: Icon(icon, color: color, size: AppTheme.iconSize2XL),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldFrequencyRow(
    String fieldName,
    int count,
    String percentage,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                fieldName,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$count ($percentage%)',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: AppTheme.fontSizeSM,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXS),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
            child: LinearProgressIndicator(
              value: double.parse(percentage) / 100,
              minHeight: 6,
              backgroundColor: AppTheme.neutral200,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.warningColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(String action, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMD),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            action.replaceAll('_', ' ').toUpperCase(),
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMD,
              vertical: AppTheme.spacingXS,
            ),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: AppTheme.fontSizeSM,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminRow(String adminName, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMD),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            adminName,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMD,
              vertical: AppTheme.spacingXS,
            ),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count actions',
              style: TextStyle(
                color: AppTheme.successColor,
                fontWeight: FontWeight.bold,
                fontSize: AppTheme.fontSizeSM,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

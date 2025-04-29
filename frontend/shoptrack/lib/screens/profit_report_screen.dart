import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/product_service.dart';
import '../constants/theme_constants.dart';

class ProfitReportScreen extends StatefulWidget {
  final String shopId;
  
  const ProfitReportScreen({Key? key, required this.shopId}) : super(key: key);

  @override
  State<ProfitReportScreen> createState() => _ProfitReportScreenState();
}

class _ProfitReportScreenState extends State<ProfitReportScreen> with SingleTickerProviderStateMixin {
  final ProductService _productService = ProductService();
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic> _reportData = {};
  String? _errorMessage;
  
  // Date range filters
  DateTime? _startDate;
  DateTime? _endDate;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReport();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      String? startDateStr;
      String? endDateStr;
      
      if (_startDate != null) {
        startDateStr = DateFormat('yyyy-MM-dd').format(_startDate!);
      }
      
      if (_endDate != null) {
        endDateStr = DateFormat('yyyy-MM-dd').format(_endDate!);
      }
      
      final reportData = await _productService.getProfitReport(
        widget.shopId,
        startDate: startDateStr,
        endDate: endDateStr,
      );
      
      setState(() {
        _reportData = reportData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load profit report: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(2000),
      lastDate: _endDate ?? DateTime.now(),
    );
    
    if (picked != null && (_startDate == null || picked != _startDate)) {
      setState(() {
        _startDate = picked;
      });
      _loadReport();
    }
  }
  
  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2000),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && (_endDate == null || picked != _endDate)) {
      setState(() {
        _endDate = picked;
      });
      _loadReport();
    }
  }
  
  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _loadReport();
  }
  
  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profit Report'),
        backgroundColor: kNewPrimaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Summary'),
            Tab(text: 'By Product'),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
        ),
      ),
      body: Column(
        children: [
          // Date filter controls
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Date Range',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _selectStartDate(context),
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          _startDate != null
                              ? DateFormat('yyyy-MM-dd').format(_startDate!)
                              : 'Start Date',
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _selectEndDate(context),
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          _endDate != null
                              ? DateFormat('yyyy-MM-dd').format(_endDate!)
                              : 'End Date',
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.clear),
                      tooltip: 'Clear filters',
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Tab content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          // Summary Tab
                          SingleChildScrollView(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Card(
                                  elevation: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Overall Profit Summary',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Divider(),
                                        const SizedBox(height: 8),
                                        _buildSummaryRow(
                                          'Total Sales',
                                          '${_reportData['overall']?['totalSales'] ?? 0} units',
                                        ),
                                        _buildSummaryRow(
                                          'Total Revenue',
                                          '\$${formatter.format(_reportData['overall']?['totalRevenue'] ?? 0)}',
                                        ),
                                        _buildSummaryRow(
                                          'Total Cost',
                                          '\$${formatter.format(_reportData['overall']?['totalCost'] ?? 0)}',
                                        ),
                                        const Divider(),
                                        _buildSummaryRow(
                                          'Total Profit',
                                          '\$${formatter.format(_reportData['overall']?['totalProfit'] ?? 0)}',
                                          isHighlighted: true,
                                        ),
                                        if (_reportData['overall']?['totalRevenue'] != null && 
                                            _reportData['overall']?['totalRevenue'] > 0)
                                          _buildSummaryRow(
                                            'Profit Margin',
                                            '${((_reportData['overall']['totalProfit'] / _reportData['overall']['totalRevenue']) * 100).toStringAsFixed(2)}%',
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 24),
                                
                                // Date range info
                                Text(
                                  'Report Period: ${_startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : 'All time'} to ${_endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : 'Present'}',
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // By Product Tab
                          _reportData['by_product'] == null || (_reportData['by_product'] as List).isEmpty
                              ? const Center(child: Text('No product data available'))
                              : ListView.builder(
                                  itemCount: (_reportData['by_product'] as List).length,
                                  itemBuilder: (context, index) {
                                    final product = (_reportData['by_product'] as List)[index];
                                    return Card(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product['product_name'] ?? 'Unknown Product',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const Divider(),
                                            _buildSummaryRow(
                                              'Units Sold',
                                              '${product['totalSales']}',
                                            ),
                                            _buildSummaryRow(
                                              'Revenue',
                                              '\$${formatter.format(product['totalRevenue'])}',
                                            ),
                                            _buildSummaryRow(
                                              'Cost',
                                              '\$${formatter.format(product['totalCost'])}',
                                            ),
                                            const Divider(),
                                            _buildSummaryRow(
                                              'Profit',
                                              '\$${formatter.format(product['totalProfit'])}',
                                              isHighlighted: true,
                                            ),
                                            if (product['totalRevenue'] > 0)
                                              _buildSummaryRow(
                                                'Profit Margin',
                                                '${((product['totalProfit'] / product['totalRevenue']) * 100).toStringAsFixed(2)}%',
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummaryRow(String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isHighlighted ? 16 : 14,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isHighlighted ? 16 : 14,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              color: isHighlighted ? kNewPrimaryColor : null,
            ),
          ),
        ],
      ),
    );
  }
} 
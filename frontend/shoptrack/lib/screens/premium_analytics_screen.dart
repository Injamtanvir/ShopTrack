import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'dart:math' as math;

class PremiumAnalyticsScreen extends StatefulWidget {
  static const routeName = '/premium-analytics';
  
  const PremiumAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<PremiumAnalyticsScreen> createState() => _PremiumAnalyticsScreenState();
}

class _PremiumAnalyticsScreenState extends State<PremiumAnalyticsScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;
  
  bool _isLoading = false;
  String? _error;
  
  // Sales analytics data
  Map<String, dynamic>? _salesAnalytics;
  
  // Product analytics data
  Map<String, dynamic>? _productAnalytics;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final shopId = authProvider.user!.shopId;
      
      // Load sales analytics
      _salesAnalytics = await _apiService.getPremiumSalesAnalytics(shopId);
      
      // Load product analytics
      _productAnalytics = await _apiService.getProductProfitAnalytics(shopId);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isPremium = authProvider.isPremium;
    
    if (!isPremium) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Premium Analytics'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
        body: const Center(
          child: Text('Premium subscription required to access analytics.'),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Analytics'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Sales Analytics'),
            Tab(text: 'Product Analytics'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSalesAnalyticsTab(),
                    _buildProductAnalyticsTab(),
                  ],
                ),
    );
  }
  
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: $_error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
  
  // Sales Analytics Tab
  Widget _buildSalesAnalyticsTab() {
    if (_salesAnalytics == null) {
      return const Center(child: Text('No sales analytics data available.'));
    }
    
    final dailySales = _salesAnalytics!['daily_sales'] as List<dynamic>;
    final monthlySales = _salesAnalytics!['monthly_sales'] as List<dynamic>;
    final topSellingProducts = _salesAnalytics!['top_selling_products'] as List<dynamic>;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Sales Overview'),
          _buildSummaryCards(),
          
          _buildSectionTitle('Daily Sales (Last 7 Days)'),
          SizedBox(
            height: 250,
            child: _buildDailySalesChart(dailySales),
          ),
          
          _buildSectionTitle('Monthly Sales (Last 6 Months)'),
          SizedBox(
            height: 250,
            child: _buildMonthlySalesChart(monthlySales),
          ),
          
          _buildSectionTitle('Top Selling Products'),
          ...topSellingProducts.take(5).map((product) => _buildTopProductItem(product)).toList(),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }
  
  // Product Analytics Tab
  Widget _buildProductAnalyticsTab() {
    if (_productAnalytics == null) {
      return const Center(child: Text('No product analytics data available.'));
    }
    
    final mostProfitableProducts = _productAnalytics!['most_profitable_products'] as List<dynamic>;
    final leastProfitableProducts = _productAnalytics!['least_profitable_products'] as List<dynamic>;
    final productCategoryShare = _productAnalytics!['category_distribution'] as List<dynamic>;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Profit Distribution'),
          SizedBox(
            height: 250,
            child: _buildProfitDistributionChart(productCategoryShare),
          ),
          
          _buildSectionTitle('Most Profitable Products'),
          ...mostProfitableProducts.take(5).map((product) => _buildProfitableProductItem(product, true)).toList(),
          
          _buildSectionTitle('Least Profitable Products'),
          ...leastProfitableProducts.take(5).map((product) => _buildProfitableProductItem(product, false)).toList(),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildSummaryCards() {
    final totalSales = _salesAnalytics!['total_sales'] ?? 0.0;
    final totalOrders = _salesAnalytics!['total_orders'] ?? 0;
    final averageOrderValue = _salesAnalytics!['average_order_value'] ?? 0.0;
    
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Sales',
            '৳${totalSales.toStringAsFixed(2)}',
            Icons.attach_money,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Orders',
            totalOrders.toString(),
            Icons.shopping_cart,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Avg. Order',
            '৳${averageOrderValue.toStringAsFixed(2)}',
            Icons.insights,
            Colors.purple,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDailySalesChart(List<dynamic> dailySales) {
    // Sort by date (assuming the data comes with dates in chronological order)
    final sortedData = List<Map<String, dynamic>>.from(dailySales);
    
    // Prepare data for the chart
    List<FlSpot> spots = [];
    List<String> bottomTitles = [];
    
    for (int i = 0; i < sortedData.length; i++) {
      final sale = sortedData[i];
      spots.add(FlSpot(i.toDouble(), sale['total'].toDouble()));
      bottomTitles.add(_formatDateShort(sale['date']));
    }
    
    return _buildLineChart(
      spots: spots,
      bottomTitles: bottomTitles,
      maxY: spots.isEmpty ? 1000 : (spots.map((spot) => spot.y).reduce(math.max) * 1.2),
      legendName: 'Daily Sales',
      gradientColors: [Colors.blue.shade300, Colors.blue.shade700],
    );
  }
  
  Widget _buildMonthlySalesChart(List<dynamic> monthlySales) {
    // Sort by month (assuming the data comes with months in chronological order)
    final sortedData = List<Map<String, dynamic>>.from(monthlySales);
    
    // Prepare data for the chart
    List<FlSpot> spots = [];
    List<String> bottomTitles = [];
    
    for (int i = 0; i < sortedData.length; i++) {
      final sale = sortedData[i];
      spots.add(FlSpot(i.toDouble(), sale['total'].toDouble()));
      bottomTitles.add(sale['month']);
    }
    
    return _buildLineChart(
      spots: spots,
      bottomTitles: bottomTitles,
      maxY: spots.isEmpty ? 5000 : (spots.map((spot) => spot.y).reduce(math.max) * 1.2),
      legendName: 'Monthly Sales',
      gradientColors: [Colors.purple.shade300, Colors.purple.shade700],
    );
  }
  
  Widget _buildProfitDistributionChart(List<dynamic> categoryDistribution) {
    // Add colors for categories
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Theme.of(context).colorScheme.primary,
      Colors.cyan,
    ];
    
    // Prepare data for the chart
    final pieData = <PieChartSectionData>[];
    
    for (int i = 0; i < categoryDistribution.length; i++) {
      final category = categoryDistribution[i];
      final color = i < colors.length ? colors[i] : colors[i % colors.length];
      
      pieData.add(
        PieChartSectionData(
          value: category['percentage'].toDouble(),
          title: '${category['percentage'].toStringAsFixed(1)}%',
          color: color,
          radius: 90,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      );
    }
    
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: pieData,
              centerSpaceRadius: 30,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: List.generate(categoryDistribution.length, (index) {
            final category = categoryDistribution[index];
            final color = index < colors.length ? colors[index] : colors[index % colors.length];
            
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  color: color,
                ),
                const SizedBox(width: 4),
                Text(category['category']),
              ],
            );
          }),
        ),
      ],
    );
  }
  
  Widget _buildLineChart({
    required List<FlSpot> spots,
    required List<String> bottomTitles,
    required double maxY,
    required String legendName,
    required List<Color> gradientColors,
  }) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < bottomTitles.length) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8,
                    child: Text(
                      bottomTitles[value.toInt()],
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 8,
                  child: Text(
                    '৳${value.toInt()}',
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300),
        ),
        minX: 0,
        maxX: (spots.length - 1).toDouble(),
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: LinearGradient(
              colors: gradientColors,
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: gradientColors
                    .map((color) => color.withOpacity(0.3))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTopProductItem(Map<String, dynamic> product) {
    final name = product['name'] as String;
    final quantity = product['quantity_sold'] as int;
    final sales = product['total_sales'] as double;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: const Icon(Icons.shopping_bag, color: Colors.blue),
        ),
        title: Text(name),
        subtitle: Text('$quantity units sold'),
        trailing: Text(
          '৳${sales.toStringAsFixed(2)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ),
    );
  }
  
  Widget _buildProfitableProductItem(Map<String, dynamic> product, bool isProfit) {
    final name = product['name'] as String;
    final profit = product['profit'] as double;
    final percentage = product['profit_percentage'] as double;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isProfit ? Colors.green.shade100 : Colors.red.shade100,
          child: Icon(
            isProfit ? Icons.trending_up : Icons.trending_down,
            color: isProfit ? Colors.green : Colors.red,
          ),
        ),
        title: Text(name),
        subtitle: Text('Profit margin: ${percentage.toStringAsFixed(1)}%'),
        trailing: Text(
          '৳${profit.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isProfit ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }
  
  String _formatDateShort(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}';
    } catch (e) {
      return dateStr;
    }
  }
} 
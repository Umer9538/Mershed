import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> with SingleTickerProviderStateMixin {
  final _budgetController = TextEditingController();
  final _destinationController = TextEditingController();
  bool _showResults = false;
  double? _totalBudget;
  Map<String, double> _expenseBreakdown = {};
  double? _exchangeRate;
  String _selectedCurrency = 'USD';
  List<String> _currencies = ['USD', 'EUR', 'GBP', 'PKR', 'INR', 'CAD', 'AUD'];
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _animation;
  final _formKey = GlobalKey<FormState>();

  final Map<String, IconData> _categoryIcons = {
    'Accommodation': Icons.hotel,
    'Food': Icons.restaurant,
    'Transport': Icons.directions_car,
    'Activities': Icons.local_activity,
  };

  @override
  void initState() {
    super.initState();
    _loadCachedExchangeRate();
    _fetchExchangeRate();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
    _animationController.forward();
  }

  Future<void> _loadCachedExchangeRate() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedRate = prefs.getDouble('exchange_rate_$_selectedCurrency');
    if (cachedRate != null) {
      setState(() {
        _exchangeRate = cachedRate;
      });
    }
  }

  Future<void> _cacheExchangeRate(double rate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('exchange_rate_$_selectedCurrency', rate);
  }

  Future<void> _fetchExchangeRate() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiKey = dotenv.env['EXCHANGERATE_API_KEY'] ?? '';
      if (apiKey.isEmpty) {
        throw Exception('ExchangeRate-API key is missing in .env file');
      }

      final url = 'https://v6.exchangerate-api.com/v6/$apiKey/latest/SAR';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] == 'success') {
          setState(() {
            _exchangeRate = data['conversion_rates'][_selectedCurrency];
          });
          await _cacheExchangeRate(_exchangeRate!);
        } else {
          throw Exception('Failed to fetch exchange rates: ${data['error-type']}');
        }
      } else {
        throw Exception('Failed to fetch exchange rates: ${response.statusCode}');
      }
    } catch (e) {
      if (_exchangeRate == null) {
        setState(() {
          _exchangeRate = _getFallbackExchangeRate(_selectedCurrency);
        });
        _showCustomSnackBar(
          'Using fallback exchange rate due to error: $e',
          Colors.orange,
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  double _getFallbackExchangeRate(String currency) {
    const fallbackRates = {
      'USD': 0.266,
      'EUR': 0.245,
      'GBP': 0.205,
      'PKR': 74.0,
      'INR': 22.5,
      'CAD': 0.365,
      'AUD': 0.405,
    };
    return fallbackRates[currency] ?? 1.0;
  }

  void _showCustomSnackBar(String message, Color backgroundColor) {
    const fabHeight = 56.0; // Default FAB height
    const fabBottomPadding = 16.0; // Default padding from bottom
    const snackBarBottomMargin = fabHeight + fabBottomPadding + 10.0; // Extra buffer

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.only(
          bottom: snackBarBottomMargin,
          left: 10,
          right: 10,
        ),
      ),
    );
  }

  Future<void> _generateExpenseBreakdown() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final budget = double.parse(_budgetController.text);
      final destination = _destinationController.text;

      final breakdown = await _fetchAIExpenseBreakdown(budget, destination);

      setState(() {
        _totalBudget = budget;
        _expenseBreakdown = breakdown;
        _showResults = true;
      });
    } catch (e) {
      final budget = double.parse(_budgetController.text);
      setState(() {
        _totalBudget = budget;
        _expenseBreakdown = {
          'Accommodation': budget * 0.4,
          'Food': budget * 0.25,
          'Transport': budget * 0.2,
          'Activities': budget * 0.15,
        };
        _showResults = true;
      });
      _showCustomSnackBar(
        'Using fallback expense breakdown due to error: $e',
        Colors.orange,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
      if (_showResults && _animationController.status != AnimationStatus.forward) {
        _animationController.reset();
        _animationController.forward();
      }
    }
  }

  Future<Map<String, double>> _fetchAIExpenseBreakdown(double budget, String destination) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw Exception('OpenAI API key is missing in .env file');
    }

    final url = 'https://api.openai.com/v1/chat/completions';
    final prompt = '''
I am traveling to $destination with a budget of $budget SAR (Saudi Riyal). 
Provide an expense breakdown for my trip in the following categories: Accommodation, Food, Transport, and Activities.
Ensure the total adds up to $budget SAR. Return the response as a JSON object with the categories as keys and the amounts in SAR as values.
Example response: {"Accommodation": 2000, "Food": 1500, "Transport": 1000, "Activities": 500}
''';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {
            'role': 'user',
            'content': prompt,
          },
        ],
        'temperature': 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];
      final breakdown = jsonDecode(content) as Map<String, dynamic>;
      return breakdown.map((key, value) => MapEntry(key, value.toDouble()));
    } else {
      throw Exception('Failed to fetch AI expense breakdown: ${response.statusCode} - ${response.body}');
    }
  }

  String _formatCurrency(double amount, [String? currencyCode]) {
    final formatter = NumberFormat.currency(
      symbol: currencyCode ?? 'SAR ',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  @override
  void dispose() {
    _budgetController.dispose();
    _destinationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          // Top section with background image
          Container(
            height: 120, // Adjust height as needed
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.jpeg'),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: FadeIn(
                duration: const Duration(milliseconds: 600),
                child: _buildAppBar(theme),
              ),
            ),
          ),
          // Main content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    FadeInUp(
                      duration: const Duration(milliseconds: 800),
                      child: _buildInputCard(theme),
                    ),
                    if (_showResults && _totalBudget != null)
                      FadeInUp(
                        duration: const Duration(milliseconds: 1000),
                        delay: const Duration(milliseconds: 300),
                        child: _buildResultsSection(theme),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: ZoomIn(
        duration: const Duration(milliseconds: 800),
        child: FloatingActionButton.extended(
          onPressed: () => _showBudgetTipsDialog(context),
          icon: const Icon(Icons.lightbulb_outline),
          label: const Text("Travel Tips"),
          tooltip: 'Budget Tips',
        ),
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
              color: Colors.white,
            ),
          ),
          Expanded(
            child: Text(
              'Smart Budget Planner',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    blurRadius: 10.0,
                    color: Colors.black.withOpacity(0.5),
                    offset: const Offset(2.0, 2.0),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildInputCard(ThemeData theme) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black38,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surface.withOpacity(0.9),
            ],
          ),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Where are you traveling?',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _destinationController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your destination';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Destination',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: theme.colorScheme.primary),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: theme.colorScheme.primary.withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'What\'s your budget?',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your budget';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Budget must be greater than zero';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Budget (SAR)',
                  prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                  suffixText: 'SAR',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: theme.colorScheme.primary.withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Convert to another currency:',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCurrency,
                      decoration: InputDecoration(
                        labelText: 'Currency',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: theme.colorScheme.primary.withOpacity(0.5)),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: _currencies.map((currency) {
                        return DropdownMenuItem<String>(
                          value: currency,
                          child: Text(currency),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCurrency = value!;
                          _loadCachedExchangeRate();
                          _fetchExchangeRate();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (_exchangeRate != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '1 SAR = ${_exchangeRate!.toStringAsFixed(4)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _generateExpenseBreakdown,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: theme.colorScheme.primary.withOpacity(0.4),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calculate_outlined),
                      const SizedBox(width: 10),
                      Text(
                        'Generate Budget Plan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsSection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.secondary.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Budget for ${_destinationController.text}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_formatCurrency(_totalBudget!)} (${_formatCurrency(_totalBudget! * _exchangeRate!, _selectedCurrency)})',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Expense Breakdown',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildPieChart(),
          const SizedBox(height: 24),
          ..._expenseBreakdown.entries.map((entry) {
            return AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                final value = _animation.value;
                return _buildExpenseItem(
                  entry.key,
                  entry.value * value,
                  (_totalBudget != 0 ? (entry.value / _totalBudget! * 100) : 0).round(),
                );
              },
            );
          }).toList(),
          const SizedBox(height: 24),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Currency Conversion',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total in SAR:',
                        style: theme.textTheme.bodyLarge,
                      ),
                      Text(
                        _formatCurrency(_totalBudget!),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total in $_selectedCurrency:',
                        style: theme.textTheme.bodyLarge,
                      ),
                      Text(
                        _formatCurrency(_totalBudget! * _exchangeRate!, _selectedCurrency),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Exchange Rate:',
                        style: theme.textTheme.bodyLarge,
                      ),
                      Text(
                        '1 SAR = ${_exchangeRate!.toStringAsFixed(4)} $_selectedCurrency',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    final List<Color> colorList = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.amber,
      Colors.purple,
      Colors.teal,
    ];

    return SizedBox(
      height: 240,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, _) {
                    return PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (_, __) {},
                        ),
                        sections: _getSections(colorList),
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        startDegreeOffset: -90,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...List.generate(
                      _expenseBreakdown.length,
                          (index) {
                        final entry = _expenseBreakdown.entries.elementAt(index);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: colorList[index % colorList.length],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _getSections(List<Color> colorList) {
    List<PieChartSectionData> sections = [];
    int index = 0;

    for (var entry in _expenseBreakdown.entries) {
      final percentage = (_totalBudget != 0)
          ? (entry.value / _totalBudget! * 100)
          : 0;

      sections.add(
        PieChartSectionData(
          color: colorList[index % colorList.length],
          value: entry.value,
          title: '${percentage.round()}%',
          radius: 110 * _animation.value,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      index++;
    }

    return sections;
  }

  Widget _buildExpenseItem(String category, double amount, int percentage) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 3,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _categoryIcons[category] ?? Icons.category,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatCurrency(amount)} ($percentage%)',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  if (_exchangeRate != null)
                    Text(
                      _formatCurrency(amount * _exchangeRate!, _selectedCurrency),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
            ),
            Column(
              children: [
                SizedBox(
                  width: 50,
                  height: 50,
                  child: Stack(
                    children: [
                      CircularProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                        strokeWidth: 6,
                      ),
                      Center(
                        child: Text(
                          '$percentage%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showBudgetTipsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 8),
                    child: Center(
                      child: Container(
                        width: 60,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Smart Travel Tips',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      children: [
                        _buildTipCard(
                          icon: Icons.calendar_today,
                          title: 'Travel Off-Season',
                          description: 'Prices can be up to 40% lower when traveling during off-peak periods. Research the destination\'s low season for the best deals.',
                          bgColor: Colors.blue[50]!,
                          iconColor: Colors.blue,
                        ),
                        _buildTipCard(
                          icon: Icons.hotel,
                          title: 'Alternative Accommodations',
                          description: 'Consider hostels, guesthouses, or vacation rentals instead of hotels. These alternatives can save you 30-50% on accommodation costs.',
                          bgColor: Colors.green[50]!,
                          iconColor: Colors.green,
                        ),
                        _buildTipCard(
                          icon: Icons.restaurant_menu,
                          title: 'Eat Like a Local',
                          description: 'Dining at local establishments instead of tourist restaurants can reduce your food expenses by up to 70% while providing a more authentic experience.',
                          bgColor: Colors.orange[50]!,
                          iconColor: Colors.orange,
                        ),
                        _buildTipCard(
                          icon: Icons.directions_bus,
                          title: 'Use Public Transportation',
                          description: 'Public transit can be 5-10 times cheaper than taxis or rental cars. Research transit passes available for tourists.',
                          bgColor: Colors.purple[50]!,
                          iconColor: Colors.purple,
                        ),
                        _buildTipCard(
                          icon: Icons.credit_card,
                          title: 'Watch Currency Exchange',
                          description: 'Use cards with no foreign transaction fees and exchange currency at banks rather than airports or tourist areas to save up to 10%.',
                          bgColor: Colors.red[50]!,
                          iconColor: Colors.red,
                        ),
                        _buildTipCard(
                          icon: Icons.local_offer,
                          title: 'Find Free Attractions',
                          description: 'Many destinations offer free museum days, parks, and walking tours. Research free activities before your trip.',
                          bgColor: Colors.teal[50]!,
                          iconColor: Colors.teal,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Got it!',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTipCard({
    required IconData icon,
    required String title,
    required String description,
    required Color bgColor,
    required Color iconColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
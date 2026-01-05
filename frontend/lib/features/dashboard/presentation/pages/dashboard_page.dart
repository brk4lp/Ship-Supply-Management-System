import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/linear_components.dart';
import '../../../../src/rust/api.dart' as rust_api;
import '../../../../src/rust/models.dart' as rust_models;

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _rustVersion = 'Yükleniyor...';
  String _greetMessage = '';
  int _shipCount = 0;
  int _supplierCount = 0;
  int _supplyItemCount = 0;
  bool _dbConnected = false;
  
  // Profitability data
  rust_models.ProfitSummary? _profitSummary;
  List<rust_models.OrderProfitInfo> _topOrders = [];
  bool _isLoadingProfit = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final version = await rust_api.getVersion();
      final greeting = await rust_api.greet(name: 'SSMS Kullanıcısı');
      final dbConnected = await rust_api.isDatabaseConnected();
      
      int shipCount = 0;
      int supplierCount = 0;
      int supplyItemCount = 0;
      rust_models.ProfitSummary? profitSummary;
      List<rust_models.OrderProfitInfo> topOrders = [];
      
      if (dbConnected) {
        shipCount = (await rust_api.getShipCount()).toInt();
        supplierCount = (await rust_api.getSupplierCount()).toInt();
        supplyItemCount = (await rust_api.getSupplyItemCount()).toInt();
        
        // Load profitability data
        try {
          profitSummary = await rust_api.getProfitSummary();
          topOrders = await rust_api.getTopProfitableOrders(limit: 5);
        } catch (e) {
          debugPrint('Profit data error: $e');
        }
      }
      
      setState(() {
        _rustVersion = version;
        _greetMessage = greeting;
        _dbConnected = dbConnected;
        _shipCount = shipCount;
        _supplierCount = supplierCount;
        _supplyItemCount = supplyItemCount;
        _profitSummary = profitSummary;
        _topOrders = topOrders;
        _isLoadingProfit = false;
      });
    } catch (e) {
      setState(() {
        _rustVersion = 'Hata: $e';
        _greetMessage = '';
        _isLoadingProfit = false;
      });
    }
  }

  Future<void> _loadSeedData(BuildContext context) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Demo Verisi Yükle'),
        content: const Text(
          'Bu işlem mevcut tüm verileri silecek ve yerine Egeport demo verilerini yükleyecektir.\n\nDevam etmek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
            child: const Text('Yükle'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!context.mounted) return;

    // Show loading indicator (non-dialog approach to avoid navigation issues)
    setState(() {});
    
    // Show loading snackbar instead of dialog
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 16),
            Text('Demo verileri yükleniyor...'),
          ],
        ),
        duration: Duration(minutes: 1),
      ),
    );

    try {
      final result = await rust_api.loadSeedData();
      scaffoldMessenger.hideCurrentSnackBar();
      
      if (!context.mounted) return;

      // Show success
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(result),
          backgroundColor: AppTheme.success,
          duration: const Duration(seconds: 5),
        ),
      );

      // Reload data
      _loadData();
    } catch (e) {
      scaffoldMessenger.hideCurrentSnackBar();
      
      if (!context.mounted) return;

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Platform-adaptive layout
    if (Platform.isWindows || Platform.isMacOS) {
      return _buildDesktopDashboard(context);
    } else {
      return _buildMobileDashboard(context);
    }
  }

  /// Desktop Dashboard - Data dense, sidebar navigation
  Widget _buildDesktopDashboard(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Text(
          'Ana Sayfa',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryText,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.secondaryText),
            onPressed: _loadData,
            tooltip: 'Yenile',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FRB Integration Status Banner
            _FRBStatusBanner(
              version: _rustVersion,
              message: _greetMessage,
              dbConnected: _dbConnected,
            ),
            const SizedBox(height: 16),
            // Summary Cards Row
            Row(
              children: [
                Expanded(child: _SummaryCard(
                  title: 'Toplam Sipariş',
                  value: '${_profitSummary?.totalOrders ?? 0}',
                  icon: Icons.shopping_cart_outlined,
                  color: AppTheme.accent,
                )),
                const SizedBox(width: 16),
                Expanded(child: _SummaryCard(
                  title: 'Toplam Gemi',
                  value: '$_shipCount',
                  icon: Icons.directions_boat_outlined,
                  color: const Color(0xFF0EA5E9),
                )),
                const SizedBox(width: 16),
                Expanded(child: _SummaryCard(
                  title: 'Tedarikçi',
                  value: '$_supplierCount',
                  icon: Icons.store_outlined,
                  color: const Color(0xFF10B981),
                )),
                const SizedBox(width: 16),
                Expanded(child: _SummaryCard(
                  title: 'Ürün Kataloğu',
                  value: '$_supplyItemCount',
                  icon: Icons.inventory_2_outlined,
                  color: const Color(0xFFF59E0B),
                )),
              ],
            ),
            const SizedBox(height: 16),
            // Profitability Cards Row
            if (_profitSummary != null) ...[
              Row(
                children: [
                  Expanded(child: _ProfitCard(
                    title: 'Toplam Gelir',
                    value: _formatCurrency(_profitSummary!.totalRevenue),
                    currency: _profitSummary!.currency,
                    icon: Icons.trending_up,
                    color: AppTheme.success,
                  )),
                  const SizedBox(width: 16),
                  Expanded(child: _ProfitCard(
                    title: 'Toplam Maliyet',
                    value: _formatCurrency(_profitSummary!.totalCost),
                    currency: _profitSummary!.currency,
                    icon: Icons.trending_down,
                    color: AppTheme.warning,
                  )),
                  const SizedBox(width: 16),
                  Expanded(child: _ProfitCard(
                    title: 'Brüt Kar',
                    value: _formatCurrency(_profitSummary!.totalProfit),
                    currency: _profitSummary!.currency,
                    icon: Icons.account_balance_wallet,
                    color: _profitSummary!.totalProfit >= 0 ? AppTheme.success : AppTheme.error,
                  )),
                  const SizedBox(width: 16),
                  Expanded(child: _ProfitCard(
                    title: 'Kar Marjı',
                    value: _profitSummary!.averageMargin != null 
                        ? '%${_profitSummary!.averageMargin!.toStringAsFixed(1)}' 
                        : '-',
                    currency: '',
                    icon: Icons.percent,
                    color: (_profitSummary!.averageMargin ?? 0) >= 20 
                        ? AppTheme.success 
                        : (_profitSummary!.averageMargin ?? 0) >= 10 
                            ? AppTheme.warning 
                            : AppTheme.error,
                  )),
                ],
              ),
              const SizedBox(height: 24),
            ],
            // Top Profitable Orders & Quick Stats
            Expanded(
              child: Row(
                children: [
                  // Top Profitable Orders
                  Expanded(
                    flex: 2,
                    child: LinearContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('En Karlı Siparişler', style: AppTheme.headingMedium),
                              Text(
                                '${_topOrders.length} sipariş',
                                style: AppTheme.bodySmall.copyWith(color: AppTheme.secondaryText),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: _topOrders.isEmpty
                                ? const EmptyState(
                                    icon: Icons.receipt_long_outlined,
                                    title: 'Henüz sipariş bulunmuyor',
                                    subtitle: 'Yeni bir sipariş oluşturarak başlayın',
                                  )
                                : ListView.separated(
                                    itemCount: _topOrders.length,
                                    separatorBuilder: (_, __) => const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final order = _topOrders[index];
                                      return _OrderProfitTile(order: order);
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Quick Actions
                  Expanded(
                    child: LinearContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hızlı İşlemler', style: AppTheme.headingMedium),
                          const SizedBox(height: 16),
                          _QuickActionButton(
                            icon: Icons.add_shopping_cart,
                            label: 'Yeni Sipariş',
                            onTap: () => Navigator.pushNamed(context, '/orders'),
                          ),
                          const SizedBox(height: 8),
                          _QuickActionButton(
                            icon: Icons.directions_boat,
                            label: 'Gemi Ekle',
                            onTap: () => Navigator.pushNamed(context, '/ships'),
                          ),
                          const SizedBox(height: 8),
                          _QuickActionButton(
                            icon: Icons.calendar_today,
                            label: 'Takvimi Görüntüle',
                            onTap: () => Navigator.pushNamed(context, '/calendar'),
                          ),
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 8),
                          _QuickActionButton(
                            icon: Icons.dataset_outlined,
                            label: 'Demo Verisi Yükle',
                            color: AppTheme.accent,
                            onTap: () => _loadSeedData(context),
                          ),
                        ],
                      ),
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
  
  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(2);
  }

  /// Mobile Dashboard - Touch friendly, bottom navigation
  Widget _buildMobileDashboard(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Text(
          'SSMS',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: AppTheme.brandColor,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary Cards - 2x2 Grid for mobile
          Row(
            children: [
              Expanded(child: _MobileSummaryCard(
                title: 'Siparişler',
                value: '0',
                icon: Icons.shopping_cart_outlined,
              )),
              const SizedBox(width: 12),
              Expanded(child: _MobileSummaryCard(
                title: 'Bekleyen',
                value: '0',
                icon: Icons.hourglass_empty_outlined,
              )),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _MobileSummaryCard(
                title: 'Teslim',
                value: '0',
                icon: Icons.check_circle_outline,
              )),
              const SizedBox(width: 12),
              Expanded(child: _MobileSummaryCard(
                title: 'Gemiler',
                value: '0',
                icon: Icons.directions_boat_outlined,
              )),
            ],
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Son Siparişler'),
          const SizedBox(height: 8),
          LinearContainer(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 48,
                  color: AppTheme.border,
                ),
                const SizedBox(height: 12),
                Text(
                  'Henüz sipariş yok',
                  style: GoogleFonts.inter(
                    color: AppTheme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Desktop Summary Card with "Linear" style
class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return LinearContainer(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Mobile Summary Card - Compact for touch
class _MobileSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MobileSummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return LinearContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.accent, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: AppTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// FRB Integration Status Banner - Shows Rust connection status
class _FRBStatusBanner extends StatelessWidget {
  final String version;
  final String message;
  final bool dbConnected;

  const _FRBStatusBanner({
    required this.version,
    required this.message,
    this.dbConnected = false,
  });

  @override
  Widget build(BuildContext context) {
    final isConnected = version.contains('SSMS Core');
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isConnected 
            ? const Color(0xFF10B981).withOpacity(0.1)
            : const Color(0xFFF59E0B).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnected 
              ? const Color(0xFF10B981).withOpacity(0.3)
              : const Color(0xFFF59E0B).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isConnected ? Icons.check_circle : Icons.warning_amber_rounded,
            color: isConnected ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConnected ? 'Flutter-Rust Köprüsü Aktif' : 'Rust Bağlantısı Bekleniyor',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      dbConnected ? Icons.storage : Icons.storage_outlined,
                      size: 14,
                      color: dbConnected ? const Color(0xFF10B981) : AppTheme.secondaryText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dbConnected ? 'SQLite Bağlı' : 'Veritabanı Bekleniyor',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: dbConnected ? const Color(0xFF10B981) : AppTheme.secondaryText,
                      ),
                    ),
                    if (message.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Text(
                        '• $message',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.secondaryText,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.border),
            ),
            child: Text(
              version,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.secondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Profit Card for financial metrics
class _ProfitCard extends StatelessWidget {
  final String title;
  final String value;
  final String currency;
  final IconData icon;
  final Color color;

  const _ProfitCard({
    required this.title,
    required this.value,
    required this.currency,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return LinearContainer(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.bodySmall),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryText,
                      ),
                    ),
                    if (currency.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text(
                        currency,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.secondaryText,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Order Profit Tile for top profitable orders list
class _OrderProfitTile extends StatelessWidget {
  final rust_models.OrderProfitInfo order;

  const _OrderProfitTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final isProfit = order.profit >= 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // Order info
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.orderNumber,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  order.shipName,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          // Revenue
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Gelir',
                  style: GoogleFonts.inter(fontSize: 10, color: AppTheme.secondaryText),
                ),
                Text(
                  '${order.totalRevenue.toStringAsFixed(2)} ${order.currency}',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Profit
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Kar',
                  style: GoogleFonts.inter(fontSize: 10, color: AppTheme.secondaryText),
                ),
                Text(
                  '${isProfit ? '+' : ''}${order.profit.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isProfit ? AppTheme.success : AppTheme.error,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Margin badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (order.marginPercent >= 20 
                  ? AppTheme.success 
                  : order.marginPercent >= 10 
                      ? AppTheme.warning 
                      : AppTheme.error).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '%${order.marginPercent.toStringAsFixed(1)}',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: order.marginPercent >= 20 
                    ? AppTheme.success 
                    : order.marginPercent >= 10 
                        ? AppTheme.warning 
                        : AppTheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick Action Button
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? AppTheme.accent;
    return Material(
      color: AppTheme.background,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color?.withOpacity(0.3) ?? AppTheme.border),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryText,
                ),
              ),
              const Spacer(),
              Icon(Icons.chevron_right, size: 18, color: AppTheme.secondaryText),
            ],
          ),
        ),
      ),
    );
  }
}

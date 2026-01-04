import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/linear_components.dart';
import '../../../../src/rust/api.dart' as rust_api;

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _rustVersion = 'Yükleniyor...';
  String _greetMessage = '';

  @override
  void initState() {
    super.initState();
    _testRustBridge();
  }

  Future<void> _testRustBridge() async {
    try {
      final version = await rust_api.getVersion();
      final greeting = await rust_api.greet(name: 'SSMS Kullanıcısı');
      setState(() {
        _rustVersion = version;
        _greetMessage = greeting;
      });
    } catch (e) {
      setState(() {
        _rustVersion = 'Hata: $e';
        _greetMessage = '';
      });
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
            onPressed: _testRustBridge,
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
            ),
            const SizedBox(height: 16),
            // Summary Cards Row
            Row(
              children: [
                Expanded(child: _SummaryCard(
                  title: 'Toplam Sipariş',
                  value: '0',
                  icon: Icons.shopping_cart_outlined,
                  color: AppTheme.accent,
                )),
                const SizedBox(width: 16),
                Expanded(child: _SummaryCard(
                  title: 'Bekleyen Sipariş',
                  value: '0',
                  icon: Icons.hourglass_empty_outlined,
                  color: const Color(0xFFF59E0B),
                )),
                const SizedBox(width: 16),
                Expanded(child: _SummaryCard(
                  title: 'Teslim Edilen',
                  value: '0',
                  icon: Icons.check_circle_outline,
                  color: const Color(0xFF10B981),
                )),
                const SizedBox(width: 16),
                Expanded(child: _SummaryCard(
                  title: 'Toplam Gemi',
                  value: '0',
                  icon: Icons.directions_boat_outlined,
                  color: const Color(0xFF0EA5E9),
                )),
              ],
            ),
            const SizedBox(height: 24),
            // Recent Orders Section
            Expanded(
              child: LinearContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Son Siparişler',
                      style: AppTheme.headingMedium,
                    ),
                    const SizedBox(height: 16),
                    const Expanded(
                      child: EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'Henüz sipariş bulunmuyor',
                        subtitle: 'Yeni bir sipariş oluşturarak başlayın',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

  const _FRBStatusBanner({
    required this.version,
    required this.message,
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
                if (message.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.secondaryText,
                    ),
                  ),
                ],
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

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/linear_components.dart';

class SupplierListPage extends StatelessWidget {
  const SupplierListPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (Platform.isWindows || Platform.isMacOS) {
      return _buildDesktopView(context);
    } else {
      return _buildMobileView(context);
    }
  }

  /// Desktop View - DataGrid style
  Widget _buildDesktopView(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Text(
          'Tedarikçiler',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryText,
          ),
        ),
        actions: [
          // Search Field
          SizedBox(
            width: 300,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Tedarikçi ara...',
                  hintStyle: GoogleFonts.inter(color: AppTheme.secondaryText),
                  prefixIcon: const Icon(Icons.search, color: AppTheme.secondaryText, size: 20),
                  filled: true,
                  fillColor: AppTheme.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.accent),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                style: GoogleFonts.inter(fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.secondaryText),
            onPressed: () {},
            tooltip: 'Yenile',
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Navigate to create supplier page
              },
              icon: const Icon(Icons.add, size: 18),
              label: Text('Yeni Tedarikçi', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: LinearContainer(
          child: Column(
            children: [
              // Table Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppTheme.border),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text('Firma Adı', style: AppTheme.labelMedium)),
                    Expanded(flex: 2, child: Text('İletişim', style: AppTheme.labelMedium)),
                    Expanded(flex: 1, child: Text('Şehir', style: AppTheme.labelMedium)),
                    Expanded(flex: 1, child: Text('Ülke', style: AppTheme.labelMedium)),
                    const SizedBox(width: 80, child: Text('İşlem', style: TextStyle(fontWeight: FontWeight.w600))),
                  ],
                ),
              ),
              // Empty State
              const Expanded(
                child: EmptyState(
                  icon: Icons.business_outlined,
                  title: 'Henüz tedarikçi bulunmuyor',
                  subtitle: 'Yeni bir tedarikçi ekleyerek başlayın',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Mobile View - ListView with cards
  Widget _buildMobileView(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Text(
          'Tedarikçiler',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryText,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppTheme.secondaryText),
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to create supplier page
        },
        backgroundColor: AppTheme.accent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: const EmptyState(
        icon: Icons.business_outlined,
        title: 'Henüz tedarikçi bulunmuyor',
        subtitle: 'Yeni bir tedarikçi ekleyerek başlayın',
      ),
    );
  }
}

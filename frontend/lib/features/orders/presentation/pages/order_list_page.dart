import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/linear_components.dart';
import '../../domain/models/order.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  OrderStatus? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    if (Platform.isWindows || Platform.isMacOS) {
      return _buildDesktopView(context);
    } else {
      return _buildMobileView(context);
    }
  }

  /// Desktop View - DataGrid with filters
  Widget _buildDesktopView(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Text(
          'Siparişler',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryText,
          ),
        ),
        actions: [
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
                // TODO: Navigate to create order page
              },
              icon: const Icon(Icons.add, size: 18),
              label: Text('Yeni Sipariş', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Filter Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterPill(
                    label: 'Tümü',
                    isSelected: _selectedStatus == null,
                    onTap: () => setState(() => _selectedStatus = null),
                  ),
                  const SizedBox(width: 8),
                  ...OrderStatus.values.map((status) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _FilterPill(
                        label: status.displayName,
                        isSelected: _selectedStatus == status,
                        onTap: () => setState(() => _selectedStatus = status),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Orders Table
            Expanded(
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
                          Expanded(flex: 1, child: Text('Sipariş No', style: AppTheme.labelMedium)),
                          Expanded(flex: 2, child: Text('Gemi', style: AppTheme.labelMedium)),
                          Expanded(flex: 1, child: Text('Durum', style: AppTheme.labelMedium)),
                          Expanded(flex: 1, child: Text('Tarih', style: AppTheme.labelMedium)),
                          Expanded(flex: 1, child: Text('Toplam', style: AppTheme.labelMedium)),
                          const SizedBox(width: 100, child: Text('İşlem', style: TextStyle(fontWeight: FontWeight.w600))),
                        ],
                      ),
                    ),
                    // Empty State
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

  /// Mobile View - ListView with cards
  Widget _buildMobileView(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Text(
          'Siparişler',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryText,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppTheme.secondaryText),
            onPressed: () {
              _showMobileFilterSheet(context);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to create order page
        },
        backgroundColor: AppTheme.accent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Status Filter Chips - Horizontal scroll
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _MobileFilterChip(
                  label: 'Tümü',
                  isSelected: _selectedStatus == null,
                  onTap: () => setState(() => _selectedStatus = null),
                ),
                ...OrderStatus.values.map((status) {
                  return _MobileFilterChip(
                    label: status.displayName,
                    isSelected: _selectedStatus == status,
                    onTap: () => setState(() => _selectedStatus = status),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Orders List
          const Expanded(
            child: EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Henüz sipariş bulunmuyor',
              subtitle: 'Yeni bir sipariş oluşturarak başlayın',
            ),
          ),
        ],
      ),
    );
  }

  void _showMobileFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Durum Filtresi', style: AppTheme.headingMedium),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MobileFilterChip(
                      label: 'Tümü',
                      isSelected: _selectedStatus == null,
                      onTap: () {
                        setState(() => _selectedStatus = null);
                        Navigator.pop(context);
                      },
                    ),
                    ...OrderStatus.values.map((status) {
                      return _MobileFilterChip(
                        label: status.displayName,
                        isSelected: _selectedStatus == status,
                        onTap: () {
                          setState(() => _selectedStatus = status);
                          Navigator.pop(context);
                        },
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Desktop Filter Pill with Linear Style
class _FilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppTheme.accent : AppTheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppTheme.accent : AppTheme.border,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : AppTheme.secondaryText,
            ),
          ),
        ),
      ),
    );
  }
}

/// Mobile Filter Chip
class _MobileFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _MobileFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: isSelected ? Colors.white : AppTheme.secondaryText,
          ),
        ),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: AppTheme.accent,
        checkmarkColor: Colors.white,
        backgroundColor: AppTheme.surface,
        side: BorderSide(color: isSelected ? AppTheme.accent : AppTheme.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

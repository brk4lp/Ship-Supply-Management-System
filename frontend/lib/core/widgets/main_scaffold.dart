import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Platform-adaptive main scaffold
/// Windows: Left Navigation Rail
/// iOS: Bottom Navigation Bar
class MainScaffold extends StatefulWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  final List<_NavItem> _navItems = const [
    _NavItem(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      label: 'Ana Sayfa',
      path: '/dashboard',
    ),
    _NavItem(
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
      label: 'Takvim',
      path: '/calendar',
    ),
    _NavItem(
      icon: Icons.shopping_cart_outlined,
      selectedIcon: Icons.shopping_cart,
      label: 'Siparişler',
      path: '/orders',
    ),
    _NavItem(
      icon: Icons.directions_boat_outlined,
      selectedIcon: Icons.directions_boat,
      label: 'Gemiler',
      path: '/ships',
    ),
    _NavItem(
      icon: Icons.business_outlined,
      selectedIcon: Icons.business,
      label: 'Tedarikçiler',
      path: '/suppliers',
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSelectedIndex();
  }

  void _updateSelectedIndex() {
    final location = GoRouterState.of(context).uri.path;
    final index = _navItems.indexWhere((item) => location.startsWith(item.path));
    if (index != -1 && index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _onDestinationSelected(int index) {
    if (index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });
      context.go(_navItems[index].path);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Platform-adaptive navigation
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return _buildDesktopScaffold(context);
    } else {
      return _buildMobileScaffold(context);
    }
  }

  /// Desktop Layout: Left Navigation Rail + Content Area
  Widget _buildDesktopScaffold(BuildContext context) {
    final isExtended = MediaQuery.of(context).size.width > 1200;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Row(
        children: [
          // Left Navigation Rail with Linear Style
          Container(
            width: isExtended ? 220 : 80,
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(
                right: BorderSide(color: AppTheme.border, width: 1),
              ),
            ),
            child: Column(
              children: [
                // Logo Header
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppTheme.border, width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: isExtended 
                        ? MainAxisAlignment.start 
                        : MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.brandColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.anchor,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                      if (isExtended) ...[
                        const SizedBox(width: 12),
                        Text(
                          'SSMS',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.brandColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Navigation Items
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _navItems.length,
                    itemBuilder: (context, index) {
                      final item = _navItems[index];
                      final isSelected = index == _selectedIndex;
                      return _DesktopNavItem(
                        icon: isSelected ? item.selectedIcon : item.icon,
                        label: item.label,
                        isSelected: isSelected,
                        isExtended: isExtended,
                        onTap: () => _onDestinationSelected(index),
                      );
                    },
                  ),
                ),
                // Bottom User Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppTheme.border, width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: isExtended 
                        ? MainAxisAlignment.start 
                        : MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          size: 20,
                          color: AppTheme.accent,
                        ),
                      ),
                      if (isExtended) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kullanıcı',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.primaryText,
                                ),
                              ),
                              Text(
                                'Admin',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppTheme.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Main Content Area
          Expanded(
            child: widget.child,
          ),
        ],
      ),
    );
  }

  /// Mobile Layout: Content Area + Bottom Navigation Bar
  Widget _buildMobileScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(
            top: BorderSide(color: AppTheme.border, width: 1),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_navItems.length, (index) {
                final item = _navItems[index];
                final isSelected = index == _selectedIndex;
                return _MobileNavItem(
                  icon: isSelected ? item.selectedIcon : item.icon,
                  label: item.label,
                  isSelected: isSelected,
                  onTap: () => _onDestinationSelected(index),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

/// Desktop Navigation Item with Linear Style
class _DesktopNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isExtended;
  final VoidCallback onTap;

  const _DesktopNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isExtended,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isSelected ? AppTheme.accent.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            height: 44,
            padding: EdgeInsets.symmetric(
              horizontal: isExtended ? 12 : 0,
            ),
            child: Row(
              mainAxisAlignment: isExtended 
                  ? MainAxisAlignment.start 
                  : MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? AppTheme.accent : AppTheme.secondaryText,
                ),
                if (isExtended) ...[
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? AppTheme.accent : AppTheme.secondaryText,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mobile Navigation Item with Linear Style
class _MobileNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _MobileNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? AppTheme.accent : AppTheme.secondaryText,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppTheme.accent : AppTheme.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String path;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.path,
  });
}

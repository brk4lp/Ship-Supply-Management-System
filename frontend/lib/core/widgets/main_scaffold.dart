import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Platform-adaptive main scaffold
/// Windows: Left Navigation Rail with Categorized Navigation
/// iOS: Bottom Navigation Bar
class MainScaffold extends StatefulWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  String _selectedPath = '/dashboard';
  
  // Kategorilerin açık/kapalı durumları
  final Map<String, bool> _expandedCategories = {
    'main': true,
    'warehouse': true,
    'maritime': true,
    'operations': true,
  };

  // Kategorize edilmiş navigasyon yapısı
  final List<_NavCategory> _navCategories = const [
    // Ana Menü - Kategori yok, direkt gösterilecek
    _NavCategory(
      id: 'main',
      title: '',
      icon: Icons.home,
      isMainSection: true,
      items: [
        _NavItem(
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
          label: 'Ana Sayfa',
          path: '/dashboard',
        ),
      ],
    ),
    // 📦 Depo Yönetimi
    _NavCategory(
      id: 'warehouse',
      title: 'Depo Yönetimi',
      icon: Icons.inventory_2,
      isMainSection: false,
      items: [
        _NavItem(
          icon: Icons.category_outlined,
          selectedIcon: Icons.category,
          label: 'Ürün Kataloğu',
          path: '/supply-items',
        ),
        _NavItem(
          icon: Icons.business_outlined,
          selectedIcon: Icons.business,
          label: 'Tedarikçiler',
          path: '/suppliers',
        ),
        _NavItem(
          icon: Icons.warehouse_outlined,
          selectedIcon: Icons.warehouse,
          label: 'Stok Takibi',
          path: '/stock',
        ),
      ],
    ),
    // ⚓ Denizcilik
    _NavCategory(
      id: 'maritime',
      title: 'Denizcilik',
      icon: Icons.anchor,
      isMainSection: false,
      items: [
        _NavItem(
          icon: Icons.directions_boat_outlined,
          selectedIcon: Icons.directions_boat,
          label: 'Gemiler',
          path: '/ships',
        ),
        // Gelecekte eklenecek:
        // _NavItem(icon: Icons.location_on_outlined, selectedIcon: Icons.location_on, label: 'Limanlar', path: '/ports'),
        // _NavItem(icon: Icons.schedule_outlined, selectedIcon: Icons.schedule, label: 'Ziyaretler', path: '/visits'),
      ],
    ),
    // 📝 Operasyon
    _NavCategory(
      id: 'operations',
      title: 'Operasyon',
      icon: Icons.assignment,
      isMainSection: false,
      items: [
        _NavItem(
          icon: Icons.shopping_cart_outlined,
          selectedIcon: Icons.shopping_cart,
          label: 'Siparişler',
          path: '/orders',
        ),
        _NavItem(
          icon: Icons.calendar_month_outlined,
          selectedIcon: Icons.calendar_month,
          label: 'Takvim',
          path: '/calendar',
        ),
        // Gelecekte eklenecek:
        // _NavItem(icon: Icons.local_shipping_outlined, selectedIcon: Icons.local_shipping, label: 'Teslimatlar', path: '/deliveries'),
      ],
    ),
  ];

  // Mobil navigasyon için flat liste (önemli sayfalar)
  final List<_NavItem> _mobileNavItems = const [
    _NavItem(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      label: 'Ana Sayfa',
      path: '/dashboard',
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
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
      label: 'Takvim',
      path: '/calendar',
    ),
    _NavItem(
      icon: Icons.more_horiz_outlined,
      selectedIcon: Icons.more_horiz,
      label: 'Daha Fazla',
      path: '/more',
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSelectedPath();
  }

  void _updateSelectedPath() {
    final location = GoRouterState.of(context).uri.path;
    if (location != _selectedPath) {
      setState(() {
        _selectedPath = location;
      });
    }
  }

  void _onDestinationSelected(String path) {
    if (path != _selectedPath) {
      setState(() {
        _selectedPath = path;
      });
      context.go(path);
    }
  }

  void _toggleCategory(String categoryId) {
    setState(() {
      _expandedCategories[categoryId] = !(_expandedCategories[categoryId] ?? true);
    });
  }

  int _getMobileSelectedIndex() {
    final index = _mobileNavItems.indexWhere((item) => _selectedPath.startsWith(item.path));
    // Eğer bulunamadıysa "Daha Fazla" seçili göster
    return index != -1 ? index : _mobileNavItems.length - 1;
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
                // Categorized Navigation Items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: _navCategories.map((category) {
                      if (category.isMainSection) {
                        // Ana Sayfa - direkt göster
                        return Column(
                          children: category.items.map((item) {
                            final isSelected = _selectedPath.startsWith(item.path);
                            return _DesktopNavItem(
                              icon: isSelected ? item.selectedIcon : item.icon,
                              label: item.label,
                              isSelected: isSelected,
                              isExtended: isExtended,
                              onTap: () => _onDestinationSelected(item.path),
                            );
                          }).toList(),
                        );
                      } else {
                        // Kategorili grup
                        final isExpanded = _expandedCategories[category.id] ?? true;
                        final hasSelectedItem = category.items.any(
                          (item) => _selectedPath.startsWith(item.path),
                        );
                        
                        return _CategorySection(
                          title: category.title,
                          icon: category.icon,
                          isExpanded: isExpanded,
                          isExtended: isExtended,
                          hasSelectedItem: hasSelectedItem,
                          onToggle: () => _toggleCategory(category.id),
                          children: category.items.map((item) {
                            final isSelected = _selectedPath.startsWith(item.path);
                            return _DesktopNavItem(
                              icon: isSelected ? item.selectedIcon : item.icon,
                              label: item.label,
                              isSelected: isSelected,
                              isExtended: isExtended,
                              onTap: () => _onDestinationSelected(item.path),
                              isNested: true,
                            );
                          }).toList(),
                        );
                      }
                    }).toList(),
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
              children: List.generate(_mobileNavItems.length, (index) {
                final item = _mobileNavItems[index];
                final isSelected = index == _getMobileSelectedIndex();
                return _MobileNavItem(
                  icon: isSelected ? item.selectedIcon : item.icon,
                  label: item.label,
                  isSelected: isSelected,
                  onTap: () {
                    if (item.path == '/more') {
                      _showMoreMenu(context);
                    } else {
                      _onDestinationSelected(item.path);
                    }
                  },
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                ..._navCategories.expand((category) {
                  return category.items.where((item) {
                    // Mobil nav bar'da olmayanları göster
                    return !_mobileNavItems.any((m) => m.path == item.path && m.path != '/more');
                  }).map((item) {
                    return ListTile(
                      leading: Icon(
                        item.icon,
                        color: _selectedPath.startsWith(item.path) 
                            ? AppTheme.accent 
                            : AppTheme.secondaryText,
                      ),
                      title: Text(
                        item.label,
                        style: GoogleFonts.inter(
                          fontWeight: _selectedPath.startsWith(item.path) 
                              ? FontWeight.w600 
                              : FontWeight.w500,
                          color: _selectedPath.startsWith(item.path) 
                              ? AppTheme.accent 
                              : AppTheme.primaryText,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _onDestinationSelected(item.path);
                      },
                    );
                  });
                }),
              ],
            ),
          ),
        );
      },
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
  final bool isNested;

  const _DesktopNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isExtended,
    required this.onTap,
    this.isNested = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 4,
        left: isNested && isExtended ? 8 : 0,
      ),
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
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? AppTheme.accent : AppTheme.secondaryText,
                      ),
                      overflow: TextOverflow.ellipsis,
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

/// Kategori Başlığı ve Açılır/Kapanır Grup
class _CategorySection extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isExpanded;
  final bool isExtended;
  final bool hasSelectedItem;
  final VoidCallback onToggle;
  final List<Widget> children;

  const _CategorySection({
    required this.title,
    required this.icon,
    required this.isExpanded,
    required this.isExtended,
    required this.hasSelectedItem,
    required this.onToggle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        // Kategori Başlığı
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: isExtended ? onToggle : null,
            child: Container(
              height: 36,
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
                    size: 16,
                    color: hasSelectedItem 
                        ? AppTheme.accent.withOpacity(0.8) 
                        : AppTheme.secondaryText.withOpacity(0.6),
                  ),
                  if (isExtended) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: hasSelectedItem 
                              ? AppTheme.accent.withOpacity(0.8) 
                              : AppTheme.secondaryText.withOpacity(0.6),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0 : -0.25,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.expand_more,
                        size: 18,
                        color: AppTheme.secondaryText.withOpacity(0.5),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        // Animasyonlu Alt Öğeler
        AnimatedCrossFade(
          firstChild: Column(children: children),
          secondChild: const SizedBox.shrink(),
          crossFadeState: isExpanded || !isExtended
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 200),
          sizeCurve: Curves.easeInOut,
        ),
      ],
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

/// Navigasyon Kategorisi
class _NavCategory {
  final String id;
  final String title;
  final IconData icon;
  final bool isMainSection;
  final List<_NavItem> items;

  const _NavCategory({
    required this.id,
    required this.title,
    required this.icon,
    required this.isMainSection,
    required this.items,
  });
}

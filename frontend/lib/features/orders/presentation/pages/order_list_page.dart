import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pluto_grid/pluto_grid.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/linear_components.dart';
import '../../../../src/rust/api.dart' as rust_api;
import '../../../../src/rust/models.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  List<Order> _orders = [];
  List<Ship> _ships = [];
  List<ShipVisit> _visits = [];
  bool _isLoading = true;
  String? _error;
  OrderStatus? _selectedStatus;
  Key _gridKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        rust_api.getAllOrders(statusFilter: _selectedStatus),
        rust_api.getAllShips(),
        rust_api.getUpcomingShipVisits(),
      ]);
      
      setState(() {
        _orders = results[0] as List<Order>;
        _ships = results[1] as List<Ship>;
        _visits = results[2] as List<ShipVisit>;
        _isLoading = false;
        _gridKey = UniqueKey();
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
    if (Platform.isWindows || Platform.isMacOS) {
      return _buildDesktopView(context);
    } else {
      return _buildMobileView(context);
    }
  }

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
            onPressed: _loadData,
            tooltip: 'Yenile',
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () => _showOrderDialog(),
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
                    onTap: () {
                      setState(() => _selectedStatus = null);
                      _loadData();
                    },
                  ),
                  const SizedBox(width: 8),
                  ..._buildFilterPills(),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Content
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFilterPills() {
    final statusDisplayNames = {
      OrderStatus.new_: 'Yeni',
      OrderStatus.quoted: 'Fiyat Verildi',
      OrderStatus.agreed: 'Onaylandı',
      OrderStatus.waitingGoods: 'Mal Bekleniyor',
      OrderStatus.prepared: 'Hazırlandı',
      OrderStatus.onWay: 'Yolda',
      OrderStatus.delivered: 'Teslim Edildi',
      OrderStatus.invoiced: 'Faturalandı',
      OrderStatus.cancelled: 'İptal',
    };

    return OrderStatus.values.map((status) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: _FilterPill(
          label: statusDisplayNames[status] ?? status.name,
          isSelected: _selectedStatus == status,
          onTap: () {
            setState(() => _selectedStatus = status);
            _loadData();
          },
        ),
      );
    }).toList();
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text('Hata: $_error', style: AppTheme.bodyMedium),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: const Text('Tekrar Dene')),
          ],
        ),
      );
    }

    if (_orders.isEmpty) {
      return const EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'Henüz sipariş bulunmuyor',
        subtitle: 'Yeni bir sipariş oluşturarak başlayın',
      );
    }

    return LinearContainer(
      padding: EdgeInsets.zero,
      child: PlutoGrid(
        key: _gridKey,
        columns: _buildColumns(),
        rows: _buildRows(),
        onLoaded: (PlutoGridOnLoadedEvent event) {
          event.stateManager.setShowColumnFilter(true);
        },
        onRowDoubleTap: (PlutoGridOnRowDoubleTapEvent event) {
          final orderId = event.row.cells['id']?.value as int?;
          if (orderId != null) {
            context.go('/orders/$orderId');
          }
        },
        configuration: PlutoGridConfiguration(
          style: PlutoGridStyleConfig(
            gridBackgroundColor: AppTheme.surface,
            rowColor: AppTheme.surface,
            activatedColor: AppTheme.accent.withOpacity(0.1),
            activatedBorderColor: AppTheme.accent,
            gridBorderColor: AppTheme.border,
            borderColor: AppTheme.border,
            cellTextStyle: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.primaryText,
            ),
            columnTextStyle: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryText,
            ),
          ),
          columnSize: const PlutoGridColumnSizeConfig(
            autoSizeMode: PlutoAutoSizeMode.scale,
          ),
        ),
      ),
    );
  }

  List<PlutoColumn> _buildColumns() {
    return [
      PlutoColumn(
        title: 'Sipariş No',
        field: 'orderNumber',
        type: PlutoColumnType.text(),
        width: 140,
      ),
      PlutoColumn(
        title: 'Gemi',
        field: 'shipName',
        type: PlutoColumnType.text(),
        width: 160,
      ),
      PlutoColumn(
        title: 'Ziyaret',
        field: 'visitInfo',
        type: PlutoColumnType.text(),
        width: 200,
      ),
      PlutoColumn(
        title: 'Durum',
        field: 'status',
        type: PlutoColumnType.text(),
        width: 130,
        renderer: (rendererContext) {
          final status = rendererContext.cell.value as String;
          return _StatusBadge(status: status);
        },
      ),
      PlutoColumn(
        title: 'Para Birimi',
        field: 'currency',
        type: PlutoColumnType.text(),
        width: 90,
      ),
      PlutoColumn(
        title: 'Oluşturulma',
        field: 'createdAt',
        type: PlutoColumnType.text(),
        width: 110,
      ),
      PlutoColumn(
        title: 'İşlemler',
        field: 'actions',
        type: PlutoColumnType.text(),
        width: 150,
        enableSorting: false,
        enableFilterMenuItem: false,
        renderer: (rendererContext) {
          final orderId = rendererContext.row.cells['id']?.value as int;
          final order = _orders.firstWhere((o) => o.id == orderId);
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility_outlined, size: 18),
                onPressed: () => context.go('/orders/$orderId'),
                tooltip: 'Detay & Ürün Ekle',
                color: AppTheme.secondaryText,
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward, size: 18),
                onPressed: () => _showStatusChangeDialog(order),
                tooltip: 'Durum İlerlet',
                color: AppTheme.accent,
              ),
              IconButton(
                icon: const Icon(Icons.cancel_outlined, size: 18),
                onPressed: () => _confirmCancel(order),
                tooltip: 'İptal Et',
                color: Colors.red.shade400,
              ),
            ],
          );
        },
      ),
    ];
  }

  List<PlutoRow> _buildRows() {
    final statusDisplayNames = {
      OrderStatus.new_: 'Yeni',
      OrderStatus.quoted: 'Fiyat Verildi',
      OrderStatus.agreed: 'Onaylandı',
      OrderStatus.waitingGoods: 'Mal Bekleniyor',
      OrderStatus.prepared: 'Hazırlandı',
      OrderStatus.onWay: 'Yolda',
      OrderStatus.delivered: 'Teslim Edildi',
      OrderStatus.invoiced: 'Faturalandı',
      OrderStatus.cancelled: 'İptal',
    };

    return _orders.map((order) {
      return PlutoRow(cells: {
        'id': PlutoCell(value: order.id),
        'orderNumber': PlutoCell(value: order.orderNumber),
        'shipName': PlutoCell(value: order.shipName ?? '-'),
        'visitInfo': PlutoCell(value: order.shipVisitInfo ?? '-'),
        'status': PlutoCell(value: statusDisplayNames[order.status] ?? order.status.name),
        'currency': PlutoCell(value: order.currency),
        'createdAt': PlutoCell(value: order.createdAt.substring(0, 10)),
        'actions': PlutoCell(value: ''),
      });
    }).toList();
  }

  void _showOrderDialog() {
    if (_ships.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Önce bir gemi eklemelisiniz!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Ship? selectedShip;
    ShipVisit? selectedVisit;
    final deliveryPortController = TextEditingController();
    final notesController = TextEditingController();
    String selectedCurrency = 'USD';

    // Filter visits for selected ship
    List<ShipVisit> getVisitsForShip(Ship? ship) {
      if (ship == null) return [];
      return _visits.where((v) => v.shipId == ship.id).toList();
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final visitsForShip = getVisitsForShip(selectedShip);
          
          return AlertDialog(
            backgroundColor: AppTheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Text('Yeni Sipariş', style: AppTheme.headingMedium),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 20, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Gemi ziyareti seçerseniz sipariş o ziyarete bağlanır ve takvimde görünür.',
                              style: GoogleFonts.inter(fontSize: 12, color: Colors.blue.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Ship Dropdown
                    Text('Gemi *', style: AppTheme.labelMedium),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Ship>(
                      value: selectedShip,
                      decoration: InputDecoration(
                        hintText: 'Gemi seçin',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      items: _ships.map((ship) {
                        return DropdownMenuItem(
                          value: ship,
                          child: Text('${ship.name} (${ship.imoNumber})'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedShip = value;
                          selectedVisit = null; // Reset visit when ship changes
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Ship Visit Dropdown (only if ship is selected and has visits)
                    if (selectedShip != null) ...[
                      Text('Gemi Ziyareti (Opsiyonel)', style: AppTheme.labelMedium),
                      const SizedBox(height: 8),
                      if (visitsForShip.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.event_busy, size: 18, color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Text(
                                'Bu gemi için planlanmış ziyaret yok',
                                style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        )
                      else
                        DropdownButtonFormField<ShipVisit>(
                          value: selectedVisit,
                          decoration: InputDecoration(
                            hintText: 'Ziyaret seçin (opsiyonel)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          ),
                          items: [
                            const DropdownMenuItem<ShipVisit>(
                              value: null,
                              child: Text('Ziyaret seçilmedi'),
                            ),
                            ...visitsForShip.map((visit) {
                              final etaDate = DateTime.parse(visit.eta);
                              final portName = visit.portName ?? 'Bilinmeyen Liman';
                              final dateStr = '${etaDate.day.toString().padLeft(2, '0')}.${etaDate.month.toString().padLeft(2, '0')}.${etaDate.year}';
                              return DropdownMenuItem(
                                value: visit,
                                child: Text('$portName - $dateStr'),
                              );
                            }),
                          ],
                          onChanged: (value) => setDialogState(() => selectedVisit = value),
                        ),
                      const SizedBox(height: 16),
                    ],

                    // Delivery Port (auto-fill if visit selected)
                    Text('Teslim Limanı', style: AppTheme.labelMedium),
                    const SizedBox(height: 8),
                    TextField(
                      controller: deliveryPortController,
                      decoration: InputDecoration(
                        hintText: selectedVisit != null 
                          ? selectedVisit!.portName ?? 'Liman bilgisi yok'
                          : 'Örn: İstanbul Limanı',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Currency
                    Text('Para Birimi *', style: AppTheme.labelMedium),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedCurrency,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      items: ['USD', 'EUR', 'TRY', 'GBP'].map((currency) {
                        return DropdownMenuItem(value: currency, child: Text(currency));
                      }).toList(),
                      onChanged: (value) => setDialogState(() => selectedCurrency = value!),
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    Text('Notlar', style: AppTheme.labelMedium),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Sipariş notları...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('İptal', style: GoogleFonts.inter(color: AppTheme.secondaryText)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selectedShip == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lütfen bir gemi seçin'), backgroundColor: Colors.orange),
                    );
                    return;
                  }

                  try {
                    // Use visit port if delivery port is empty and visit is selected
                    String? deliveryPort = deliveryPortController.text.isNotEmpty 
                      ? deliveryPortController.text 
                      : selectedVisit?.portName;

                    final request = CreateOrderRequest(
                      shipId: selectedShip!.id,
                      shipVisitId: selectedVisit?.id,
                      deliveryPort: deliveryPort,
                      notes: notesController.text.isNotEmpty ? notesController.text : null,
                      currency: selectedCurrency,
                    );

                    final newOrder = await rust_api.createOrder(order: request);
                    if (mounted) {
                      Navigator.pop(context);
                      _loadData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Sipariş ${newOrder.orderNumber} oluşturuldu. Şimdi ürün ekleyebilirsiniz.'),
                          backgroundColor: Colors.green,
                          action: SnackBarAction(
                            label: 'Ürün Ekle',
                            textColor: Colors.white,
                            onPressed: () => context.go('/orders/${newOrder.id}'),
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.white,
                ),
                child: Text('Oluştur & Ürün Ekle', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showStatusChangeDialog(Order order) {
    final statusDisplayNames = {
      OrderStatus.new_: 'Yeni',
      OrderStatus.quoted: 'Fiyat Verildi',
      OrderStatus.agreed: 'Onaylandı',
      OrderStatus.waitingGoods: 'Mal Bekleniyor',
      OrderStatus.prepared: 'Hazırlandı',
      OrderStatus.onWay: 'Yolda',
      OrderStatus.delivered: 'Teslim Edildi',
      OrderStatus.invoiced: 'Faturalandı',
      OrderStatus.cancelled: 'İptal',
    };

    // Get next status based on current
    OrderStatus? nextStatus;
    switch (order.status) {
      case OrderStatus.new_:
        nextStatus = OrderStatus.quoted;
        break;
      case OrderStatus.quoted:
        nextStatus = OrderStatus.agreed;
        break;
      case OrderStatus.agreed:
        nextStatus = OrderStatus.waitingGoods;
        break;
      case OrderStatus.waitingGoods:
        nextStatus = OrderStatus.prepared;
        break;
      case OrderStatus.prepared:
        nextStatus = OrderStatus.onWay;
        break;
      case OrderStatus.onWay:
        nextStatus = OrderStatus.delivered;
        break;
      case OrderStatus.delivered:
        nextStatus = OrderStatus.invoiced;
        break;
      default:
        nextStatus = null;
    }

    if (nextStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu sipariş için sonraki durum yok'), backgroundColor: Colors.orange),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Durum Değiştir', style: AppTheme.headingMedium),
        content: Text(
          'Sipariş ${order.orderNumber} durumu "${statusDisplayNames[order.status]}" → "${statusDisplayNames[nextStatus]}" olarak değiştirilsin mi?',
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: GoogleFonts.inter(color: AppTheme.secondaryText)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await rust_api.updateOrderStatus(id: order.id, newStatus: nextStatus!);
                if (mounted) {
                  Navigator.pop(context);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Durum "${statusDisplayNames[nextStatus]}" olarak güncellendi'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
            ),
            child: Text('Onayla', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  void _confirmCancel(Order order) {
    if (order.status == OrderStatus.cancelled || order.status == OrderStatus.invoiced) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu sipariş iptal edilemez'), backgroundColor: Colors.orange),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Siparişi İptal Et', style: AppTheme.headingMedium),
        content: Text(
          'Sipariş "${order.orderNumber}" iptal edilecek. Bu işlem geri alınamaz!',
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Vazgeç', style: GoogleFonts.inter(color: AppTheme.secondaryText)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await rust_api.updateOrderStatus(id: order.id, newStatus: OrderStatus.cancelled);
                if (mounted) {
                  Navigator.pop(context);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sipariş iptal edildi'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('İptal Et', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

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
            icon: const Icon(Icons.refresh, color: AppTheme.secondaryText),
            onPressed: _loadData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showOrderDialog(),
        backgroundColor: AppTheme.accent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _buildMobileContent(),
    );
  }

  Widget _buildMobileContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text('Hata: $_error', style: AppTheme.bodyMedium),
          ],
        ),
      );
    }

    if (_orders.isEmpty) {
      return const EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'Henüz sipariş bulunmuyor',
        subtitle: 'Yeni bir sipariş oluşturarak başlayın',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            title: Text(order.orderNumber, style: AppTheme.labelMedium),
            subtitle: Text(order.shipName ?? '-'),
            trailing: _StatusBadge(status: _getStatusDisplayName(order.status)),
            onTap: () => context.go('/orders/${order.id}'),
          ),
        );
      },
    );
  }

  String _getStatusDisplayName(OrderStatus status) {
    final statusDisplayNames = {
      OrderStatus.new_: 'Yeni',
      OrderStatus.quoted: 'Fiyat Verildi',
      OrderStatus.agreed: 'Onaylandı',
      OrderStatus.waitingGoods: 'Mal Bekleniyor',
      OrderStatus.prepared: 'Hazırlandı',
      OrderStatus.onWay: 'Yolda',
      OrderStatus.delivered: 'Teslim Edildi',
      OrderStatus.invoiced: 'Faturalandı',
      OrderStatus.cancelled: 'İptal',
    };
    return statusDisplayNames[status] ?? status.name;
  }
}

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

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'Yeni':
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        break;
      case 'Fiyat Verildi':
        bgColor = Colors.purple.shade50;
        textColor = Colors.purple.shade700;
        break;
      case 'Onaylandı':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        break;
      case 'Mal Bekleniyor':
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        break;
      case 'Hazırlandı':
        bgColor = Colors.cyan.shade50;
        textColor = Colors.cyan.shade700;
        break;
      case 'Yolda':
        bgColor = Colors.indigo.shade50;
        textColor = Colors.indigo.shade700;
        break;
      case 'Teslim Edildi':
        bgColor = Colors.teal.shade50;
        textColor = Colors.teal.shade700;
        break;
      case 'Faturalandı':
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        break;
      case 'İptal':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        break;
      default:
        bgColor = Colors.grey.shade50;
        textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}

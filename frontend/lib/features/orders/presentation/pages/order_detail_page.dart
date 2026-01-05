import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pluto_grid/pluto_grid.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/linear_components.dart';
import '../../../../src/rust/api.dart' as rust_api;
import '../../../../src/rust/models.dart';

class OrderDetailPage extends StatefulWidget {
  final int orderId;

  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  Order? _order;
  List<OrderItem> _items = [];
  List<SupplyItem> _catalogItems = [];
  bool _isLoading = true;
  String? _error;
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
        rust_api.getAllOrders(),
        rust_api.getOrderItems(orderId: widget.orderId),
        rust_api.getAllSupplyItems(),
      ]);

      final orders = results[0] as List<Order>;
      final order = orders.firstWhere((o) => o.id == widget.orderId);

      setState(() {
        _order = order;
        _items = results[1] as List<OrderItem>;
        _catalogItems = results[2] as List<SupplyItem>;
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

  String _getStatusDisplayName(OrderStatus status) {
    final names = {
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
    return names[status] ?? status.name;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Sipariş #${widget.orderId}')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _order == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Sipariş #${widget.orderId}')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text('Hata: ${_error ?? "Sipariş bulunamadı"}'),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadData, child: const Text('Tekrar Dene')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Text(
          'Sipariş ${_order!.orderNumber}',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.primaryText),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.secondaryText),
            onPressed: _loadData,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Info Card
            _buildOrderInfoCard(),
            const SizedBox(height: 24),
            // Items Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Sipariş Kalemleri', style: AppTheme.headingMedium),
                ElevatedButton.icon(
                  onPressed: () => _showAddItemDialog(),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text('Ürün Ekle', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Items Grid
            Expanded(child: _buildItemsGrid()),
            // Totals
            const SizedBox(height: 16),
            _buildTotalsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderInfoCard() {
    return LinearContainer(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gemi', style: AppTheme.labelMedium.copyWith(color: AppTheme.secondaryText)),
                const SizedBox(height: 4),
                Text(_order!.shipName ?? '-', style: AppTheme.bodyMedium),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Durum', style: AppTheme.labelMedium.copyWith(color: AppTheme.secondaryText)),
                const SizedBox(height: 4),
                _StatusBadge(status: _getStatusDisplayName(_order!.status)),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Liman', style: AppTheme.labelMedium.copyWith(color: AppTheme.secondaryText)),
                const SizedBox(height: 4),
                Text(_order!.deliveryPort ?? '-', style: AppTheme.bodyMedium),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Para Birimi', style: AppTheme.labelMedium.copyWith(color: AppTheme.secondaryText)),
                const SizedBox(height: 4),
                Text(_order!.currency, style: AppTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsGrid() {
    if (_items.isEmpty) {
      return const LinearContainer(
        child: EmptyState(
          icon: Icons.inventory_2_outlined,
          title: 'Henüz ürün eklenmemiş',
          subtitle: 'Sipariş kalemleri eklemek için "Ürün Ekle" butonuna tıklayın',
        ),
      );
    }

    return LinearContainer(
      padding: EdgeInsets.zero,
      child: PlutoGrid(
        key: _gridKey,
        columns: _buildColumns(),
        rows: _buildRows(),
        configuration: PlutoGridConfiguration(
          style: PlutoGridStyleConfig(
            gridBackgroundColor: AppTheme.surface,
            rowColor: AppTheme.surface,
            activatedColor: AppTheme.accent.withOpacity(0.1),
            activatedBorderColor: AppTheme.accent,
            gridBorderColor: AppTheme.border,
            borderColor: AppTheme.border,
            cellTextStyle: GoogleFonts.inter(fontSize: 13, color: AppTheme.primaryText),
            columnTextStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryText),
          ),
          columnSize: const PlutoGridColumnSizeConfig(autoSizeMode: PlutoAutoSizeMode.scale),
        ),
      ),
    );
  }

  List<PlutoColumn> _buildColumns() {
    return [
      PlutoColumn(title: 'Ürün Adı', field: 'productName', type: PlutoColumnType.text(), width: 180),
      PlutoColumn(title: 'IMPA', field: 'impaCode', type: PlutoColumnType.text(), width: 100),
      PlutoColumn(title: 'Miktar', field: 'quantity', type: PlutoColumnType.number(), width: 80),
      PlutoColumn(title: 'Birim', field: 'unit', type: PlutoColumnType.text(), width: 60),
      PlutoColumn(title: 'Alış', field: 'buyingPrice', type: PlutoColumnType.number(), width: 100),
      PlutoColumn(title: 'Satış', field: 'sellingPrice', type: PlutoColumnType.number(), width: 100),
      PlutoColumn(
        title: 'Teslimat',
        field: 'deliveryType',
        type: PlutoColumnType.text(),
        width: 130,
        renderer: (ctx) {
          final type = ctx.cell.value as String;
          final isWarehouse = type == 'Depo Üzerinden';
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isWarehouse ? Colors.blue.shade50 : Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              type,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isWarehouse ? Colors.blue.shade700 : Colors.green.shade700,
              ),
            ),
          );
        },
      ),
      PlutoColumn(title: 'Gemiye Teslim', field: 'shipDeliveryDate', type: PlutoColumnType.text(), width: 110),
      PlutoColumn(
        title: 'İşlem',
        field: 'actions',
        type: PlutoColumnType.text(),
        width: 80,
        enableSorting: false,
        renderer: (ctx) {
          final itemId = ctx.row.cells['id']?.value as int;
          return IconButton(
            icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade400),
            onPressed: () => _deleteItem(itemId),
            tooltip: 'Sil',
          );
        },
      ),
    ];
  }

  List<PlutoRow> _buildRows() {
    return _items.map((item) {
      final deliveryTypeName = item.deliveryType == DeliveryType.viaWarehouse ? 'Depo Üzerinden' : 'Direkt Gemiye';
      return PlutoRow(cells: {
        'id': PlutoCell(value: item.id),
        'productName': PlutoCell(value: item.productName),
        'impaCode': PlutoCell(value: item.impaCode ?? '-'),
        'quantity': PlutoCell(value: item.quantity),
        'unit': PlutoCell(value: item.unit),
        'buyingPrice': PlutoCell(value: item.buyingPrice),
        'sellingPrice': PlutoCell(value: item.sellingPrice),
        'deliveryType': PlutoCell(value: deliveryTypeName),
        'shipDeliveryDate': PlutoCell(value: item.shipDeliveryDate ?? '-'),
        'actions': PlutoCell(value: ''),
      });
    }).toList();
  }

  Widget _buildTotalsCard() {
    double totalCost = 0;
    double totalRevenue = 0;
    for (final item in _items) {
      totalCost += item.buyingPrice * item.quantity;
      totalRevenue += item.sellingPrice * item.quantity;
    }
    final profit = totalRevenue - totalCost;
    final margin = totalRevenue > 0 ? (profit / totalRevenue) * 100 : 0;

    return LinearContainer(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _TotalItem(label: 'Toplam Maliyet', value: '${totalCost.toStringAsFixed(2)} ${_order!.currency}'),
          _TotalItem(label: 'Toplam Satış', value: '${totalRevenue.toStringAsFixed(2)} ${_order!.currency}'),
          _TotalItem(
            label: 'Kar',
            value: '${profit.toStringAsFixed(2)} ${_order!.currency}',
            valueColor: profit >= 0 ? Colors.green.shade700 : Colors.red.shade700,
          ),
          _TotalItem(label: 'Marj', value: '%${margin.toStringAsFixed(1)}'),
        ],
      ),
    );
  }

  void _showAddItemDialog() {
    SupplyItem? selectedCatalogItem;
    final productNameController = TextEditingController();
    final impaCodeController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final unitController = TextEditingController(text: 'Adet');
    final buyingPriceController = TextEditingController();
    final sellingPriceController = TextEditingController();
    DeliveryType selectedDeliveryType = DeliveryType.viaWarehouse;
    DateTime? warehouseDeliveryDate;
    DateTime? shipDeliveryDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppTheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Text('Ürün Ekle', style: AppTheme.headingMedium),
            content: SizedBox(
              width: 550,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Catalog Selection (Optional)
                    Text('Katalogdan Seç (Opsiyonel)', style: AppTheme.labelMedium),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<SupplyItem>(
                      value: selectedCatalogItem,
                      decoration: InputDecoration(
                        hintText: 'Katalogdan ürün seçin...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      items: _catalogItems.map((item) {
                        return DropdownMenuItem(
                          value: item,
                          child: Text('${item.name} (${item.impaCode ?? "IMPA Yok"})'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedCatalogItem = value;
                          if (value != null) {
                            productNameController.text = value.name;
                            impaCodeController.text = value.impaCode ?? '';
                            unitController.text = value.unit;
                            buyingPriceController.text = value.unitPrice.toString();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Product Name
                    Text('Ürün Adı *', style: AppTheme.labelMedium),
                    const SizedBox(height: 8),
                    TextField(
                      controller: productNameController,
                      decoration: InputDecoration(
                        hintText: 'Ürün adı girin',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // IMPA Code + Quantity + Unit in row
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('IMPA Kodu', style: AppTheme.labelMedium),
                              const SizedBox(height: 8),
                              TextField(
                                controller: impaCodeController,
                                decoration: InputDecoration(
                                  hintText: 'IMPA',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Miktar *', style: AppTheme.labelMedium),
                              const SizedBox(height: 8),
                              TextField(
                                controller: quantityController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: '1',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Birim *', style: AppTheme.labelMedium),
                              const SizedBox(height: 8),
                              TextField(
                                controller: unitController,
                                decoration: InputDecoration(
                                  hintText: 'Adet',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Buying Price + Selling Price
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Alış Fiyatı *', style: AppTheme.labelMedium),
                              const SizedBox(height: 8),
                              TextField(
                                controller: buyingPriceController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: '0.00',
                                  prefixText: '${_order!.currency} ',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Satış Fiyatı *', style: AppTheme.labelMedium),
                              const SizedBox(height: 8),
                              TextField(
                                controller: sellingPriceController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: '0.00',
                                  prefixText: '${_order!.currency} ',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Delivery Type
                    Text('Teslimat Tipi *', style: AppTheme.labelMedium),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<DeliveryType>(
                            title: Row(
                              children: [
                                Icon(Icons.warehouse_outlined, size: 18, color: Colors.blue.shade600),
                                const SizedBox(width: 8),
                                Text('Depo Üzerinden', style: GoogleFonts.inter(fontSize: 13)),
                              ],
                            ),
                            value: DeliveryType.viaWarehouse,
                            groupValue: selectedDeliveryType,
                            onChanged: (v) => setDialogState(() => selectedDeliveryType = v!),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<DeliveryType>(
                            title: Row(
                              children: [
                                Icon(Icons.directions_boat_outlined, size: 18, color: Colors.green.shade600),
                                const SizedBox(width: 8),
                                Text('Direkt Gemiye', style: GoogleFonts.inter(fontSize: 13)),
                              ],
                            ),
                            value: DeliveryType.directToShip,
                            groupValue: selectedDeliveryType,
                            onChanged: (v) => setDialogState(() => selectedDeliveryType = v!),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Warehouse Delivery Date (only for ViaWarehouse)
                    if (selectedDeliveryType == DeliveryType.viaWarehouse) ...[
                      Text('Depoya Teslim Tarihi', style: AppTheme.labelMedium),
                      const SizedBox(height: 8),
                      _DatePickerField(
                        date: warehouseDeliveryDate,
                        hint: 'Depoya teslim tarihi seçin',
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: warehouseDeliveryDate ?? DateTime.now(),
                            firstDate: DateTime.now().subtract(const Duration(days: 30)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) setDialogState(() => warehouseDeliveryDate = date);
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Ship Delivery Date
                    Text('Gemiye Teslim Tarihi *', style: AppTheme.labelMedium),
                    const SizedBox(height: 8),
                    _DatePickerField(
                      date: shipDeliveryDate,
                      hint: 'Gemiye teslim tarihi seçin',
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: shipDeliveryDate ?? DateTime.now(),
                          firstDate: DateTime.now().subtract(const Duration(days: 30)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) setDialogState(() => shipDeliveryDate = date);
                      },
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
                onPressed: () => _saveItem(
                  productNameController.text,
                  impaCodeController.text,
                  quantityController.text,
                  unitController.text,
                  buyingPriceController.text,
                  sellingPriceController.text,
                  selectedDeliveryType,
                  warehouseDeliveryDate,
                  shipDeliveryDate,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.white,
                ),
                child: Text('Ekle', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveItem(
    String productName,
    String impaCode,
    String quantity,
    String unit,
    String buyingPrice,
    String sellingPrice,
    DeliveryType deliveryType,
    DateTime? warehouseDate,
    DateTime? shipDate,
  ) async {
    if (productName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ürün adı gerekli'), backgroundColor: Colors.orange),
      );
      return;
    }

    final qty = double.tryParse(quantity);
    final buying = double.tryParse(buyingPrice);
    final selling = double.tryParse(sellingPrice);

    if (qty == null || buying == null || selling == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Miktar ve fiyatlar sayı olmalı'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (shipDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gemiye teslim tarihi gerekli'), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      final request = CreateOrderItemRequest(
        orderId: widget.orderId,
        productName: productName,
        impaCode: impaCode.isNotEmpty ? impaCode : null,
        description: null,
        quantity: qty,
        unit: unit,
        buyingPrice: buying,
        sellingPrice: selling,
        currency: _order!.currency,
        deliveryType: deliveryType,
        warehouseDeliveryDate: warehouseDate != null
            ? '${warehouseDate.year}-${warehouseDate.month.toString().padLeft(2, '0')}-${warehouseDate.day.toString().padLeft(2, '0')}'
            : null,
        shipDeliveryDate:
            '${shipDate.year}-${shipDate.month.toString().padLeft(2, '0')}-${shipDate.day.toString().padLeft(2, '0')}',
        notes: null,
      );

      await rust_api.addOrderItem(item: request);

      if (mounted) {
        Navigator.pop(context);
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ürün eklendi'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteItem(int itemId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ürünü Sil'),
        content: const Text('Bu ürünü siparişten kaldırmak istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await rust_api.deleteOrderItem(id: itemId);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ürün silindi'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor = Colors.grey.shade100;
    Color textColor = Colors.grey.shade700;

    if (status == 'Yeni') {
      bgColor = Colors.blue.shade50;
      textColor = Colors.blue.shade700;
    } else if (status == 'Onaylandı') {
      bgColor = Colors.green.shade50;
      textColor = Colors.green.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Text(status, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: textColor)),
    );
  }
}

class _TotalItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _TotalItem({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: AppTheme.labelMedium.copyWith(color: AppTheme.secondaryText)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: valueColor ?? AppTheme.primaryText)),
      ],
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final DateTime? date;
  final String hint;
  final VoidCallback onTap;

  const _DatePickerField({required this.date, required this.hint, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 18, color: AppTheme.secondaryText),
            const SizedBox(width: 8),
            Text(
              date != null ? '${date!.day}/${date!.month}/${date!.year}' : hint,
              style: GoogleFonts.inter(color: date != null ? AppTheme.primaryText : AppTheme.secondaryText),
            ),
          ],
        ),
      ),
    );
  }
}

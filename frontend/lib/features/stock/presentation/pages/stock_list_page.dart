import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pluto_grid/pluto_grid.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../src/rust/api.dart' as rust_api;
import '../../../../src/rust/models.dart';

class StockListPage extends StatefulWidget {
  const StockListPage({super.key});

  @override
  State<StockListPage> createState() => _StockListPageState();
}

class _StockListPageState extends State<StockListPage> {
  List<Stock> _stockItems = [];
  StockSummary? _summary;
  bool _isLoading = true;
  bool _showLowStockOnly = false;
  Key _gridKey = UniqueKey();

  // PlutoGrid state
  List<PlutoColumn> _columns = [];
  List<PlutoRow> _rows = [];

  @override
  void initState() {
    super.initState();
    _initColumns();
    _loadData();
  }

  void _initColumns() {
    _columns = [
      PlutoColumn(
        title: 'ID',
        field: 'id',
        type: PlutoColumnType.number(),
        width: 60,
        frozen: PlutoColumnFrozen.start,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Ürün',
        field: 'supply_item_name',
        type: PlutoColumnType.text(),
        width: 200,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Miktar',
        field: 'quantity',
        type: PlutoColumnType.number(),
        width: 100,
        enableEditingMode: false,
        renderer: (ctx) {
          final qty = ctx.cell.value is num ? (ctx.cell.value as num).toDouble() : 0.0;
          final minQty = ctx.row.cells['minimum_quantity']?.value is num 
              ? (ctx.row.cells['minimum_quantity']?.value as num).toDouble() 
              : 0.0;
          final isLow = qty <= minQty;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isLow ? Colors.red.shade50 : Colors.green.shade50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              qty.toStringAsFixed(1),
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: isLow ? Colors.red.shade700 : Colors.green.shade700,
              ),
            ),
          );
        },
      ),
      PlutoColumn(
        title: 'Birim',
        field: 'unit',
        type: PlutoColumnType.text(),
        width: 80,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Min. Miktar',
        field: 'minimum_quantity',
        type: PlutoColumnType.number(),
        width: 100,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Konum',
        field: 'warehouse_location',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Son Güncelleme',
        field: 'last_updated',
        type: PlutoColumnType.text(),
        width: 150,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'İşlemler',
        field: 'actions',
        type: PlutoColumnType.text(),
        width: 150,
        enableSorting: false,
        enableFilterMenuItem: false,
        renderer: (ctx) {
          final stockId = ctx.row.cells['id']?.value as int?;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Giriş butonu
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.green, size: 20),
                tooltip: 'Stok Girişi',
                onPressed: () => _showMovementDialog(stockId!, StockMovementType.in_),
              ),
              // Çıkış butonu
              IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
                tooltip: 'Stok Çıkışı',
                onPressed: () => _showMovementDialog(stockId!, StockMovementType.out),
              ),
              // Geçmiş butonu
              IconButton(
                icon: const Icon(Icons.history, color: AppTheme.secondaryText, size: 20),
                tooltip: 'Hareket Geçmişi',
                onPressed: () => _showMovementHistory(stockId!),
              ),
            ],
          );
        },
      ),
    ];
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final stocks = _showLowStockOnly
          ? await rust_api.getLowStock()
          : await rust_api.getAllStock();
      final summary = await rust_api.getStockSummary();
      
      setState(() {
        _stockItems = stocks;
        _summary = summary;
        _rows = _buildRows();
        _gridKey = UniqueKey();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<PlutoRow> _buildRows() {
    return _stockItems.map((stock) {
      return PlutoRow(cells: {
        'id': PlutoCell(value: stock.id),
        'supply_item_name': PlutoCell(value: stock.supplyItemName ?? 'Bilinmeyen Ürün'),
        'quantity': PlutoCell(value: stock.quantity),
        'unit': PlutoCell(value: stock.unit),
        'minimum_quantity': PlutoCell(value: stock.minimumQuantity),
        'warehouse_location': PlutoCell(value: stock.warehouseLocation ?? '-'),
        'last_updated': PlutoCell(value: _formatDate(stock.lastUpdated)),
        'actions': PlutoCell(value: ''),
      });
    }).toList();
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  void _showMovementDialog(int stockId, StockMovementType type) {
    final quantityController = TextEditingController();
    final notesController = TextEditingController();
    final referenceInfoController = TextEditingController();
    String? selectedRefType;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              type == StockMovementType.in_ ? Icons.add_circle : Icons.remove_circle,
              color: type == StockMovementType.in_ ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(
              type == StockMovementType.in_ ? 'Stok Girişi' : 'Stok Çıkışı',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(
                  labelText: 'Miktar *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRefType,
                decoration: const InputDecoration(
                  labelText: 'Referans Tipi',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'order', child: Text('Sipariş')),
                  DropdownMenuItem(value: 'supplier', child: Text('Tedarikçi')),
                  DropdownMenuItem(value: 'adjustment', child: Text('Sayım')),
                ],
                onChanged: (val) => selectedRefType = val,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: referenceInfoController,
                decoration: const InputDecoration(
                  labelText: 'Referans Bilgisi',
                  hintText: 'Örn: Sipariş #ORD-2026-001',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notlar',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: type == StockMovementType.in_ ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final qty = double.tryParse(quantityController.text);
              if (qty == null || qty <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Geçerli bir miktar girin')),
                );
                return;
              }

              try {
                await rust_api.createStockMovement(
                  movement: CreateStockMovementRequest(
                    stockId: stockId,
                    movementType: type,
                    quantity: qty,
                    referenceType: selectedRefType,
                    referenceId: null,
                    referenceInfo: referenceInfoController.text.isEmpty 
                        ? null 
                        : referenceInfoController.text,
                    notes: notesController.text.isEmpty ? null : notesController.text,
                  ),
                );
                if (mounted) {
                  Navigator.pop(context);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(type == StockMovementType.in_ 
                          ? 'Stok girişi başarılı' 
                          : 'Stok çıkışı başarılı'),
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
            child: Text(type == StockMovementType.in_ ? 'Giriş Yap' : 'Çıkış Yap'),
          ),
        ],
      ),
    );
  }

  void _showMovementHistory(int stockId) async {
    try {
      final movements = await rust_api.getStockMovements(stockId: stockId);
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.history, color: AppTheme.accent),
              const SizedBox(width: 8),
              Text('Hareket Geçmişi', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ],
          ),
          content: SizedBox(
            width: 600,
            height: 400,
            child: movements.isEmpty
                ? const Center(child: Text('Henüz hareket yok'))
                : ListView.builder(
                    itemCount: movements.length,
                    itemBuilder: (context, index) {
                      final m = movements[index];
                      final isIn = m.movementType == StockMovementType.in_ || 
                                   m.movementType == StockMovementType.return_;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isIn ? Colors.green.shade100 : Colors.red.shade100,
                            child: Icon(
                              isIn ? Icons.add : Icons.remove,
                              color: isIn ? Colors.green : Colors.red,
                            ),
                          ),
                          title: Text(
                            '${isIn ? '+' : '-'}${m.quantity.toStringAsFixed(1)} ${m.unit}',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: isIn ? Colors.green : Colors.red,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_getMovementTypeText(m.movementType)),
                              if (m.referenceInfo != null)
                                Text(m.referenceInfo!, style: const TextStyle(fontSize: 12)),
                              if (m.notes != null)
                                Text(m.notes!, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                            ],
                          ),
                          trailing: Text(
                            _formatDate(m.createdAt),
                            style: const TextStyle(fontSize: 12, color: AppTheme.secondaryText),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kapat'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    }
  }

  String _getMovementTypeText(StockMovementType type) {
    switch (type) {
      case StockMovementType.in_:
        return 'Giriş';
      case StockMovementType.out:
        return 'Çıkış';
      case StockMovementType.adjustment:
        return 'Sayım Düzeltme';
      case StockMovementType.return_:
        return 'İade';
    }
  }

  void _showAddStockDialog() async {
    // Ürün listesini yükle
    final supplyItems = await rust_api.getAllSupplyItems();
    if (!mounted) return;

    int? selectedSupplyItemId;
    final quantityController = TextEditingController(text: '0');
    final minQtyController = TextEditingController(text: '10');
    final locationController = TextEditingController();
    String selectedUnit = 'Adet';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.inventory_2, color: AppTheme.accent),
              const SizedBox(width: 8),
              Text('Yeni Stok Kaydı', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ],
          ),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: selectedSupplyItemId,
                  decoration: const InputDecoration(
                    labelText: 'Ürün Seç *',
                    border: OutlineInputBorder(),
                  ),
                  items: supplyItems.map((item) {
                    return DropdownMenuItem(
                      value: item.id,
                      child: Text('${item.name} (${item.unit})'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setDialogState(() {
                      selectedSupplyItemId = val;
                      final item = supplyItems.firstWhere((i) => i.id == val);
                      selectedUnit = item.unit;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: quantityController,
                        decoration: InputDecoration(
                          labelText: 'Başlangıç Miktarı',
                          suffixText: selectedUnit,
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: minQtyController,
                        decoration: InputDecoration(
                          labelText: 'Minimum Miktar',
                          suffixText: selectedUnit,
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Depo Konumu',
                    hintText: 'Örn: Raf A-12',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Ekle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (selectedSupplyItemId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lütfen bir ürün seçin')),
                  );
                  return;
                }

                try {
                  await rust_api.createStock(
                    stock: CreateStockRequest(
                      supplyItemId: selectedSupplyItemId!,
                      quantity: double.tryParse(quantityController.text) ?? 0,
                      unit: selectedUnit,
                      warehouseLocation: locationController.text.isEmpty 
                          ? null 
                          : locationController.text,
                      minimumQuantity: double.tryParse(minQtyController.text) ?? 10,
                    ),
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    _loadData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Stok kaydı oluşturuldu'),
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
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.inventory_2, size: 28, color: AppTheme.accent),
                const SizedBox(width: 12),
                Text(
                  'Stok Takibi',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryText,
                  ),
                ),
                const Spacer(),
                // Low stock filter
                FilterChip(
                  label: Text(
                    'Düşük Stok',
                    style: GoogleFonts.inter(
                      color: _showLowStockOnly ? Colors.white : AppTheme.primaryText,
                    ),
                  ),
                  selected: _showLowStockOnly,
                  selectedColor: Colors.orange,
                  onSelected: (val) {
                    setState(() => _showLowStockOnly = val);
                    _loadData();
                  },
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Yeni Stok'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: _showAddStockDialog,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Summary Cards
            if (_summary != null) ...[
              Row(
                children: [
                  _buildSummaryCard(
                    'Toplam Ürün',
                    _summary!.totalItems.toString(),
                    Icons.inventory,
                    AppTheme.accent,
                  ),
                  const SizedBox(width: 16),
                  _buildSummaryCard(
                    'Düşük Stok',
                    _summary!.lowStockCount.toString(),
                    Icons.warning,
                    Colors.orange,
                  ),
                  const SizedBox(width: 16),
                  _buildSummaryCard(
                    'Stok Yok',
                    _summary!.outOfStockCount.toString(),
                    Icons.error,
                    Colors.red,
                  ),
                  const SizedBox(width: 16),
                  _buildSummaryCard(
                    'Toplam Değer',
                    '\$${_summary!.totalValue.toStringAsFixed(2)}',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Data Grid
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _rows.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inventory_2_outlined, 
                                    size: 64, color: AppTheme.secondaryText.withOpacity(0.5)),
                                const SizedBox(height: 16),
                                Text(
                                  _showLowStockOnly 
                                      ? 'Düşük stoklu ürün yok' 
                                      : 'Henüz stok kaydı yok',
                                  style: GoogleFonts.inter(
                                    color: AppTheme.secondaryText,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (!_showLowStockOnly)
                                  TextButton.icon(
                                    onPressed: _showAddStockDialog,
                                    icon: const Icon(Icons.add),
                                    label: const Text('İlk stok kaydını oluştur'),
                                  ),
                              ],
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: PlutoGrid(
                              key: _gridKey,
                              columns: _columns,
                              rows: _rows,
                              configuration: PlutoGridConfiguration(
                                style: PlutoGridStyleConfig(
                                  gridBorderColor: AppTheme.border,
                                  borderColor: AppTheme.border,
                                  activatedBorderColor: AppTheme.accent,
                                  activatedColor: AppTheme.accent.withOpacity(0.1),
                                  gridBackgroundColor: AppTheme.surface,
                                  rowColor: AppTheme.surface,
                                  evenRowColor: AppTheme.background,
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
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
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
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.secondaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryText,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

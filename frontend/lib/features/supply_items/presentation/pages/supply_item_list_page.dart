import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pluto_grid/pluto_grid.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/linear_components.dart';
import '../../../../src/rust/api.dart' as rust_api;
import '../../../../src/rust/models.dart';

class SupplyItemListPage extends StatefulWidget {
  const SupplyItemListPage({super.key});

  @override
  State<SupplyItemListPage> createState() => _SupplyItemListPageState();
}

class _SupplyItemListPageState extends State<SupplyItemListPage> {
  List<SupplyItem> _items = [];
  List<Supplier> _suppliers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // PlutoGrid state
  List<PlutoColumn> _columns = [];
  List<PlutoRow> _rows = [];
  Key _gridKey = UniqueKey();

  // Item categories
  static const List<String> _categories = [
    'Gıda',
    'Teknik Malzeme',
    'Güverte Malzemesi',
    'Makine Malzemesi',
    'Kimyasal',
    'Elektrik',
    'Emniyet Ekipmanı',
    'Diğer',
  ];

  // Units
  static const List<String> _units = [
    'Adet',
    'Kg',
    'Lt',
    'Metre',
    'Kutu',
    'Paket',
    'Çift',
    'Set',
    'Ton',
    'M²',
    'M³',
  ];

  // Currencies
  static const List<String> _currencies = ['USD', 'EUR', 'TRY', 'GBP'];

  @override
  void initState() {
    super.initState();
    _initColumns();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _initColumns() {
    _columns = [
      PlutoColumn(
        title: 'ID',
        field: 'id',
        type: PlutoColumnType.number(),
        width: 60,
        enableEditingMode: false,
        frozen: PlutoColumnFrozen.start,
      ),
      PlutoColumn(
        title: 'IMPA Kodu',
        field: 'impa_code',
        type: PlutoColumnType.text(),
        width: 110,
      ),
      PlutoColumn(
        title: 'Ürün Adı',
        field: 'name',
        type: PlutoColumnType.text(),
        width: 200,
      ),
      PlutoColumn(
        title: 'Kategori',
        field: 'category',
        type: PlutoColumnType.text(),
        width: 130,
      ),
      PlutoColumn(
        title: 'Tedarikçi',
        field: 'supplier_name',
        type: PlutoColumnType.text(),
        width: 150,
      ),
      PlutoColumn(
        title: 'Birim Fiyat',
        field: 'unit_price',
        type: PlutoColumnType.number(),
        width: 100,
        renderer: (rendererContext) {
          final rawPrice = rendererContext.cell.value;
          final price = rawPrice is num ? rawPrice.toDouble() : null;
          final currency = rendererContext.row.cells['currency']?.value as String?;
          return Text(
            price != null ? '${price.toStringAsFixed(2)} ${currency ?? ''}' : '-',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.accent,
            ),
          );
        },
      ),
      PlutoColumn(
        title: 'Birim',
        field: 'unit',
        type: PlutoColumnType.text(),
        width: 80,
      ),
      PlutoColumn(
        title: 'Min. Sipariş',
        field: 'min_qty',
        type: PlutoColumnType.number(),
        width: 90,
      ),
      PlutoColumn(
        title: 'İşlemler',
        field: 'actions',
        type: PlutoColumnType.text(),
        width: 100,
        enableSorting: false,
        enableFilterMenuItem: false,
        renderer: (rendererContext) {
          final itemId = rendererContext.row.cells['id']?.value as int?;
          final itemName = rendererContext.row.cells['name']?.value as String?;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () {
                  if (itemId != null) {
                    final item = _items.firstWhere((s) => s.id == itemId);
                    _showEditItemDialog(item);
                  }
                },
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.edit_outlined, size: 16, color: AppTheme.accent),
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: () {
                  if (itemId != null && itemName != null) {
                    _deleteItem(itemId, itemName);
                  }
                },
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(Icons.delete_outline, size: 16, color: Colors.red.shade400),
                ),
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
      final results = await Future.wait([
        rust_api.getAllSupplyItems(),
        rust_api.getAllSuppliers(),
      ]);
      setState(() {
        _items = results[0] as List<SupplyItem>;
        _suppliers = results[1] as List<Supplier>;
        _updateRows();
        _gridKey = UniqueKey();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veriler yüklenirken hata: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _searchItems(String query) async {
    if (query.isEmpty) {
      _loadData();
      return;
    }

    setState(() => _isLoading = true);
    try {
      final items = await rust_api.searchSupplyItems(query: query);
      setState(() {
        _items = items;
        _updateRows();
        _gridKey = UniqueKey();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _updateRows() {
    _rows = _items.map((item) {
      return PlutoRow(
        cells: {
          'id': PlutoCell(value: item.id),
          'impa_code': PlutoCell(value: item.impaCode ?? '-'),
          'name': PlutoCell(value: item.name),
          'category': PlutoCell(value: item.category),
          'supplier_name': PlutoCell(value: item.supplierName ?? '-'),
          'unit_price': PlutoCell(value: item.unitPrice),
          'currency': PlutoCell(value: item.currency),
          'unit': PlutoCell(value: item.unit),
          'min_qty': PlutoCell(value: item.minimumOrderQuantity ?? 1),
          'actions': PlutoCell(value: ''),
        },
      );
    }).toList();
  }

  Future<void> _deleteItem(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ürün Sil', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        content: Text('$name ürününü silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await rust_api.deleteSupplyItem(id: id);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$name silindi'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Silme hatası: $e'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      }
    }
  }

  void _showAddItemDialog() {
    showDialog<bool>(
      context: context,
      builder: (dialogContext) => _SupplyItemFormDialog(
        suppliers: _suppliers,
        categories: _categories,
        units: _units,
        currencies: _currencies,
        onSave: (item) async {
          await rust_api.createSupplyItem(item: item);
        },
      ),
    ).then((result) {
      if (result == true) {
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ürün başarıyla eklendi'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    });
  }

  void _showEditItemDialog(SupplyItem item) {
    showDialog<bool>(
      context: context,
      builder: (dialogContext) => _SupplyItemFormDialog(
        item: item,
        suppliers: _suppliers,
        categories: _categories,
        units: _units,
        currencies: _currencies,
        onSave: (request) async {
          final updateRequest = UpdateSupplyItemRequest(
            supplierId: request.supplierId,
            impaCode: request.impaCode,
            name: request.name,
            description: request.description,
            category: request.category,
            unit: request.unit,
            unitPrice: request.unitPrice,
            currency: request.currency,
            minimumOrderQuantity: request.minimumOrderQuantity,
          );
          await rust_api.updateSupplyItem(id: item.id, item: updateRequest);
        },
      ),
    ).then((result) {
      if (result == true) {
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ürün başarıyla güncellendi'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    });
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
        leadingWidth: 200,
        leading: Padding(
          padding: const EdgeInsets.only(left: 24),
          child: Row(
            children: [
              Icon(Icons.inventory_2_outlined, color: AppTheme.brandColor, size: 24),
              const SizedBox(width: 12),
              Text(
                'Ürün Kataloğu',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: AppTheme.primaryText,
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Search
          Container(
            width: 300,
            height: 36,
            margin: const EdgeInsets.symmetric(vertical: 10),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                _searchQuery = value;
                _searchItems(value);
              },
              decoration: InputDecoration(
                hintText: 'Ürün ara (isim, IMPA kodu)...',
                hintStyle: GoogleFonts.inter(fontSize: 13, color: AppTheme.secondaryText),
                prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.secondaryText),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          _searchQuery = '';
                          _loadData();
                        },
                      )
                    : null,
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              style: GoogleFonts.inter(fontSize: 14),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.secondaryText),
            onPressed: _loadData,
            tooltip: 'Yenile',
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _showAddItemDialog,
              icon: const Icon(Icons.add, size: 18),
              label: Text('Yeni Ürün', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
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
          padding: EdgeInsets.zero,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty
                  ? const EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'Henüz ürün bulunmuyor',
                      subtitle: 'Yeni bir ürün ekleyerek başlayın',
                    )
                  : Column(
                      children: [
                        // Stats bar
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: AppTheme.border)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.inventory_2, size: 20, color: AppTheme.accent),
                              const SizedBox(width: 8),
                              Text(
                                '${_items.length} ürün',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryText,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Düzenlemek için satıra çift tıklayın',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppTheme.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // PlutoGrid
                        Expanded(
                          child: PlutoGrid(
                            key: _gridKey,
                            columns: _columns,
                            rows: _rows,
                            onRowDoubleTap: (event) {
                              final itemId = event.row.cells['id']?.value as int?;
                              if (itemId != null) {
                                final item = _items.firstWhere((s) => s.id == itemId);
                                _showEditItemDialog(item);
                              }
                            },
                            createFooter: (stateManager) {
                              return _buildGridFooter();
                            },
                            configuration: PlutoGridConfiguration(
                              style: PlutoGridStyleConfig(
                                gridBorderColor: AppTheme.border,
                                borderColor: AppTheme.border,
                                activatedBorderColor: AppTheme.accent,
                                activatedColor: AppTheme.accent.withOpacity(0.1),
                                gridBackgroundColor: AppTheme.surface,
                                rowColor: AppTheme.surface,
                                evenRowColor: AppTheme.background,
                                columnTextStyle: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppTheme.primaryText,
                                ),
                                cellTextStyle: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppTheme.primaryText,
                                ),
                              ),
                              columnSize: const PlutoGridColumnSizeConfig(
                                autoSizeMode: PlutoAutoSizeMode.scale,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildGridFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.border)),
        color: AppTheme.background,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Toplam: ${_items.length} ürün',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.secondaryText,
            ),
          ),
          Text(
            'Satıra çift tıklayarak düzenleyin',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.secondaryText,
            ),
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
          'Ürün Kataloğu',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryText,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppTheme.secondaryText),
            onPressed: () {
              // TODO: Mobile search
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.secondaryText),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'Henüz ürün bulunmuyor',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return _SupplyItemCard(
                      item: item,
                      onTap: () => _showEditItemDialog(item),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        backgroundColor: AppTheme.accent,
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Mobile card for supply item
class _SupplyItemCard extends StatelessWidget {
  final SupplyItem item;
  final VoidCallback onTap;

  const _SupplyItemCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return LinearContainer(
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              item.impaCode ?? '?',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 10,
                color: AppTheme.accent,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        title: Text(
          item.name,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${item.category} • ${item.unitPrice.toStringAsFixed(2)} ${item.currency}/${item.unit}',
          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.secondaryText),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.secondaryText),
        onTap: onTap,
      ),
    );
  }
}

/// Supply Item Form Dialog for Create/Edit
class _SupplyItemFormDialog extends StatefulWidget {
  final SupplyItem? item;
  final List<Supplier> suppliers;
  final List<String> categories;
  final List<String> units;
  final List<String> currencies;
  final Future<void> Function(CreateSupplyItemRequest) onSave;

  const _SupplyItemFormDialog({
    this.item,
    required this.suppliers,
    required this.categories,
    required this.units,
    required this.currencies,
    required this.onSave,
  });

  @override
  State<_SupplyItemFormDialog> createState() => _SupplyItemFormDialogState();
}

class _SupplyItemFormDialogState extends State<_SupplyItemFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _impaCodeController;
  late TextEditingController _descriptionController;
  late TextEditingController _unitPriceController;
  late TextEditingController _minQtyController;
  late int? _selectedSupplierId;
  late String _selectedCategory;
  late String _selectedUnit;
  late String _selectedCurrency;
  bool _isLoading = false;

  bool get isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _impaCodeController = TextEditingController(text: widget.item?.impaCode ?? '');
    _descriptionController = TextEditingController(text: widget.item?.description ?? '');
    _unitPriceController = TextEditingController(
      text: widget.item?.unitPrice.toStringAsFixed(2) ?? '',
    );
    _minQtyController = TextEditingController(
      text: widget.item?.minimumOrderQuantity?.toString() ?? '',
    );
    _selectedSupplierId = widget.item?.supplierId ?? (widget.suppliers.isNotEmpty ? widget.suppliers.first.id : null);
    _selectedCategory = widget.item?.category ?? widget.categories.first;
    _selectedUnit = widget.item?.unit ?? widget.units.first;
    _selectedCurrency = widget.item?.currency ?? widget.currencies.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _impaCodeController.dispose();
    _descriptionController.dispose();
    _unitPriceController.dispose();
    _minQtyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSupplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir tedarikçi seçin'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    final request = CreateSupplyItemRequest(
      supplierId: _selectedSupplierId!,
      impaCode: _impaCodeController.text.trim().isEmpty ? null : _impaCodeController.text.trim(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      category: _selectedCategory,
      unit: _selectedUnit,
      unitPrice: double.tryParse(_unitPriceController.text) ?? 0.0,
      currency: _selectedCurrency,
      minimumOrderQuantity: int.tryParse(_minQtyController.text),
    );

    try {
      await widget.onSave(request);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Ürün Düzenle' : 'Yeni Ürün Ekle',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryText,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Form fields - Row 1
                Row(
                  children: [
                    // IMPA Code
                    Expanded(
                      flex: 1,
                      child: _buildTextField(
                        controller: _impaCodeController,
                        label: 'IMPA Kodu',
                        hint: '123456',
                        icon: Icons.qr_code,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Product Name
                    Expanded(
                      flex: 2,
                      child: _buildTextField(
                        controller: _nameController,
                        label: 'Ürün Adı *',
                        hint: 'Ürün adı girin',
                        icon: Icons.inventory_2_outlined,
                        validator: (v) => v?.isEmpty == true ? 'Zorunlu alan' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Row 2 - Category & Supplier
                Row(
                  children: [
                    // Category
                    Expanded(
                      child: _buildDropdownField(
                        label: 'Kategori',
                        value: _selectedCategory,
                        items: widget.categories,
                        onChanged: (v) => setState(() => _selectedCategory = v!),
                        icon: Icons.category_outlined,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Supplier
                    Expanded(
                      child: _buildSupplierDropdown(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Row 3 - Price, Currency, Unit
                Row(
                  children: [
                    // Unit Price
                    Expanded(
                      flex: 2,
                      child: _buildTextField(
                        controller: _unitPriceController,
                        label: 'Birim Fiyat *',
                        hint: '0.00',
                        icon: Icons.attach_money,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v?.isEmpty == true) return 'Zorunlu alan';
                          if (double.tryParse(v!) == null) return 'Geçersiz fiyat';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Currency
                    Expanded(
                      child: _buildDropdownField(
                        label: 'Para Birimi',
                        value: _selectedCurrency,
                        items: widget.currencies,
                        onChanged: (v) => setState(() => _selectedCurrency = v!),
                        icon: Icons.currency_exchange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Unit
                    Expanded(
                      child: _buildDropdownField(
                        label: 'Birim',
                        value: _selectedUnit,
                        items: widget.units,
                        onChanged: (v) => setState(() => _selectedUnit = v!),
                        icon: Icons.straighten,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Row 4 - Min Qty
                _buildTextField(
                  controller: _minQtyController,
                  label: 'Min. Sipariş Miktarı',
                  hint: '1',
                  icon: Icons.production_quantity_limits,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // Description
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Açıklama',
                  hint: 'Ürün açıklaması (opsiyonel)',
                  icon: Icons.description_outlined,
                  maxLines: 2,
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'İptal',
                        style: GoogleFonts.inter(color: AppTheme.secondaryText),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              isEditing ? 'Güncelle' : 'Kaydet',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.secondaryText,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: AppTheme.secondaryText.withOpacity(0.5)),
            prefixIcon: Icon(icon, size: 18, color: AppTheme.secondaryText),
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red.shade300),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          style: GoogleFonts.inter(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.secondaryText,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          onChanged: onChanged,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: AppTheme.secondaryText),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                item,
                style: GoogleFonts.inter(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSupplierDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tedarikçi *',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.secondaryText,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<int>(
          value: _selectedSupplierId,
          isExpanded: true,
          onChanged: (v) => setState(() => _selectedSupplierId = v),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.business_outlined, size: 18, color: AppTheme.secondaryText),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          items: widget.suppliers.map((supplier) {
            return DropdownMenuItem(
              value: supplier.id,
              child: Text(
                supplier.name,
                style: GoogleFonts.inter(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

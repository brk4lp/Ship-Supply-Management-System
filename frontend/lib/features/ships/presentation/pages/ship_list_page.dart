import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pluto_grid/pluto_grid.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/linear_components.dart';
import '../../../../src/rust/api.dart' as rust_api;
import '../../../../src/rust/models.dart';

class ShipListPage extends StatefulWidget {
  const ShipListPage({super.key});

  @override
  State<ShipListPage> createState() => _ShipListPageState();
}

class _ShipListPageState extends State<ShipListPage> {
  List<Ship> _ships = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // PlutoGrid state
  List<PlutoColumn> _columns = [];
  List<PlutoRow> _rows = [];
  Key _gridKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _initColumns();
    _loadShips();
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
        width: 70,
        enableEditingMode: false,
        frozen: PlutoColumnFrozen.start,
      ),
      PlutoColumn(
        title: 'Gemi Adı',
        field: 'name',
        type: PlutoColumnType.text(),
        width: 200,
      ),
      PlutoColumn(
        title: 'IMO No',
        field: 'imo_number',
        type: PlutoColumnType.text(),
        width: 120,
      ),
      PlutoColumn(
        title: 'Bayrak',
        field: 'flag',
        type: PlutoColumnType.text(),
        width: 100,
      ),
      PlutoColumn(
        title: 'Gemi Tipi',
        field: 'ship_type',
        type: PlutoColumnType.text(),
        width: 150,
      ),
      PlutoColumn(
        title: 'Gross Tonaj',
        field: 'gross_tonnage',
        type: PlutoColumnType.number(),
        width: 120,
        formatter: (value) => value != null ? '${value.toString()} GT' : '-',
      ),
      PlutoColumn(
        title: 'Armatör',
        field: 'owner',
        type: PlutoColumnType.text(),
        width: 180,
      ),
      PlutoColumn(
        title: 'Oluşturulma',
        field: 'created_at',
        type: PlutoColumnType.text(),
        width: 150,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'İşlemler',
        field: 'actions',
        type: PlutoColumnType.text(),
        width: 100,
        enableEditingMode: false,
        enableSorting: false,
        enableFilterMenuItem: false,
        renderer: (rendererContext) {
          final shipId = rendererContext.row.cells['id']?.value as int?;
          final shipName = rendererContext.row.cells['name']?.value as String?;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () {
                  if (shipId != null) {
                    final ship = _ships.firstWhere((s) => s.id == shipId);
                    _showEditShipDialog(ship);
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
                  if (shipId != null && shipName != null) {
                    _deleteShip(shipId, shipName);
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

  Future<void> _loadShips() async {
    setState(() => _isLoading = true);
    try {
      final ships = await rust_api.getAllShips();
      setState(() {
        _ships = ships;
        _updateRows();
        _gridKey = UniqueKey();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gemiler yüklenirken hata: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _searchShips(String query) async {
    if (query.isEmpty) {
      _loadShips();
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final ships = await rust_api.searchShips(query: query);
      setState(() {
        _ships = ships;
        _updateRows();
        _gridKey = UniqueKey();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _updateRows() {
    _rows = _ships.map((ship) {
      return PlutoRow(
        cells: {
          'id': PlutoCell(value: ship.id),
          'name': PlutoCell(value: ship.name),
          'imo_number': PlutoCell(value: ship.imoNumber),
          'flag': PlutoCell(value: ship.flag),
          'ship_type': PlutoCell(value: ship.shipType ?? '-'),
          'gross_tonnage': PlutoCell(value: ship.grossTonnage),
          'owner': PlutoCell(value: ship.owner ?? '-'),
          'created_at': PlutoCell(value: _formatDate(ship.createdAt)),
          'actions': PlutoCell(value: ''),
        },
      );
    }).toList();
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _deleteShip(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Gemi Sil', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        content: Text('$name gemisini silmek istediğinize emin misiniz?'),
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
        await rust_api.deleteShip(id: id);
        _loadShips();
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

  void _showAddShipDialog() {
    showDialog<bool>(
      context: context,
      builder: (dialogContext) => _ShipFormDialog(
        onSave: (ship) async {
          await rust_api.createShip(ship: ship);
        },
      ),
    ).then((result) {
      if (result == true) {
        _loadShips();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gemi başarıyla eklendi'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    });
  }

  void _showEditShipDialog(Ship ship) {
    showDialog<bool>(
      context: context,
      builder: (dialogContext) => _ShipFormDialog(
        ship: ship,
        onSave: (request) async {
          final updateRequest = UpdateShipRequest(
            name: request.name,
            imoNumber: request.imoNumber,
            flag: request.flag,
            shipType: request.shipType,
            grossTonnage: request.grossTonnage,
            owner: request.owner,
          );
          await rust_api.updateShip(id: ship.id, ship: updateRequest);
        },
      ),
    ).then((result) {
      if (result == true) {
        _loadShips();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gemi başarıyla güncellendi'),
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
        title: Text(
          'Gemiler',
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
                controller: _searchController,
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
                onSubmitted: _searchShips,
                decoration: InputDecoration(
                  hintText: 'Gemi ara (isim, IMO, bayrak)...',
                  hintStyle: GoogleFonts.inter(color: AppTheme.secondaryText, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: AppTheme.secondaryText, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                            _loadShips();
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                style: GoogleFonts.inter(fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.secondaryText),
            onPressed: _loadShips,
            tooltip: 'Yenile',
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _showAddShipDialog,
              icon: const Icon(Icons.add, size: 18),
              label: Text('Yeni Gemi', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
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
              : _ships.isEmpty
                  ? const EmptyState(
                      icon: Icons.directions_boat_outlined,
                      title: 'Henüz gemi bulunmuyor',
                      subtitle: 'Yeni bir gemi ekleyerek başlayın',
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
                              Icon(Icons.directions_boat, size: 20, color: AppTheme.accent),
                              const SizedBox(width: 8),
                              Text(
                                '${_ships.length} gemi',
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
                              final shipId = event.row.cells['id']?.value as int?;
                              if (shipId != null) {
                                final ship = _ships.firstWhere((s) => s.id == shipId);
                                _showEditShipDialog(ship);
                              }
                            },
                            createFooter: (stateManager) {
                              return _buildGridFooter(stateManager);
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

  Widget _buildGridFooter(PlutoGridStateManager _) {
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
            'Toplam: ${_ships.length} gemi',
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
          'Gemiler',
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
            onPressed: _loadShips,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _ships.isEmpty
              ? const EmptyState(
                  icon: Icons.directions_boat_outlined,
                  title: 'Henüz gemi bulunmuyor',
                  subtitle: 'Yeni bir gemi ekleyerek başlayın',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _ships.length,
                  itemBuilder: (context, index) {
                    final ship = _ships[index];
                    return _ShipCard(
                      ship: ship,
                      onTap: () => _showEditShipDialog(ship),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddShipDialog,
        backgroundColor: AppTheme.accent,
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Ship Card for mobile view
class _ShipCard extends StatelessWidget {
  final Ship ship;
  final VoidCallback onTap;

  const _ShipCard({required this.ship, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              ship.flag,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppTheme.accent,
              ),
            ),
          ),
        ),
        title: Text(
          ship.name,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'IMO: ${ship.imoNumber} • ${ship.shipType ?? "Tip belirtilmemiş"}',
          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.secondaryText),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.secondaryText),
        onTap: onTap,
      ),
    );
  }
}

/// Ship Form Dialog for Create/Edit
class _ShipFormDialog extends StatefulWidget {
  final Ship? ship;
  final Future<void> Function(CreateShipRequest) onSave;

  const _ShipFormDialog({this.ship, required this.onSave});

  @override
  State<_ShipFormDialog> createState() => _ShipFormDialogState();
}

class _ShipFormDialogState extends State<_ShipFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _imoController;
  late TextEditingController _flagController;
  late TextEditingController _typeController;
  late TextEditingController _tonnageController;
  late TextEditingController _ownerController;
  bool _isLoading = false;

  bool get isEditing => widget.ship != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.ship?.name ?? '');
    _imoController = TextEditingController(text: widget.ship?.imoNumber ?? '');
    _flagController = TextEditingController(text: widget.ship?.flag ?? '');
    _typeController = TextEditingController(text: widget.ship?.shipType ?? '');
    _tonnageController = TextEditingController(
      text: widget.ship?.grossTonnage?.toString() ?? '',
    );
    _ownerController = TextEditingController(text: widget.ship?.owner ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _imoController.dispose();
    _flagController.dispose();
    _typeController.dispose();
    _tonnageController.dispose();
    _ownerController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final request = CreateShipRequest(
      name: _nameController.text.trim(),
      imoNumber: _imoController.text.trim(),
      flag: _flagController.text.trim().toUpperCase(),
      shipType: _typeController.text.trim().isEmpty ? null : _typeController.text.trim(),
      grossTonnage: _tonnageController.text.isEmpty
          ? null
          : double.tryParse(_tonnageController.text),
      owner: _ownerController.text.trim().isEmpty ? null : _ownerController.text.trim(),
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
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Gemi Düzenle' : 'Yeni Gemi Ekle',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryText,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Form fields
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildTextField(
                      controller: _nameController,
                      label: 'Gemi Adı *',
                      hint: 'MV Example Ship',
                      validator: (v) => v?.isEmpty == true ? 'Gemi adı gerekli' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _imoController,
                      label: 'IMO No *',
                      hint: '1234567',
                      validator: (v) {
                        if (v?.isEmpty == true) return 'IMO gerekli';
                        if (v!.length != 7) return '7 haneli olmalı';
                        if (int.tryParse(v) == null) return 'Sayı olmalı';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _flagController,
                      label: 'Bayrak *',
                      hint: 'TR',
                      validator: (v) => v?.isEmpty == true ? 'Bayrak gerekli' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: _buildTextField(
                      controller: _typeController,
                      label: 'Gemi Tipi',
                      hint: 'Bulk Carrier',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _tonnageController,
                      label: 'Gross Tonaj',
                      hint: '50000',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: _buildTextField(
                      controller: _ownerController,
                      label: 'Armatör',
                      hint: 'Shipping Company Ltd.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Actions
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
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            isEditing ? 'Güncelle' : 'Ekle',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryText,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: AppTheme.secondaryText),
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
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}

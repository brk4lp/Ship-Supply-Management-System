import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../src/rust/api.dart';
import '../../../../src/rust/models.dart';

class ShipVisitListPage extends StatefulWidget {
  const ShipVisitListPage({super.key});

  @override
  State<ShipVisitListPage> createState() => _ShipVisitListPageState();
}

class _ShipVisitListPageState extends State<ShipVisitListPage> {
  List<ShipVisit> _visits = [];
  List<Ship> _ships = [];
  List<Port> _ports = [];
  bool _isLoading = true;
  String? _error;
  bool _showUpcomingOnly = true;

  late PlutoGridStateManager _stateManager;

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
      final futures = await Future.wait([
        _showUpcomingOnly ? getUpcomingShipVisits() : getAllShipVisits(),
        getAllShips(),
        getActivePorts(),
      ]);
      
      setState(() {
        _visits = futures[0] as List<ShipVisit>;
        _ships = futures[1] as List<Ship>;
        _ports = futures[2] as List<Port>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(VisitStatus status) {
    switch (status) {
      case VisitStatus.planned:
        return AppTheme.info;
      case VisitStatus.arrived:
        return AppTheme.success;
      case VisitStatus.departed:
        return AppTheme.secondaryText;
      case VisitStatus.cancelled:
        return AppTheme.error;
    }
  }

  String _getStatusText(VisitStatus status) {
    switch (status) {
      case VisitStatus.planned:
        return 'Planlandı';
      case VisitStatus.arrived:
        return 'Limanda';
      case VisitStatus.departed:
        return 'Ayrıldı';
      case VisitStatus.cancelled:
        return 'İptal';
    }
  }

  String _formatDateTime(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoDate;
    }
  }

  List<PlutoColumn> _buildColumns() {
    return [
      PlutoColumn(
        title: 'ID',
        field: 'id',
        type: PlutoColumnType.number(),
        width: 60,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Gemi',
        field: 'ship_name',
        type: PlutoColumnType.text(),
        width: 160,
        enableEditingMode: false,
        renderer: (rendererContext) {
          return Row(
            children: [
              Icon(Icons.directions_boat, size: 16, color: AppTheme.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  rendererContext.cell.value ?? '-',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        },
      ),
      PlutoColumn(
        title: 'Liman',
        field: 'port_name',
        type: PlutoColumnType.text(),
        width: 140,
        enableEditingMode: false,
        renderer: (rendererContext) {
          return Row(
            children: [
              Icon(Icons.location_on, size: 16, color: AppTheme.warning),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  rendererContext.cell.value ?? '-',
                  style: GoogleFonts.inter(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        },
      ),
      PlutoColumn(
        title: 'ETA',
        field: 'eta',
        type: PlutoColumnType.text(),
        width: 140,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'ETD',
        field: 'etd',
        type: PlutoColumnType.text(),
        width: 140,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Durum',
        field: 'status',
        type: PlutoColumnType.text(),
        width: 110,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final statusStr = rendererContext.cell.value as String;
          VisitStatus status;
          switch (statusStr) {
            case 'Limanda':
              status = VisitStatus.arrived;
              break;
            case 'Ayrıldı':
              status = VisitStatus.departed;
              break;
            case 'İptal':
              status = VisitStatus.cancelled;
              break;
            default:
              status = VisitStatus.planned;
          }
          return Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                statusStr,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _getStatusColor(status),
                ),
              ),
            ),
          );
        },
      ),
      PlutoColumn(
        title: 'İşlemler',
        field: 'actions',
        type: PlutoColumnType.text(),
        width: 140,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final visitId = rendererContext.row.cells['id']?.value as int;
          final statusStr = rendererContext.row.cells['status']?.value as String;
          
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (statusStr == 'Planlandı')
                IconButton(
                  icon: const Icon(Icons.login, size: 18),
                  color: AppTheme.success,
                  onPressed: () => _updateStatus(visitId, VisitStatus.arrived),
                  tooltip: 'Limana Vardı',
                ),
              if (statusStr == 'Limanda')
                IconButton(
                  icon: const Icon(Icons.logout, size: 18),
                  color: AppTheme.warning,
                  onPressed: () => _updateStatus(visitId, VisitStatus.departed),
                  tooltip: 'Limandan Ayrıldı',
                ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                color: AppTheme.accent,
                onPressed: () => _showVisitDialog(visitId: visitId),
                tooltip: 'Düzenle',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                color: AppTheme.error,
                onPressed: () => _confirmDelete(visitId),
                tooltip: 'Sil',
              ),
            ],
          );
        },
      ),
    ];
  }

  List<PlutoRow> _buildRows() {
    return _visits.map((visit) {
      return PlutoRow(
        cells: {
          'id': PlutoCell(value: visit.id),
          'ship_name': PlutoCell(value: visit.shipName ?? 'Bilinmiyor'),
          'port_name': PlutoCell(value: visit.portName ?? 'Bilinmiyor'),
          'eta': PlutoCell(value: _formatDateTime(visit.eta)),
          'etd': PlutoCell(value: _formatDateTime(visit.etd)),
          'status': PlutoCell(value: _getStatusText(visit.status)),
          'actions': PlutoCell(value: ''),
        },
      );
    }).toList();
  }

  Future<void> _updateStatus(int visitId, VisitStatus newStatus) async {
    try {
      await updateShipVisitStatus(id: visitId, status: newStatus);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Durum güncellendi: ${_getStatusText(newStatus)}'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  Future<void> _showVisitDialog({int? visitId}) async {
    ShipVisit? existingVisit;
    if (visitId != null) {
      try {
        existingVisit = await getShipVisitById(id: visitId);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ziyaret yüklenemedi: $e')),
          );
        }
        return;
      }
    }

    if (!mounted) return;

    int? selectedShipId = existingVisit?.shipId;
    int? selectedPortId = existingVisit?.portId;
    DateTime etaDate = existingVisit != null 
        ? DateTime.parse(existingVisit.eta)
        : DateTime.now().add(const Duration(days: 1));
    DateTime etdDate = existingVisit != null 
        ? DateTime.parse(existingVisit.etd)
        : DateTime.now().add(const Duration(days: 3));
    final agentController = TextEditingController(text: existingVisit?.agentInfo ?? '');
    final notesController = TextEditingController(text: existingVisit?.notes ?? '');

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            visitId == null ? 'Yeni Gemi Ziyareti' : 'Ziyaret Düzenle',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ship Dropdown
                  Text('Gemi *', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.secondaryText)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: selectedShipId,
                    decoration: const InputDecoration(
                      hintText: 'Gemi seçin',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: _ships.map((ship) {
                      return DropdownMenuItem(
                        value: ship.id,
                        child: Text('${ship.name} (${ship.imoNumber})'),
                      );
                    }).toList(),
                    onChanged: (v) => setDialogState(() => selectedShipId = v),
                  ),
                  const SizedBox(height: 16),
                  // Port Dropdown
                  Text('Liman *', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.secondaryText)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: selectedPortId,
                    decoration: const InputDecoration(
                      hintText: 'Liman seçin',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: _ports.map((port) {
                      return DropdownMenuItem(
                        value: port.id,
                        child: Text('${port.name} (${port.country})'),
                      );
                    }).toList(),
                    onChanged: (v) => setDialogState(() => selectedPortId = v),
                  ),
                  const SizedBox(height: 16),
                  // ETA
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ETA (Tahmini Varış) *', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.secondaryText)),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: etaDate,
                                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (date != null) {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.fromDateTime(etaDate),
                                  );
                                  if (time != null) {
                                    setDialogState(() {
                                      etaDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                                    });
                                  }
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppTheme.border),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 18),
                                    const SizedBox(width: 8),
                                    Text(_formatDateTime(etaDate.toIso8601String())),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ETD (Tahmini Ayrılış) *', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.secondaryText)),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: etdDate,
                                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (date != null) {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.fromDateTime(etdDate),
                                  );
                                  if (time != null) {
                                    setDialogState(() {
                                      etdDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                                    });
                                  }
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppTheme.border),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 18),
                                    const SizedBox(width: 8),
                                    Text(_formatDateTime(etdDate.toIso8601String())),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: agentController,
                    decoration: const InputDecoration(
                      labelText: 'Acenta Bilgisi',
                      hintText: 'Acenta adı ve iletişim',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notlar',
                      hintText: 'Ek bilgiler...',
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedShipId == null || selectedPortId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gemi ve liman seçin')),
                  );
                  return;
                }

                try {
                  if (visitId == null) {
                    await createShipVisit(
                      visit: CreateShipVisitRequest(
                        shipId: selectedShipId!,
                        portId: selectedPortId!,
                        eta: etaDate.toUtc().toIso8601String(),
                        etd: etdDate.toUtc().toIso8601String(),
                        agentInfo: agentController.text.isEmpty ? null : agentController.text,
                        notes: notesController.text.isEmpty ? null : notesController.text,
                      ),
                    );
                  } else {
                    await updateShipVisit(
                      id: visitId,
                      visit: UpdateShipVisitRequest(
                        portId: selectedPortId,
                        eta: etaDate.toUtc().toIso8601String(),
                        etd: etdDate.toUtc().toIso8601String(),
                        agentInfo: agentController.text.isEmpty ? null : agentController.text,
                        notes: notesController.text.isEmpty ? null : notesController.text,
                      ),
                    );
                  }
                  if (mounted) {
                    Navigator.pop(context);
                    _loadData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(visitId == null ? 'Ziyaret oluşturuldu' : 'Ziyaret güncellendi'),
                        backgroundColor: AppTheme.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Hata: $e')),
                    );
                  }
                }
              },
              child: Text(visitId == null ? 'Oluştur' : 'Güncelle'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(int visitId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ziyareti Sil', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        content: const Text('Bu ziyareti silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await deleteShipVisit(id: visitId);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ziyaret silindi'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(
                bottom: BorderSide(color: AppTheme.border),
              ),
            ),
            child: Row(
              children: [
                // Title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gemi Ziyaretleri',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_visits.length} ziyaret ${_showUpcomingOnly ? "(yaklaşan)" : "(tümü)"}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                // Actions
                Row(
                  children: [
                    // Upcoming Toggle
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _showUpcomingOnly,
                            onChanged: (v) {
                              setState(() => _showUpcomingOnly = v ?? true);
                              _loadData();
                            },
                          ),
                          Text(
                            'Sadece Yaklaşanlar',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppTheme.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: _loadData,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Yenile',
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _showVisitDialog(),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Yeni Ziyaret'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
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
            Icon(Icons.error_outline, size: 48, color: AppTheme.error),
            const SizedBox(height: 16),
            Text('Hata: $_error', style: GoogleFonts.inter(color: AppTheme.error)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: const Text('Tekrar Dene')),
          ],
        ),
      );
    }

    if (_visits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule, size: 64, color: AppTheme.secondaryText.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              _showUpcomingOnly ? 'Yaklaşan ziyaret yok' : 'Henüz ziyaret kaydı yok',
              style: GoogleFonts.inter(
                fontSize: 18,
                color: AppTheme.secondaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Yeni bir ziyaret ekleyerek başlayın',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.secondaryText.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showVisitDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Ziyaret Ekle'),
            ),
          ],
        ),
      );
    }

    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: PlutoGrid(
              columns: _buildColumns(),
              rows: _buildRows(),
              onLoaded: (event) {
                _stateManager = event.stateManager;
              },
              configuration: PlutoGridConfiguration(
                style: PlutoGridStyleConfig(
                  gridBackgroundColor: AppTheme.surface,
                  rowColor: AppTheme.surface,
                  activatedColor: AppTheme.accent.withOpacity(0.1),
                  activatedBorderColor: AppTheme.accent,
                  gridBorderColor: AppTheme.border,
                  borderColor: AppTheme.border,
                  columnTextStyle: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryText,
                  ),
                  cellTextStyle: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.primaryText,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _visits.length,
        itemBuilder: (context, index) {
          final visit = _visits[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getStatusColor(visit.status).withOpacity(0.1),
                child: Icon(
                  Icons.directions_boat,
                  color: _getStatusColor(visit.status),
                ),
              ),
              title: Text(
                visit.shipName ?? 'Bilinmiyor',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${visit.portName ?? '-'} • ${_getStatusText(visit.status)}',
                    style: GoogleFonts.inter(color: AppTheme.secondaryText),
                  ),
                  Text(
                    'ETA: ${_formatDateTime(visit.eta)}',
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.secondaryText),
                  ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _showVisitDialog(visitId: visit.id),
              ),
            ),
          );
        },
      );
    }
  }
}

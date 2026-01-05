import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../src/rust/api.dart';
import '../../../../src/rust/models.dart';

class PortListPage extends StatefulWidget {
  const PortListPage({super.key});

  @override
  State<PortListPage> createState() => _PortListPageState();
}

class _PortListPageState extends State<PortListPage> {
  List<Port> _ports = [];
  bool _isLoading = true;
  String? _error;
  bool _showInactive = false;

  late PlutoGridStateManager _stateManager;

  @override
  void initState() {
    super.initState();
    _loadPorts();
  }

  Future<void> _loadPorts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final ports = _showInactive 
          ? await getAllPorts()
          : await getActivePorts();
      setState(() {
        _ports = ports;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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
        title: 'Liman Adı',
        field: 'name',
        type: PlutoColumnType.text(),
        width: 180,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Ülke',
        field: 'country',
        type: PlutoColumnType.text(),
        width: 80,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final country = rendererContext.cell.value as String;
          return Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                country,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.accent,
                ),
              ),
            ),
          );
        },
      ),
      PlutoColumn(
        title: 'Şehir',
        field: 'city',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Saat Dilimi',
        field: 'timezone',
        type: PlutoColumnType.text(),
        width: 160,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Durum',
        field: 'is_active',
        type: PlutoColumnType.text(),
        width: 100,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final isActive = rendererContext.cell.value == 'Aktif';
          return Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isActive 
                    ? AppTheme.success.withOpacity(0.1)
                    : AppTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                rendererContext.cell.value,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isActive ? AppTheme.success : AppTheme.error,
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
        width: 120,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final portId = rendererContext.row.cells['id']?.value as int;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                color: AppTheme.accent,
                onPressed: () => _showPortDialog(portId: portId),
                tooltip: 'Düzenle',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                color: AppTheme.error,
                onPressed: () => _confirmDelete(portId),
                tooltip: 'Sil',
              ),
            ],
          );
        },
      ),
    ];
  }

  // Yaygın saat dilimleri listesi
  static const List<String> _timezones = [
    'Europe/Istanbul',
    'Europe/London',
    'Europe/Paris',
    'Europe/Berlin',
    'Europe/Rome',
    'Europe/Madrid',
    'Europe/Athens',
    'Europe/Moscow',
    'Asia/Dubai',
    'Asia/Singapore',
    'Asia/Shanghai',
    'Asia/Tokyo',
    'Asia/Seoul',
    'America/New_York',
    'America/Los_Angeles',
    'America/Chicago',
    'America/Sao_Paulo',
    'Africa/Cairo',
    'Australia/Sydney',
    'UTC',
  ];

  List<PlutoRow> _buildRows() {
    return _ports.map((port) {
      return PlutoRow(
        cells: {
          'id': PlutoCell(value: port.id),
          'name': PlutoCell(value: port.name),
          'country': PlutoCell(value: port.country),
          'city': PlutoCell(value: port.city ?? '-'),
          'timezone': PlutoCell(value: port.timezone),
          'is_active': PlutoCell(value: port.isActive ? 'Aktif' : 'Pasif'),
          'actions': PlutoCell(value: ''),
        },
      );
    }).toList();
  }

  Future<void> _showPortDialog({int? portId}) async {
    Port? existingPort;
    if (portId != null) {
      try {
        existingPort = await getPortById(id: portId);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Liman yüklenemedi: $e')),
          );
        }
        return;
      }
    }

    if (!mounted) return;

    final nameController = TextEditingController(text: existingPort?.name ?? '');
    final countryController = TextEditingController(text: existingPort?.country ?? 'TR');
    final cityController = TextEditingController(text: existingPort?.city ?? '');
    String selectedTimezone = existingPort?.timezone ?? 'Europe/Istanbul';
    final notesController = TextEditingController(text: existingPort?.notes ?? '');
    bool isActive = existingPort?.isActive ?? true;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            portId == null ? 'Yeni Liman' : 'Liman Düzenle',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Liman Adı *',
                      hintText: 'Örn: Tuzla Limanı',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: countryController,
                          decoration: const InputDecoration(
                            labelText: 'Ülke Kodu *',
                            hintText: 'TR, US, DE...',
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: cityController,
                          decoration: const InputDecoration(
                            labelText: 'Şehir',
                            hintText: 'İstanbul',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedTimezone,
                    decoration: const InputDecoration(
                      labelText: 'Saat Dilimi *',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: _timezones.map((tz) {
                      return DropdownMenuItem(
                        value: tz,
                        child: Text(tz),
                      );
                    }).toList(),
                    onChanged: (v) => setDialogState(() => selectedTimezone = v ?? 'Europe/Istanbul'),
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
                  if (portId != null) ...[
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: Text('Aktif', style: GoogleFonts.inter()),
                      value: isActive,
                      onChanged: (v) => setDialogState(() => isActive = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
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
                if (nameController.text.isEmpty || 
                    countryController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Zorunlu alanları doldurun')),
                  );
                  return;
                }

                try {
                  if (portId == null) {
                    await createPort(
                      port: CreatePortRequest(
                        name: nameController.text,
                        country: countryController.text,
                        city: cityController.text.isEmpty ? null : cityController.text,
                        timezone: selectedTimezone,
                        latitude: null,
                        longitude: null,
                        notes: notesController.text.isEmpty ? null : notesController.text,
                      ),
                    );
                  } else {
                    await updatePort(
                      id: portId,
                      port: UpdatePortRequest(
                        name: nameController.text,
                        country: countryController.text,
                        city: cityController.text.isEmpty ? null : cityController.text,
                        timezone: selectedTimezone,
                        latitude: null,
                        longitude: null,
                        notes: notesController.text.isEmpty ? null : notesController.text,
                        isActive: isActive,
                      ),
                    );
                  }
                  if (mounted) {
                    Navigator.pop(context);
                    _loadPorts();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(portId == null ? 'Liman oluşturuldu' : 'Liman güncellendi'),
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
              child: Text(portId == null ? 'Oluştur' : 'Güncelle'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(int portId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Limanı Sil', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        content: const Text('Bu limanı silmek istediğinizden emin misiniz?'),
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
        await deletePort(id: portId);
        _loadPorts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Liman silindi'),
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
                        'Limanlar',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_ports.length} liman kayıtlı',
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
                    // Show Inactive Toggle
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
                            value: _showInactive,
                            onChanged: (v) {
                              setState(() => _showInactive = v ?? false);
                              _loadPorts();
                            },
                          ),
                          Text(
                            'Pasif Limanları Göster',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppTheme.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Refresh Button
                    IconButton(
                      onPressed: _loadPorts,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Yenile',
                    ),
                    const SizedBox(width: 12),
                    // Add Button
                    ElevatedButton.icon(
                      onPressed: () => _showPortDialog(),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Yeni Liman'),
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
            ElevatedButton(onPressed: _loadPorts, child: const Text('Tekrar Dene')),
          ],
        ),
      );
    }

    if (_ports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: AppTheme.secondaryText.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'Henüz liman kaydı yok',
              style: GoogleFonts.inter(
                fontSize: 18,
                color: AppTheme.secondaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Yeni bir liman ekleyerek başlayın',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.secondaryText.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showPortDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Liman Ekle'),
            ),
          ],
        ),
      );
    }

    // Desktop: PlutoGrid, Mobile: ListView
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
        itemCount: _ports.length,
        itemBuilder: (context, index) {
          final port = _ports[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.accent.withOpacity(0.1),
                child: Text(
                  port.country,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accent,
                  ),
                ),
              ),
              title: Text(port.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              subtitle: Text(
                '${port.city ?? ''} • ${port.timezone}',
                style: GoogleFonts.inter(color: AppTheme.secondaryText),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _showPortDialog(portId: port.id),
              ),
            ),
          );
        },
      );
    }
  }
}

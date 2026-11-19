import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'farms_screen.dart';
import 'lots_screen.dart';
import 'historial_screen.dart';
import 'irrigation_screen.dart';
import 'crops_screen.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import 'assistant_screen.dart';
import 'admin_dashboard_screen.dart';
import 'login_screen.dart';
import 'bluetooth_connect_screen.dart';
import 'alerts_screen.dart';

typedef AdminRecord = Map<String, String>;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = 'Usuario';
  String userRole = 'productor'; // 'admin', 'productor', 'consulta'
  bool _isOfflineModeActive = true;
  List<AdminRecord> _adminDbRecords = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final currentUser = await AuthService.getCurrentUser();
    if (currentUser != null) {
      setState(() {
        userName = currentUser.name;
        userRole = currentUser.role.toLowerCase();
      });
    } else {
      setState(() {
        userName = 'Administrador General';
        userRole = 'admin';
      });
    }

    if (userRole == 'admin') {
      await _loadAdminDatabaseRecords();
    }
  }

  Future<void> _loadAdminDatabaseRecords() async {
    try {
      final farmsBox = Hive.isBoxOpen('farms') ? Hive.box('farms') : await Hive.openBox('farms');
      final lotsBox = Hive.isBoxOpen('lots') ? Hive.box('lots') : await Hive.openBox('lots');
      final cropsBox = Hive.isBoxOpen('crops') ? Hive.box('crops') : await Hive.openBox('crops');

      final AdminRecord ownerMap = {};
      String defaultProducerName = 'Productor Registrado';

      for (var u in DatabaseService.users.values) {
        if (u is Map) {
          final email = (u['email'] ?? '').toString().trim().toLowerCase();
          final name = (u['name'] ?? '').toString().trim();
          final role = (u['role'] ?? '').toString().trim().toLowerCase();
          if (email.isNotEmpty && name.isNotEmpty) {
            ownerMap[email] = name;
          }
          if (role == 'productor' && name.isNotEmpty) {
            defaultProducerName = name;
          }
        }
      }

      String resolveOwner(dynamic item) {
        if (item is Map) {
          final explicitName = (item['ownerName'] ??
                  item['propietario'] ??
                  item['producerName'] ??
                  item['userName'] ??
                  '')
              .toString()
              .trim();
          if (explicitName.isNotEmpty) return explicitName;

          final emailKey = (item['ownerEmail'] ?? item['userEmail'] ?? item['email'] ?? '')
              .toString()
              .trim()
              .toLowerCase();
          if (emailKey.isNotEmpty && ownerMap.containsKey(emailKey)) {
            return ownerMap[emailKey]!;
          }
        }
        return defaultProducerName;
      }

      String resolveName(dynamic item, List<String> keys) {
        if (item is String) return item.trim();
        if (item is Map) {
          for (final k in keys) {
            if (item[k] != null && item[k].toString().trim().isNotEmpty) {
              return item[k].toString().trim();
            }
          }
        }
        return item?.toString().trim() ?? 'Sin nombre';
      }

      final List<AdminRecord> records = [];

      for (var f in farmsBox.values) {
        records.add({
          'tipo': 'Finca',
          'nombre': resolveName(f, ['name', 'nombre', 'title']),
          'detalle': f is Map ? (f['location'] ?? f['ubicacion'] ?? 'Principal').toString() : 'Registrada',
          'propietario': resolveOwner(f),
        });
      }

      for (var l in lotsBox.values) {
        records.add({
          'tipo': 'Lote',
          'nombre': resolveName(l, ['name', 'nombre', 'loteName']),
          'detalle': l is Map ? (l['farmName'] ?? l['finca'] ?? 'Asociado').toString() : 'Registrado',
          'propietario': resolveOwner(l),
        });
      }

      for (var c in cropsBox.values) {
        records.add({
          'tipo': 'Cultivo',
          'nombre': resolveName(c, ['name', 'nombre', 'crop', 'cultivo']),
          'detalle': c is Map ? (c['variety'] ?? c['variedad'] ?? c['lote'] ?? 'Activo').toString() : 'Activo',
          'propietario': resolveOwner(c),
        });
      }

      if (mounted) {
        setState(() {
          _adminDbRecords = records;
        });
      }
    } catch (e) {
      debugPrint('Error cargando tabla de base de datos Admin: $e');
    }
  }

  void _openAlertsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AlertsScreen(
          currentHumidity: 72.0,
          isIrrigating: true,
        ),
      ),
    );
  }

  void _showAccountDialog() async {
    final currentUser = await AuthService.getCurrentUser();
    String? farmCode;
    if (currentUser != null && currentUser.role.toLowerCase() == 'productor') {
      final userData = DatabaseService.users.get(currentUser.email.trim().toLowerCase());
      if (userData is Map) {
        farmCode = userData['farmCode'];
      } else {
        farmCode = currentUser.farmCode;
      }
    }
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Cuenta y Sesión',
          style: TextStyle(
            color: Color(0xFF1B4332),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Usuario: $userName', style: const TextStyle(fontSize: 13, color: Colors.black87)),
            const SizedBox(height: 4),
            Text('Rol: ${userRole.toUpperCase()}', style: const TextStyle(fontSize: 13, color: Colors.black87)),
            if (farmCode != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2E7D32)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Tu Código de Finca (Para Consulta):',
                      style: TextStyle(fontSize: 11, color: Color(0xFF2D6A4F), fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      farmCode,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B4332),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Text('¿Deseas cerrar sesión?', style: TextStyle(fontSize: 13, color: Colors.black87)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              await AuthService.logout();
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
            child: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 800;
    final bool isAdmin = userRole == 'admin';
    final bool isConsulta = userRole == 'consulta';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F5),
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 480 : double.infinity,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 0. IMAGEN SUPERIOR DECORATIVA DE FONDO
                  Container(
                    height: 130,
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1B4332), Color(0xFF2E7D32), Color(0xFF52B788)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1B4332).withOpacity(0.18),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      image: const DecorationImage(
                        image: NetworkImage(
                          'https://images.unsplash.com/photo-1500382017468-9049fed747ef?auto=format&fit=crop&w=1000&q=80',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF1B4332).withOpacity(0.75),
                            const Color(0xFF2E7D32).withOpacity(0.25),
                          ],
                          begin: Alignment.bottomLeft,
                          end: Alignment.topRight,
                        ),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.eco_rounded, color: Colors.white, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'ESSENZA AGRO IoT',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Agricultura Inteligente y Sostenible',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 1. SALUDO Y AVATAR DINÁMICO
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF2E7D32), width: 1.5),
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: Color(0xFF2E7D32),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '¡Hola! (${userRole.toUpperCase()})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                userName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B4332),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: _openAlertsScreen,
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.notifications_none_rounded,
                                color: Color(0xFF1B4332),
                                size: 22,
                              ),
                            ),
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE63946),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 2. BARRA DE BÚSQUEDA
                  if (!isConsulta) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.search_rounded, color: Colors.grey),
                                SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      hintText: 'Buscar finca, lote o actividad...',
                                      hintStyle: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          height: 52,
                          width: 52,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 4. MÓDULOS PRINCIPALES SEGÚN ROL
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isAdmin
                            ? 'Panel de Control Maestro'
                            : (isConsulta ? 'Panel de Consulta (Solo Lectura)' : 'Gestión y Servicios'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B4332),
                        ),
                      ),
                      Text(
                        _isOfflineModeActive ? 'Offline: Activado' : 'Offline: Sincronizando',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isOfflineModeActive ? const Color(0xFF2E7D32) : Colors.orange.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // VISTA ADMINISTRADOR
                  if (isAdmin) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AdminDashboardScreen(),
                                ),
                              );
                              _loadAdminDatabaseRecords();
                            },
                            icon: const Icon(Icons.admin_panel_settings_rounded),
                            label: const Text(
                              'Gestión de Usuarios y Registros',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Actualizar tabla',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _loadAdminDatabaseRecords,
                          icon: const Icon(Icons.refresh_rounded, color: Color(0xFF2E7D32)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // TABLA DE BASE DE DATOS
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.table_chart_rounded, color: Color(0xFF2E7D32), size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Base de Datos: Fincas, Lotes y Cultivos',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Color(0xFF1B4332),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${_adminDbRecords.length} reg.',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          if (_adminDbRecords.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Center(
                                child: Text(
                                  'No hay fincas, lotes ni cultivos registrados aún.',
                                  style: TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                              ),
                            )
                          else
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F8E9)),
                                columnSpacing: 20,
                                horizontalMargin: 16,
                                columns: const [
                                  DataColumn(
                                    label: Text(
                                      'Tipo',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B4332), fontSize: 12),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Nombre',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B4332), fontSize: 12),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Propietario',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B4332), fontSize: 12),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Detalle',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B4332), fontSize: 12),
                                    ),
                                  ),
                                ],
                                rows: _adminDbRecords.map((row) {
                                  Color badgeColor = const Color(0xFF2E7D32);
                                  if (row['tipo'] == 'Lote') badgeColor = const Color(0xFF1E88E5);
                                  if (row['tipo'] == 'Cultivo') badgeColor = const Color(0xFF8E24AA);

                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: badgeColor.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            row['tipo'] ?? '',
                                            style: TextStyle(
                                              color: badgeColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          row['nombre'] ?? '',
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.person_pin, size: 14, color: Color(0xFF2E7D32)),
                                            const SizedBox(width: 4),
                                            Text(
                                              row['propietario'] ?? '',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF1B4332),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          row['detalle'] ?? '',
                                          style: const TextStyle(color: Colors.black54, fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // GRILLA PARA PRODUCTOR Y CONSULTA
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 4,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.85,
                      children: [
                        if (userRole == 'productor') ...[
                          _QuickServiceItem(
                            icon: Icons.agriculture_rounded,
                            label: 'Fincas',
                            color: const Color(0xFF2E7D32),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const FarmsScreen()),
                              );
                            },
                          ),
                          _QuickServiceItem(
                            icon: Icons.grass_rounded,
                            label: 'Lotes',
                            color: const Color(0xFF43A047),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const LotsScreen()),
                              );
                            },
                          ),
                          _QuickServiceItem(
                            icon: Icons.water_rounded,
                            label: 'Riego IoT',
                            color: const Color(0xFF1E88E5),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const BluetoothConnectionScreen()),
                              );
                            },
                          ),
                          _QuickServiceItem(
                            icon: Icons.eco_rounded,
                            label: 'Cultivos',
                            color: const Color(0xFF8E24AA),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const CropsScreen()),
                              );
                            },
                          ),
                          _QuickServiceItem(
                            icon: Icons.history_rounded,
                            label: 'Historial',
                            color: const Color(0xFF6D4C41),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const HistorialScreen(
                                    loteName: 'General',
                                    crop: 'Personal',
                                  ),
                                ),
                              );
                            },
                          ),
                          _QuickServiceItem(
                            icon: Icons.notifications_active_rounded,
                            label: 'Alertas',
                            color: const Color(0xFFE63946),
                            onTap: _openAlertsScreen,
                          ),
                          _QuickServiceItem(
                            icon: Icons.smart_toy_rounded,
                            label: 'Asistente',
                            color: const Color(0xFF00ACC1),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AssistantScreen()),
                              );
                            },
                          ),
                        ],

                        if (isConsulta) ...[
                          _QuickServiceItem(
                            icon: Icons.history_edu_rounded,
                            label: 'Historial',
                            color: const Color(0xFF546E7A),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const HistorialScreen(
                                    loteName: 'Consulta',
                                    crop: 'Vinculada',
                                  ),
                                ),
                              );
                            },
                          ),
                          _QuickServiceItem(
                            icon: Icons.water_rounded,
                            label: 'Monitoreo',
                            color: const Color(0xFF1E88E5),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const IrrigationScreen()),
                              );
                            },
                          ),
                          _QuickServiceItem(
                            icon: Icons.notifications_active_rounded,
                            label: 'Alertas',
                            color: const Color(0xFFE63946),
                            onTap: _openAlertsScreen,
                          ),
                          _QuickServiceItem(
                            icon: Icons.smart_toy_rounded,
                            label: 'Asistente IA',
                            color: const Color(0xFF00ACC1),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AssistantScreen()),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),

                  // 5. OPCIÓN INTERACTIVA DE OFFLINE FIRST (SWITCH)
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Configuración de Sincronización',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B4332),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            _isOfflineModeActive ? Icons.wifi_off_rounded : Icons.wifi_rounded,
                            color: const Color(0xFF2E7D32),
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Modo Offline First (Hive)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF1B4332),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isOfflineModeActive
                                    ? 'Operando con base de datos local'
                                    : 'Sincronizando con la nube',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isOfflineModeActive,
                          activeColor: const Color(0xFF2E7D32),
                          onChanged: (bool value) {
                            setState(() {
                              _isOfflineModeActive = value;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  value
                                      ? 'Modo Offline First activado correctamente.'
                                      : 'Modo en línea / Sincronización activada.',
                                ),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),

      // BARRA INFERIOR ADAPTADA SEGÚN ROL
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          height: 64,
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavBarIcon(icon: Icons.home_rounded, isActive: true, onTap: () {}),

                  if (isConsulta)
                    _NavBarIcon(
                      icon: Icons.water_drop_outlined,
                      isActive: false,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const IrrigationScreen()),
                        );
                      },
                    )
                  else if (isAdmin)
                    _NavBarIcon(
                      icon: Icons.table_view_rounded,
                      isActive: false,
                      onTap: _loadAdminDatabaseRecords,
                    )
                  else
                    _NavBarIcon(
                      icon: Icons.agriculture_rounded,
                      isActive: false,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const FarmsScreen()),
                        );
                      },
                    ),

                  if (!isAdmin)
                    _NavBarIcon(
                      icon: Icons.chat_bubble_outline_rounded,
                      isActive: false,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AssistantScreen()),
                        );
                      },
                    ),

                  _NavBarIcon(
                    icon: Icons.person_outline_rounded,
                    isActive: false,
                    onTap: _showAccountDialog,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickServiceItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickServiceItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B4332),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBarIcon extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavBarIcon({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2E7D32) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : Colors.grey.shade400,
          size: 24,
        ),
      ),
    );
  }
}
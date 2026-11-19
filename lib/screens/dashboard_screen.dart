import 'package:flutter/material.dart';
import 'farms_screen.dart';
import 'lots_screen.dart';
import 'add_farm_screen.dart';
import '../services/database_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String userName = 'Productor(a)';
  int farmsCount = 0;
  int lotsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Método para cargar datos dinámicos desde las cajas de Hive
  void _loadUserData() {
    final userBox = DatabaseService.users;
    if (userBox.isNotEmpty) {
      final lastUser = userBox.values.last;
      if (lastUser is Map && lastUser.containsKey('name')) {
        userName = lastUser['name'];
      }
    }

    // Contamos las fincas y lotes almacenados localmente
    farmsCount = DatabaseService.farms.length;
    lotsCount = DatabaseService.lots.length;

    setState(() {});
  }

  // Método auxiliar para refrescar al volver de otra pantalla
  Future<void> _refreshData(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
    _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'ESSENZA',
          style: TextStyle(
            color: Color(0xFF165631),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF165631),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hola, $userName 👋',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF183A25),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Gestiona tus fincas de forma inteligente offline.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 25),

            // TARJETA PRINCIPAL
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF165631),
                    Color(0xFF2E7D32),
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.eco_outlined,
                    color: Colors.white,
                    size: 35,
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Estado de tus fincas',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Todo está en orden',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Sistemas de riego IoT sincronizados localmente.',
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Resumen',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF183A25),
              ),
            ),

            const SizedBox(height: 15),

            // TARJETAS DE RESUMEN CONECTADAS A HIVE
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _refreshData(const FarmsScreen()),
                    child: _SummaryCard(
                      icon: Icons.home_work_outlined,
                      value: farmsCount.toString(),
                      label: 'Fincas',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _refreshData(const LotsScreen()),
                    child: _SummaryCard(
                      icon: Icons.grass_outlined,
                      value: lotsCount.toString(),
                      label: 'Lotes',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            const Text(
              'Accesos rápidos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF183A25),
              ),
            ),

            const SizedBox(height: 15),

            _QuickAction(
              icon: Icons.add_business_outlined,
              title: 'Agregar finca',
              subtitle: 'Registra una nueva finca',
              onTap: () => _refreshData(const AddFarmScreen()),
            ),

            const SizedBox(height: 12),

            _QuickAction(
              icon: Icons.grass_outlined,
              title: 'Gestionar lotes',
              subtitle: 'Consulta y administra tus lotes',
              onTap: () => _refreshData(const LotsScreen()),
            ),

            const SizedBox(height: 12),

            _QuickAction(
              icon: Icons.agriculture_rounded,
              title: 'Ver mis fincas',
              subtitle: 'Listado completo de terrenos',
              onTap: () => _refreshData(const FarmsScreen()),
            ),
          ],
        ),
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) {
            _refreshData(const LotsScreen());
          }
        },
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFDCEEDC),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.grass_outlined),
            selectedIcon: Icon(Icons.grass),
            label: 'Lotes',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alertas',
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _SummaryCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: const Color(0xFF2E7D32),
            size: 28,
          ),
          const SizedBox(height: 15),
          Text(
            value,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: Color(0xFF183A25),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(17),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F3E8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF183A25),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF2E7D32)),
          ],
        ),
      ),
    );
  }
}
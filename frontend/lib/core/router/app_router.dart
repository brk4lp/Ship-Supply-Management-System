import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/calendar/presentation/pages/calendar_page.dart';
import '../../features/orders/presentation/pages/order_list_page.dart';
import '../../features/orders/presentation/pages/order_detail_page.dart';
import '../../features/ships/presentation/pages/ship_list_page.dart';
import '../../features/suppliers/presentation/pages/supplier_list_page.dart';
import '../../features/supply_items/presentation/pages/supply_item_list_page.dart';
import '../widgets/main_scaffold.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/dashboard',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return MainScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/calendar',
            name: 'calendar',
            builder: (context, state) => const CalendarPage(),
          ),
          GoRoute(
            path: '/orders',
            name: 'orders',
            builder: (context, state) => const OrderListPage(),
            routes: [
              GoRoute(
                path: ':id',
                name: 'order-detail',
                builder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return OrderDetailPage(orderId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/ships',
            name: 'ships',
            builder: (context, state) => const ShipListPage(),
          ),
          GoRoute(
            path: '/suppliers',
            name: 'suppliers',
            builder: (context, state) => const SupplierListPage(),
          ),
          GoRoute(
            path: '/supply-items',
            name: 'supply-items',
            builder: (context, state) => const SupplyItemListPage(),
          ),
        ],
      ),
    ],
  );
});

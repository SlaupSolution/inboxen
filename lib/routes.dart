import 'package:flutter/material.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'perfil_page.dart';
import 'orders_page.dart';
import 'create_order_page.dart';

class AppRoutes {
  static const String initial = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String createOrder = '/create_order';
  static const String ordersList = '/orders';

  static Map<String, WidgetBuilder> routes = {
    login: (context) => LoginPage(),
    register: (context) => RegisterPage(),
    profile: (context) => PerfilPage(),
    createOrder: (context) => CreateOrderPage(),
    ordersList: (context) => OrdersPage(),
  };

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => LoginPage());
      case register:
        return MaterialPageRoute(builder: (_) => RegisterPage());
      case profile:
        return MaterialPageRoute(builder: (_) => PerfilPage());
      case createOrder:
        return MaterialPageRoute(builder: (_) => CreateOrderPage());
      case ordersList:
        return MaterialPageRoute(builder: (_) => OrdersPage());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Rota não encontrada: ${settings.name}'),
            ),
          ),
        );
    }
  }
}
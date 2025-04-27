import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'frontend/theme/app_theme.dart';
import 'frontend/providers/theme_provider.dart';
import 'frontend/providers/shopping_list_provider.dart';
import 'frontend/screens/login_screen.dart';
import 'frontend/screens/register_screen.dart';
import 'frontend/screens/home_screen.dart';
import 'frontend/screens/add_item_screen.dart';

void main() {
  runApp(const ToBuyApp());
}

class ToBuyApp extends StatelessWidget {
  const ToBuyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ShoppingListProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'ToBuy',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: '/login',
            routes: {
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/home': (context) => const HomeScreen(),
              '/add-item': (context) => const AddItemScreen(),
            },
          );
        },
      ),
    );
  }
}
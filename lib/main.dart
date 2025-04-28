import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';
import 'package:background_fetch/background_fetch.dart';
import 'frontend/theme/app_theme.dart';
import 'frontend/providers/theme_provider.dart';
import 'frontend/providers/shopping_list_provider.dart';
import 'frontend/screens/login_screen.dart';
import 'frontend/screens/register_screen.dart';
import 'frontend/screens/home_screen.dart';
import 'frontend/screens/add_item_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialiser background_fetch
  BackgroundFetch.configure(
    BackgroundFetchConfig(
      minimumFetchInterval: 15, // Toutes les 15 minutes
      stopOnTerminate: false,
      enableHeadless: true,
      requiresBatteryNotLow: false,
      requiresCharging: false,
      requiresStorageNotLow: false,
      requiresDeviceIdle: false,
      requiredNetworkType: NetworkType.ANY,
    ),
    (String taskId) async {
      // Tâche en arrière-plan
      final provider = ShoppingListProvider();
      final message = provider.list.items.isEmpty ? 'Aucun article' : '${provider.list.items.length} article(s)';
      await HomeWidget.saveWidgetData<String>('title', 'ToBuy Widget');
      await HomeWidget.saveWidgetData<String>('message', message);
      await HomeWidget.updateWidget(name: 'ToBuyWidget', androidName: 'ToBuyWidget');
      BackgroundFetch.finish(taskId);
    },
  ).then((int status) {
    print('[BackgroundFetch] configure success: $status');
  }).catchError((e) {
    print('[BackgroundFetch] configure ERROR: $e');
  });
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
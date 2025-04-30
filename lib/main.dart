import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tobuy/frontend/screens/home_screen.dart';
import 'package:tobuy/frontend/screens/add_item_screen.dart';
import 'package:tobuy/frontend/screens/edit_item_screen.dart';
import 'package:tobuy/models/shopping_item.dart';
import 'package:tobuy/frontend/theme/app_theme.dart';
import 'package:tobuy/data/local_repository.dart';
import 'package:tobuy/frontend/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurer BackgroundFetch
  await BackgroundFetch.configure(
    BackgroundFetchConfig(
      minimumFetchInterval: 15,
      stopOnTerminate: false,
      enableHeadless: true,
      requiresBatteryNotLow: false,
      requiresCharging: false,
      requiresStorageNotLow: false,
      requiresDeviceIdle: false,
      requiredNetworkType: NetworkType.ANY,
    ),
    (String taskId) async {
      final repo = LocalRepository();
      final user = await repo.getUser();
      final lists = await repo.getLists(user?.id ?? '');
      final totalItems = lists.fold<int>(0, (sum, list) => sum + list.items.length);
      final message = totalItems == 0 ? 'Aucun article' : '$totalItems article(s)';
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

  runApp(const ProviderScope(child: ToBuyApp()));
}

class ToBuyApp extends ConsumerWidget {
  const ToBuyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'ToBuy',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('fr', ''),
      ],
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/add-item': (context) => const AddItemScreen(),
        '/edit-item': (context) => EditItemScreen(
              item: ModalRoute.of(context)!.settings.arguments as ShoppingItem,
            ),
      },
    );
  }
}
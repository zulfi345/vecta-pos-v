import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/di/app_providers.dart';
import '../../../core/i18n/app_lang.dart';
import '../../providers/main/main_notifier.dart';
import '../welcome/welcome_screen.dart';
import '../../widgets/expiry_banner.dart';
class MainScreen extends ConsumerStatefulWidget {
final Widget child;
const MainScreen({
super.key,
required this.child,
});
@override
ConsumerState<MainScreen> createState() => _MainScreenState();
}
class _MainScreenState extends ConsumerState<MainScreen> {
@override
void initState() {
super.initState();
WidgetsBinding.instance.addPostFrameCallback((_) async {
await ref.read(mainNotifierProvider.notifier).initMainProvider();
});
}
@override
Widget build(BuildContext context) {
final isLoaded = ref.watch(mainNotifierProvider.select((p) => p.isLoaded));
final isHasInternet = ref.watch(mainNotifierProvider.select((p) => p.isHasInternet));
final user = ref.watch(mainNotifierProvider.select((p) => p.user));
ref.watch(languageProvider);
// Display RootScreen when data is being load
if (!isLoaded) {
return const WelcomeScreen();
}
// User data might still null for the first time app open or login without internet connection
// So, throw error with a first time internet error message then the [ErrorScreen] will be shown
if (isLoaded && user == null && !isHasInternet) {
throw Exception(
'No Internet connection! Internet connection is required for the first time app open or user login',
);
}
return Scaffold(
body: widget.child,
bottomNavigationBar: Column(
mainAxisSize: MainAxisSize.min,
children: [
const ExpiryBanner(),
NavigationBar(
selectedIndex: _calculateSelectedIndex(),
onDestinationSelected: _onItemTapped,
height: 66,
labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
destinations: [
NavigationDestination(
icon: const Icon(Icons.storefront_outlined),
selectedIcon: const Icon(Icons.storefront_rounded),
label: tr('Home'),
),
NavigationDestination(
icon: const Icon(Icons.inventory_2_outlined),
selectedIcon: const Icon(Icons.inventory_2_rounded),
label: tr('Products'),
),
NavigationDestination(
icon: const Icon(Icons.insights_outlined),
selectedIcon: const Icon(Icons.insights_rounded),
label: tr('Reports'),
),
NavigationDestination(
icon: const Icon(Icons.receipt_long_outlined),
selectedIcon: const Icon(Icons.receipt_long_rounded),
label: tr('Transactions'),
),
NavigationDestination(
icon: const Icon(Icons.person_outline_rounded),
selectedIcon: const Icon(Icons.person_rounded),
label: tr('Account'),
),
],
),
]),
);
}
int _calculateSelectedIndex() {
final String location = ref.read(appRoutesProvider).router.state.uri.path;
if (location.startsWith('/home')) {
return 0;
}
if (location.startsWith('/products')) {
return 1;
}
if (location.startsWith('/reports')) {
return 2;
}
if (location.startsWith('/transactions')) {
return 3;
}
if (location.startsWith('/account')) {
return 4;
}
return 0;
}
void _onItemTapped(int index) {
final router = ref.read(appRoutesProvider).router;
switch (index) {
case 0:
router.go('/home');
case 1:
router.go('/products');
case 2:
router.go('/reports');
case 3:
router.go('/transactions');
case 4:
router.go('/account');
}
}
}

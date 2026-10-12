import 'package:app_image/app_image.dart';
import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/i18n/app_lang.dart';
import '../../../core/i18n/tr_text.dart';
import '../../../core/themes/app_sizes.dart';
import '../../providers/auth/auth_notifier.dart';
import '../../providers/main/main_notifier.dart';
import '../../providers/theme/theme_notifier.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/ui_kit.dart';
class AccountScreen extends ConsumerWidget {
const AccountScreen({super.key});
@override
Widget build(BuildContext context, WidgetRef ref) {
ref.watch(languageProvider);
return Scaffold(
appBar: AppBar(title: const Text('Account')),
body: ListView(
padding: const EdgeInsets.fromLTRB(AppSizes.padding, 4, AppSizes.padding, 32),
children: [
const _UserInfo(),
const SectionTitle('Operations'),
MenuTile(
icon: Icons.point_of_sale_rounded,
title: tr('Cashier Shift'),
subtitle: tr('Open / close cashier, cash drawer'),
color: Colors.green,
onTap: () => context.go('/account/cashier'),
),
MenuTile(
icon: Icons.event_available_rounded,
title: tr('Attendance'),
subtitle: tr('Employee check in / check out'),
color: Colors.blue,
onTap: () => context.go('/account/attendance'),
),
MenuTile(
icon: Icons.badge_rounded,
title: tr('Employee Management'),
subtitle: tr('Add and manage your staff'),
color: Colors.indigo,
onTap: () => context.go('/account/employees'),
),
if (ref.watch(authNotifierProvider.select((s) => s.isOwner)))
MenuTile(
icon: Icons.pin_rounded,
title: 'Akses Karyawan (PIN)',
subtitle: 'Buat PIN login karyawan, lepas HP',
color: Colors.deepPurple,
onTap: () => context.go('/account/staff-access'),
),
const SizedBox(height: 8),
const SectionTitle('Finance'),
MenuTile(
icon: Icons.calculate_rounded,
title: tr('Cost of Goods (HPP)'),
subtitle: tr('Calculate cost and selling price'),
color: Colors.deepOrange,
onTap: () => context.go('/account/hpp'),
),
MenuTile(
icon: Icons.outbox_rounded,
title: tr('Expenses'),
subtitle: tr('Record daily business expenses'),
color: Colors.redAccent,
onTap: () => context.go('/account/expenses'),
),
const SizedBox(height: 8),
const SectionTitle('Inventory & Insights'),
MenuTile(
icon: Icons.warning_amber_rounded,
title: tr('Low Stock'),
subtitle: tr('Products that need restocking'),
color: Colors.orange,
onTap: () => context.go('/account/low-stock'),
),
MenuTile(
icon: Icons.emoji_events_rounded,
title: tr('Best Sellers'),
subtitle: tr('Your most sold products'),
color: Colors.amber.shade800,
onTap: () => context.go('/account/best-sellers'),
),
const SizedBox(height: 8),
const SectionTitle('Settings'),
MenuTile(
icon: Icons.translate_rounded,
title: tr('Language'),
subtitle: AppLang.isId ? 'Bahasa Indonesia' : 'English',
color: Colors.teal,
onTap: () => AppDialog.show(
title: 'Language',
leftButtonText: 'Close',
child: const _LanguageDialogBody(),
),
),
MenuTile(
icon: Icons.person_rounded,
title: tr('Profile'),
color: Colors.blueGrey,
onTap: () => context.go('/account/profile'),
),
MenuTile(
icon: Icons.format_paint_outlined,
title: tr('Theme'),
color: Colors.purple,
onTap: () => AppDialog.show(
title: 'Theme',
leftButtonText: 'Close',
child: const _ThemeDialogBody(),
),
),
MenuTile(
icon: Icons.print_outlined,
title: tr('Printer Settings'),
color: Colors.cyan,
onTap: () => context.go('/account/printer-settings'),
),
MenuTile(
icon: Icons.info_outline_rounded,
title: tr('About'),
color: Colors.grey,
onTap: () => context.go('/account/about'),
),
const _SignOutTile(),
],
),
);
}
}
class _UserInfo extends ConsumerWidget {
const _UserInfo();
@override
Widget build(BuildContext context, WidgetRef ref) {
final user = ref.watch(mainNotifierProvider.select((p) => p.user));
final cs = Theme.of(context).colorScheme;
return Container(
margin: const EdgeInsets.only(bottom: 18),
padding: const EdgeInsets.all(18),
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(24),
gradient: LinearGradient(
begin: Alignment.topLeft,
end: Alignment.bottomRight,
colors: [cs.primary, cs.tertiary],
),
),
child: Row(
children: [
AppImage(
image: user?.imageUrl ?? '',
width: 68,
height: 68,
borderRadius: BorderRadius.circular(100),
backgroundColor: cs.surface,
),
const SizedBox(width: 16),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
user?.name ?? '(No Name)',
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: Theme.of(context).textTheme.titleLarge?.copyWith(
fontWeight: FontWeight.w800,
color: Colors.white,
),
),
const SizedBox(height: 2),
Text(
user?.email ?? '',
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: const TextStyle(color: Colors.white70),
),
],
),
),
],
),
);
}
}
class _LanguageDialogBody extends ConsumerWidget {
const _LanguageDialogBody();
@override
Widget build(BuildContext context, WidgetRef ref) {
final lang = ref.watch(languageProvider);
Widget option(String code, String label) {
return ListTile(
contentPadding: EdgeInsets.zero,
title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
trailing: lang == code ? const Icon(Icons.check_circle_rounded, color: Colors.green) : null,
onTap: () => ref.read(languageProvider.notifier).setLanguage(code),
);
}
return Column(
mainAxisSize: MainAxisSize.min,
children: [
option('id', 'Bahasa Indonesia'),
option('en', 'English'),
],
);
}
}
class _ThemeDialogBody extends ConsumerWidget {
const _ThemeDialogBody();
@override
Widget build(BuildContext context, WidgetRef ref) {
final themeState = ref.watch(themeNotifierProvider);
return Row(
children: [
Switch(
value: !themeState.isLight,
onChanged: (val) {
ref.read(themeNotifierProvider.notifier).changeBrightness(!val);
},
),
const SizedBox(width: AppSizes.padding),
Text(
'Dark Mode',
style: Theme.of(context).textTheme.bodyLarge?.copyWith(
fontWeight: FontWeight.bold,
),
),
],
);
}
}
class _SignOutTile extends ConsumerWidget {
const _SignOutTile();
@override
Widget build(BuildContext context, WidgetRef ref) {
return MenuTile(
icon: Icons.exit_to_app_rounded,
title: tr('Sign Out'),
color: Colors.red,
onTap: () {
AppDialog.show(
title: 'Confirm',
text: 'Are you sure want to sign out?',
leftButtonText: 'Cancel',
rightButtonText: 'Sign Out',
onTapRightButton: (context) async {
context.pop();
final isSyncronizing = ref.read(mainNotifierProvider).isSyncronizing;
if (isSyncronizing) {
AppSnackBar.showError('Cannot sign out while synchronizing data is in progress. Please wait a moment.');
return;
}
final res = await AppDialog.showProgress(() async {
return ref.read(authNotifierProvider.notifier).signOut();
});
if (res.isSuccess) {
if (!context.mounted) return;
context.go('/sign-in');
} else {
AppSnackBar.showError(res.error.toString());
}
},
);
},
);
}
}

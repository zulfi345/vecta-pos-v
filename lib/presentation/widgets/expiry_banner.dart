import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/di/app_providers.dart';
import '../../core/utilities/support_contact.dart';
import '../providers/auth/auth_notifier.dart';

/// Pengingat masa aktif untuk owner: muncul saat sisa 7 hari atau kurang,
/// supaya owner sempat memperpanjang sebelum terkunci.
class ExpiryBanner extends ConsumerWidget {
  const ExpiryBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider);
    if (!auth.isAuthenticated || !auth.isOwner) return const SizedBox.shrink();

    final expiry = ref.read(accountServiceProvider).savedExpiry;
    if (expiry == null) return const SizedBox.shrink();

    final days = (expiry.difference(DateTime.now()).inMinutes / 1440).ceil();
    if (days > 7) return const SizedBox.shrink();

    final urgent = days <= 3;
    final scheme = Theme.of(context).colorScheme;
    final bg = urgent ? scheme.errorContainer : scheme.tertiaryContainer;
    final fg = urgent ? scheme.onErrorContainer : scheme.onTertiaryContainer;
    final text = days <= 0
        ? 'Masa aktif habis hari ini. Perpanjang sekarang agar tetap bisa masuk.'
        : 'Masa aktif tinggal $days hari. Perpanjang agar tidak terkunci.';

    return Material(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: fg, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                maxLines: 3,
                style: TextStyle(color: fg, fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: () => context.go('/account/subscription'),
              child: const Text('Perpanjang'),
            ),
            IconButton(
              tooltip: 'Bantuan WhatsApp',
              icon: Icon(Icons.support_agent_rounded, color: fg),
              onPressed: () => SupportContact.openWhatsApp(
                context,
                message: 'Halo, saya mau perpanjang langganan Vecta POS.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

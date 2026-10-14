import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Kontak bantuan developer.
class SupportContact {
  SupportContact._();

  /// Format internasional untuk wa.me (tanpa + dan tanpa 0 di depan).
  static const waNumber = '6285196159855';
  static const display = '0851-9615-9855';

  /// Buka chat WhatsApp developer. Bila WhatsApp tidak bisa dibuka, nomor disalin.
  static Future<void> openWhatsApp(
    BuildContext context, {
    String message = 'Halo, saya butuh bantuan Vecta POS.',
  }) async {
    final uri = Uri.parse('https://wa.me/$waNumber?text=${Uri.encodeComponent(message)}');
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened && context.mounted) {
      await Clipboard.setData(const ClipboardData(text: '085196159855'));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('WhatsApp tidak bisa dibuka. Nomor $display sudah disalin.')),
      );
    }
  }
}

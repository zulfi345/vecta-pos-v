import 'package:app_image/app_image.dart';
import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vecta_pos/core/i18n/tr_text.dart';

import '../../../../app/di/app_providers.dart';
import '../../../../core/assets/assets.dart';
import '../../../../core/themes/app_sizes.dart';
import '../../../../core/utilities/support_contact.dart';
import '../../../providers/auth/auth_notifier.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_dialog.dart';

enum _Mode { owner, register, staff }

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _email = TextEditingController();
  final _secret = TextEditingController();
  _Mode _mode = _Mode.owner;
  bool _hide = true;
  bool _expired = false;

  @override
  void dispose() {
    _email.dispose();
    _secret.dispose();
    super.dispose();
  }

  void _setMode(_Mode mode) {
    setState(() {
      _mode = mode;
      _secret.clear();
    });
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final secret = _secret.text;
    final isStaff = _mode == _Mode.staff;

    if (email.isEmpty || secret.isEmpty) {
      AppDialog.showError(error: isStaff ? 'Isi email owner dan PIN.' : 'Isi email dan sandi.');
      return;
    }
    if (!isStaff && secret.length < 6) {
      AppDialog.showError(error: 'Sandi minimal 6 karakter.');
      return;
    }

    final notifier = ref.read(authNotifierProvider.notifier);
    final res = await AppDialog.showProgress(() async {
      return switch (_mode) {
        _Mode.register => notifier.registerOwner(email, secret),
        _Mode.owner => notifier.signInOwner(email, secret),
        _Mode.staff => notifier.signInStaff(email, secret),
      };
    });

    if (!mounted) return;
    if (res.isSuccess) {
      ref.read(appRoutesProvider).router.refresh();
    } else {
      if (res.error?.toString().contains('Masa aktif') ?? false) {
        setState(() => _expired = true);
      }
      AppDialog.showError(error: res.error?.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final notice = ref.watch(authNotifierProvider.select((s) => s.notice));
    final isStaff = _mode == _Mode.staff;
    final isRegister = _mode == _Mode.register;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _WelcomeMessage(),
              const SizedBox(height: AppSizes.padding),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(value: false, label: Text('Owner')),
                  ButtonSegment<bool>(value: true, label: Text('Karyawan')),
                ],
                selected: {isStaff},
                onSelectionChanged: (s) => _setMode(s.first ? _Mode.staff : _Mode.owner),
              ),
              const SizedBox(height: AppSizes.padding),
              if (notice != null && notice.isNotEmpty) ...[
                Text(notice, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                const SizedBox(height: 12),
              ],
              if (!isStaff &&
                  (_expired || (notice?.toLowerCase().contains('langganan') ?? false)) &&
                  Supabase.instance.client.auth.currentSession != null) ...[
                OutlinedButton.icon(
                  onPressed: () => context.go('/sign-in/renew'),
                  icon: const Icon(Icons.workspace_premium_rounded),
                  label: const Text('Perpanjang langganan'),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: isStaff ? 'Email Owner' : 'Email',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _secret,
                obscureText: _hide,
                keyboardType: isStaff ? TextInputType.number : TextInputType.visiblePassword,
                decoration: InputDecoration(
                  labelText: isStaff ? 'PIN' : 'Sandi',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_hide ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _hide = !_hide),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.padding),
              AppButton(text: isRegister ? 'Daftar' : 'Masuk', onTap: _submit),
              if (!isStaff)
                TextButton(
                  onPressed: () => _setMode(isRegister ? _Mode.owner : _Mode.register),
                  child: Text(isRegister ? 'Sudah punya akun? Masuk' : 'Daftar owner baru'),
                ),
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: () => SupportContact.openWhatsApp(
                  context,
                  message: _email.text.trim().isEmpty
                      ? 'Halo, saya butuh bantuan Vecta POS.'
                      : 'Halo, saya butuh bantuan Vecta POS. Email akun: ${_email.text.trim()}',
                ),
                icon: const Icon(Icons.support_agent_rounded),
                label: Text('Bantuan WhatsApp: ${SupportContact.display}'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeMessage extends StatelessWidget {
  const _WelcomeMessage();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 270, maxHeight: 240),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Flexible(
            child: AppImage(
              image: Assets.welcome,
              imgProvider: ImgProvider.assetImage,
            ),
          ),
          const SizedBox(height: AppSizes.padding),
          Text(
            'Welcome!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Welcome to Vecta POS',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

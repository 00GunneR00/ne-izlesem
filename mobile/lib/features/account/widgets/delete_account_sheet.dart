import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/session/session_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/auth_service.dart';

/// Permanent account deletion (Google Play requires it in-app): lists what
/// goes away, asks for the password, then signs out to the login screen.
class DeleteAccountSheet extends StatefulWidget {
  const DeleteAccountSheet({super.key});

  static Future<void> show() => Get.bottomSheet(
    const DeleteAccountSheet(),
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceContainer,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
  );

  @override
  State<DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends State<DeleteAccountSheet> {
  final _password = TextEditingController();
  bool _confirmed = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthService().deleteAccount(_password.text);
      await Get.find<SessionService>().logout();
      Get.offAllNamed(AppRoutes.login);
      Get.snackbar(
        'Hesabın silindi',
        'Tüm verilerin kalıcı olarak kaldırıldı.',
      );
    } on AuthFailure catch (f) {
      if (mounted) setState(() => _error = f.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canDelete = _confirmed && _password.text.isNotEmpty && !_busy;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.primaryContainer,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Hesabı kalıcı olarak sil',
                  style: AppTextStyles.headlineMd.copyWith(fontSize: 20),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Bu işlem geri alınamaz. Şunlar silinir: profilin, kütüphanen ve '
              'puanların, listelerin, planların, yorumların, arkadaşlıkların, '
              'grup üyeliklerin ve kurduğun gruplar, bildirimlerin.',
              style: AppTextStyles.bodyMd.copyWith(fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _password,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (_) => setState(() => _error = null),
              decoration: InputDecoration(
                labelText: 'Şifren',
                errorText: _error,
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
              ),
            ),
            CheckboxListTile(
              value: _confirmed,
              onChanged: (v) => setState(() => _confirmed = v ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.primaryContainer,
              title: Text(
                'Verilerimin kalıcı olarak silineceğini anlıyorum.',
                style: AppTextStyles.bodyMd.copyWith(fontSize: 14),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                ),
                onPressed: canDelete ? _delete : null,
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Hesabımı Sil'),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _busy ? null : Get.back,
                child: const Text('Vazgeç'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

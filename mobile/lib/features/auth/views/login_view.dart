import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/glass_container.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/cinematic_background.dart';

class LoginView extends GetView<AuthController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    return Scaffold(
      body: CinematicBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  children: [
                    Text('Ne İzlesem?',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.displayLg.copyWith(color: AppColors.primaryContainer)),
                    const SizedBox(height: AppSpacing.xl),
                    GlassContainer(
                      opacity: 0.5,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.outline),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Form(
                          key: formKey,
                          child: Column(
                            children: [
                              Text('Hoş Geldiniz', style: AppTextStyles.headlineMd),
                              const SizedBox(height: AppSpacing.md),
                              AuthTextField(
                                controller: emailController,
                                hint: 'E-posta Adresi',
                                icon: Icons.mail_outline,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) => (v == null || !v.contains('@')) ? 'Geçerli bir e-posta gir' : null,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              AuthTextField(
                                controller: passwordController,
                                hint: 'Şifre',
                                icon: Icons.lock_outline,
                                obscureText: true,
                                validator: (v) => (v == null || v.isEmpty) ? 'Şifreni gir' : null,
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: controller.notifyLoginNotReady,
                                  child: Text('Şifremi Unuttum', style: AppTextStyles.labelSm.copyWith(color: AppColors.secondary)),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Obx(() => SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                      onPressed: controller.isSubmitting.value
                                          ? null
                                          : () {
                                              if (formKey.currentState!.validate()) {
                                                controller.login(email: emailController.text.trim());
                                              }
                                            },
                                      icon: controller.isSubmitting.value
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                            )
                                          : const Icon(Icons.arrow_forward, size: 20),
                                      label: const Text('Giriş Yap'),
                                    ),
                                  )),
                              const SizedBox(height: AppSpacing.md),
                              Row(
                                children: [
                                  const Expanded(child: Divider(color: AppColors.outline)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                                    child: Text('VEYA', style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
                                  ),
                                  const Expanded(child: Divider(color: AppColors.outline)),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: controller.notifyLoginNotReady,
                                  icon: const Icon(Icons.g_mobiledata, size: 24),
                                  label: const Text('Google ile Giriş Yap'),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: controller.notifyLoginNotReady,
                                  icon: const Icon(Icons.apple, size: 20),
                                  label: const Text('Apple ile Giriş Yap'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Hesabın yok mu? ', style: AppTextStyles.bodyMd),
                        GestureDetector(
                          onTap: () => Get.offNamed(AppRoutes.register),
                          child: Text('Kayıt Ol', style: AppTextStyles.bodyMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

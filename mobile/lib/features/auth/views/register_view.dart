import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/glass_container.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/cinematic_background.dart';

class RegisterView extends GetView<AuthController> {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final usernameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();

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
                        style: AppTextStyles.displayLg.copyWith(color: AppColors.primary)),
                    const SizedBox(height: AppSpacing.xs),
                    Text('Sinematik Macerana Başla',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
                    const SizedBox(height: AppSpacing.xl),
                    GlassContainer(
                      tint: AppColors.surfaceContainer,
                      opacity: 0.6,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.outline),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Form(
                          key: formKey,
                          child: Column(
                            children: [
                              AuthTextField(
                                controller: nameController,
                                hint: 'Ad Soyad',
                                icon: Icons.person_outline,
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Ad soyad gir' : null,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              AuthTextField(
                                controller: usernameController,
                                hint: 'Kullanıcı Adı',
                                icon: Icons.alternate_email,
                                validator: (v) {
                                  final value = v?.trim() ?? '';
                                  if (!RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(value)) {
                                    return '3-20 karakter, boşluksuz (harf/rakam/_)';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppSpacing.sm),
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
                                validator: (v) => (v == null || v.length < 6) ? 'En az 6 karakter' : null,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              AuthTextField(
                                controller: confirmController,
                                hint: 'Şifreyi Onayla',
                                icon: Icons.lock_outline,
                                obscureText: true,
                                validator: (v) => (v != passwordController.text) ? 'Şifreler eşleşmiyor' : null,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Obx(() => SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                      onPressed: controller.isSubmitting.value
                                          ? null
                                          : () {
                                              if (formKey.currentState!.validate()) {
                                                controller.register(
                                                  name: nameController.text.trim(),
                                                  email: emailController.text.trim(),
                                                  username: usernameController.text.trim(),
                                                );
                                              }
                                            },
                                      icon: controller.isSubmitting.value
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                            )
                                          : const Icon(Icons.arrow_forward, size: 20),
                                      label: const Text('Kayıt Ol'),
                                    ),
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      child: Text(
                        'Kayıt olarak Hizmet Şartları\'nı ve Gizlilik Politikası\'nı kabul etmiş olursun.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w400),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Zaten hesabın var mı? ', style: AppTextStyles.bodyMd),
                        GestureDetector(
                          onTap: () => Get.offNamed(AppRoutes.login),
                          child: Text('Giriş Yap', style: AppTextStyles.bodyMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
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

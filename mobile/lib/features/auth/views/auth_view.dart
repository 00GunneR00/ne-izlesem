import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/auth_controller.dart';
import '../widgets/poster_wall.dart';

/// Sign-in / sign-up in one animated screen: a drifting poster wall behind a
/// glowing logo and rotating taglines, and a glass card with a sliding
/// Giriş Yap | Kayıt Ol switch. Register-only fields slide in; errors shake
/// the card. Old accounts without a password land on "Şifreni belirle".
class AuthView extends StatefulWidget {
  const AuthView({super.key});

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> with TickerProviderStateMixin {
  final AuthController controller = Get.find<AuthController>();

  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordAgain = TextEditingController();
  bool _obscure = true;

  /// Field-level problems found before calling the server.
  final Map<String, String> _fieldErrors = {};

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  static const _taglines = [
    'Bu akşam ne izlesek?',
    'Arkadaşlarınla birlikte seç.',
    'Eşleş, oyla, planla.',
    'İzle, puanla, paylaş.',
  ];
  int _tagline = 0;
  late final Timer _taglineTimer = Timer.periodic(
    const Duration(milliseconds: 2800),
    (_) => setState(() => _tagline = (_tagline + 1) % _taglines.length),
  );

  late final Worker _modeWorker;
  late final Worker _errorWorker;

  @override
  void initState() {
    super.initState();
    _taglineTimer; // start rotating
    _modeWorker = ever(controller.mode, (_) {
      setState(_fieldErrors.clear);
      _passwordAgain.clear();
    });
    _errorWorker = ever(controller.errorTick, (_) => _shake.forward(from: 0));
    for (final c in [_name, _username, _email, _password, _passwordAgain]) {
      c.addListener(() {
        if (_fieldErrors.isNotEmpty || controller.error.value != null) {
          setState(_fieldErrors.clear);
          controller.clearError();
        }
      });
    }
  }

  @override
  void dispose() {
    _modeWorker.dispose();
    _errorWorker.dispose();
    _shake.dispose();
    _taglineTimer.cancel();
    _entrance.dispose();
    _glow.dispose();
    for (final c in [_name, _username, _email, _password, _passwordAgain]) {
      c.dispose();
    }
    super.dispose();
  }

  Animation<double> _stagger(double start, double end) => CurvedAnimation(
    parent: _entrance,
    curve: Interval(start, end, curve: Curves.easeOutCubic),
  );

  // ---- validation + submit ----

  bool _validate(AuthMode mode) {
    final errors = <String, String>{};
    final email = _email.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      errors['email'] = 'Geçerli bir e-posta gir.';
    }
    if (_password.text.length < 8) {
      errors['password'] = mode == AuthMode.login
          ? 'Şifreni gir.'
          : 'En az 8 karakter olmalı.';
    }
    if (mode == AuthMode.register) {
      if (_name.text.trim().isEmpty) errors['name'] = 'Adını gir.';
      if (!RegExp(
        r'^[a-z0-9_.]{3,20}$',
      ).hasMatch(_username.text.trim().toLowerCase())) {
        errors['username'] = '3–20 karakter; harf, rakam, _ ve .';
      }
    }
    if (mode == AuthMode.setPassword && _passwordAgain.text != _password.text) {
      errors['passwordAgain'] = 'Şifreler aynı değil.';
    }
    setState(() {
      _fieldErrors
        ..clear()
        ..addAll(errors);
    });
    if (errors.isNotEmpty) controller.errorTick.value++;
    return errors.isEmpty;
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final mode = controller.mode.value;
    if (!_validate(mode)) return;
    switch (mode) {
      case AuthMode.login:
        controller.login(_email.text, _password.text);
      case AuthMode.register:
        controller.register(
          name: _name.text,
          username: _username.text.toLowerCase(),
          email: _email.text,
          password: _password.text,
        );
      case AuthMode.setPassword:
        controller.setInitialPassword(_email.text, _password.text);
    }
  }

  // ---- UI ----

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: true,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const PosterWall(),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      children: [
                        _fadeSlide(_stagger(0, 0.5), _header()),
                        const SizedBox(height: AppSpacing.xl),
                        _fadeSlide(_stagger(0.3, 1), _card()),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fadeSlide(Animation<double> a, Widget child) => AnimatedBuilder(
    animation: a,
    builder: (context, child) => Opacity(
      opacity: a.value,
      child: Transform.translate(
        offset: Offset(0, 28 * (1 - a.value)),
        child: child,
      ),
    ),
    child: child,
  );

  Widget _header() => Column(
    children: [
      AnimatedBuilder(
        animation: _glow,
        builder: (context, child) => Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFF4B55), AppColors.primaryContainer],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.glowPrimary.withValues(
                  alpha: 0.5 + _glow.value * 0.5,
                ),
                blurRadius: 24 + _glow.value * 18,
                spreadRadius: 1 + _glow.value * 4,
              ),
            ],
          ),
          child: child,
        ),
        child: const Icon(
          Icons.play_arrow_rounded,
          color: Colors.white,
          size: 44,
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      Text(
        'Ne İzlesem?',
        style: AppTextStyles.displayLg.copyWith(
          fontSize: 34,
          color: AppColors.onSurface,
        ),
      ),
      const SizedBox(height: 6),
      SizedBox(
        height: 22,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.5),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          child: Text(
            _taglines[_tagline],
            key: ValueKey(_tagline),
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    ],
  );

  /// Glass card; [_shake] runs whenever [AuthController.errorTick] changes.
  Widget _card() => Obx(() {
    final mode = controller.mode.value;
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        final t = _shake.value;
        return Transform.translate(
          offset: Offset(math.sin(t * math.pi * 6) * 10 * (1 - t), 0),
          child: child,
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (mode == AuthMode.setPassword)
                    _setPasswordIntro()
                  else
                    _modeSwitch(mode),
                  const SizedBox(height: AppSpacing.md),
                  ..._fields(mode),
                  _serverError(),
                  const SizedBox(height: AppSpacing.md),
                  _submitButton(mode),
                  if (mode == AuthMode.setPassword)
                    TextButton(
                      onPressed: () => controller.switchMode(AuthMode.login),
                      child: const Text('Girişe dön'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  });

  Widget _modeSwitch(AuthMode mode) {
    final isLogin = mode == AuthMode.login;
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: isLogin ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  boxShadow: [
                    BoxShadow(color: AppColors.glowPrimary, blurRadius: 12),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final (m, label) in const [
                (AuthMode.login, 'Giriş Yap'),
                (AuthMode.register, 'Kayıt Ol'),
              ])
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => controller.switchMode(m),
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: AppTextStyles.labelSm.copyWith(
                          fontSize: 14,
                          color: mode == m
                              ? Colors.white
                              : AppColors.onSurfaceVariant,
                        ),
                        child: Text(label),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _setPasswordIntro() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Şifreni belirle',
        style: AppTextStyles.headlineMd.copyWith(fontSize: 20),
      ),
      const SizedBox(height: 4),
      Text(
        'Hesabın şifreler gelmeden önce açılmış. Devam etmek için bir şifre belirle; '
        'bundan sonra bu şifreyle giriş yapacaksın.',
        style: AppTextStyles.bodyMd.copyWith(
          fontSize: 13,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    ],
  );

  List<Widget> _fields(AuthMode mode) {
    final register = mode == AuthMode.register;
    return [
      // Register-only fields slide in / out.
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        transitionBuilder: (child, anim) => SizeTransition(
          sizeFactor: anim,
          child: FadeTransition(opacity: anim, child: child),
        ),
        child: register
            ? Column(
                key: const ValueKey('register-fields'),
                children: [
                  _field(
                    _name,
                    'Ad Soyad',
                    Icons.person_outline,
                    errorKey: 'name',
                    action: TextInputAction.next,
                  ),
                  _field(
                    _username,
                    'Kullanıcı adı',
                    Icons.alternate_email,
                    errorKey: 'username',
                    action: TextInputAction.next,
                    formatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[a-zA-Z0-9_.]'),
                      ),
                      LengthLimitingTextInputFormatter(20),
                    ],
                  ),
                ],
              )
            : const SizedBox(
                key: ValueKey('no-register-fields'),
                width: double.infinity,
              ),
      ),
      _field(
        _email,
        'E-posta',
        Icons.mail_outline,
        errorKey: 'email',
        keyboard: TextInputType.emailAddress,
        action: TextInputAction.next,
        enabled: mode != AuthMode.setPassword,
      ),
      _field(
        _password,
        mode == AuthMode.setPassword ? 'Yeni şifre' : 'Şifre',
        Icons.lock_outline,
        errorKey: 'password',
        obscure: true,
        action: mode == AuthMode.setPassword
            ? TextInputAction.next
            : TextInputAction.done,
      ),
      if (mode != AuthMode.login) _strengthBar(),
      if (mode == AuthMode.setPassword)
        _field(
          _passwordAgain,
          'Yeni şifre (tekrar)',
          Icons.lock_reset,
          errorKey: 'passwordAgain',
          obscure: true,
        ),
    ];
  }

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon, {
    required String errorKey,
    TextInputType? keyboard,
    TextInputAction? action,
    bool obscure = false,
    bool enabled = true,
    List<TextInputFormatter>? formatters,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: TextField(
      controller: c,
      enabled: enabled,
      keyboardType: keyboard,
      textInputAction: action ?? TextInputAction.next,
      obscureText: obscure && _obscure,
      autocorrect: false,
      enableSuggestions: !obscure,
      inputFormatters: formatters,
      onSubmitted: (_) => action == TextInputAction.done ? _submit() : null,
      style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurface),
      decoration: InputDecoration(
        labelText: label,
        errorText: _fieldErrors[errorKey],
        prefixIcon: Icon(icon, size: 20, color: AppColors.onSurfaceVariant),
        suffixIcon: obscure
            ? IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: AppColors.onSurfaceVariant,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
        labelStyle: AppTextStyles.bodyMd.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
        filled: true,
        fillColor: AppColors.background.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(
            color: AppColors.primaryContainer,
            width: 1.5,
          ),
        ),
      ),
    ),
  );

  /// 0–4 segments: length ≥ 8, ≥ 12, has a digit, has a symbol/uppercase.
  Widget _strengthBar() => AnimatedBuilder(
    animation: _password,
    builder: (context, _) {
      final p = _password.text;
      final score = [
        p.length >= 8,
        p.length >= 12,
        RegExp(r'\d').hasMatch(p),
        RegExp(r'[A-Z]|[^a-zA-Z0-9]').hasMatch(p),
      ].where((x) => x).length;
      const labels = ['Çok zayıf', 'Zayıf', 'İdare eder', 'İyi', 'Güçlü'];
      final color = Color.lerp(
        const Color(0xFF8A2A24),
        const Color(0xFF3FBF7F),
        score / 4,
      )!;
      return Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, AppSpacing.sm),
        child: Row(
          children: [
            for (var i = 0; i < 4; i++)
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 4,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: i < score
                        ? color
                        : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            const SizedBox(width: 6),
            Text(
              p.isEmpty ? '' : labels[score],
              style: AppTextStyles.labelSm.copyWith(
                fontSize: 11,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    },
  );

  Widget _serverError() {
    final message = controller.error.value;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: message == null
          ? const SizedBox(width: double.infinity)
          : Container(
              key: ValueKey(message),
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      message,
                      style: AppTextStyles.bodyMd.copyWith(
                        fontSize: 13,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _submitButton(AuthMode mode) {
    final busy = controller.isSubmitting.value;
    final label = switch (mode) {
      AuthMode.login => 'Giriş Yap',
      AuthMode.register => 'Hesap Oluştur',
      AuthMode.setPassword => 'Şifreyi Kaydet ve Gir',
    };
    return SizedBox(
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.full),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF3B47), AppColors.primaryContainer],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.glowPrimary,
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ],
        ),
        child: FilledButton(
          onPressed: busy ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: busy
                ? const SizedBox(
                    key: ValueKey('busy'),
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    label,
                    key: ValueKey(label),
                    style: AppTextStyles.labelSm.copyWith(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

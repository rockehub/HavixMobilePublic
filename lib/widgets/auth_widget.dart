import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/models/storefront_models.dart';
import '../core/store/auth_store.dart';

class AuthWidget extends StatefulWidget {
  final Map<String, dynamic> config;
  final StorefrontResolveResponse storefront;

  const AuthWidget({super.key, required this.config, required this.storefront});

  @override
  State<AuthWidget> createState() => _AuthWidgetState();
}

class _AuthWidgetState extends State<AuthWidget> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  // Login
  final _idCtrl  = TextEditingController();
  final _pwCtrl  = TextEditingController();
  bool _obscurePw = true;

  // Register
  final _fnCtrl    = TextEditingController();
  final _lnCtrl    = TextEditingController();
  final _regEmail  = TextEditingController();
  final _regPw     = TextEditingController();
  final _regConfirm = TextEditingController();
  final _ddd       = TextEditingController();
  final _phone     = TextEditingController();
  bool _obscureRegPw  = true;
  bool _obscureConfirm = true;

  // 2FA
  final _tfaCtrl = TextEditingController();

  List<String> _providers = [];
  String? _error;
  bool _biometricLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProviders();
    context.read<AuthStore>().initBiometrics();
  }

  @override
  void dispose() {
    for (final c in [_idCtrl, _pwCtrl, _fnCtrl, _lnCtrl, _regEmail, _regPw,
        _regConfirm, _ddd, _phone, _tfaCtrl]) {
      c.dispose();
    }
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadProviders() async {
    try {
      final p = await context.read<AuthStore>().getActiveProviders();
      if (mounted) setState(() => _providers = p);
    } catch (_) {}
  }

  void _redirect() {
    final redirect = widget.config['redirectAfterLogin'] as String? ?? '/account';
    context.go(redirect);
  }

  Future<void> _login() async {
    setState(() => _error = null);
    try {
      final ok = await context.read<AuthStore>().login(_idCtrl.text.trim(), _pwCtrl.text);
      if (ok && mounted) {
        await _promptEnableBiometric(_idCtrl.text.trim(), _pwCtrl.text);
        _redirect();
      }
      // if !ok → requires2FA → the build will show the 2FA dialog automatically
    } catch (e) {
      if (mounted) setState(() => _error = context.read<AuthStore>().error ?? e.toString());
    }
  }

  Future<void> _loginWithBiometrics() async {
    setState(() { _biometricLoading = true; _error = null; });
    try {
      final ok = await context.read<AuthStore>().authenticateWithBiometrics();
      if (ok && mounted) _redirect();
      if (!ok && mounted) setState(() => _error = 'Autenticação biométrica falhou.');
    } catch (e) {
      if (mounted) setState(() => _error = 'Erro na biometria. Tente com senha.');
    } finally {
      if (mounted) setState(() => _biometricLoading = false);
    }
  }

  Future<void> _promptEnableBiometric(String identifier, String password) async {
    final auth = context.read<AuthStore>();
    if (!auth.biometricAvailable || auth.biometricEnabled) return;
    final enable = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Ativar biometria', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Deseja usar sua impressão digital ou reconhecimento facial para entrar mais rápido?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Não')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ativar')),
        ],
      ),
    );
    if (enable == true && mounted) {
      await auth.enableBiometric(identifier, password);
    }
  }

  Future<void> _register() async {
    setState(() => _error = null);
    if (_regPw.text != _regConfirm.text) {
      setState(() => _error = 'As senhas não conferem.');
      return;
    }
    if (_regPw.text.length < 8) {
      setState(() => _error = 'A senha deve ter pelo menos 8 caracteres.');
      return;
    }
    final areaCode = int.tryParse(_ddd.text.trim());
    try {
      await context.read<AuthStore>().register(
        firstname: _fnCtrl.text.trim(),
        lastname: _lnCtrl.text.trim(),
        email: _regEmail.text.trim(),
        password: _regPw.text,
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        areaCode: _ddd.text.trim().isEmpty ? null : areaCode,
      );
      if (mounted) _redirect();
    } catch (e) {
      if (mounted) setState(() => _error = context.read<AuthStore>().error ?? e.toString());
    }
  }

  Future<void> _verify2FA() async {
    setState(() => _error = null);
    try {
      await context.read<AuthStore>().verifyTwoFactor(_tfaCtrl.text.trim());
      if (mounted) _redirect();
    } catch (e) {
      if (mounted) setState(() => _error = 'Código inválido. Tente novamente.');
    }
  }

  Future<void> _oauthLogin(String provider) async {
    try {
      final url = await context.read<AuthStore>().getOAuthUrl(provider);
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) setState(() => _error = 'Erro ao iniciar login com $provider.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    // ── 2FA overlay ───────────────────────────────────────────────────────────
    if (auth.requires2FA) {
      return _TwoFactorView(
        ctrl: _tfaCtrl,
        loading: auth.isLoading,
        error: _error,
        onVerify: _verify2FA,
        onCancel: () {
          auth.cancelTwoFactor();
          setState(() => _error = null);
        },
      );
    }

    // ── Logged-in state ───────────────────────────────────────────────────────
    if (auth.isAuthenticated && auth.user != null) {
      final user = auth.user!;
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(user.initials,
                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 16),
            Text('Olá, ${user.firstname}!',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(user.email, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.55), fontSize: 14)),
            const SizedBox(height: 28),
            _ActionTile(icon: Icons.person_outline_rounded, label: 'Minha conta',
                onTap: () => context.push('/account')),
            _ActionTile(icon: Icons.shopping_bag_outlined, label: 'Meus pedidos',
                onTap: () => context.push('/orders')),
            if (auth.biometricAvailable) ...[
              const Divider(),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                secondary: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.fingerprint_rounded, size: 20, color: accent),
                ),
                title: const Text('Login biométrico', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text(
                  auth.biometricEnabled ? 'Ativado' : 'Desativado',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55)),
                ),
                value: auth.biometricEnabled,
                onChanged: (val) async {
                  if (val) {
                    // Need credentials — send user to login tab to re-enter password
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Faça login novamente para ativar a biometria.')),
                    );
                  } else {
                    await auth.disableBiometric();
                  }
                },
              ),
            ],
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.logout_rounded, color: Colors.red, size: 18),
              label: const Text('Sair da conta', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              ),
              onPressed: () async {
                await auth.logout();
                if (context.mounted) context.go('/');
              },
            ),
          ],
        ),
      );
    }

    // ── Auth forms ────────────────────────────────────────────────────────────
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          // Tab selector
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(4),
            child: TabBar(
              controller: _tabs,
              indicator: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4)],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: theme.colorScheme.onSurface,
              unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.5),
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              tabs: const [Tab(text: 'Entrar'), Tab(text: 'Criar conta')],
            ),
          ),

          const SizedBox(height: 24),

          if (_error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(_error!, style: TextStyle(color: Colors.red[700], fontSize: 13)),
            ),

          SizedBox(
            height: 420,
            child: TabBarView(controller: _tabs, children: [
              _loginTab(auth, accent),
              _registerTab(auth, accent),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _loginTab(AuthStore auth, Color accent) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Field(
            label: 'E-mail ou usuário',
            child: TextField(
              controller: _idCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDec('seu@email.com', autocomplete: 'username'),
            ),
          ),
          const SizedBox(height: 14),
          _Field(
            label: 'Senha',
            child: TextField(
              controller: _pwCtrl,
              obscureText: _obscurePw,
              decoration: _inputDec('••••••••',
                  autocomplete: 'current-password',
                  suffix: IconButton(
                    icon: Icon(_obscurePw ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                    onPressed: () => setState(() => _obscurePw = !_obscurePw),
                  )),
              onSubmitted: (_) => _login(),
            ),
          ),
          const SizedBox(height: 20),
          _PrimaryButton(label: 'Entrar', loading: auth.isLoading, onTap: _login, accent: accent),

          // Biometric login
          if (auth.biometricAvailable && auth.biometricEnabled) ...[
            const SizedBox(height: 16),
            Center(
              child: OutlinedButton.icon(
                icon: _biometricLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.fingerprint_rounded, size: 22),
                label: const Text('Entrar com biometria'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
                onPressed: _biometricLoading ? null : _loginWithBiometrics,
              ),
            ),
          ],

          // OAuth section
          if (_providers.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: Divider(color: Colors.grey.shade300)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('ou continue com',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ),
              Expanded(child: Divider(color: Colors.grey.shade300)),
            ]),
            const SizedBox(height: 14),
            Row(
              children: [
                if (_providers.contains('google'))
                  Expanded(child: _OAuthBtn(provider: 'google', onTap: () => _oauthLogin('google'))),
                if (_providers.contains('google') && _providers.contains('facebook'))
                  const SizedBox(width: 10),
                if (_providers.contains('facebook'))
                  Expanded(child: _OAuthBtn(provider: 'facebook', onTap: () => _oauthLogin('facebook'))),
                if ((_providers.contains('google') || _providers.contains('facebook')) && _providers.contains('apple'))
                  const SizedBox(width: 10),
                if (_providers.contains('apple'))
                  Expanded(child: _OAuthBtn(provider: 'apple', onTap: () => _oauthLogin('apple'))),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _registerTab(AuthStore auth, Color accent) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(child: _Field(label: 'Nome *', child: TextField(controller: _fnCtrl, decoration: _inputDec('João')))),
            const SizedBox(width: 12),
            Expanded(child: _Field(label: 'Sobrenome *', child: TextField(controller: _lnCtrl, decoration: _inputDec('Silva')))),
          ]),
          const SizedBox(height: 14),
          _Field(
            label: 'E-mail *',
            child: TextField(controller: _regEmail, keyboardType: TextInputType.emailAddress,
                decoration: _inputDec('seu@email.com', autocomplete: 'email')),
          ),
          const SizedBox(height: 14),
          _Field(
            label: 'Senha *',
            child: TextField(
              controller: _regPw,
              obscureText: _obscureRegPw,
              decoration: _inputDec('Mínimo 8 caracteres',
                  autocomplete: 'new-password',
                  suffix: IconButton(
                    icon: Icon(_obscureRegPw ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                    onPressed: () => setState(() => _obscureRegPw = !_obscureRegPw),
                  )),
            ),
          ),
          const SizedBox(height: 14),
          _Field(
            label: 'Confirmar senha *',
            child: TextField(
              controller: _regConfirm,
              obscureText: _obscureConfirm,
              decoration: _inputDec('Repita a senha',
                  autocomplete: 'new-password',
                  suffix: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  )),
            ),
          ),
          const SizedBox(height: 14),
          Row(children: [
            SizedBox(
              width: 72,
              child: _Field(label: 'DDD', child: TextField(controller: _ddd,
                  keyboardType: TextInputType.number, maxLength: 3,
                  decoration: _inputDec('11').copyWith(counterText: ''))),
            ),
            const SizedBox(width: 12),
            Expanded(child: _Field(label: 'Telefone', child: TextField(controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: _inputDec('99999-9999')))),
          ]),
          const SizedBox(height: 20),
          _PrimaryButton(label: 'Criar conta', loading: auth.isLoading, onTap: _register, accent: accent),
        ],
      ),
    );
  }

  InputDecoration _inputDec(String hint,
      {String? autocomplete, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 14),
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5)),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final String label;
  final Widget child;
  const _Field({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;
  final Color accent;
  const _PrimaryButton({required this.label, required this.loading, required this.onTap, required this.accent});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          disabledBackgroundColor: accent.withOpacity(0.5),
        ),
        child: loading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      ),
    );
  }
}

class _OAuthBtn extends StatelessWidget {
  final String provider;
  final VoidCallback onTap;
  const _OAuthBtn({required this.provider, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final labels = {'google': 'Google', 'facebook': 'Facebook', 'apple': 'Apple'};
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _OAuthIcon(provider: provider),
        const SizedBox(width: 6),
        Text(labels[provider] ?? provider,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _OAuthIcon extends StatelessWidget {
  final String provider;
  const _OAuthIcon({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider == 'google') {
      return const Text('G', style: TextStyle(color: Color(0xFF4285F4), fontWeight: FontWeight.w900, fontSize: 16));
    }
    if (provider == 'facebook') {
      return const Text('f', style: TextStyle(color: Color(0xFF1877F2), fontWeight: FontWeight.w900, fontSize: 18));
    }
    if (provider == 'apple') {
      return const Icon(Icons.apple, size: 18);
    }
    return const SizedBox.shrink();
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}

class _TwoFactorView extends StatelessWidget {
  final TextEditingController ctrl;
  final bool loading;
  final String? error;
  final VoidCallback onVerify;
  final VoidCallback onCancel;
  const _TwoFactorView({
    required this.ctrl, required this.loading, required this.error,
    required this.onVerify, required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.lock_outlined, size: 48),
          const SizedBox(height: 16),
          Text('Verificação em dois fatores',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Digite o código de 6 dígitos do seu aplicativo autenticador.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 14)),
          const SizedBox(height: 28),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: 8),
            decoration: InputDecoration(
              counterText: '',
              hintText: '000000',
              hintStyle: TextStyle(letterSpacing: 8, color: Colors.grey.shade400),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5)),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.red[700], fontSize: 13)),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: loading ? null : onVerify,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Verificar', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onCancel, child: const Text('Cancelar')),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/models/storefront_models.dart';
import '../core/store/auth_store.dart';

class MyAccountWidget extends StatefulWidget {
  final Map<String, dynamic> config;
  final StorefrontResolveResponse storefront;

  const MyAccountWidget({super.key, required this.config, required this.storefront});

  @override
  State<MyAccountWidget> createState() => _MyAccountWidgetState();
}

class _MyAccountWidgetState extends State<MyAccountWidget> {
  late final TextEditingController _fnCtrl;
  late final TextEditingController _lnCtrl;
  late final TextEditingController _phoneCtrl;

  bool _saving = false;
  String? _saveError;
  bool _saveSuccess = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthStore>().user;
    _fnCtrl    = TextEditingController(text: user?.firstname ?? '');
    _lnCtrl    = TextEditingController(text: user?.lastname ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _fnCtrl.dispose();
    _lnCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() { _saving = true; _saveError = null; _saveSuccess = false; });
    try {
      await context.read<AuthStore>().updateProfile(
        firstname: _fnCtrl.text.trim(),
        lastname: _lnCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      );
      if (mounted) setState(() => _saveSuccess = true);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _saveSuccess = false);
      });
    } catch (e) {
      if (mounted) setState(() => _saveError = 'Erro ao salvar. Tente novamente.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    if (auth.isLoading && !auth.isAuthenticated) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!auth.isAuthenticated) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.lock_outline_rounded, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            const Text('Área restrita', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Faça login para acessar sua conta.',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.55))),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.push('/login?redirect=/account'),
              child: const Text('Entrar'),
            ),
          ]),
        ),
      );
    }

    final user = auth.user!;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Row(children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(user.initials,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user.fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(user.email, style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.55))),
            ])),
          ]),

          const SizedBox(height: 28),

          // ── Profile form ──────────────────────────────────────────────────
          _Card(
            title: 'Dados pessoais',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  Expanded(child: _FormField(label: 'Nome *', ctrl: _fnCtrl, hint: 'Nome')),
                  const SizedBox(width: 12),
                  Expanded(child: _FormField(label: 'Sobrenome *', ctrl: _lnCtrl, hint: 'Sobrenome')),
                ]),
                const SizedBox(height: 14),
                _FormField(label: 'E-mail', ctrl: TextEditingController(text: user.email),
                    hint: '', enabled: false),
                const SizedBox(height: 14),
                _FormField(label: 'Telefone', ctrl: _phoneCtrl, hint: '(11) 91234-5678',
                    keyboardType: TextInputType.phone),
                if (_saveError != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                    child: Text(_saveError!, style: TextStyle(color: Colors.red[700], fontSize: 13)),
                  ),
                ],
                if (_saveSuccess) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)),
                    child: Text('Dados atualizados com sucesso!',
                        style: TextStyle(color: Colors.green[700], fontSize: 13)),
                  ),
                ],
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _saving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                  child: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Salvar alterações', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Quick links ───────────────────────────────────────────────────
          _Card(
            title: 'Ações',
            child: Column(children: [
              _Link(icon: Icons.shopping_bag_outlined, label: 'Meus pedidos',
                  accent: accent, onTap: () => context.push('/orders')),
              if (auth.biometricAvailable) ...[
                const Divider(height: 0),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.fingerprint_rounded, size: 18, color: accent),
                  ),
                  title: const Text('Login biométrico', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    auth.biometricEnabled ? 'Ativado' : 'Desativado',
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.55)),
                  ),
                  value: auth.biometricEnabled,
                  onChanged: (val) async {
                    if (!val) {
                      await auth.disableBiometric();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Faça logout e login novamente para ativar a biometria.')),
                      );
                    }
                  },
                ),
              ],
              const Divider(height: 0),
              _Link(
                icon: Icons.logout_rounded,
                label: 'Sair da conta',
                accent: Colors.red,
                iconBg: Colors.red.withOpacity(0.1),
                onTap: () async {
                  await auth.logout();
                  if (context.mounted) context.go('/');
                },
              ),
            ]),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        child,
      ]),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final String hint;
  final bool enabled;
  final TextInputType? keyboardType;
  const _FormField({required this.label, required this.ctrl, required this.hint,
      this.enabled = true, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          enabled: enabled,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            filled: !enabled,
            fillColor: enabled ? null : theme.colorScheme.surfaceContainerHighest,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5)),
          ),
        ),
      ],
    );
  }
}

class _Link extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final Color? iconBg;
  final VoidCallback onTap;
  const _Link({required this.icon, required this.label, required this.accent,
      this.iconBg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: iconBg ?? accent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 18, color: accent),
      ),
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }
}

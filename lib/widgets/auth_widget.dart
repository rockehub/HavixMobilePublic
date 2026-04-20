import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
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
  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();
  final _regName = TextEditingController();
  final _regEmail = TextEditingController();
  final _regPassword = TextEditingController();
  bool _obscureLogin = true;
  bool _obscureReg = true;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();

    if (auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/account'));
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TabBar(controller: _tabs, tabs: const [Tab(text: 'Entrar'), Tab(text: 'Criar conta')]),
          const SizedBox(height: 16),
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          SizedBox(
            height: 320,
            child: TabBarView(controller: _tabs, children: [
              _loginTab(auth),
              _registerTab(auth),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _loginTab(AuthStore auth) {
    return Column(
      children: [
        TextField(controller: _loginEmail, decoration: const InputDecoration(labelText: 'E-mail'), keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 12),
        TextField(
          controller: _loginPassword,
          decoration: InputDecoration(
            labelText: 'Senha',
            suffixIcon: IconButton(icon: Icon(_obscureLogin ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _obscureLogin = !_obscureLogin)),
          ),
          obscureText: _obscureLogin,
        ),
        const SizedBox(height: 8),
        Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () {}, child: const Text('Esqueci a senha'))),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: auth.isLoading ? null : () async {
              setState(() => _error = null);
              final ok = await auth.login(_loginEmail.text, _loginPassword.text);
              if (!ok && mounted) setState(() => _error = 'E-mail ou senha incorretos');
            },
            child: auth.isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Entrar'),
          ),
        ),
      ],
    );
  }

  Widget _registerTab(AuthStore auth) {
    return Column(
      children: [
        TextField(controller: _regName, decoration: const InputDecoration(labelText: 'Nome completo')),
        const SizedBox(height: 12),
        TextField(controller: _regEmail, decoration: const InputDecoration(labelText: 'E-mail'), keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 12),
        TextField(
          controller: _regPassword,
          decoration: InputDecoration(
            labelText: 'Senha',
            suffixIcon: IconButton(icon: Icon(_obscureReg ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _obscureReg = !_obscureReg)),
          ),
          obscureText: _obscureReg,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: auth.isLoading ? null : () async {
              setState(() => _error = null);
              final ok = await auth.register(_regName.text, _regEmail.text, _regPassword.text);
              if (!ok && mounted) setState(() => _error = 'Erro ao criar conta. Tente novamente.');
            },
            child: auth.isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Cadastrar'),
          ),
        ),
      ],
    );
  }
}

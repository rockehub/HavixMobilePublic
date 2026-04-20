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
  bool _editMode = false;
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthStore>();
    if (!auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/login'));
    }
    _nameCtrl = TextEditingController(text: auth.user?.name ?? '');
    _phoneCtrl = TextEditingController(text: auth.user?.phone ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    final user = auth.user;

    if (user == null) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Meu Perfil', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      IconButton(icon: Icon(_editMode ? Icons.close : Icons.edit), onPressed: () => setState(() => _editMode = !_editMode)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_editMode) ...[
                    TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nome')),
                    const SizedBox(height: 12),
                    TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Telefone'), keyboardType: TextInputType.phone),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => _editMode = false);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil atualizado!')));
                      },
                      child: const Text('Salvar'),
                    ),
                  ] else ...[
                    _infoRow(Icons.person, user.name),
                    _infoRow(Icons.email, user.email),
                    if (user.phone != null) _infoRow(Icons.phone, user.phone!),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(leading: const Icon(Icons.shopping_bag_outlined), title: const Text('Meus Pedidos'), trailing: const Icon(Icons.chevron_right), onTap: () => context.go('/orders')),
                const Divider(height: 0),
                ListTile(leading: const Icon(Icons.lock_outline), title: const Text('Alterar Senha'), trailing: const Icon(Icons.chevron_right), onTap: () {}),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Sair', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
              onPressed: () async {
                await auth.logout();
                if (context.mounted) context.go('/');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [Icon(icon, size: 18, color: Colors.grey), const SizedBox(width: 8), Text(text)]),
  );
}

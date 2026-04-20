import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/models/commerce_models.dart';
import '../core/models/storefront_models.dart';
import '../core/store/cart_store.dart';

class CheckoutWidget extends StatefulWidget {
  final Map<String, dynamic> config;
  final StorefrontResolveResponse storefront;

  const CheckoutWidget({super.key, required this.config, required this.storefront});

  @override
  State<CheckoutWidget> createState() => _CheckoutWidgetState();
}

class _CheckoutWidgetState extends State<CheckoutWidget> {
  int _step = 0;
  final _formKey = GlobalKey<FormState>();
  final _street = TextEditingController();
  final _number = TextEditingController();
  final _complement = TextEditingController();
  final _neighborhood = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _zipCode = TextEditingController();
  String? _selectedShipping;
  String _paymentMethod = 'PIX';
  bool _placing = false;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartStore>();
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Stepper(
      currentStep: _step,
      onStepTapped: (s) => setState(() => _step = s),
      controlsBuilder: (context, details) => Row(
        children: [
          if (_step < 3)
            ElevatedButton(onPressed: details.onStepContinue, child: const Text('Continuar')),
          if (_step > 0) ...[
            const SizedBox(width: 8),
            TextButton(onPressed: details.onStepCancel, child: const Text('Voltar')),
          ],
        ],
      ),
      onStepContinue: () async {
        if (_step == 0 && _formKey.currentState!.validate()) {
          setState(() => _step = 1);
          await cart.fetchShippingOptions(_zipCode.text);
        } else if (_step == 1 && _selectedShipping != null) {
          await cart.selectShipping(_selectedShipping!);
          setState(() => _step = 2);
        } else if (_step == 2) {
          await cart.selectPayment(_paymentMethod, {});
          setState(() => _step = 3);
        }
      },
      onStepCancel: () => setState(() { if (_step > 0) _step--; }),
      steps: [
        Step(
          title: const Text('Endereço'),
          isActive: _step >= 0,
          content: Form(
            key: _formKey,
            child: Column(
              children: [
                _field(_zipCode, 'CEP', onChanged: (v) { if (v.length == 8) cart.fetchShippingOptions(v); }),
                _field(_street, 'Rua'),
                Row(children: [
                  Expanded(child: _field(_number, 'Número')),
                  const SizedBox(width: 8),
                  Expanded(child: _field(_complement, 'Complemento', required: false)),
                ]),
                _field(_neighborhood, 'Bairro'),
                _field(_city, 'Cidade'),
                _field(_state, 'Estado'),
              ],
            ),
          ),
        ),
        Step(
          title: const Text('Frete'),
          isActive: _step >= 1,
          content: cart.shippingOptions.isEmpty
              ? const Text('Preencha o CEP na etapa anterior')
              : Column(
                  children: cart.shippingOptions.map((opt) => RadioListTile<String>(
                    value: opt.id,
                    groupValue: _selectedShipping,
                    onChanged: (v) => setState(() => _selectedShipping = v),
                    title: Text(opt.name),
                    subtitle: Text('${opt.estimatedDelivery ?? ''} — ${fmt.format(opt.price)}'),
                  )).toList(),
                ),
        ),
        Step(
          title: const Text('Pagamento'),
          isActive: _step >= 2,
          content: Column(
            children: [
              RadioListTile(value: 'PIX', groupValue: _paymentMethod, onChanged: (v) => setState(() => _paymentMethod = v!), title: const Text('Pix'), secondary: const Icon(Icons.qr_code)),
              RadioListTile(value: 'CREDIT_CARD', groupValue: _paymentMethod, onChanged: (v) => setState(() => _paymentMethod = v!), title: const Text('Cartão de crédito'), secondary: const Icon(Icons.credit_card)),
              RadioListTile(value: 'BOLETO', groupValue: _paymentMethod, onChanged: (v) => setState(() => _paymentMethod = v!), title: const Text('Boleto'), secondary: const Icon(Icons.receipt_long)),
            ],
          ),
        ),
        Step(
          title: const Text('Resumo'),
          isActive: _step >= 3,
          content: Column(
            children: [
              ...cart.cart.lines.map((l) => ListTile(
                title: Text(l.productName),
                trailing: Text(fmt.format(l.totalPrice)),
                dense: true,
              )),
              const Divider(),
              ListTile(title: const Text('Total'), trailing: Text(fmt.format(cart.cart.total), style: const TextStyle(fontWeight: FontWeight.bold)), dense: true),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _placing ? null : () async {
                    setState(() => _placing = true);
                    final order = await cart.placeOrder();
                    setState(() => _placing = false);
                    if (order != null && mounted) {
                      context.go('/orders/${order.id}');
                    }
                  },
                  child: _placing ? const CircularProgressIndicator(color: Colors.white) : const Text('Finalizar Pedido'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _field(TextEditingController ctrl, String label, {bool required = true, void Function(String)? onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(labelText: label),
        onChanged: onChanged,
        validator: required ? (v) => v == null || v.isEmpty ? 'Campo obrigatório' : null : null,
      ),
    );
  }
}

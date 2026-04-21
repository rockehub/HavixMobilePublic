import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/api/api_client.dart';
import '../core/store/auth_store.dart';
import '../core/api/commerce_api.dart';
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

  // Address fields
  final _cep          = TextEditingController();
  final _street       = TextEditingController();
  final _number       = TextEditingController();
  final _complement   = TextEditingController();
  final _neighborhood = TextEditingController();
  final _city         = TextEditingController();
  final _stateCode    = TextEditingController();

  bool _cepLoading  = false;
  bool _addressSaving = false;
  String? _addressError;

  // Geo
  String? _countryId;
  String? _stateId;
  List<_GeoEntry> _states = [];

  // Saved addresses
  List<CustomerAddress> _savedAddresses = [];

  // Shipping step state
  final _api = CommerceApi();
  List<DeliveryShippingSplit> _splits = [];
  bool _shippingLoading = false;
  String? _shippingError;
  final Map<String, DeliveryShippingItem> _selectedOptions = {};
  final Map<String, bool> _insuranceEnabled = {};

  bool _placing = false;
  String? _placeError;

  @override
  void initState() {
    super.initState();
    _loadGeo();
    _cep.addListener(_onCepChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSavedAddresses());
  }

  @override
  void dispose() {
    for (final c in [_cep, _street, _number, _complement, _neighborhood, _city, _stateCode]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadGeo() async {
    try {
      final dio = ApiClient().dio;
      final countriesResp = await dio.get('/api/v1/storefront/geo/countries');
      final countries = countriesResp.data as List<dynamic>;
      final br = countries.firstWhere(
        (c) => (c['code'] as String?)?.toUpperCase() == 'BR',
        orElse: () => null,
      );
      if (br == null) return;
      _countryId = br['id']?.toString();
      if (_countryId == null) return;
      final statesResp = await dio.get('/api/v1/storefront/geo/countries/$_countryId/states');
      final statesList = statesResp.data as List<dynamic>;
      if (mounted) {
        setState(() {
          _states = statesList
              .map((s) => _GeoEntry(
                    id: s['id']?.toString() ?? '',
                    code: s['code']?.toString() ?? '',
                    name: s['name']?.toString() ?? '',
                  ))
              .toList();
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Checkout] loadGeo error: $e');
    }
  }

  void _onCepChanged() {
    final digits = _cep.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 8) _fetchViaCep(digits);
  }

  Future<void> _fetchViaCep(String digits) async {
    setState(() { _cepLoading = true; });
    try {
      final dio = ApiClient().dio;
      final resp = await dio.get('https://viacep.com.br/ws/$digits/json/');
      final data = resp.data as Map<String, dynamic>;
      if (data['erro'] == true || data['erro'] == 'true') return;
      if (mounted) {
        setState(() {
          if ((data['logradouro'] as String?)?.isNotEmpty == true)
            _street.text = data['logradouro'] as String;
          if ((data['bairro'] as String?)?.isNotEmpty == true)
            _neighborhood.text = data['bairro'] as String;
          if ((data['localidade'] as String?)?.isNotEmpty == true)
            _city.text = data['localidade'] as String;
          if ((data['uf'] as String?)?.isNotEmpty == true) {
            _stateCode.text = (data['uf'] as String).toUpperCase();
            _resolveState(_stateCode.text);
          }
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Checkout] ViaCEP error: $e');
    } finally {
      if (mounted) setState(() => _cepLoading = false);
    }
  }

  void _resolveState(String code) {
    final match = _states.where(
      (s) => s.code.toUpperCase() == code.toUpperCase(),
    ).firstOrNull;
    _stateId = match?.id;
  }

  Future<void> _submitAddress() async {
    if (!_formKey.currentState!.validate()) return;
    if (_countryId == null) {
      setState(() => _addressError = 'Dados geográficos não carregados. Tente novamente.');
      return;
    }
    _resolveState(_stateCode.text.trim());
    setState(() { _addressSaving = true; _addressError = null; });
    try {
      final dio = ApiClient().dio;
      final resp = await dio.post('/api/v1/commerce/cart/addresses/shipping', data: {
        'name':      'Endereço de entrega',
        'street':    _street.text.trim(),
        'zip':       _cep.text.replaceAll(RegExp(r'\D'), ''),
        'city':      _city.text.trim(),
        'details':   _complement.text.trim().isEmpty ? null : _complement.text.trim(),
        'district':  _neighborhood.text.trim(),
        'number':    _number.text.trim(),
        if (_stateId != null) 'stateId': _stateId,
        'countryId': _countryId,
      });
      if (kDebugMode) debugPrint('[Checkout] address saved: ${resp.statusCode}');
      if (mounted) {
        setState(() => _step = 1);
        _loadShippingOptions();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Checkout] address error: $e');
      if (mounted) setState(() => _addressError = 'Erro ao salvar endereço. Verifique os dados.');
    } finally {
      if (mounted) setState(() => _addressSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartStore>();
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final theme = Theme.of(context);

    return Stepper(
      currentStep: _step,
      onStepTapped: (s) { if (s < _step) setState(() => _step = s); },
      controlsBuilder: (context, details) => const SizedBox.shrink(),
      steps: [
        // ── Step 0: Address ──────────────────────────────────────────────────
        Step(
          title: const Text('Endereço'),
          isActive: _step >= 0,
          state: _step > 0 ? StepState.complete : StepState.indexed,
          content: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Saved addresses picker
              if (_savedAddresses.isNotEmpty) ...[
                Text('Seus endereços salvos',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                const SizedBox(height: 8),
                SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _savedAddresses.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      final a = _savedAddresses[i];
                      return InkWell(
                        onTap: () => _applySavedAddress(a),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 220,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(a.name,
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text('${a.street}, ${a.number}'
                                  '${a.details != null && a.details!.isNotEmpty ? ' - ${a.details}' : ''}',
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                              Text('${a.district}, ${a.city}'
                                  '${a.stateCode != null ? ' - ${a.stateCode!.toUpperCase()}' : ''}',
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // CEP row with auto-fill indicator
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    flex: 2,
                    child: _FormField(
                      label: Row(children: [
                        const Text('CEP *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        if (_cepLoading) ...[
                          const SizedBox(width: 8),
                          const SizedBox(width: 12, height: 12,
                              child: CircularProgressIndicator(strokeWidth: 1.5)),
                          const SizedBox(width: 4),
                          Text('buscando...', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                        ],
                      ]),
                      child: TextFormField(
                        controller: _cep,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          _CepInputFormatter(),
                        ],
                        decoration: _dec('00000-000'),
                        validator: (v) {
                          final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
                          return d.length != 8 ? 'CEP inválido' : null;
                        },
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                _FormField.text(label: 'Rua *', ctrl: _street, hint: 'Rua das Flores',
                    validator: _required),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _FormField.text(label: 'Número *', ctrl: _number,
                      hint: '123', validator: _required)),
                  const SizedBox(width: 12),
                  Expanded(child: _FormField.text(label: 'Complemento', ctrl: _complement,
                      hint: 'Apto 4B')),
                ]),
                const SizedBox(height: 12),
                _FormField.text(label: 'Bairro *', ctrl: _neighborhood, hint: 'Centro',
                    validator: _required),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(flex: 3, child: _FormField.text(label: 'Cidade *', ctrl: _city,
                      hint: 'São Paulo', validator: _required)),
                  const SizedBox(width: 12),
                  Expanded(child: _FormField(
                    label: const Text('Estado', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    child: TextFormField(
                      controller: _stateCode,
                      maxLength: 2,
                      textCapitalization: TextCapitalization.characters,
                      decoration: _dec('SP').copyWith(counterText: ''),
                      onChanged: (v) => _resolveState(v),
                    ),
                  )),
                ]),
                if (_addressError != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                    child: Text(_addressError!, style: TextStyle(color: Colors.red[700], fontSize: 13)),
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _addressSaving ? null : _submitAddress,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _addressSaving
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Continuar', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),

        // ── Step 1: Shipping ─────────────────────────────────────────────────
        Step(
          title: const Text('Frete'),
          isActive: _step >= 1,
          state: _step > 1 ? StepState.complete : StepState.indexed,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_shippingLoading)
                const Center(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(),
                ))
              else if (_shippingError != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                  child: Text(_shippingError!, style: TextStyle(color: Colors.red[700], fontSize: 13)),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _loadShippingOptions,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Tentar novamente'),
                ),
              ] else if (_splits.isEmpty)
                Text('Nenhuma opção de frete disponível.',
                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 13))
              else
                ..._splits.map((split) {
                  final key = split.deliveryId ?? '';
                  return _ShippingSplitCard(
                    split: split,
                    selected: _selectedOptions[key],
                    insuranceEnabled: _insuranceEnabled[key] ?? true,
                    onSelect: (opt) => setState(() => _selectedOptions[key] = opt),
                    onInsuranceToggle: (v) => setState(() => _insuranceEnabled[key] = v),
                  );
                }),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: _shippingLoading ? null : () => setState(() => _step = 0),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Voltar'),
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: _shippingLoading || _splits.isEmpty ? null : _submitShipping,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade200,
                  ),
                  child: const Text('Continuar', style: TextStyle(fontWeight: FontWeight.w700)),
                )),
              ]),
            ],
          ),
        ),

        // ── Step 2: Review + Place Order ─────────────────────────────────────
        Step(
          title: const Text('Revisão'),
          isActive: _step >= 2,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Address summary
              if (_street.text.isNotEmpty) ...[
                _SectionTitle('Endereço de entrega'),
                const SizedBox(height: 6),
                Text('${_street.text}, ${_number.text}'
                    '${_complement.text.isNotEmpty ? ' - ${_complement.text}' : ''}',
                    style: const TextStyle(fontSize: 14)),
                Text('${_neighborhood.text}, ${_city.text}'
                    '${_stateCode.text.isNotEmpty ? ' - ${_stateCode.text.toUpperCase()}' : ''}'
                    ' — CEP ${_cep.text}',
                    style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                const SizedBox(height: 16),
              ],

              // Items
              _SectionTitle('Itens'),
              const SizedBox(height: 6),
              ...cart.cart.lines.map((l) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Expanded(child: Text(l.productName,
                      style: const TextStyle(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Text('${l.quantity}x  ${fmt.format(l.totalPrice)}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
              )),
              const Divider(height: 24),
              if (cart.cart.discount != null && cart.cart.discount! > 0)
                _SummaryRow('Desconto', '-${fmt.format(cart.cart.discount!)}',
                    color: Colors.green[700]),
              if (cart.cart.shipping != null && cart.cart.shipping! > 0)
                _SummaryRow('Frete', fmt.format(cart.cart.shipping!)),
              _SummaryRow('Total', fmt.format(cart.cart.total), bold: true, large: true),

              if (_placeError != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                  child: Text(_placeError!, style: TextStyle(color: Colors.red[700], fontSize: 13)),
                ),
              ],

              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => setState(() => _step = 1),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Voltar'),
                )),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: ElevatedButton(
                  onPressed: _placing ? null : () async {
                    setState(() { _placing = true; _placeError = null; });
                    final order = await cart.placeOrder();
                    if (!mounted) return;
                    setState(() => _placing = false);
                    if (order == null) {
                      setState(() => _placeError = 'Erro ao finalizar pedido. Tente novamente.');
                      return;
                    }
                    if (kDebugMode) {
                      debugPrint('[Checkout] order=${order.id} action=${order.resolvedPaymentAction} link=${order.paymentLink}');
                    }
                    final action = order.resolvedPaymentAction;
                    if (action == 'REDIRECT' && order.paymentLink != null && order.paymentLink!.isNotEmpty) {
                      if (mounted) {
                        context.push('/payment?url=${Uri.encodeComponent(order.paymentLink!)}');
                      }
                    } else if (action == 'AWAITING_APPROVAL') {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Pedido enviado para aprovação. Acompanhe em Meus pedidos.'),
                          duration: Duration(seconds: 4),
                        ));
                        context.go('/orders');
                      }
                    } else {
                      if (mounted) context.go('/orders');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade200,
                  ),
                  child: _placing
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Finalizar Pedido', style: TextStyle(fontWeight: FontWeight.w700)),
                )),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _loadSavedAddresses() async {
    final auth = context.read<AuthStore>();
    if (!auth.isAuthenticated) return;
    try {
      final addresses = await _api.listAddresses();
      if (kDebugMode) debugPrint('[Checkout] loaded ${addresses.length} saved addresses');
      if (mounted) setState(() => _savedAddresses = addresses);
    } catch (e) {
      if (kDebugMode) debugPrint('[Checkout] listAddresses error: $e');
    }
  }

  void _applySavedAddress(CustomerAddress a) {
    setState(() {
      _street.text       = a.street;
      _number.text       = a.number;
      _complement.text   = a.details ?? '';
      _neighborhood.text = a.district;
      _city.text         = a.city;
      _stateCode.text    = a.stateCode?.toUpperCase() ?? '';
      // Format zip as 00000-000
      final digits = a.zip.replaceAll(RegExp(r'\D'), '');
      _cep.text = digits.length == 8
          ? '${digits.substring(0, 5)}-${digits.substring(5)}'
          : digits;
    });
    if (a.stateCode != null) _resolveState(a.stateCode!);
    // If stateId available, set directly without ViaCEP lookup
    if (a.stateId != null) _stateId = a.stateId;
  }

  Future<void> _loadShippingOptions() async {
    setState(() { _shippingLoading = true; _shippingError = null; });
    try {
      final splits = await _api.getDeliveryShippingOptions();
      if (!mounted) return;
      setState(() {
        _splits = splits;
        for (final split in splits) {
          if (split.shippingType == 'DIGITAL') continue;
          final key = split.deliveryId ?? '';
          final available = split.options.where((o) => o.isAvailable).toList();
          if (available.isNotEmpty && !_selectedOptions.containsKey(key)) {
            _selectedOptions[key] = available.first;
            _insuranceEnabled[key] = true;
          }
        }
      });
    } catch (e) {
      if (mounted) setState(() => _shippingError = 'Erro ao buscar opções de frete.');
      if (kDebugMode) debugPrint('[Checkout] shipping options error: $e');
    } finally {
      if (mounted) setState(() => _shippingLoading = false);
    }
  }

  Future<void> _submitShipping() async {
    final physicalSplits = _splits.where((s) => s.shippingType != 'DIGITAL').toList();
    for (final split in physicalSplits) {
      final key = split.deliveryId ?? '';
      if (!_selectedOptions.containsKey(key)) {
        setState(() => _shippingError = 'Selecione uma opção de frete para cada entrega.');
        return;
      }
    }
    setState(() { _shippingLoading = true; _shippingError = null; });
    try {
      for (final split in physicalSplits) {
        final key = split.deliveryId ?? '';
        final opt = _selectedOptions[key]!;
        final useInsurance = _insuranceEnabled[key] ?? true;
        final price = useInsurance ? opt.priceInCents : opt.priceWithoutInsuranceInCents;
        await _api.setDeliveryShipping(
          split.deliveryId ?? key,
          provider: opt.provider,
          serviceCode: opt.serviceCode,
          name: opt.name,
          company: opt.company,
          priceInCents: price,
          deliveryDays: opt.deliveryDays,
          providerData: opt.providerData,
          insuranceIncluded: useInsurance,
        );
      }
      if (mounted) setState(() => _step = 2);
    } catch (e) {
      if (mounted) setState(() => _shippingError = 'Erro ao selecionar frete. Tente novamente.');
      if (kDebugMode) debugPrint('[Checkout] set shipping error: $e');
    } finally {
      if (mounted) setState(() => _shippingLoading = false);
    }
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null;

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 1.5)),
  );
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _FormField extends StatelessWidget {
  final Widget label;
  final Widget child;
  const _FormField({required this.label, required this.child});

  factory _FormField.text({
    required String label,
    required TextEditingController ctrl,
    required String hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return _FormField(
      label: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      child: Builder(builder: (context) => TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red)),
          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 1.5)),
        ),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [label, const SizedBox(height: 6), child],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14));
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final bool large;
  final Color? color;
  const _SummaryRow(this.label, this.value, {this.bold = false, this.large = false, this.color});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(
          fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
          fontSize: large ? 16 : 14)),
      Text(value, style: TextStyle(
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          fontSize: large ? 18 : 14,
          color: color ?? (bold ? Theme.of(context).colorScheme.primary : null))),
    ]),
  );
}

class _ShippingSplitCard extends StatelessWidget {
  final DeliveryShippingSplit split;
  final DeliveryShippingItem? selected;
  final bool insuranceEnabled;
  final ValueChanged<DeliveryShippingItem> onSelect;
  final ValueChanged<bool> onInsuranceToggle;

  const _ShippingSplitCard({
    required this.split,
    required this.selected,
    required this.insuranceEnabled,
    required this.onSelect,
    required this.onInsuranceToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    if (split.shippingType == 'DIGITAL') {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(children: [
          Icon(Icons.download_outlined, color: Colors.blue[700], size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(
            '${split.warehouseName ?? 'Entrega digital'} — produto digital, sem frete',
            style: TextStyle(color: Colors.blue[700], fontSize: 13),
          )),
        ]),
      );
    }

    final availableOptions = split.options.where((o) => o.isAvailable).toList();
    final errorOptions = split.options.where((o) => !o.isAvailable).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Split header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(children: [
              Icon(Icons.local_shipping_outlined, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Expanded(child: Text(
                split.warehouseName ?? 'Entrega',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              )),
              if (split.itemCount > 0)
                Text('${split.itemCount} ${split.itemCount == 1 ? 'item' : 'itens'}',
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5))),
            ]),
          ),

          if (availableOptions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text('Nenhuma opção de frete disponível para este pacote.',
                  style: TextStyle(fontSize: 13, color: Colors.red[700])),
            )
          else
            ...availableOptions.map((opt) {
              final isSelected = selected?.serviceCode == opt.serviceCode && selected?.provider == opt.provider;
              final canToggleInsurance = opt.hasInsuranceToggle;
              final displayPrice = (isSelected && canToggleInsurance && !insuranceEnabled)
                  ? opt.priceWithoutInsuranceInCents
                  : opt.priceInCents;
              final totalDays = opt.deliveryDays + split.preparationDays;

              return InkWell(
                onTap: () => onSelect(opt),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Radio<String>(
                          value: '${opt.provider}:${opt.serviceCode}',
                          groupValue: selected != null ? '${selected!.provider}:${selected!.serviceCode}' : null,
                          onChanged: (_) => onSelect(opt),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                        const SizedBox(width: 4),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(opt.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            if (opt.company != null && opt.company!.isNotEmpty)
                              Text(opt.company!, style: TextStyle(fontSize: 11,
                                  color: theme.colorScheme.onSurface.withOpacity(0.5))),
                          ],
                        )),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text(
                            displayPrice == 0 ? 'Grátis' : fmt.format(displayPrice / 100),
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                                color: displayPrice == 0 ? Colors.green[700] : null),
                          ),
                          Text(
                            totalDays == 1 ? '1 dia útil' : '$totalDays dias úteis',
                            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                          ),
                        ]),
                      ]),
                      // Insurance toggle (only for selected option)
                      if (isSelected && canToggleInsurance)
                        Padding(
                          padding: const EdgeInsets.only(left: 36, top: 4),
                          child: Row(children: [
                            Switch(
                              value: insuranceEnabled,
                              onChanged: onInsuranceToggle,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            const SizedBox(width: 6),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Seguro de frete', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                Text(
                                  insuranceEnabled
                                      ? '+${fmt.format((opt.priceInCents - opt.priceWithoutInsuranceInCents) / 100)} incluso'
                                      : 'Não incluso',
                                  style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                                ),
                              ],
                            )),
                          ]),
                        ),
                    ],
                  ),
                ),
              );
            }),

          if (errorOptions.isNotEmpty && availableOptions.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Text(errorOptions.first.error ?? 'Erro ao calcular frete',
                  style: TextStyle(fontSize: 12, color: Colors.red[600])),
            ),
        ],
      ),
    );
  }
}

class _GeoEntry {
  final String id;
  final String code;
  final String name;
  const _GeoEntry({required this.id, required this.code, required this.name});
}

// Formats CEP as 00000-000
class _CepInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 5) return newValue.copyWith(text: digits);
    final formatted = '${digits.substring(0, 5)}-${digits.substring(5, digits.length > 8 ? 8 : digits.length)}';
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

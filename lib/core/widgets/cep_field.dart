import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../features/checklist/domain/checklist_models.dart';
import '../location/location_providers.dart';
import '../location/viacep.dart';
import 'endereco_mapa.dart';

/// Campo de CEP com consulta ao ViaCEP e prévia do mapa.
class CepField extends ConsumerStatefulWidget {
  const CepField({
    super.key,
    required this.cep,
    required this.rua,
    required this.bairro,
    required this.cidade,
    required this.estado,
    this.numero,
  });

  final TextEditingController cep;
  final TextEditingController rua;
  final TextEditingController bairro;
  final TextEditingController cidade;
  final TextEditingController estado;
  final TextEditingController? numero;

  @override
  ConsumerState<CepField> createState() => CepFieldState();
}

class CepFieldState extends ConsumerState<CepField> {
  String? _confirmado;
  String? _mensagem;
  bool _buscando = false;
  bool _indisponivel = false;
  LatLng? _ponto;

  /// Confere o CEP antes de salvar. CEP vazio passa. CEP inexistente bloqueia.
  Future<bool> garantir() async {
    final texto = widget.cep.text.trim();
    if (texto.isEmpty) return true;
    if (normalizarCep(texto) == null) {
      setState(() => _mensagem = 'CEP deve ter 8 dígitos');
      return false;
    }
    if (_confirmado == normalizarCep(texto) && _mensagem == null) return true;
    await _verificar();
    return _mensagem == null || _indisponivel;
  }

  Future<void> _verificar() async {
    final digitos = normalizarCep(widget.cep.text);
    if (digitos == null) {
      setState(() {
        _mensagem = widget.cep.text.trim().isEmpty
            ? null
            : 'CEP deve ter 8 dígitos';
        _ponto = null;
        _confirmado = null;
        _indisponivel = false;
      });
      return;
    }

    setState(() {
      _buscando = true;
      _mensagem = null;
      _indisponivel = false;
    });

    try {
      final via = await ref.read(viaCepClientProvider).consultar(widget.cep.text);
      if (!mounted) return;
      if (normalizarCep(widget.cep.text) != digitos) {
        setState(() => _buscando = false);
        if (normalizarCep(widget.cep.text) != null) await _verificar();
        return;
      }
      if (via.logradouro.trim().isNotEmpty) widget.rua.text = via.logradouro;
      if (via.bairro.trim().isNotEmpty) widget.bairro.text = via.bairro;
      if (via.cidade.trim().isNotEmpty) widget.cidade.text = via.cidade;
      if (via.uf.trim().isNotEmpty) widget.estado.text = via.uf;
      if (via.cep.trim().isNotEmpty) widget.cep.text = via.cep;

      LatLng? ponto;
      try {
        ponto = await ref.read(enderecoGeocoderProvider).coordenadas(
              Endereco(
                rua: widget.rua.text,
                numero: widget.numero?.text,
                bairro: widget.bairro.text,
                cidade: widget.cidade.text,
                estado: widget.estado.text,
                cep: widget.cep.text,
              ),
            );
      } catch (_) {
        ponto = null;
      }
      if (!mounted) return;
      if (normalizarCep(widget.cep.text) != digitos) {
        setState(() => _buscando = false);
        if (normalizarCep(widget.cep.text) != null) await _verificar();
        return;
      }
      setState(() {
        _confirmado = digitos;
        _ponto = ponto;
        _mensagem = null;
        _buscando = false;
      });
    } on ViaCepException catch (e) {
      if (!mounted) return;
      setState(() {
        _mensagem = e.mensagem;
        _indisponivel = !e.naoEncontrado;
        _ponto = null;
        _confirmado = null;
        _buscando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: widget.cep,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'CEP',
            errorText: _mensagem,
            suffixIcon: IconButton(
              tooltip: 'Verificar no ViaCEP',
              onPressed: _buscando ? null : _verificar,
              icon: _buscando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.travel_explore),
            ),
          ),
          onChanged: (valor) {
            final digitos = normalizarCep(valor);
            if (digitos != null && digitos != _confirmado && !_buscando) {
              _verificar();
            }
          },
        ),
        if (_mensagem == null && _confirmado != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 4),
            child: Text(
              'CEP confirmado no ViaCEP',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF3DDC97),
                  ),
            ),
          ),
        if (_ponto != null) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: EnderecoMapa(
              endereco: Endereco(
                rua: widget.rua.text,
                numero: widget.numero?.text,
                bairro: widget.bairro.text,
                cidade: widget.cidade.text,
                estado: widget.estado.text,
                cep: widget.cep.text,
                latitude: _ponto!.latitude,
                longitude: _ponto!.longitude,
              ),
              altura: 140,
            ),
          ),
        ],
      ],
    );
  }
}

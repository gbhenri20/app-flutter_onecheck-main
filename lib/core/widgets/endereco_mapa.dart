import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme/app_theme.dart';
import '../../features/checklist/domain/checklist_models.dart';
import '../location/endereco_geocoder.dart';
import '../location/location_providers.dart';
import '../location/viacep.dart';

class LocalizacaoPainel extends StatelessWidget {
  const LocalizacaoPainel({
    super.key,
    required this.endereco,
    this.altura = 160,
    this.interativo = false,
  });

  final Endereco endereco;
  final double altura;
  final bool interativo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CepConferenciaBadge(endereco: endereco),
        EnderecoMapa(
          endereco: endereco,
          altura: altura,
          interativo: interativo,
        ),
      ],
    );
  }
}

class CepConferenciaBadge extends ConsumerWidget {
  const CepConferenciaBadge({super.key, required this.endereco});

  final Endereco endereco;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conferencia = ref.watch(
      cepConferenciaProvider(LocalizacaoChave(endereco)),
    );
    return conferencia.when(
      loading: () => const _FaixaCep(
        texto: 'Verificando CEP no ViaCEP...',
        cor: AppTheme.brandMuted,
        icone: Icons.hourglass_top,
      ),
      error: (erro, detalhe) => const _FaixaCep(
        texto: 'ViaCEP indisponível',
        cor: AppTheme.brandMuted,
        icone: Icons.cloud_off_outlined,
      ),
      data: (resultado) {
        final visual = switch (resultado) {
          CepConferencia.confere => (
              'CEP confirmado no ViaCEP',
              AppTheme.brandGreen,
              Icons.verified_outlined,
            ),
          CepConferencia.diverge => (
              'Endereço diferente do ViaCEP',
              const Color(0xFFFFB74D),
              Icons.report_problem_outlined,
            ),
          CepConferencia.invalido => (
              'CEP não encontrado no ViaCEP',
              AppTheme.brandDanger,
              Icons.location_off_outlined,
            ),
          CepConferencia.indisponivel => (
              'ViaCEP indisponível',
              AppTheme.brandMuted,
              Icons.cloud_off_outlined,
            ),
          CepConferencia.semCep => (
              'Sem CEP para verificar',
              AppTheme.brandMuted,
              Icons.pin_drop_outlined,
            ),
        };
        return _FaixaCep(texto: visual.$1, cor: visual.$2, icone: visual.$3);
      },
    );
  }
}

class _FaixaCep extends StatelessWidget {
  const _FaixaCep({
    required this.texto,
    required this.cor,
    required this.icone,
  });

  final String texto;
  final Color cor;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Row(
        children: [
          Icon(icone, size: 16, color: cor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cor),
            ),
          ),
        ],
      ),
    );
  }
}

class EnderecoMapa extends ConsumerWidget {
  const EnderecoMapa({
    super.key,
    required this.endereco,
    this.altura = 160,
    this.interativo = false,
  });

  final Endereco endereco;
  final double altura;
  final bool interativo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latitude = endereco.latitude;
    final longitude = endereco.longitude;
    if (latitude != null && longitude != null) {
      return _MapaPronto(
        ponto: LatLng(latitude, longitude),
        titulo: endereco.linhaCompleta,
        altura: altura,
        interativo: interativo,
      );
    }

    final busca = ref.watch(coordenadasProvider(LocalizacaoChave(endereco)));
    return busca.when(
      loading: () => _MapaCaixa(
        altura: altura,
        child: const CircularProgressIndicator(),
      ),
      error: (erro, detalhe) => _MapaCaixa(
        altura: altura,
        child: const Text('Não foi possível carregar o mapa'),
      ),
      data: (ponto) {
        if (ponto == null) {
          return _MapaCaixa(
            altura: altura,
            child: const Text('Endereço sem ponto no mapa'),
          );
        }
        return _MapaPronto(
          ponto: ponto,
          titulo: endereco.linhaCompleta,
          altura: altura,
          interativo: interativo,
        );
      },
    );
  }
}

class _MapaPronto extends StatelessWidget {
  const _MapaPronto({
    required this.ponto,
    required this.titulo,
    required this.altura,
    required this.interativo,
  });

  final LatLng ponto;
  final String titulo;
  final double altura;
  final bool interativo;

  @override
  Widget build(BuildContext context) {
    final mapa = _MapaBase(ponto: ponto, interativo: interativo);
    return Semantics(
      label: 'Mapa de $titulo',
      child: SizedBox(
        height: altura,
        child: interativo
            ? mapa
            : Stack(
                children: [
                  mapa,
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _abrirMapa(context, ponto, titulo),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _MapaBase extends StatelessWidget {
  const _MapaBase({required this.ponto, required this.interativo});

  final LatLng ponto;
  final bool interativo;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: ponto,
        initialZoom: 16,
        interactionOptions: InteractionOptions(
          flags: interativo ? InteractiveFlag.all : InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'one_check',
          maxNativeZoom: 19,
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: ponto,
              width: 36,
              height: 36,
              alignment: Alignment.topCenter,
              child: const Icon(
                Icons.location_on,
                color: Color(0xFFE53935),
                size: 36,
              ),
            ),
          ],
        ),
        const Align(
          alignment: Alignment.bottomRight,
          child: ColoredBox(
            color: Color(0xCCFFFFFF),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                '© OpenStreetMap',
                style: TextStyle(fontSize: 9, color: Colors.black87),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MapaCaixa extends StatelessWidget {
  const _MapaCaixa({required this.altura, required this.child});

  final double altura;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: altura,
      child: ColoredBox(
        color: AppTheme.brandInput,
        child: Center(child: child),
      ),
    );
  }
}

void _abrirMapa(BuildContext context, LatLng ponto, String titulo) {
  showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: 640,
        height: 460,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  const Icon(Icons.map_outlined),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      titulo,
                      style: Theme.of(ctx).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _MapaBase(ponto: ponto, interativo: true),
            ),
          ],
        ),
      ),
    ),
  );
}

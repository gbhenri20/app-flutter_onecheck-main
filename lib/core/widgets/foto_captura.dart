import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/theme/app_theme.dart';

class FotoEscolhida {
  const FotoEscolhida({required this.bytes, required this.filename});

  final Uint8List bytes;
  final String filename;
}

/// Abre a câmera ou a galeria e só devolve a foto depois da confirmação.
Future<FotoEscolhida?> capturarFoto(
  BuildContext context, {
  required ImageSource origem,
}) async {
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final picker = ImagePicker();
  final daCamera = origem == ImageSource.camera;

  while (true) {
    XFile? arquivo;
    try {
      arquivo = await picker.pickImage(
        source: origem,
        imageQuality: 90,
        preferredCameraDevice: CameraDevice.rear,
      );
    } on PlatformException {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            daCamera
                ? 'Não foi possível abrir a câmera.'
                : 'Não foi possível abrir a galeria.',
          ),
        ),
      );
      return null;
    }
    if (arquivo == null || !navigator.mounted) return null;

    final bytes = await arquivo.readAsBytes();
    if (!navigator.mounted) return null;
    if (bytes.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('A foto veio vazia. Tente de novo.')),
      );
      return null;
    }

    final usar = await navigator.push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _ConfirmarFotoPage(bytes: bytes, daCamera: daCamera),
      ),
    );
    if (usar == true) {
      return FotoEscolhida(bytes: bytes, filename: arquivo.name);
    }
    if (usar != false || !navigator.mounted) return null;
  }
}

class _ConfirmarFotoPage extends StatelessWidget {
  const _ConfirmarFotoPage({required this.bytes, required this.daCamera});

  final Uint8List bytes;
  final bool daCamera;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Confirmar foto'),
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              child: Center(
                child: Image.memory(bytes, fit: BoxFit.contain),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: AppTheme.brandBorder),
                      ),
                      child: Text(daCamera ? 'Tirar outra' : 'Escolher outra'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Usar esta foto'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

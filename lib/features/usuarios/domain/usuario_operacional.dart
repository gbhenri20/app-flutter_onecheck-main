import 'package:equatable/equatable.dart';

/// Nome usado para distribuir contrato ou vistoria, sem dados de conta.
class UsuarioOperacional extends Equatable {
  const UsuarioOperacional({
    required this.id,
    required this.nome,
    required this.role,
  });

  final String id;
  final String nome;
  final String role;

  factory UsuarioOperacional.fromJson(Map<String, dynamic> json) {
    return UsuarioOperacional(
      id: json['id'] as String,
      nome: json['nome'] as String? ?? '',
      role: json['role'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [id];
}

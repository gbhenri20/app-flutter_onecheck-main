class MfaAdminSetup {
  const MfaAdminSetup({
    required this.secret,
    required this.provisioningUri,
    required this.qrUrl,
  });

  final String secret;
  final String provisioningUri;
  final String qrUrl;

  factory MfaAdminSetup.fromJson(Map<String, dynamic> json) {
    final uri = (json['provisioning_uri'] ?? json['otpauth_uri']) as String? ?? '';
    return MfaAdminSetup(
      secret: json['secret'] as String? ?? '',
      provisioningUri: uri,
      qrUrl: json['qr_url'] as String? ?? '',
    );
  }
}

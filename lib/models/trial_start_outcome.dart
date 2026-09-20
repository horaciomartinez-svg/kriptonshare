/// Resultado de `start_premium_trial()`.
///
/// [code] es un identificador estable (inglés) para localizar el feedback:
/// `started`, `already_used`, `not_eligible`, `not_found`, `no_session`,
/// `error`. [message] es el texto humano devuelto por el servidor (respaldo).
class TrialStartOutcome {
  final bool started;
  final String? code;
  final String? message;

  const TrialStartOutcome({
    required this.started,
    this.code,
    this.message,
  });

  /// Fallo de transporte/inesperado (excepción en el cliente).
  static const TrialStartOutcome error =
      TrialStartOutcome(started: false, code: 'error');
}

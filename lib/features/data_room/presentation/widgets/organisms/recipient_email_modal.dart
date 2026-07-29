import 'package:flutter/material.dart';
import '../../../../../app/config/theme/app_theme.dart';

class RecipientEmailModal extends StatefulWidget {
  final void Function(String email) onSubmit;

  const RecipientEmailModal({super.key, required this.onSubmit});

  @override
  State<RecipientEmailModal> createState() => _RecipientEmailModalState();
}

class _RecipientEmailModalState extends State<RecipientEmailModal> {
  final _controller = TextEditingController();
  String? _error;

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  void _submit() {
    final email = _controller.text.trim();
    if (!_isValidEmail(email)) {
      setState(() => _error = 'Ingresa un correo válido');
      return;
    }
    widget.onSubmit(email);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Acceso al Data Room',
            style: TextStyle(
              color: AppTheme.platinum,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ingresa tu correo para continuar. El acceso quedará auditado.',
            style: TextStyle(color: AppTheme.silver),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: AppTheme.platinum),
            decoration: InputDecoration(
              labelText: 'Correo electrónico',
              errorText: _error,
              prefixIcon: const Icon(Icons.email, color: AppTheme.silver),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submit,
            child: const Text('Acceder'),
          ),
        ],
      ),
    );
  }
}

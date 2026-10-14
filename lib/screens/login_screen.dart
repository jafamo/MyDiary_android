import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_exception.dart';
import '../auth/session_notifier.dart';
import '../providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  /// Espera si el backend responde `429` sin `Retry-After`.
  static const _defaultRetryAfter = Duration(seconds: 60);

  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _obscurePassword = true;
  bool _submitting = false;
  String? _error;

  /// Segundos que quedan de bloqueo tras un `429`.
  int _blockedSeconds = 0;
  Timer? _blockTimer;

  @override
  void dispose() {
    _blockTimer?.cancel();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(sessionProvider.notifier)
          .login(_username.text.trim(), _password.text);
      // Con sesión, el router lleva al inicio.
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        if (e.code == ApiException.tooManyRequests) {
          _block(e.retryAfter ?? _defaultRetryAfter);
        } else {
          _error = e.message;
        }
      });
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _block(Duration duration) {
    _blockTimer?.cancel();
    _blockedSeconds = duration.inSeconds;
    _blockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _blockedSeconds--;
        if (_blockedSeconds <= 0) {
          timer.cancel();
        }
      });
    });
  }

  String get _blockedMessage {
    final minutes = _blockedSeconds ~/ 60;
    final seconds = (_blockedSeconds % 60).toString().padLeft(2, '0');
    return 'Demasiados intentos. Prueba de nuevo en $minutes:$seconds.';
  }

  String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Obligatorio' : null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blocked = _blockedSeconds > 0;
    final message = blocked ? _blockedMessage : _error;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '📔 MyDiary',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _username,
                        decoration: const InputDecoration(
                          labelText: 'Usuario',
                          border: OutlineInputBorder(),
                        ),
                        autofillHints: const [AutofillHints.username],
                        autocorrect: false,
                        textInputAction: TextInputAction.next,
                        validator: _required,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? 'Mostrar contraseña'
                                : 'Ocultar contraseña',
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        autofillHints: const [AutofillHints.password],
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) {
                          if (!blocked && !_submitting) {
                            _submit();
                          }
                        },
                        validator: _required,
                      ),
                      if (message != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          '⚠ $message',
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: blocked || _submitting ? null : _submit,
                        child: _submitting
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Entrar'),
                      ),
                      if (kDebugMode) ...[
                        const SizedBox(height: 32),
                        Text(
                          ref.watch(appConfigProvider).apiBaseUrl.toString(),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

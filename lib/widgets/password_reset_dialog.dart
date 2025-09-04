import 'package:flutter/material.dart';
import 'package:mindload/theme.dart';
import 'package:mindload/services/password_reset_service.dart';

/// Password Reset Dialog
class PasswordResetDialog extends StatefulWidget {
  const PasswordResetDialog({super.key});

  @override
  State<PasswordResetDialog> createState() => _PasswordResetDialogState();
}

class _PasswordResetDialogState extends State<PasswordResetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Dialog(
      backgroundColor: tokens.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(tokens),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_emailSent) ...[
                        _buildSuccessMessage(tokens),
                      ] else ...[
                        _buildEmailField(tokens),
                        const SizedBox(height: 20),
                        _buildInfoText(tokens),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          _buildErrorMessage(tokens),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
            _buildActionButtons(tokens),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(SemanticTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: tokens.primary.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tokens.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _emailSent ? Icons.check_circle : Icons.lock_reset,
              color: tokens.onPrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _emailSent ? 'Email Sent' : 'Reset Password',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: tokens.textPrimary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  _emailSent
                      ? 'Check your email for reset instructions'
                      : 'Enter your email to receive reset instructions',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: tokens.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField(SemanticTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email Address',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: tokens.textPrimary,
              ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          enabled: !_isLoading,
          decoration: InputDecoration(
            hintText: 'Enter your email address',
            prefixIcon: Icon(Icons.email_outlined, color: tokens.textSecondary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: tokens.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: tokens.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: tokens.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: tokens.error),
            ),
            filled: true,
            fillColor: tokens.surfaceAlt.withOpacity(0.3),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email address';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Please enter a valid email address';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildInfoText(SemanticTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tokens.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: tokens.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'We\'ll send you an email with a link to reset your password. The link will expire in 1 hour.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: tokens.textSecondary,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage(SemanticTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokens.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tokens.success.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: tokens.success,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Reset Email Sent!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: tokens.success,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ve sent a password reset link to:\n${_emailController.text}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: tokens.textSecondary,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'Please check your email and follow the instructions to reset your password.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: tokens.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(SemanticTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: tokens.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: tokens.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: tokens.error,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(SemanticTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (!_emailSent) ...[
            Expanded(
              child: TextButton(
                onPressed:
                    _isLoading ? null : () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: tokens.textSecondary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleResetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: tokens.primary,
                  foregroundColor: tokens.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            tokens.onPrimary,
                          ),
                        ),
                      )
                    : const Text('Send Reset Email'),
              ),
            ),
          ] else ...[
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: tokens.primary,
                  foregroundColor: tokens.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('OK'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    // Check rate limiting
    if (!PasswordResetService.instance.canSendResetEmail()) {
      final timeRemaining =
          PasswordResetService.instance.getTimeUntilNextReset();
      setState(() {
        _errorMessage =
            'Please wait ${timeRemaining!.inMinutes} minutes before requesting another reset email.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await PasswordResetService.instance
          .sendPasswordResetEmail(_emailController.text.trim());

      if (success) {
        setState(() {
          _emailSent = true;
        });
      } else {
        setState(() {
          _errorMessage =
              'Failed to send reset email. Please check your email address and try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again later.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../services/auth_service.dart';
import '../theme/melody_theme.dart';
import '../widgets/music_visuals.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isRegister = false;
  bool _loading = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _showMessage(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      if (_isRegister) {
        await AuthService.instance.register(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        await AuthService.instance.login(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }

      // AuthGate tự mở HomeScreen khi đăng nhập thành công.
    } on FirebaseAuthException catch (error) {
      _showMessage(AuthService.errorMessage(error));
    } catch (error) {
      debugPrint('Auth error: $error');
      _showMessage('Không thể đăng nhập. Vui lòng thử lại.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    if (_loading) return;

    setState(() => _loading = true);

    try {
      await AuthService.instance.loginWithGoogle();
    } on GoogleSignInException catch (error) {
      if (error.code != GoogleSignInExceptionCode.canceled) {
        debugPrint('Google Sign-In error: $error');
        _showMessage(
          'Đăng nhập Google thất bại. '
          'Hãy kiểm tra SHA-1 và cấu hình Firebase.',
        );
      }
    } on FirebaseAuthException catch (error) {
      _showMessage(AuthService.errorMessage(error));
    } catch (error) {
      debugPrint('Google login error: $error');
      _showMessage('Không thể đăng nhập bằng Google.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _forgotPassword() async {
    if (_loading) return;

    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _showMessage('Hãy nhập Email trước khi đặt lại mật khẩu.');
      return;
    }

    setState(() => _loading = true);

    try {
      await AuthService.instance.resetPassword(email);

      _showMessage(
        'Nếu Email hợp lệ, hãy kiểm tra hộp thư '
        'để đặt lại mật khẩu.',
      );
    } on FirebaseAuthException catch (error) {
      _showMessage(AuthService.errorMessage(error));
    } catch (error) {
      _showMessage('Không thể gửi Email đặt lại mật khẩu.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _switchMode() {
    _formKey.currentState?.reset();

    setState(() {
      _isRegister = !_isRegister;
      _passwordController.clear();
      _confirmController.clear();
    });
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: MelodyColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x087757B9),
            blurRadius: 40,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isRegister ? 'Bắt đầu cùng Melody' : 'Chào mừng trở lại',
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.7,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isRegister
                  ? 'Tạo tài khoản để lưu nhạc yêu thích'
                  : 'Đăng nhập để tiếp tục giai điệu của bạn.',
              style: const TextStyle(
                color: MelodyColors.muted,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),

            if (_isRegister) ...[
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Họ và tên',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (_isRegister && (value == null || value.trim().isEmpty)) {
                    return 'Vui lòng nhập họ tên';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
            ],

            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (value) {
                final email = value?.trim() ?? '';

                if (email.isEmpty ||
                    !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
                  return 'Email không hợp lệ';
                }

                return null;
              },
            ),

            const SizedBox(height: 15),

            TextFormField(
              controller: _passwordController,
              obscureText: _hidePassword,
              decoration: InputDecoration(
                labelText: 'Mật khẩu',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _hidePassword = !_hidePassword;
                    });
                  },
                  icon: Icon(
                    _hidePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập mật khẩu';
                }

                if (_isRegister && value.length < 6) {
                  return 'Mật khẩu phải có ít nhất 6 ký tự';
                }

                return null;
              },
            ),

            if (_isRegister) ...[
              const SizedBox(height: 15),

              TextFormField(
                controller: _confirmController,
                obscureText: _hidePassword,
                decoration: const InputDecoration(
                  labelText: 'Xác nhận mật khẩu',
                  prefixIcon: Icon(Icons.verified_user_outlined),
                ),
                validator: (value) {
                  if (_isRegister && value != _passwordController.text) {
                    return 'Mật khẩu xác nhận không khớp';
                  }
                  return null;
                },
              ),
            ],

            if (!_isRegister)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _loading ? null : _forgotPassword,
                  child: const Text('Quên mật khẩu?'),
                ),
              ),

            const SizedBox(height: 20),

            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isRegister ? 'Đăng ký tài khoản' : 'Đăng nhập',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 22),

            const Row(
              children: [
                Expanded(child: Divider()),
                Flexible(
                  flex: 3,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      'Hoặc đăng nhập bằng',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: MelodyColors.muted, fontSize: 12),
                    ),
                  ),
                ),
                Expanded(child: Divider()),
              ],
            ),

            const SizedBox(height: 14),

            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _loading ? null : _loginWithGoogle,
                icon: const Icon(Icons.account_circle_outlined),
                label: const Text('Tiếp tục với Google'),
              ),
            ),

            const SizedBox(height: 20),

            TextButton(
              onPressed: _loading ? null : _switchMode,
              child: Text(
                _isRegister
                    ? 'Đã có tài khoản? Đăng nhập'
                    : 'Chưa có tài khoản? Đăng ký ngay',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcome(bool wide) {
    return Column(
      crossAxisAlignment: wide
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MelodyMark(size: 48),
            const SizedBox(width: 13),
            const Text(
              'Melody',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.2,
              ),
            ),
          ],
        ),
        if (wide) ...[
          const SizedBox(height: 46),
          Container(
            height: 230,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: const LinearGradient(
                colors: [Color(0xFFE8DDF7), Color(0xFFF2E5EC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const RecordIllustration(size: 220),
          ),
          const SizedBox(height: 30),
          const Text(
            'Một giai điệu.\nNgàn cảm xúc.',
            style: TextStyle(
              fontSize: 42,
              height: 1.15,
              letterSpacing: -1.8,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
        ] else
          const SizedBox(height: 12),
        const Text(
          'Âm nhạc của bạn, mọi lúc mọi nơi',
          style: TextStyle(
            color: MelodyColors.muted,
            fontSize: 14,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF1ECF9),
              MelodyColors.background,
              Color(0xFFFAF3F6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: wide ? 48 : 20,
                    vertical: 32,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: wide ? 1000 : 440),
                    child: wide
                        ? Row(
                            children: [
                              Expanded(child: _buildWelcome(true)),
                              const SizedBox(width: 80),
                              Expanded(child: _buildFormCard()),
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildWelcome(false),
                              const SizedBox(height: 28),
                              _buildFormCard(),
                            ],
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

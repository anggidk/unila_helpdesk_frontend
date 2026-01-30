import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unila_helpdesk_frontend/app/app_router.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';
import 'package:unila_helpdesk_frontend/core/models/user_models.dart';

final loginEntityProvider = StateProvider.autoDispose<String>(
  (ref) => 'Mahasiswa',
);

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    // Validasi form
    if (!_formKey.currentState!.validate()) {
      setState(() => _isLoading = false);
      return;
    }

    final entity = ref.read(loginEntityProvider);
    final username = _usernameController.text.trim();

    // Deteksi apakah admin berdasarkan username
    final isAdmin = username.toLowerCase() == 'admin';

    final user = UserProfile(
      id: isAdmin ? 'ADM-001' : 'USR-SSO-001',
      name: isAdmin ? 'Administrator' : username,
      email: '$username@unila.ac.id',
      role: isAdmin ? UserRole.admin : UserRole.registered,
      entity: isAdmin ? 'Admin' : entity,
    );

    // Navigasi berdasarkan role
    if (isAdmin) {
      context.goNamed(AppRouteNames.admin);
    } else {
      context.goNamed(AppRouteNames.userShell, extra: user);
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;
            final minHeight = (constraints.maxHeight - 40)
                .clamp(0, double.infinity)
                .toDouble();
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isWide ? 520 : double.infinity,
                    minHeight: minHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 12),
                            Image.asset(
                              'assets/logo/Logo_unila.png',
                              width: 120,
                              height: 120,
                              errorBuilder: (context, error, stackTrace) {
                                return const CircleAvatar(
                                  radius: 38,
                                  backgroundColor: AppTheme.surface,
                                  child: Icon(Icons.school, size: 40),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'HELPDESK TIK UNILA',
                              style: textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Layanan Bantuan TI Unila',
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textMuted,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.outline),
                              ),
                              child: Column(
                                children: const [
                                  Text(
                                    'Waktu Layanan',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Senin-Kamis 08.00-12.00 | 13.30-16.00 WIB\nJumat 08.00-11.30 | 14.00-16.30 WIB',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Gunakan akun SSO Unila untuk masuk',
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textMuted,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Form(
                              key: _formKey,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _usernameController,
                                    enabled: !_isLoading,
                                    decoration: const InputDecoration(
                                      labelText: 'Username',
                                      hintText: 'Masukkan username',
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Username tidak boleh kosong';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _passwordController,
                                    enabled: !_isLoading,
                                    obscureText: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Password',
                                      hintText: 'Masukkan password',
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Password tidak boleh kosong';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _signIn,
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('LOGIN'),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () =>
                                  context.pushNamed(AppRouteNames.guestTicket),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('Lupa Password SSO?'),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton(
                                  onPressed: () => context.pushNamed(
                                    AppRouteNames.guestTicket,
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    minimumSize: const Size(0, 0),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Registrasi SSO',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ),
                                Text(
                                  '|',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => context.pushNamed(
                                    AppRouteNames.guestTicket,
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    minimumSize: const Size(0, 0),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Registrasi Email @unila.ac.id',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: const [
                                Expanded(child: Divider()),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Text('ATAU'),
                                ),
                                Expanded(child: Divider()),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => context.pushNamed(
                                  AppRouteNames.guestTracking,
                                ),
                                icon: const Icon(Icons.search),
                                label: const Text('Lacak Tiket'),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: Text(
                            '© ${DateTime.now().year} All RIGHT RESERVED',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppTheme.textMuted,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

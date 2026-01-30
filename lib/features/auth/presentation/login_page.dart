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

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signIn() {
    // Validasi form
    if (!_formKey.currentState!.validate()) {
      return; // Hentikan jika validasi gagal
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
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final entity = ref.watch(loginEntityProvider);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              CircleAvatar(
                radius: 38,
                backgroundColor: AppTheme.surface,
                child: Icon(
                  Icons.support_agent,
                  size: 38,
                  color: AppTheme.navy,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Helpdesk Unila',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
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
                      style: TextStyle(fontWeight: FontWeight.w700),
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
                child: Column(
                  children: [
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        hintText: 'Masukkan username',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Username tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        hintText: 'Masukkan password',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
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
                  onPressed: _signIn,
                  child: const Text('LOGIN'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {},
                child: const Text('Lupa Password SSO?'),
              ),
              const SizedBox(height: 8),
              Text(
                'Registrasi SSO - Registrasi Email @unila.ac.id',
                style: textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
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
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      context.pushNamed(AppRouteNames.guestTracking),
                  icon: const Icon(Icons.search),
                  label: const Text('Lacak Tiket'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

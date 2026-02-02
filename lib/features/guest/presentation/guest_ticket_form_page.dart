import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unila_helpdesk_frontend/app/app_providers.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';
import 'package:unila_helpdesk_frontend/core/models/ticket_models.dart';
import 'package:unila_helpdesk_frontend/features/auth/data/auth_repository.dart';
import 'package:unila_helpdesk_frontend/features/tickets/data/ticket_repository.dart';

final guestTicketSelectedCategoryProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);
final guestTicketPriorityProvider = StateProvider.autoDispose<TicketPriority>(
  (ref) => TicketPriority.low,
);

class GuestTicketFormPage extends ConsumerStatefulWidget {
  const GuestTicketFormPage({super.key});

  @override
  ConsumerState<GuestTicketFormPage> createState() =>
      _GuestTicketFormPageState();
}

class _GuestTicketFormPageState extends ConsumerState<GuestTicketFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;
  String? _statusUser;
  bool _identityUploaded = false;
  bool _selfieUploaded = false;
  bool _attachmentsError = false;

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _composeDescription() {
    final buffer = StringBuffer();
    final description = _descriptionController.text.trim();
    if (description.isNotEmpty) {
      buffer.writeln(description);
    }
    buffer.writeln('');
    buffer.writeln('--- Data Pelapor Guest ---');
    buffer.writeln('Nama: ${_nameController.text.trim()}');
    buffer.writeln('Status: ${_statusUser ?? '-'}');
    buffer.writeln('No. Identitas: ${_idController.text.trim()}');
    buffer.writeln('Email: ${_emailController.text.trim()}');
    buffer.writeln('No. Telepon: ${_phoneController.text.trim()}');
    return buffer.toString().trim();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final isValid = _formKey.currentState!.validate();
    final attachmentsValid = _identityUploaded && _selfieUploaded;
    if (!attachmentsValid) {
      setState(() => _attachmentsError = true);
    }
    if (!isValid || !attachmentsValid) {
      return;
    }

    final selectedCategory = ref.read(guestTicketSelectedCategoryProvider);
    if (selectedCategory == null || selectedCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jenis layanan wajib dipilih')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final auth = AuthRepository();
      await auth.signInAsGuest(name: name, email: email);

      final categories = ref.read(guestCategoriesProvider).value ?? [];
      final categoryName = categories
          .where((item) => item.id == selectedCategory)
          .map((item) => item.name)
          .cast<String?>()
          .firstWhere((item) => item != null, orElse: () => null);
      final title = categoryName == null
          ? 'Laporan Guest'
          : 'Laporan Guest - $categoryName';

      final draft = TicketDraft(
        title: title,
        description: _composeDescription(),
        category: selectedCategory,
        priority: ref.read(guestTicketPriorityProvider),
      );
      final response = await TicketRepository().createTicket(draft);
      if (!response.isSuccess) {
        throw Exception(
          response.error?.message ?? 'Gagal mengirim laporan guest',
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan guest berhasil dikirim.')),
      );
      context.pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(guestCategoriesProvider);
    final categories = categoriesAsync.value ?? [];
    final selectedCategory = ref.watch(guestTicketSelectedCategoryProvider);
    final selectedPriority = ref.watch(guestTicketPriorityProvider);
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Guest Ticket Form')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _InfoBanner(
            text:
                'Silakan isi formulir di bawah ini untuk melaporkan masalah tanpa login. Laporan Anda akan diproses oleh tim helpdesk kami.',
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              children: [
                _SectionCard(
                  title: 'INFORMASI TIKET',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _RequiredLabel(text: 'Jenis Layanan'),
                      const SizedBox(height: 8),
                      if (categoriesAsync.isLoading)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: LinearProgressIndicator(),
                        ),
                      if (categoriesAsync.hasError)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Gagal memuat kategori: ${categoriesAsync.error}',
                            style: const TextStyle(color: AppTheme.textMuted),
                          ),
                        ),
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        items: categories
                            .map(
                              (category) => DropdownMenuItem(
                                value: category.id,
                                child: Text(category.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => ref
                            .read(guestTicketSelectedCategoryProvider.notifier)
                            .state = value,
                        decoration: const InputDecoration(
                          hintText: '--Pilih Layanan--',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Jenis layanan wajib dipilih';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      const _RequiredLabel(text: 'Prioritas'),
                      const SizedBox(height: 10),
                      Row(
                        children: TicketPriority.values.map((priority) {
                          final isSelected = selectedPriority == priority;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: priority == TicketPriority.high ? 0 : 8,
                              ),
                              child: _PriorityChip(
                                label: priority.label,
                                selected: isSelected,
                                onTap: () => ref
                                    .read(
                                      guestTicketPriorityProvider.notifier,
                                    )
                                    .state = priority,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'INFORMASI PELAPOR',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _RequiredLabel(text: 'Nama Lengkap'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'Masukkan nama lengkap',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nama lengkap wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      const _RequiredLabel(text: 'Status User'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _statusUser,
                        items: const [
                          DropdownMenuItem(
                            value: 'Mahasiswa',
                            child: Text('Mahasiswa'),
                          ),
                          DropdownMenuItem(value: 'Dosen', child: Text('Dosen')),
                          DropdownMenuItem(
                            value: 'Tendik',
                            child: Text('Tendik'),
                          ),
                        ],
                        onChanged: (value) => setState(() {
                          _statusUser = value;
                        }),
                        decoration: const InputDecoration(
                          hintText: '--Pilih Status--',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Status user wajib dipilih';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      const _RequiredLabel(text: 'No. Identitas'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _idController,
                        decoration: const InputDecoration(
                          hintText: 'NPM / NIP / NIK',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'No. identitas wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No KTM (Mahasiswa) / NIP / NIK / SK Pengangkatan',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const _RequiredLabel(text: 'Email Aktif'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'contoh@email.com',
                          prefixIcon: Icon(Icons.mail_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email aktif wajib diisi';
                          }
                          if (!value.contains('@')) {
                            return 'Email tidak valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bukan email @unila.ac.id',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const _RequiredLabel(text: 'No. Telepon'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: '0812...',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'No. telepon wajib diisi';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'DETAIL MASALAH',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _RequiredLabel(text: 'Deskripsi Masalah'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText:
                              'Jelaskan kendala yang Anda alami secara detail...',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Deskripsi masalah wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Lampiran',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const _RequiredLabel(text: 'Wajib diisi'),
                      const SizedBox(height: 8),
                      _UploadTile(
                        title: 'Foto KTM / ID Card / SK Pengangkatan',
                        subtitle: 'JPG, PNG (Max 2MB)',
                        icon: Icons.badge_outlined,
                        isUploaded: _identityUploaded,
                        onTap: () => setState(() {
                          _identityUploaded = true;
                          _attachmentsError = false;
                        }),
                      ),
                      const SizedBox(height: 12),
                      _UploadTile(
                        title: 'Swafoto (Selfie) dengan KTM',
                        subtitle: 'JPG, PNG (Max 2MB)',
                        icon: Icons.camera_alt_outlined,
                        isUploaded: _selfieUploaded,
                        onTap: () => setState(() {
                          _selfieUploaded = true;
                          _attachmentsError = false;
                        }),
                      ),
                      if (_attachmentsError)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Lampiran wajib diisi.',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppTheme.danger,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('KIRIM LAPORAN'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentBlue.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info, color: AppTheme.accentBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppTheme.accentBlue),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleSmall?.copyWith(
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _RequiredLabel extends StatelessWidget {
  const _RequiredLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return RichText(
      text: TextSpan(
        style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        children: [
          TextSpan(text: text),
          const TextSpan(
            text: ' *',
            style: TextStyle(color: AppTheme.danger),
          ),
        ],
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.navy.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppTheme.navy : AppTheme.outline,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppTheme.navy : AppTheme.textMuted,
                  width: 1.6,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.navy,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppTheme.navy : AppTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadTile extends StatelessWidget {
  const _UploadTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isUploaded,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isUploaded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUploaded ? AppTheme.success : AppTheme.outline,
            style: BorderStyle.solid,
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(icon, color: AppTheme.navy),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isUploaded ? Icons.check_circle : Icons.upload_file,
              color: isUploaded ? AppTheme.success : AppTheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

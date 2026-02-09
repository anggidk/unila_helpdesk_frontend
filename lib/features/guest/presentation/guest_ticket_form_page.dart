import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unila_helpdesk_frontend/app/app_router.dart';
import 'package:unila_helpdesk_frontend/app/app_providers.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';
import 'package:unila_helpdesk_frontend/core/models/ticket_models.dart';
import 'package:unila_helpdesk_frontend/core/utils/file_picker_utils.dart';
import 'package:unila_helpdesk_frontend/core/widgets/attachment_tile.dart';
import 'package:unila_helpdesk_frontend/core/widgets/form_widgets.dart';
import 'package:unila_helpdesk_frontend/core/widgets/info_banner.dart';
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
  String? _identityAttachment;
  String? _selfieAttachment;
  String? _identityName;
  String? _selfieName;
  bool _isUploadingIdentity = false;
  bool _isUploadingSelfie = false;
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
    buffer.writeln('--- Data Pelapor Tamu ---');
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
    final attachmentsValid =
        _identityAttachment != null && _selfieAttachment != null;
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
      final categories = ref.read(guestCategoriesProvider).value ?? [];
      final categoryName = categories
          .where((item) => item.id == selectedCategory)
          .map((item) => item.name)
          .cast<String?>()
          .firstWhere((item) => item != null, orElse: () => null);
      final title = categoryName == null
          ? 'Laporan Tamu'
          : 'Laporan Tamu - $categoryName';

      final draft = TicketDraft(
        title: title,
        description: _composeDescription(),
        category: selectedCategory,
        priority: ref.read(guestTicketPriorityProvider),
        attachments: [
          if (_identityAttachment != null) _identityAttachment!,
          if (_selfieAttachment != null) _selfieAttachment!,
        ],
      );
      final response = await TicketRepository().createGuestTicket(
        draft: draft,
        reporterName: name,
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      if (!response.isSuccess) {
        throw Exception(
          response.error?.message ?? 'Gagal mengirim laporan tamu',
        );
      }
      final payload = response.data?['data'];
      final createdTicket = payload is Map<String, dynamic>
          ? Ticket.fromJson(payload)
          : null;
      final createdTicketID = payload is Map<String, dynamic>
          ? (payload['ticketNumber']?.toString() ??
                payload['id']?.toString() ??
                '')
          : '';
      if (!mounted) return;
      if (createdTicket != null && createdTicket.id.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Laporan tamu berhasil dikirim. Nomor tiket: ${createdTicket.displayNumber}',
            ),
          ),
        );
        context.pushNamed(AppRouteNames.ticketDetail, extra: createdTicket);
        return;
      }

      final fallbackTicketID = createdTicketID.isNotEmpty
          ? createdTicketID
          : '-';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Laporan tamu berhasil dikirim. Nomor tiket: $fallbackTicketID',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _pickGuestAttachment({required bool isIdentity}) async {
    if (isIdentity && _isUploadingIdentity) return;
    if (!isIdentity && _isUploadingSelfie) return;
    final pickedFile = await pickAttachmentFile(context);
    if (pickedFile == null) {
      return;
    }
    setState(() {
      if (isIdentity) {
        _isUploadingIdentity = true;
      } else {
        _isUploadingSelfie = true;
      }
    });
    try {
      final url = await TicketRepository().uploadAttachment(
        filename: pickedFile.name,
        bytes: pickedFile.bytes,
      );
      setState(() {
        if (isIdentity) {
          _identityAttachment = url;
          _identityName = pickedFile.name;
        } else {
          _selfieAttachment = url;
          _selfieName = pickedFile.name;
        }
        _attachmentsError = false;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          if (isIdentity) {
            _isUploadingIdentity = false;
          } else {
            _isUploadingSelfie = false;
          }
        });
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
      appBar: AppBar(title: const Text('Form Tiket Tamu')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const InfoBanner(
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
                      const RequiredLabel(text: 'Jenis Layanan'),
                      const SizedBox(height: 8),
                      ...buildCategoryLoadIndicators(
                        isLoading: categoriesAsync.isLoading,
                        error: categoriesAsync.hasError
                            ? categoriesAsync.error
                            : null,
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: selectedCategory,
                        items: categories
                            .map(
                              (category) => DropdownMenuItem(
                                value: category.id,
                                child: Text(category.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            ref
                                    .read(
                                      guestTicketSelectedCategoryProvider
                                          .notifier,
                                    )
                                    .state =
                                value,
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
                      const RequiredLabel(text: 'Prioritas'),
                      const SizedBox(height: 10),
                      PrioritySelector(
                        selected: selectedPriority,
                        onChanged: (priority) {
                          ref.read(guestTicketPriorityProvider.notifier).state =
                              priority;
                        },
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
                      const RequiredLabel(text: 'Nama Lengkap'),
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
                      const RequiredLabel(text: 'Status User'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _statusUser,
                        items: const [
                          DropdownMenuItem(
                            value: 'Mahasiswa',
                            child: Text('Mahasiswa'),
                          ),
                          DropdownMenuItem(
                            value: 'Dosen',
                            child: Text('Dosen'),
                          ),
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
                      const RequiredLabel(text: 'No. Identitas'),
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
                      const RequiredLabel(text: 'Email Aktif'),
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
                      const RequiredLabel(text: 'No. Telepon'),
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
                      const RequiredLabel(text: 'Deskripsi Masalah'),
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
                      const RequiredLabel(text: 'Wajib diisi'),
                      const SizedBox(height: 8),
                      AttachmentTile(
                        title: 'Foto KTM / ID Card / SK Pengangkatan',
                        subtitle: _identityName ?? 'JPG, PNG, PDF (Max 5MB)',
                        icon: Icons.badge_outlined,
                        isUploaded: _identityAttachment != null,
                        isUploading: _isUploadingIdentity,
                        onTap: () => _pickGuestAttachment(isIdentity: true),
                      ),
                      const SizedBox(height: 12),
                      AttachmentTile(
                        title: 'Swafoto (Selfie) dengan KTM',
                        subtitle: _selfieName ?? 'JPG, PNG, PDF (Max 5MB)',
                        icon: Icons.camera_alt_outlined,
                        isUploaded: _selfieAttachment != null,
                        isUploading: _isUploadingSelfie,
                        onTap: () => _pickGuestAttachment(isIdentity: false),
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

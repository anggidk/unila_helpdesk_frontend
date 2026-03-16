import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unila_helpdesk_frontend/app/app_router.dart';
import 'package:unila_helpdesk_frontend/app/app_providers.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';
import 'package:unila_helpdesk_frontend/core/models/ticket_models.dart';
import 'package:unila_helpdesk_frontend/core/network/api_client.dart';
import 'package:unila_helpdesk_frontend/core/utils/file_picker_utils.dart';
import 'package:unila_helpdesk_frontend/core/widgets/app_feedback_snackbar.dart';
import 'package:unila_helpdesk_frontend/core/widgets/attachment_tile.dart';
import 'package:unila_helpdesk_frontend/core/widgets/form_widgets.dart';
import 'package:unila_helpdesk_frontend/core/widgets/info_banner.dart';
import 'package:unila_helpdesk_frontend/core/widgets/user_top_app_bar.dart';
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
  final _numberIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;
  String? _entity;
  String? _lamp1;
  String? _lamp2;
  String? _lamp1Name;
  String? _lamp2Name;
  bool _isUploadingLamp1 = false;
  bool _isUploadingLamp2 = false;
  bool _attachmentsError = false;

  @override
  void dispose() {
    _nameController.dispose();
    _numberIdController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final isValid = _formKey.currentState!.validate();
    final attachmentsValid = _lamp1 != null && _lamp2 != null;
    if (!attachmentsValid) {
      setState(() => _attachmentsError = true);
    }
    if (!isValid || !attachmentsValid) {
      return;
    }

    final selectedCategory = ref.read(guestTicketSelectedCategoryProvider);
    if (selectedCategory == null || selectedCategory.isEmpty) {
      showAppFeedbackSnackBar(
        context,
        message: 'Jenis layanan wajib dipilih.',
        tone: AppFeedbackTone.warning,
      );
      return;
    }
    if (_entity == null || _entity!.isEmpty) {
      showAppFeedbackSnackBar(
        context,
        message: 'Entitas wajib dipilih.',
        tone: AppFeedbackTone.warning,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final response = await TicketRepository().createGuestTicket(
        draft: GuestTicketDraft(
          name: _nameController.text.trim(),
          numberId: _numberIdController.text.trim(),
          email: _emailController.text.trim(),
          entity: _entity!,
          serviceId: selectedCategory,
          notes: _notesController.text.trim(),
          priority: ref.read(guestTicketPriorityProvider),
          lamp1: _lamp1!,
          lamp2: _lamp2!,
        ),
      );
      if (!response.isSuccess) {
        if (!mounted) return;
        showAppFeedbackSnackBar(
          context,
          message: _guestTicketSubmitErrorMessage(response.error),
          tone: AppFeedbackTone.error,
        );
        return;
      }
      final payload = response.data?['data'];
      final createdTicket = payload is Map<String, dynamic>
          ? Ticket.fromJson(payload)
          : null;
      if (!mounted) return;
      if (createdTicket != null && createdTicket.id.isNotEmpty) {
        showAppFeedbackSnackBar(
          context,
          message:
              'Laporan tamu berhasil dikirim. Nomor tiket: ${createdTicket.displayNumber}',
          tone: AppFeedbackTone.success,
          duration: const Duration(seconds: 4),
        );
        context.goNamed(AppRouteNames.ticketDetail, extra: createdTicket);
        return;
      }
      showAppFeedbackSnackBar(
        context,
        message: 'Laporan tamu berhasil dikirim.',
        tone: AppFeedbackTone.success,
      );
    } catch (error) {
      if (!mounted) return;
      showAppFeedbackSnackBar(
        context,
        message: _normalizeUnexpectedError(error),
        tone: AppFeedbackTone.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _pickGuestAttachment({required bool firstSlot}) async {
    if (firstSlot && _isUploadingLamp1) return;
    if (!firstSlot && _isUploadingLamp2) return;
    final pickedFile = await pickAttachmentFile(context);
    if (pickedFile == null) {
      return;
    }

    setState(() {
      if (firstSlot) {
        _isUploadingLamp1 = true;
      } else {
        _isUploadingLamp2 = true;
      }
    });

    try {
      final path = await TicketRepository().uploadAttachment(
        filename: pickedFile.name,
        bytes: pickedFile.bytes,
      );
      setState(() {
        if (firstSlot) {
          _lamp1 = path;
          _lamp1Name = pickedFile.name;
        } else {
          _lamp2 = path;
          _lamp2Name = pickedFile.name;
        }
        _attachmentsError = false;
      });
    } catch (error) {
      if (!mounted) return;
      showAppFeedbackSnackBar(
        context,
        message: _normalizeUnexpectedError(error),
        tone: AppFeedbackTone.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          if (firstSlot) {
            _isUploadingLamp1 = false;
          } else {
            _isUploadingLamp2 = false;
          }
        });
      }
    }
  }

  String _guestTicketSubmitErrorMessage(ApiError? error) {
    final status = error?.statusCode;
    final message = _cleanErrorText(error?.message ?? '');
    final lower = message.toLowerCase();

    if (_isNetworkError(lower)) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet lalu coba lagi.';
    }
    if (status == 413 ||
        lower.contains('too large') ||
        lower.contains('ukuran file')) {
      return 'Ukuran lampiran terlalu besar. Gunakan file yang lebih kecil.';
    }
    if (status == 422 ||
        lower.contains('validation') ||
        lower.contains('wajib') ||
        lower.contains('invalid')) {
      return 'Data tiket belum valid. Periksa kembali isian form.';
    }
    if (status != null && status >= 500) {
      return 'Server sedang bermasalah. Coba beberapa saat lagi.';
    }
    return 'Laporan tamu gagal dikirim. Periksa data lalu coba lagi.';
  }

  String _normalizeUnexpectedError(Object error) {
    final cleaned = _cleanErrorText(error.toString());
    final lower = cleaned.toLowerCase();
    if (_isNetworkError(lower)) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet lalu coba lagi.';
    }
    return 'Terjadi kesalahan. Silakan coba lagi.';
  }

  String _cleanErrorText(String value) {
    var text = value.trim();
    if (text.startsWith('Exception:')) {
      text = text.replaceFirst('Exception:', '').trim();
    }
    if (text.startsWith('ClientException:')) {
      text = text.replaceFirst('ClientException:', '').trim();
    }
    return text;
  }

  bool _isNetworkError(String message) {
    return message.contains('failed host lookup') ||
        message.contains('socketexception') ||
        message.contains('connection reset') ||
        message.contains('timed out') ||
        message.contains('failed to fetch') ||
        message.contains('network');
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(guestCategoriesProvider);
    final categories = categoriesAsync.value ?? [];
    final selectedCategory = ref.watch(guestTicketSelectedCategoryProvider);
    final selectedPriority = ref.watch(guestTicketPriorityProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: UserTopAppBar(titleText: 'Form Tiket Tamu'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const InfoBanner(
            text:
                'Silakan lengkapi formulir berikut dengan data yang benar dan lengkap agar laporan dapat diverifikasi dan diproses oleh tim helpdesk.',
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
                        initialValue: _entity,
                        items: const [
                          DropdownMenuItem(
                            value: 'MAHASISWA',
                            child: Text('Mahasiswa'),
                          ),
                          DropdownMenuItem(
                            value: 'DOSEN',
                            child: Text('Dosen'),
                          ),
                          DropdownMenuItem(
                            value: 'TENDIK',
                            child: Text('Tendik'),
                          ),
                          DropdownMenuItem(
                            value: 'LAINNYA',
                            child: Text('Lainnya'),
                          ),
                        ],
                        onChanged: (value) => setState(() => _entity = value),
                        decoration: const InputDecoration(
                          hintText: '--Pilih Status User--',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Status user wajib dipilih';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      const RequiredLabel(text: 'No Identitas'),
                      const SizedBox(height: 4),
                      Text(
                        'Masukkan No KTM (Mahasiswa) / NIP / NIK / SK Pengangkatan',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _numberIdController,
                        decoration: const InputDecoration(
                          hintText:
                              'No KTM (Mahasiswa) / NIP / NIK / SK Pengangkatan',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'No identitas wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      const RequiredLabel(text: 'Email Aktif'),
                      const SizedBox(height: 4),
                      Text(
                        'Masukkan email Aktif (bukan email @unila.ac.id)',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
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
                        controller: _notesController,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          hintText:
                              'Jelaskan kendala yang Anda alami secara detail.',
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
                        'Lampiran Wajib',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const RequiredLabel(
                        text: 'Lampiran 1 dan Lampiran 2 wajib',
                      ),
                      const SizedBox(height: 8),
                      AttachmentTile(
                        title:
                            'Foto KTM (Mahasiswa) / ID Card / KTP / SK Pengangkatan',
                        subtitle: _lamp1Name ?? 'JPG, PNG, PDF (maks 5MB)',
                        icon: Icons.badge_outlined,
                        isUploaded: _lamp1 != null,
                        isUploading: _isUploadingLamp1,
                        onTap: () => _pickGuestAttachment(firstSlot: true),
                      ),
                      const SizedBox(height: 12),
                      AttachmentTile(
                        title:
                            'Swafoto (Selfie) dengan KTM (Mahasiswa) / ID Card / KTP / SK Pengangkatan',
                        subtitle: _lamp2Name ?? 'JPG, PNG, PDF (maks 5MB)',
                        icon: Icons.camera_alt_outlined,
                        isUploaded: _lamp2 != null,
                        isUploading: _isUploadingLamp2,
                        onTap: () => _pickGuestAttachment(firstSlot: false),
                      ),
                      if (_attachmentsError)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Lampiran 1 dan Lampiran 2 wajib diisi.',
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

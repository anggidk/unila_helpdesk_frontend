import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unila_helpdesk_frontend/app/app_providers.dart';
import 'package:unila_helpdesk_frontend/core/models/ticket_models.dart';
import 'package:unila_helpdesk_frontend/core/network/api_client.dart';
import 'package:unila_helpdesk_frontend/core/utils/file_picker_utils.dart';
import 'package:unila_helpdesk_frontend/core/utils/input_validation.dart';
import 'package:unila_helpdesk_frontend/core/utils/snackbar_utils.dart';
import 'package:unila_helpdesk_frontend/core/widgets/attachment_tile.dart';
import 'package:unila_helpdesk_frontend/core/widgets/form_widgets.dart';
import 'package:unila_helpdesk_frontend/core/widgets/user_top_app_bar.dart';
import 'package:unila_helpdesk_frontend/features/tickets/data/ticket_repository.dart';

final ticketFormSelectedCategoryProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);
final ticketFormPriorityProvider = StateProvider.autoDispose<TicketPriority>(
  (ref) => TicketPriority.medium,
);

class TicketFormPage extends ConsumerStatefulWidget {
  const TicketFormPage({super.key, this.existing});

  final Ticket? existing;

  @override
  ConsumerState<TicketFormPage> createState() => _TicketFormPageState();
}

class _TicketFormPageState extends ConsumerState<TicketFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _notesController;
  Timer? _categoryReloadTimer;
  bool _isSubmitting = false;
  bool _isUploading = false;
  String? _lamp1;
  String? _lamp1Name;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(
      text: widget.existing?.notes ?? '',
    );
    _lamp1 = widget.existing?.lamp1.isNotEmpty == true
        ? widget.existing!.lamp1
        : null;
    _lamp1Name = widget.existing?.lamp1.isNotEmpty == true
        ? widget.existing!.lamp1
        : null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(ticketFormPriorityProvider.notifier).state =
          widget.existing?.priority ?? TicketPriority.medium;
      ref
          .read(ticketFormSelectedCategoryProvider.notifier)
          .state = widget.existing?.serviceId.isNotEmpty == true
          ? widget.existing!.serviceId
          : widget.existing?.categoryId;
    });
  }

  @override
  void dispose() {
    _categoryReloadTimer?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  void _syncCategoryAutoReload(AsyncValue<List<ServiceCategory>> snapshot) {
    final shouldRetry =
        !snapshot.isLoading && (snapshot.valueOrNull?.isEmpty ?? true);
    if (!shouldRetry) {
      _categoryReloadTimer?.cancel();
      _categoryReloadTimer = null;
      return;
    }

    _categoryReloadTimer ??= Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final latest = ref.read(serviceCategoriesProvider);
      if (latest.isLoading) {
        return;
      }
      final hasData = (latest.valueOrNull?.isNotEmpty ?? false);
      if (hasData) {
        _categoryReloadTimer?.cancel();
        _categoryReloadTimer = null;
        return;
      }
      ref.invalidate(serviceCategoriesProvider);
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final selectedCategory = ref.read(ticketFormSelectedCategoryProvider);
    final selectedPriority = ref.read(ticketFormPriorityProvider);
    if (selectedCategory == null || selectedCategory.isEmpty) {
      showAppSnackBar(
        context,
        message: 'Layanan wajib dipilih.',
        tone: AppSnackTone.warning,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final draft = TicketDraft(
        serviceId: selectedCategory,
        notes: sanitizeTextInput(_notesController.text),
        priority: selectedPriority,
        lamp1: _lamp1,
      );
      final repo = TicketRepository();
      final response = widget.existing == null
          ? await repo.createTicket(draft)
          : await repo.updateTicket(id: widget.existing!.id, draft: draft);
      if (!response.isSuccess) {
        if (!mounted) return;
        showAppSnackBar(
          context,
          message: _ticketSubmitErrorMessage(response.error),
          tone: AppSnackTone.error,
        );
        return;
      }
      if (!mounted) return;
      ref.invalidate(ticketsProvider);
      showAppSnackBar(
        context,
        message: widget.existing == null
            ? 'Tiket berhasil dikirim.'
            : 'Tiket berhasil diperbarui.',
        tone: AppSnackTone.success,
      );
      context.pop(true);
    } catch (error) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: _normalizeUnexpectedError(error),
        tone: AppSnackTone.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _pickAttachment() async {
    if (_isUploading) return;
    final pickedFile = await pickAttachmentFile(context);
    if (pickedFile == null) {
      return;
    }
    setState(() => _isUploading = true);
    try {
      final path = await TicketRepository().uploadAttachment(
        filename: pickedFile.name,
        bytes: pickedFile.bytes,
      );
      setState(() {
        _lamp1 = path;
        _lamp1Name = pickedFile.name;
      });
    } catch (error) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: 'Upload lampiran gagal. Silakan coba lagi.',
        tone: AppSnackTone.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  String _ticketSubmitErrorMessage(ApiError? error) {
    final status = error?.statusCode;
    final message = _cleanErrorText(error?.message ?? '');
    final lower = message.toLowerCase();

    if (_isNetworkError(lower)) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet lalu coba lagi.';
    }
    if (status == 401 || status == 403 || lower.contains('unauthorized')) {
      return 'Sesi login berakhir. Silakan login ulang.';
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
    if (status == 404) {
      return 'Layanan tidak ditemukan. Muat ulang halaman lalu coba lagi.';
    }
    if (status != null && status >= 500) {
      return 'Server sedang bermasalah. Coba beberapa saat lagi.';
    }
    if (status == null && message.isNotEmpty) {
      return message;
    }
    return 'Tiket gagal dikirim. Periksa data lalu coba lagi.';
  }

  String _normalizeUnexpectedError(Object error) {
    final cleaned = _cleanErrorText(error.toString());
    final lower = cleaned.toLowerCase();
    if (_isNetworkError(lower)) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet lalu coba lagi.';
    }
    return 'Tiket gagal dikirim. Silakan coba lagi.';
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
    final categoriesAsync = ref.watch(serviceCategoriesProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncCategoryAutoReload(categoriesAsync);
    });
    final allCategories = categoriesAsync.value ?? <ServiceCategory>[];
    final categories = allCategories
        .where((category) => !category.guestAllowed)
        .toList();
    final selectedCategoryRaw = ref.watch(ticketFormSelectedCategoryProvider);
    final selectedCategory =
        selectedCategoryRaw != null &&
            categories.any((category) => category.id == selectedCategoryRaw)
        ? selectedCategoryRaw
        : null;
    final selectedPriority = ref.watch(ticketFormPriorityProvider);
    final isEditing = widget.existing != null;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: UserTopAppBar(
        titleText: isEditing ? 'Edit Tiket' : 'Buat Tiket Baru',
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const RequiredLabel(text: 'Layanan'),
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
                              .read(ticketFormSelectedCategoryProvider.notifier)
                              .state =
                          value,
                  decoration: const InputDecoration(
                    hintText: 'Pilih layanan internal',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Layanan wajib dipilih';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const RequiredLabel(text: 'Deskripsi Masalah'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesController,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    hintText: 'Jelaskan masalah yang Anda alami secara detail.',
                  ),
                  validator: (value) {
                    if (!hasMeaningfulText(value)) {
                      return 'Deskripsi masalah wajib diisi';
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
                    ref.read(ticketFormPriorityProvider.notifier).state =
                        priority;
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Lampiran (Opsional)',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                if (_lamp1Name != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Chip(
                      label: Text(_lamp1Name!),
                      onDeleted: () => setState(() {
                        _lamp1 = null;
                        _lamp1Name = null;
                      }),
                    ),
                  ),
                AttachmentTile(
                  title: 'Lampiran Masalah',
                  subtitle: _lamp1Name ?? 'JPG, PNG, PDF (maks 5MB)',
                  icon: Icons.attach_file,
                  isUploaded: _lamp1 != null,
                  isUploading: _isUploading,
                  onTap: _pickAttachment,
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
                        : Text(isEditing ? 'SIMPAN PERUBAHAN' : 'KIRIM TIKET'),
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

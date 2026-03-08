import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unila_helpdesk_frontend/app/app_providers.dart';
import 'package:unila_helpdesk_frontend/core/models/ticket_models.dart';
import 'package:unila_helpdesk_frontend/core/utils/file_picker_utils.dart';
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
  bool _isSubmitting = false;
  bool _isUploading = false;
  String? _lamp1;
  String? _lamp1Name;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.existing?.notes ?? '');
    _lamp1 = widget.existing?.lamp1.isNotEmpty == true ? widget.existing!.lamp1 : null;
    _lamp1Name = widget.existing?.lamp1.isNotEmpty == true ? widget.existing!.lamp1 : null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(ticketFormPriorityProvider.notifier).state =
          widget.existing?.priority ?? TicketPriority.medium;
      ref.read(ticketFormSelectedCategoryProvider.notifier).state =
          widget.existing?.serviceId.isNotEmpty == true
          ? widget.existing!.serviceId
          : widget.existing?.categoryId;
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final selectedCategory = ref.read(ticketFormSelectedCategoryProvider);
    final selectedPriority = ref.read(ticketFormPriorityProvider);
    if (selectedCategory == null || selectedCategory.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Layanan wajib dipilih')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final draft = TicketDraft(
        serviceId: selectedCategory,
        notes: _notesController.text.trim(),
        priority: selectedPriority,
        lamp1: _lamp1,
      );
      final repo = TicketRepository();
      final response = widget.existing == null
          ? await repo.createTicket(draft)
          : await repo.updateTicket(id: widget.existing!.id, draft: draft);
      if (!response.isSuccess) {
        throw Exception(response.error?.message ?? 'Gagal menyimpan tiket');
      }
      if (!mounted) return;
      ref.invalidate(ticketsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.existing == null
                ? 'Tiket berhasil dikirim.'
                : 'Tiket berhasil diperbarui.',
          ),
        ),
      );
      context.pop(true);
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(serviceCategoriesProvider);
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
                  error: categoriesAsync.hasError ? categoriesAsync.error : null,
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
                      ref.read(ticketFormSelectedCategoryProvider.notifier).state =
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
                    if (value == null || value.trim().isEmpty) {
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
                    ref.read(ticketFormPriorityProvider.notifier).state = priority;
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

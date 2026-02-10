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
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  bool _isSubmitting = false;
  bool _isUploading = false;
  final List<_AttachmentItem> _attachments = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.existing?.title ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.existing?.description ?? '',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(ticketFormPriorityProvider.notifier).state =
          widget.existing?.priority ?? TicketPriority.medium;
      ref.read(ticketFormSelectedCategoryProvider.notifier).state =
          widget.existing?.categoryId;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
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
      ).showSnackBar(const SnackBar(content: Text('Kategori wajib dipilih')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final draft = TicketDraft(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: selectedCategory,
        priority: selectedPriority,
        attachments: _attachments.map((item) => item.url).toList(),
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
      String errorMessage = error.toString();
      // Handle specific error messages from backend
      if (errorMessage.contains(
        'tiket yang sudah selesai tidak dapat diedit',
      )) {
        errorMessage = 'Tiket yang sudah selesai tidak dapat diedit';
      } else if (errorMessage.contains('tidak memiliki akses')) {
        errorMessage = 'Anda tidak memiliki akses untuk mengedit tiket ini';
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
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
      final url = await TicketRepository().uploadAttachment(
        filename: pickedFile.name,
        bytes: pickedFile.bytes,
      );
      setState(() {
        _attachments.add(_AttachmentItem(name: pickedFile.name, url: url));
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
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
    final existing = widget.existing;
    if (existing != null &&
        existing.categoryId.isNotEmpty &&
        !categories.any((category) => category.id == existing.categoryId)) {
      final matched = allCategories.where((category) {
        return category.id == existing.categoryId;
      });
      if (matched.isNotEmpty) {
        categories.insert(0, matched.first);
      } else {
        categories.insert(
          0,
          ServiceCategory(
            id: existing.categoryId,
            name: existing.category,
            guestAllowed: true,
          ),
        );
      }
    }
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
                const RequiredLabel(text: 'Kategori Layanan'),
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
                      ref
                              .read(ticketFormSelectedCategoryProvider.notifier)
                              .state =
                          value,
                  decoration: const InputDecoration(
                    hintText: 'Pilih Kategori... ',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Kategori wajib dipilih';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const RequiredLabel(text: 'Judul Masalah'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: 'Contoh: Login E-Learning Gagal...',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Judul masalah wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const RequiredLabel(text: 'Deskripsi'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Jelaskan masalah anda secara detail...',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Deskripsi wajib diisi';
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
                if (_attachments.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _attachments
                        .map(
                          (item) => Chip(
                            label: Text(item.name),
                            onDeleted: () => setState(() {
                              _attachments.remove(item);
                            }),
                          ),
                        )
                        .toList(),
                  ),
                const SizedBox(height: 8),
                AttachmentTile(
                  title: 'Tambah Lampiran',
                  subtitle: 'Maks 5MB (JPG, PNG, PDF)',
                  icon: Icons.attach_file,
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

class _AttachmentItem {
  const _AttachmentItem({required this.name, required this.url});

  final String name;
  final String url;
}

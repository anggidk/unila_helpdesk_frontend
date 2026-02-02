import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unila_helpdesk_frontend/app/app_providers.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';
import 'package:unila_helpdesk_frontend/core/models/ticket_models.dart';

final ticketFormSelectedCategoryProvider =
    StateProvider.autoDispose<String?>((ref) => null);
final ticketFormPriorityProvider =
    StateProvider.autoDispose<TicketPriority>((ref) => TicketPriority.medium);

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

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.existing?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.existing?.description ?? '');
    ref.read(ticketFormPriorityProvider.notifier).state =
        widget.existing?.priority ?? TicketPriority.medium;
    ref.read(ticketFormSelectedCategoryProvider.notifier).state =
        widget.existing?.categoryId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.existing == null
              ? 'Tiket berhasil dikirim.'
              : 'Tiket berhasil diperbarui.',
        ),
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(serviceCategoriesProvider);
    final categories = categoriesAsync.value ?? [];
    final selectedCategory = ref.watch(ticketFormSelectedCategoryProvider);
    final selectedPriority = ref.watch(ticketFormPriorityProvider);
    final isEditing = widget.existing != null;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Tiket' : 'Buat Tiket Baru'),
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
                const _RequiredLabel(text: 'Kategori Layanan'),
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
                      .read(ticketFormSelectedCategoryProvider.notifier)
                      .state = value,
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
                const _RequiredLabel(text: 'Judul Masalah'),
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
                const _RequiredLabel(text: 'Deskripsi'),
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
                              .read(ticketFormPriorityProvider.notifier)
                              .state = priority,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  'Lampiran (Opsional)',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                const _AttachmentTile(
                  title: 'Tambah Lampiran',
                  subtitle: 'Maks 5MB (JPG, PNG, PDF)',
                  icon: Icons.attach_file,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: Text(isEditing ? 'SIMPAN PERUBAHAN' : 'KIRIM TIKET'),
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

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline, style: BorderStyle.solid),
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
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
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
          const Icon(Icons.upload_file, color: AppTheme.textMuted),
        ],
      ),
    );
  }
}

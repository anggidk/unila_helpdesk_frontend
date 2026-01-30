import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unila_helpdesk_frontend/app/app_providers.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';
import 'package:unila_helpdesk_frontend/core/models/ticket_models.dart';

final ticketFormSelectedCategoryProvider = StateProvider.autoDispose<String?>((ref) => null);
final ticketFormPriorityProvider =
    StateProvider.autoDispose<TicketPriority>((ref) => TicketPriority.medium);

class TicketFormPage extends ConsumerStatefulWidget {
  const TicketFormPage({super.key, this.existing});

  final Ticket? existing;

  @override
  ConsumerState<TicketFormPage> createState() => _TicketFormPageState();
}

class _TicketFormPageState extends ConsumerState<TicketFormPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existing?.title ?? '');
    _descriptionController = TextEditingController(text: widget.existing?.description ?? '');
    ref.read(ticketFormPriorityProvider.notifier).state =
        widget.existing?.priority ?? TicketPriority.medium;
    ref.read(ticketFormSelectedCategoryProvider.notifier).state = widget.existing?.category;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.existing == null ? 'Tiket berhasil dikirim (mock).' : 'Tiket berhasil diperbarui (mock).'),
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(serviceCategoriesProvider);
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
          Text('Kategori Layanan', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: selectedCategory,
            items: categories
                .map((category) => DropdownMenuItem(
                      value: category.name,
                      child: Text(category.name),
                    ))
                .toList(),
            onChanged: (value) => ref.read(ticketFormSelectedCategoryProvider.notifier).state = value,
            decoration: const InputDecoration(hintText: 'Pilih kategori'),
          ),
          const SizedBox(height: 16),
          Text('Judul Masalah', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(hintText: 'Contoh: Login e-learning gagal'),
          ),
          const SizedBox(height: 16),
          Text('Deskripsi', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: const InputDecoration(hintText: 'Jelaskan masalah secara detail'),
          ),
          const SizedBox(height: 16),
          Text('Prioritas', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            children: TicketPriority.values.map((priority) {
              final selected = selectedPriority == priority;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: OutlinedButton(
                    onPressed: () => ref.read(ticketFormPriorityProvider.notifier).state = priority,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: selected ? AppTheme.navy : Colors.white,
                      foregroundColor: selected ? Colors.white : AppTheme.navy,
                    ),
                    child: Text(priority.label),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text('Lampiran (Opsional)', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.outline, style: BorderStyle.solid),
            ),
            child: Row(
              children: const [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.attach_file, color: AppTheme.navy),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tambah Lampiran', style: TextStyle(fontWeight: FontWeight.w700)),
                      SizedBox(height: 4),
                      Text('Maks 5MB (JPG, PNG, PDF)', style: TextStyle(color: AppTheme.textMuted)),
                    ],
                  ),
                ),
                Icon(Icons.upload_file, color: AppTheme.textMuted),
              ],
            ),
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
    );
  }
}

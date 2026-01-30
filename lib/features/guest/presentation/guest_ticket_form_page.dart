import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unila_helpdesk_frontend/app/app_providers.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';
import 'package:unila_helpdesk_frontend/core/models/ticket_models.dart';

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
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Laporan guest berhasil dikirim (mock).')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(guestCategoriesProvider);
    final selectedCategory = ref.watch(guestTicketSelectedCategoryProvider);
    final selectedPriority = ref.watch(guestTicketPriorityProvider);
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Guest Ticket Form')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 16),
          Text(
            'Informasi Tiket',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
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
                ref.read(guestTicketSelectedCategoryProvider.notifier).state =
                    value,
            decoration: const InputDecoration(labelText: 'Jenis Layanan'),
          ),
          const SizedBox(height: 12),
          Text(
            'Prioritas',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Row(
            children: TicketPriority.values.map((priority) {
              final isSelected = selectedPriority == priority;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: OutlinedButton(
                    onPressed: () =>
                        ref.read(guestTicketPriorityProvider.notifier).state =
                            priority,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isSelected
                          ? AppTheme.navy
                          : Colors.white,
                      foregroundColor: isSelected
                          ? Colors.white
                          : AppTheme.navy,
                    ),
                    child: Text(priority.label),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Text(
            'Informasi Pelapor',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nama Lengkap'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: 'Mahasiswa',
            items: const [
              DropdownMenuItem(value: 'Mahasiswa', child: Text('Mahasiswa')),
              DropdownMenuItem(value: 'Dosen', child: Text('Dosen')),
              DropdownMenuItem(value: 'Tendik', child: Text('Tendik')),
            ],
            onChanged: (_) {},
            decoration: const InputDecoration(labelText: 'Status User'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _idController,
            decoration: const InputDecoration(labelText: 'No. Identitas'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email Aktif (Bukan @unila.ac.id)',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(labelText: 'No. Telepon'),
          ),
          const SizedBox(height: 20),
          Text(
            'Detail Masalah',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Deskripsi Masalah',
              hintText: 'Jelaskan kendala secara detail',
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Lampiran',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          _AttachmentTile(
            title: 'Kartu Identitas',
            subtitle: 'JPG, PNG (Max 2MB)',
            icon: Icons.badge_outlined,
          ),
          const SizedBox(height: 12),
          _AttachmentTile(
            title: 'Selfie dengan Kartu Identitas',
            subtitle: 'JPG, PNG (Max 2MB)',
            icon: Icons.camera_alt_outlined,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              child: const Text('KIRIM LAPORAN'),
            ),
          ),
        ],
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
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
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppTheme.textMuted),
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

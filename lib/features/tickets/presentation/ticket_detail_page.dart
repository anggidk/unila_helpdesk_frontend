import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unila_helpdesk_frontend/app/app_providers.dart';
import 'package:unila_helpdesk_frontend/app/app_router.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';
import 'package:unila_helpdesk_frontend/core/models/ticket_models.dart';
import 'package:unila_helpdesk_frontend/core/utils/date_utils.dart';
import 'package:unila_helpdesk_frontend/core/utils/snackbar_utils.dart';
import 'package:unila_helpdesk_frontend/core/widgets/badges.dart';
import 'package:unila_helpdesk_frontend/core/widgets/user_top_app_bar.dart';
import 'package:unila_helpdesk_frontend/features/feedback/data/survey_repository.dart';
import 'package:unila_helpdesk_frontend/features/tickets/data/ticket_repository.dart';
import 'package:url_launcher/url_launcher.dart';

class TicketDetailPage extends ConsumerStatefulWidget {
  const TicketDetailPage({super.key, required this.ticket});

  final Ticket ticket;

  @override
  ConsumerState<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends ConsumerState<TicketDetailPage> {
  bool _isDeleting = false;
  bool _isLoadingSurvey = false;
  bool _isLoadingDetail = false;
  String? _detailError;
  late Ticket _ticket;

  @override
  void initState() {
    super.initState();
    _ticket = widget.ticket;
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoadingDetail = true;
      _detailError = null;
    });
    try {
      final detail = await TicketRepository().fetchTicketById(_ticket.id);
      if (!mounted) return;
      setState(() => _ticket = detail);
    } catch (error) {
      if (!mounted) return;
      setState(() => _detailError = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoadingDetail = false);
      }
    }
  }

  void _handleMenu(String value) {
    if (value == 'edit') {
      _openEdit();
      return;
    }
    if (value != 'delete') {
      return;
    }
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Tiket'),
        content: const Text('Apakah Anda yakin ingin menghapus tiket ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: _isDeleting
                ? null
                : () async {
                    setState(() => _isDeleting = true);
                    final response = await TicketRepository().deleteTicket(
                      _ticket.id,
                    );
                    if (!mounted) return;
                    if (!response.isSuccess) {
                      showAppSnackBar(
                        context,
                        message:
                            response.error?.message ?? 'Gagal menghapus tiket.',
                        tone: AppSnackTone.error,
                      );
                      setState(() => _isDeleting = false);
                      return;
                    }
                    ref.invalidate(ticketsProvider);
                    if (!dialogContext.mounted) return;
                    Navigator.of(dialogContext).pop();
                    context.pop();
                  },
            child: _isDeleting
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _openEdit() async {
    final updated = await context.pushNamed<bool>(
      AppRouteNames.ticketForm,
      extra: _ticket,
    );
    if (updated == true) {
      ref.invalidate(ticketsProvider);
      await _loadDetail();
    }
  }

  Future<void> _openSurvey() async {
    if (_isLoadingSurvey) return;
    setState(() => _isLoadingSurvey = true);
    try {
      final template = await SurveyRepository().fetchTemplateByCategory(
        _ticket.categoryId,
      );
      if (!mounted) return;
      final submitted = await context.pushNamed<bool>(
        AppRouteNames.survey,
        extra: SurveyPayload(ticket: _ticket, template: template),
      );
      if (submitted == true) {
        ref.invalidate(ticketsProvider);
        await _loadDetail();
      }
    } catch (error) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: _normalizeErrorMessage(error),
        tone: AppSnackTone.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingSurvey = false);
      }
    }
  }

  String _normalizeErrorMessage(Object error) {
    final text = error.toString().trim();
    if (text.startsWith('Exception:')) {
      return text.replaceFirst('Exception:', '').trim();
    }
    return text;
  }

  void _finishOrBack() {
    if (Navigator.of(context).canPop()) {
      context.pop();
      return;
    }
    context.goNamed(AppRouteNames.boot);
  }

  @override
  Widget build(BuildContext context) {
    final ticket = _ticket;
    final currentUser = ref.watch(currentUserProvider);
    final canEdit =
        currentUser != null &&
        ticket.status == TicketStatus.waiting &&
        !ticket.isGuest;
    final canGoBack = Navigator.of(context).canPop();

    return Scaffold(
      appBar: UserTopAppBar(
        titleText: 'Detail Tiket',
        leading: canGoBack
            ? null
            : IconButton(
                onPressed: _finishOrBack,
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Kembali',
              ),
        actions: [
          if (!canGoBack)
            TextButton(onPressed: _finishOrBack, child: const Text('Selesai')),
          if (canEdit)
            PopupMenuButton<String>(
              onSelected: _handleMenu,
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit Tiket')),
                PopupMenuItem(value: 'delete', child: Text('Hapus Tiket')),
              ],
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_isLoadingDetail) const LinearProgressIndicator(),
          if (_detailError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Gagal memuat detail: $_detailError',
                style: const TextStyle(color: AppTheme.textMuted),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      ticket.displayNumber,
                      style: const TextStyle(color: AppTheme.textMuted),
                    ),
                    StatusBadge(status: ticket.status),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  ticket.serviceName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          formatDate(ticket.ticketDate),
                          style: const TextStyle(color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 18,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          ticket.name.isEmpty ? '-' : ticket.name,
                          style: const TextStyle(color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                PriorityBadge(priority: ticket.priority),
                const SizedBox(height: 16),
                const Text(
                  'Deskripsi',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(ticket.notes.isEmpty ? '-' : ticket.notes),
                const SizedBox(height: 16),
                const Text(
                  'Catatan Staff',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  ticket.staffNotes.isEmpty
                      ? 'Belum ada catatan staff.'
                      : ticket.staffNotes,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Lampiran',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                if (ticket.attachments.isEmpty)
                  const Text(
                    'Tidak ada lampiran.',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                ...ticket.attachments.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _AttachmentItem(value: item),
                  ),
                ),
              ],
            ),
          ),
          if (ticket.status == TicketStatus.done && ticket.surveyRequired) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoadingSurvey ? null : _openSurvey,
                icon: _isLoadingSurvey
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.rate_review_outlined),
                label: Text(_isLoadingSurvey ? 'Memuat...' : 'Isi Umpan Balik'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget untuk menampilkan satu lampiran tiket.
/// Mendukung dua format:
///   - Baru: "{namafile}|data:{mime};base64,{data}" → tombol download
///   - Lama: nama file/path biasa → teks saja
class _AttachmentItem extends StatelessWidget {
  const _AttachmentItem({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final sepIndex = value.indexOf('|data:');
    final isDataUri = sepIndex != -1;
    final displayName = isDataUri ? value.substring(0, sepIndex) : value;
    final dataUri = isDataUri ? value.substring(sepIndex + 1) : null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: isDataUri
          ? InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                final uri = Uri.parse(dataUri!);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.attach_file, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(displayName, overflow: TextOverflow.ellipsis),
                    ),
                    const Icon(Icons.download, size: 16),
                  ],
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text(displayName),
            ),
    );
  }
}

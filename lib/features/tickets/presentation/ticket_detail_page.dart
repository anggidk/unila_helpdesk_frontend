import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unila_helpdesk_frontend/app/app_providers.dart';
import 'package:unila_helpdesk_frontend/app/app_router.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';
import 'package:unila_helpdesk_frontend/core/models/ticket_models.dart';
import 'package:unila_helpdesk_frontend/core/utils/date_utils.dart';
import 'package:unila_helpdesk_frontend/core/widgets/badges.dart';
import 'package:unila_helpdesk_frontend/features/feedback/data/survey_repository.dart';
import 'package:unila_helpdesk_frontend/features/tickets/data/ticket_repository.dart';

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
      setState(() {
        _ticket = detail;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _detailError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingDetail = false);
      }
    }
  }

  void _handleMenu(String value) {
    if (value == 'edit') {
      _openEdit();
    } else if (value == 'delete') {
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              response.error?.message ??
                                  'Gagal menghapus tiket.',
                            ),
                          ),
                        );
                        setState(() => _isDeleting = false);
                        return;
                      }
                      ref.invalidate(ticketsProvider);
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _isLoadingSurvey = false);
      }
    }
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
        !ticket.isGuest &&
        ticket.status != TicketStatus.resolved;
    final canGoBack = Navigator.of(context).canPop();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Tiket'),
        leading: canGoBack
            ? null
            : IconButton(
                onPressed: _finishOrBack,
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Kembali',
              ),
        actions: [
          if (!canGoBack)
            TextButton(
              onPressed: _finishOrBack,
              child: const Text('Selesai'),
            ),
          if (canEdit) // Only show edit menu if ticket can be edited
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
                const SizedBox(height: 8),
                Text(
                  ticket.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.category_outlined,
                      size: 18,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      ticket.category,
                      style: const TextStyle(color: AppTheme.textMuted),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      formatDate(ticket.createdAt),
                      style: const TextStyle(color: AppTheme.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                PriorityBadge(priority: ticket.priority),
                const SizedBox(height: 12),
                Text(ticket.description),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Riwayat Status',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.outline),
            ),
            child: Column(
              children: [
                if (_isLoadingDetail && ticket.history.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: LinearProgressIndicator(),
                  ),
                if (_detailError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Gagal memuat detail: $_detailError',
                      style: const TextStyle(color: AppTheme.textMuted),
                    ),
                  ),
                if (!_isLoadingDetail && ticket.history.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Belum ada riwayat status.',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                  ),
                ...ticket.history.map(
                  (update) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: AppTheme.surface,
                      child: Icon(Icons.person_outline, color: AppTheme.navy),
                    ),
                    title: Text(
                      update.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${update.description}\n${formatDateTime(update.timestamp)}',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Komentar',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          if (ticket.comments.where((comment) => comment.isStaff).isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Belum ada catatan staff.',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            ),
          ...ticket.comments
              .where((comment) => comment.isStaff)
              .map((comment) => _CommentBubble(comment: comment)),
          if (ticket.isResolved && ticket.surveyRequired && !ticket.isGuest) ...[
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

class _CommentBubble extends StatelessWidget {
  const _CommentBubble({required this.comment});

  final TicketComment comment;

  @override
  Widget build(BuildContext context) {
    const background = AppTheme.surface;
    const textColor = AppTheme.textPrimary;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const CircleAvatar(
            backgroundColor: AppTheme.surface,
            child: Icon(Icons.person, color: AppTheme.navy),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comment.author,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(comment.message, style: TextStyle(color: textColor)),
                  const SizedBox(height: 6),
                  Text(
                    formatTime(comment.timestamp),
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

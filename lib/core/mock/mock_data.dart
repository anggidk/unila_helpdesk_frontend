import 'package:unila_helpdesk_frontend/core/models/analytics_models.dart';
import 'package:unila_helpdesk_frontend/core/models/notification_models.dart';
import 'package:unila_helpdesk_frontend/core/models/survey_models.dart';
import 'package:unila_helpdesk_frontend/core/models/ticket_models.dart';
import 'package:unila_helpdesk_frontend/core/models/user_models.dart';

class MockData {
  static const registeredUser = UserProfile(
    id: 'USR-001',
    name: 'Ahmad Pratama',
    email: 'ahmad.pratama@unila.ac.id',
    role: UserRole.registered,
    entity: 'Mahasiswa FMIPA',
  );

  static const adminUser = UserProfile(
    id: 'ADM-001',
    name: 'Budi Santoso',
    email: 'admin@unila.ac.id',
    role: UserRole.admin,
    entity: 'Super Admin',
  );

  static const serviceCategories = [
    ServiceCategory(id: 'internet', name: 'Jaringan Internet', guestAllowed: false),
    ServiceCategory(id: 'website', name: 'Website Layanan', guestAllowed: false),
    ServiceCategory(id: 'vclass', name: 'VClass', guestAllowed: false),
    ServiceCategory(id: 'siakad', name: 'SIAKAD', guestAllowed: false),
    ServiceCategory(id: 'email', name: 'Email Unila', guestAllowed: false),
    ServiceCategory(id: 'membership', name: 'Keanggotaan', guestAllowed: true),
  ];

  static const guestCategories = [
    ServiceCategory(id: 'guest-password', name: 'Lupa Password', guestAllowed: true),
    ServiceCategory(id: 'guest-account', name: 'Buat Akun Baru', guestAllowed: true),
    ServiceCategory(id: 'guest-email', name: 'Buat Email @unila.ac.id', guestAllowed: true),
  ];

  static final tickets = [
    Ticket(
      id: 'TK-2026-001',
      title: 'Internet Lambat di Lab Komputer FMIPA',
      description: 'Kecepatan internet turun drastis sejak pagi.',
      category: 'Jaringan Internet',
      status: TicketStatus.inProgress,
      priority: TicketPriority.high,
      createdAt: DateTime(2026, 10, 12, 8, 0),
      reporter: 'Ahmad Pratama',
      isGuest: false,
      assignee: 'Budi Santoso',
      history: [
        TicketUpdate(
          title: 'Technician Assigned',
          description: 'Budi Santoso assigned',
          timestamp: DateTime(2026, 10, 12, 9, 30),
        ),
        TicketUpdate(
          title: 'Ticket Created',
          description: 'Reported by user',
          timestamp: DateTime(2026, 10, 12, 8, 0),
        ),
      ],
      comments: [
        TicketComment(
          author: 'Budi Santoso',
          message:
              'Mohon maaf, kami akan cek lokasi dalam 30 menit untuk memeriksa router.',
          timestamp: DateTime(2026, 10, 12, 9, 35),
          isStaff: true,
        ),
        TicketComment(
          author: 'Ahmad Pratama',
          message: 'Baik, terima kasih pak. Saya tunggu di lab.',
          timestamp: DateTime(2026, 10, 12, 9, 40),
          isStaff: false,
        ),
      ],
    ),
    Ticket(
      id: 'TK-2026-002',
      title: 'Tidak bisa login WiFi kampus',
      description: 'Login WiFi gagal untuk akun SSO.',
      category: 'Jaringan Internet',
      status: TicketStatus.waiting,
      priority: TicketPriority.medium,
      createdAt: DateTime(2026, 10, 10, 9, 15),
      reporter: 'Ahmad Pratama',
      isGuest: false,
      assignee: 'Tim Network',
      history: [
        TicketUpdate(
          title: 'Ticket Created',
          description: 'Reported by user',
          timestamp: DateTime(2026, 10, 10, 9, 15),
        ),
      ],
      comments: [],
    ),
    Ticket(
      id: 'TK-2026-003',
      title: 'Instalasi Software MatLab',
      description: 'Permintaan instalasi MatLab di lab praktikum.',
      category: 'SIAKAD',
      status: TicketStatus.resolved,
      priority: TicketPriority.low,
      createdAt: DateTime(2026, 10, 9, 13, 20),
      reporter: 'Ahmad Pratama',
      isGuest: false,
      assignee: 'Tim Lab',
      history: [
        TicketUpdate(
          title: 'Ticket Resolved',
          description: 'Software berhasil terpasang',
          timestamp: DateTime(2026, 10, 9, 15, 10),
        ),
        TicketUpdate(
          title: 'Ticket Created',
          description: 'Reported by user',
          timestamp: DateTime(2026, 10, 9, 13, 20),
        ),
      ],
      comments: [
        TicketComment(
          author: 'Tim Lab',
          message: 'MatLab sudah terinstal di 20 perangkat.',
          timestamp: DateTime(2026, 10, 9, 15, 12),
          isStaff: true,
        ),
      ],
    ),
    Ticket(
      id: 'TK-2026-004',
      title: 'Lupa Password SIAKAD Mahasiswa',
      description: 'Tidak bisa reset password lewat portal.',
      category: 'Keanggotaan',
      status: TicketStatus.resolved,
      priority: TicketPriority.medium,
      createdAt: DateTime(2026, 10, 8, 11, 0),
      reporter: 'Guest User',
      isGuest: true,
      assignee: 'Tim Helpdesk',
      history: [
        TicketUpdate(
          title: 'Ticket Resolved',
          description: 'Password reset selesai',
          timestamp: DateTime(2026, 10, 8, 12, 0),
        ),
      ],
      comments: [],
    ),
  ];

  static final surveyTemplates = [
    SurveyTemplate(
      id: 'survey-internet',
      title: 'Survey Layanan Internet',
      description: 'Kuesioner khusus layanan jaringan internet.',
      categoryId: 'internet',
      questions: [
        SurveyQuestion(
          id: 'q1',
          text: 'Seberapa puas Anda dengan kecepatan respon tim kami?',
          type: SurveyQuestionType.likert,
        ),
        SurveyQuestion(
          id: 'q2',
          text: 'Apakah masalah Anda terselesaikan dengan tuntas?',
          type: SurveyQuestionType.yesNo,
        ),
        SurveyQuestion(
          id: 'q3',
          text: 'Bagian layanan mana yang perlu ditingkatkan?',
          type: SurveyQuestionType.multipleChoice,
          options: ['Kecepatan', 'Komunikasi', 'Solusi', 'Sikap petugas'],
        ),
      ],
    ),
    SurveyTemplate(
      id: 'survey-website',
      title: 'Survey Layanan Website',
      description: 'Kuesioner untuk layanan website kampus.',
      categoryId: 'website',
      questions: [
        SurveyQuestion(
          id: 'q1',
          text: 'Seberapa mudah portal website digunakan?',
          type: SurveyQuestionType.likert,
        ),
        SurveyQuestion(
          id: 'q2',
          text: 'Apakah bug Anda ditangani dengan cepat?',
          type: SurveyQuestionType.yesNo,
        ),
      ],
    ),
    SurveyTemplate(
      id: 'survey-membership',
      title: 'Survey Keanggotaan',
      description: 'Evaluasi layanan keanggotaan dan SSO.',
      categoryId: 'membership',
      questions: [
        SurveyQuestion(
          id: 'q1',
          text: 'Apakah proses reset akun sudah jelas?',
          type: SurveyQuestionType.likert,
        ),
        SurveyQuestion(
          id: 'q2',
          text: 'Apakah petugas memberikan arahan yang jelas?',
          type: SurveyQuestionType.likert,
        ),
      ],
    ),
  ];

  static final notifications = [
    AppNotification(
      id: 'notif-1',
      title: 'Status Tiket Diperbarui',
      message: 'TK-2026-001 kini berstatus Progres.',
      timestamp: DateTime(2026, 10, 12, 10, 0),
      isRead: false,
    ),
    AppNotification(
      id: 'notif-2',
      title: 'Kuesioner Menunggu',
      message: 'Isi survey kepuasan untuk TK-2026-003.',
      timestamp: DateTime(2026, 10, 9, 16, 0),
      isRead: true,
    ),
  ];

  static const cohortRows = [
    CohortRow(label: 'Jan 2026', users: 1240, retention: [100, 42, 28, 15, 12]),
    CohortRow(label: 'Feb 2026', users: 980, retention: [100, 51, 32, 18, 8]),
    CohortRow(label: 'Mar 2026', users: 1050, retention: [100, 45, 30, 21, 0]),
    CohortRow(label: 'Apr 2026', users: 1120, retention: [100, 38, 19, 0, 0]),
    CohortRow(label: 'Mei 2026', users: 1300, retention: [100, 48, 0, 0, 0]),
  ];

  static const serviceTrends = [
    ServiceTrend(
      label: 'Internet Service',
      percentage: 45,
      note: 'High satisfaction, dip kecil saat weekend.',
    ),
    ServiceTrend(
      label: 'SIAKAD',
      percentage: 30,
      note: 'Perlu peningkatan stabilitas.',
    ),
    ServiceTrend(
      label: 'Email',
      percentage: 15,
      note: 'Permintaan reset akun meningkat.',
    ),
    ServiceTrend(
      label: 'Lainnya',
      percentage: 10,
      note: 'Permintaan sporadis.',
    ),
  ];

  static SurveyTemplate surveyForCategory(String categoryId) {
    return surveyTemplates.firstWhere(
      (template) => template.categoryId == categoryId,
      orElse: () => surveyTemplates.first,
    );
  }

  static String categoryIdForName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('internet') || lower.contains('jaringan')) {
      return 'internet';
    }
    if (lower.contains('website')) {
      return 'website';
    }
    if (lower.contains('vclass')) {
      return 'vclass';
    }
    if (lower.contains('keanggotaan')) {
      return 'membership';
    }
    return serviceCategories.first.id;
  }
}

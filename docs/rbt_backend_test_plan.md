# Dokumen Pengujian Backend Berbasis RBT dan User Story

Tanggal: 10 Maret 2026  
Sistem: Unila Helpdesk Backend (`..\unila_helpdesk_backend`)  
Strategi: `Tahap 1 RBT per modul -> Tahap 2 RBT fungsi pure -> whitebox unit test untuk pure high + medium -> blackbox/UAT per user story`

## 1. Tujuan Dokumen

Dokumen ini disusun supaya narasi skripsi tetap sinkron dengan codebase backend terbaru.

1. Semua fungsi backend tetap dianalisis berdasarkan implementasi aktual.
2. Analisis awal tetap dimulai dari modul, bukan langsung loncat ke level fungsi.
3. Pada modul yang memiliki pure function, analisis dipecah sampai level fungsi.
4. Fungsi `pure + High risk` dan `pure + Medium risk` dipilih sebagai objek `whitebox unit testing`.
5. Blackbox system test dan UAT diorganisasi berdasarkan `user story`, bukan berdasarkan modul internal.

## 2. Sumber Data dan Traceability

Sumber data fungsi diambil langsung dari kode backend:

```powershell
rg -n --glob '!**/*_test.go' "^func " ..\unila_helpdesk_backend\internal
```

Hasil inventaris per 10 Maret 2026:

1. Total fungsi: `288`.
2. Total file sumber: `34`.
3. Semua fungsi tercantum pada Lampiran A, lengkap per file, nama fungsi, dan line number.
4. Snapshot lama `244 fungsi / 33 file` sudah tidak valid lagi dan tidak dipakai sebagai dasar narasi.
5. Sumber user story untuk blackbox dan UAT diambil dari dokumen `user stories.docx`.

## 3. Metode RBT

Landasan teori: pendekatan pengujian berbasis risiko (risk-based testing) mengacu pada Amland (1999), yang mendefinisikan risiko sebagai hasil perkalian antara probability of a defect dengan cost of the defect. Implementasi pengukuran risiko mengikuti standar ISTQB dengan menggunakan dua parameter:

- `Impact (I)` dengan skala `1-5`: besarnya kerugian/dampak jika defect benar-benar terjadi pada objek uji.
- `Likelihood (L)` dengan skala `1-5`: besarnya kemungkinan terdapat defect pada objek uji.
- `Risk Score = I × L`.
- `Impact` dinilai dari dampak riil jika fungsi itu salah, bukan otomatis mewarisi criticality modul induknya.
- Helper yang sangat kecil, deterministik, dan bercabang minimal tidak otomatis mendapat `L=2`; nilai `L` harus turun bila peluang defect memang rendah.
- `Likelihood` tidak hanya ditentukan oleh jumlah branch, tetapi juga oleh keragaman tipe input, risiko boundary/default, aritmetika tanggal, serta fan-out ke lebih dari satu flow kritis.

Catatan terminologi: dalam terminologi Amland (1999), padanan `Impact` adalah `Cost` dan padanan `Likelihood` adalah `Probability`. Dokumen ini menggunakan terminologi ISTQB sebagai standar implementasi.

Klasifikasi:

- `High` = 15-25
- `Medium` = 8-14
- `Low` = 1-7

Aturan level pengujian:

1. `Pure + High` -> `Whitebox Unit Test`.
2. `Pure + Medium` -> `Whitebox Unit Test`.
3. `Pure + Low` -> `Blackbox + UAT`.
4. `Non-pure` -> `Blackbox + UAT`.

## 4. Tahap 1 - RBT Per Modul

| Modul | Cakupan File (Ringkas) | Jumlah Fungsi | I | L | Skor | Level | Strategi Uji Dominan |
|---|---|---:|---:|---:|---:|---|---|
| Auth & Session | `service/auth`, `handler/auth`, `middleware/auth`, `repo/user`, `repo/refresh` | 27 | 5 | 4 | 20 | High | Blackbox + UAT, plus drill-down pure |
| Ticket Lifecycle & Upload | `service/ticket`, `handler/ticket`, `handler/upload`, `repo/ticket` | 60 | 5 | 4 | 20 | High | Blackbox + UAT, plus drill-down pure |
| Survey Management & Scoring | `service/survey`, `service/score_utils`, `handler/survey`, `repo/survey` | 37 | 5 | 4 | 20 | High | Blackbox + UAT, plus drill-down pure |
| Reporting/Dashboard/Cohort Analytics | `service/report`, `service/cohort_analysis_service`, `handler/report`, `repo/report` | 102 | 5 | 4 | 20 | High | Blackbox + UAT, plus drill-down pure |
| Notification & FCM | `service/notification`, `handler/notification`, `repo/notification`, `fcm/client` | 21 | 3 | 3 | 9 | Medium | Blackbox + UAT |
| Category & Template Binding | `service/category`, `handler/category`, `repo/category`, `service/seed` | 20 | 3 | 2 | 6 | Low | Blackbox + UAT |
| Platform/Core | `config`, `db`, `domain`, `handler/helpers`, `handler/response`, `middleware/cors`, `util` | 21 | 3 | 1 | 3 | Low | Blackbox + UAT |

Kesimpulan Tahap 1:

1. Prioritas tertinggi tetap berada pada area transaksional dan akses: Auth serta Ticket.
2. Dengan skala `1-5`, keempat modul inti berada pada level `High` (skor 20), tetapi diferensiasi detail antar area dilakukan di Tahap 2 pada level fungsi pure.
3. Modul `Medium` dan `Low` tetap dianalisis penuh, tetapi bukan target utama whitebox kecuali ditemukan pure function yang `High` atau `Medium` namun sangat sentral.

## 5. Tahap 2 - RBT Fungsi Pure Pada Modul Terkait

Definisi pure function yang dipakai:

1. Deterministik terhadap input.
2. Tidak akses DB, network, file system, atau context HTTP.
3. Tidak bergantung langsung pada state non-deterministik seperti `time.Now`, random, atau generator ID.
4. Tidak menghasilkan side effect.

Catatan eksklusi dari daftar pure:

1. `ParseToken`, `generateRefreshToken`, `randomDigits`, `buildSurveyQuestions`, dan `buildSurveyResponseItems` tidak diperlakukan sebagai pure karena bergantung pada library eksternal yang membaca waktu runtime atau pada sumber acak.
2. `applyStatus` tidak diperlakukan sebagai pure karena memutasi objek tiket yang diterima.
3. `notifyTicketStatus` dan seluruh operasi repository/handler utama jelas non-pure karena menyentuh DB, HTTP, file, atau notifikasi.

## 5.1 Auth & Session (Pure Function)

| Fungsi | Lokasi | I | L | Skor | Level | Keputusan |
|---|---|---:|---:|---:|---|---|
| `ensureAdminAllowed` | `..\unila_helpdesk_backend\internal\service\auth_service.go:181` | 5 | 3 | 15 | High | Unit test |
| `hashToken` | `..\unila_helpdesk_backend\internal\service\auth_service.go:212` | 4 | 1 | 4 | Low | Blackbox + UAT |

## 5.2 Ticket Lifecycle & Upload (Pure Function)

| Fungsi | Lokasi | I | L | Skor | Level | Keputusan |
|---|---|---:|---:|---:|---|---|
| `normalizeInitialTicketStatus` | `..\unila_helpdesk_backend\internal\service\ticket_service.go:525` | 3 | 2 | 6 | Low | Blackbox + UAT |
| `surveyRequiredForTicket` | `..\unila_helpdesk_backend\internal\service\ticket_service.go:443` | 3 | 2 | 6 | Low | Blackbox + UAT |
| `ticketOwnedByUser` | `..\unila_helpdesk_backend\internal\service\ticket_service.go:453` | 5 | 3 | 15 | High | Unit test |
| `normalizeEntity` | `..\unila_helpdesk_backend\internal\service\ticket_service.go:469` | 3 | 2 | 6 | Low | Blackbox + UAT |
| `ticketIsGuest` | `..\unila_helpdesk_backend\internal\service\ticket_service.go:449` | 2 | 1 | 2 | Low | Blackbox + UAT |
| `normalizePriority` | `..\unila_helpdesk_backend\internal\service\ticket_service.go:458` | 2 | 1 | 2 | Low | Blackbox + UAT |
| `statusLabel` | `..\unila_helpdesk_backend\internal\service\ticket_service.go:534` | 1 | 1 | 1 | Low | Blackbox + UAT |
| `statusChangeNotification` | `..\unila_helpdesk_backend\internal\service\ticket_service.go:549` | 2 | 1 | 2 | Low | Blackbox + UAT |
| `parseTicketID` | `..\unila_helpdesk_backend\internal\service\ticket_service.go:598` | 2 | 1 | 2 | Low | Blackbox + UAT |
| `parseTicketStatus` | `..\unila_helpdesk_backend\internal\handler\ticket_handler.go:95` | 2 | 1 | 2 | Low | Blackbox + UAT |
| `isGuestServiceID` | `..\unila_helpdesk_backend\internal\service\ticket_service.go:581` | 1 | 1 | 1 | Low | Blackbox + UAT |
| `ticketIDs` | `..\unila_helpdesk_backend\internal\service\ticket_service.go:590` | 1 | 1 | 1 | Low | Blackbox + UAT |
| `cleanOptionalString` | `..\unila_helpdesk_backend\internal\service\ticket_service.go:658` | 1 | 1 | 1 | Low | Blackbox + UAT |
| `stringOrEmpty` | `..\unila_helpdesk_backend\internal\service\ticket_service.go:666` | 1 | 1 | 1 | Low | Blackbox + UAT |
| `scoreZero` | `..\unila_helpdesk_backend\internal\service\ticket_service.go:673` | 1 | 1 | 1 | Low | Blackbox + UAT |

## 5.3 Survey Management & Scoring (Pure Function)

| Fungsi | Lokasi | I | L | Skor | Level | Keputusan |
|---|---|---:|---:|---:|---|---|
| `scoreFromQuestionValue` | `..\unila_helpdesk_backend\internal\service\score_utils.go:10` | 5 | 3 | 15 | High | Unit test |
| `scoreFromYesNo` | `..\unila_helpdesk_backend\internal\service\score_utils.go:28` | 3 | 3 | 9 | Medium | Unit test |
| `scoreFromScale` | `..\unila_helpdesk_backend\internal\service\score_utils.go:47` | 5 | 4 | 20 | High | Unit test |
| `normalizeToFive` | `..\unila_helpdesk_backend\internal\service\score_utils.go:70` | 5 | 3 | 15 | High | Unit test |
| `calculateSurveyScore` | `..\unila_helpdesk_backend\internal\service\survey_service.go:288` | 5 | 4 | 20 | High | Unit test |
| `scoreToFivePoint` | `..\unila_helpdesk_backend\internal\service\score_utils.go:85` | 3 | 1 | 3 | Low | Blackbox + UAT |
| `mapSurveyTemplate` | `..\unila_helpdesk_backend\internal\service\survey_service.go:265` | 1 | 1 | 1 | Low | Blackbox + UAT |
| `mapSurveyTemplates` | `..\unila_helpdesk_backend\internal\service\survey_service.go:257` | 1 | 1 | 1 | Low | Blackbox + UAT |

## 5.4 Reporting/Dashboard/Cohort Analytics (Pure Function)

### 5.4.1 Reporting, Satisfaction, dan Export Helper

| Fungsi | Lokasi | I | L | Skor | Level | Keputusan |
|---|---|---:|---:|---:|---|---|
| `normalizePeriod` | `..\unila_helpdesk_backend\internal\service\report_service.go:39` | 3 | 2 | 6 | Low | Blackbox + UAT |
| `normalizeCohortLookback` | `..\unila_helpdesk_backend\internal\service\report_service.go:122` | 2 | 1 | 2 | Low | Blackbox + UAT |
| `normalizeCohortBuckets` | `..\unila_helpdesk_backend\internal\service\report_service.go:129` | 2 | 1 | 2 | Low | Blackbox + UAT |
| `periodRange` | `..\unila_helpdesk_backend\internal\service\report_service.go:569` | 4 | 3 | 12 | Medium | Unit test |
| `rollingReportRange` | `..\unila_helpdesk_backend\internal\service\report_service.go:580` | 4 | 3 | 12 | Medium | Unit test |
| `scoreFromResponseItem` | `..\unila_helpdesk_backend\internal\service\report_service.go:773` | 5 | 4 | 20 | High | Unit test |
| `periodStart` | `..\unila_helpdesk_backend\internal\service\report_service.go:52` | 4 | 3 | 12 | Medium | Unit test |
| `addPeriods` | `..\unila_helpdesk_backend\internal\service\report_service.go:70` | 3 | 3 | 9 | Medium | Unit test |
| `calculateCohortScores` | `..\unila_helpdesk_backend\internal\service\report_service.go:136` | 2 | 2 | 4 | Low | Blackbox + UAT |
| `pickSatisfactionOverviewItem` | `..\unila_helpdesk_backend\internal\service\report_service.go:651` | 3 | 2 | 6 | Low | Blackbox + UAT |
| `isBetterSatisfactionOverviewItem` | `..\unila_helpdesk_backend\internal\service\report_service.go:668` | 3 | 2 | 6 | Low | Blackbox + UAT |
| `buildEntityPreferenceOverview` | `..\unila_helpdesk_backend\internal\service\report_service.go:688` | 3 | 3 | 9 | Medium | Unit test |
| `buildAnswerPayload` | `..\unila_helpdesk_backend\internal\service\report_service.go:790` | 2 | 1 | 2 | Low | Blackbox + UAT |
| `formatCohortLabel` | `..\unila_helpdesk_backend\internal\service\report_service.go:83` | 1 | 1 | 1 | Low | Blackbox + UAT |
| `defaultCohortLookback` | `..\unila_helpdesk_backend\internal\service\report_service.go:96` | 1 | 1 | 1 | Low | Blackbox + UAT |
| `defaultCohortBuckets` | `..\unila_helpdesk_backend\internal\service\report_service.go:109` | 1 | 1 | 1 | Low | Blackbox + UAT |
| `nowInWIB` | `..\unila_helpdesk_backend\internal\service\report_service.go:597` | 1 | 1 | 1 | Low | Blackbox + UAT |
| `surveyResponseIDs` | `..\unila_helpdesk_backend\internal\service\report_service.go:755` | 1 | 1 | 1 | Low | Blackbox + UAT |
| `groupResponseItemsByResponseID` | `..\unila_helpdesk_backend\internal\service\report_service.go:763` | 2 | 1 | 2 | Low | Blackbox + UAT |
| `sanitizeFilename` | `..\unila_helpdesk_backend\internal\handler\report_handler.go:265` | 2 | 1 | 2 | Low | Blackbox + UAT |
| `formatAnswerValue` | `..\unila_helpdesk_backend\internal\handler\report_handler.go:273` | 1 | 1 | 1 | Low | Blackbox + UAT |

### 5.4.2 Cohort Analytics Helper

| Fungsi | Lokasi | I | L | Skor | Level | Keputusan |
|---|---|---:|---:|---:|---|---|
| `periodDiff` | `..\unila_helpdesk_backend\internal\service\cohort_analysis_service.go:415` | 3 | 3 | 9 | Medium | Unit test |
| `bucketDropOff` | `..\unila_helpdesk_backend\internal\service\cohort_analysis_service.go:439` | 3 | 2 | 6 | Low | Blackbox + UAT |
| `bucketScoreDelta` | `..\unila_helpdesk_backend\internal\service\cohort_analysis_service.go:447` | 3 | 2 | 6 | Low | Blackbox + UAT |
| `bestRetentionRows` | `..\unila_helpdesk_backend\internal\service\cohort_analysis_service.go:527` | 3 | 2 | 6 | Low | Blackbox + UAT |
| `largestDropOffRows` | `..\unila_helpdesk_backend\internal\service\cohort_analysis_service.go:562` | 3 | 2 | 6 | Low | Blackbox + UAT |
| `mostStableRow` | `..\unila_helpdesk_backend\internal\service\cohort_analysis_service.go:593` | 2 | 2 | 4 | Low | Blackbox + UAT |
| `buildCohortBucketLabels` | `..\unila_helpdesk_backend\internal\service\cohort_analysis_service.go:397` | 1 | 1 | 1 | Low | Blackbox + UAT |
| `strongestScoreShiftRow` | `..\unila_helpdesk_backend\internal\service\cohort_analysis_service.go:613` | 2 | 2 | 4 | Low | Blackbox + UAT |
| `retentionStability` | `..\unila_helpdesk_backend\internal\service\cohort_analysis_service.go:640` | 2 | 1 | 2 | Low | Blackbox + UAT |
| `roundTo` | `..\unila_helpdesk_backend\internal\service\cohort_analysis_service.go:431` | 1 | 1 | 1 | Low | Blackbox + UAT |
| `bucketRetention` | `..\unila_helpdesk_backend\internal\service\cohort_analysis_service.go:628` | 2 | 1 | 2 | Low | Blackbox + UAT |
| `bucketRetentionValue` | `..\unila_helpdesk_backend\internal\service\cohort_analysis_service.go:635` | 1 | 1 | 1 | Low | Blackbox + UAT |
| `formatSignedFloat` | `..\unila_helpdesk_backend\internal\service\cohort_analysis_service.go:658` | 1 | 1 | 1 | Low | Blackbox + UAT |
| `nearlyEqual` | `..\unila_helpdesk_backend\internal\service\cohort_analysis_service.go:665` | 1 | 1 | 1 | Low | Blackbox + UAT |
| `tieAwareTitle` | `..\unila_helpdesk_backend\internal\service\cohort_analysis_service.go:669` | 1 | 1 | 1 | Low | Blackbox + UAT |
| `tieAwareVerb` | `..\unila_helpdesk_backend\internal\service\cohort_analysis_service.go:676` | 1 | 1 | 1 | Low | Blackbox + UAT |
| `formatRowLabelGroup` | `..\unila_helpdesk_backend\internal\service\cohort_analysis_service.go:683` | 1 | 1 | 1 | Low | Blackbox + UAT |
| `formatLabelGroup` | `..\unila_helpdesk_backend\internal\service\cohort_analysis_service.go:691` | 1 | 1 | 1 | Low | Blackbox + UAT |

## 5.5 Modul Lain Yang Memiliki Pure Function

| Fungsi | Lokasi | I | L | Skor | Level | Keputusan |
|---|---|---:|---:|---:|---|---|
| `serviceIsGuestAllowed` | `..\unila_helpdesk_backend\internal\repository\category_repository.go:17` | 2 | 1 | 2 | Low | Blackbox + UAT |
| `isInvalidTokenError` | `..\unila_helpdesk_backend\internal\fcm\client.go:133` | 2 | 1 | 2 | Low | Blackbox + UAT |
| `CalcTotalPages` | `..\unila_helpdesk_backend\internal\util\pagination.go:4` | 1 | 1 | 1 | Low | Blackbox + UAT |
| `toCategoryDTOs` | `..\unila_helpdesk_backend\internal\service\category_service.go:53` | 1 | 1 | 1 | Low | Blackbox + UAT |
| `quoteIdentifier` | `..\unila_helpdesk_backend\internal\db\db.go:74` | 2 | 1 | 2 | Low | Blackbox + UAT |
| `ToUserDTO` | `..\unila_helpdesk_backend\internal\domain\dto.go:258` | 1 | 1 | 1 | Low | Blackbox + UAT |
| `TableName` | `..\unila_helpdesk_backend\internal\domain\models.go:96` | 1 | 1 | 1 | Low | Blackbox + UAT |

## 6. Keputusan Final Level Pengujian

## 6.1 Fungsi Unit Whitebox (High)

1. `ensureAdminAllowed` — I=5, L=3, Skor=15
2. `ticketOwnedByUser` — I=5, L=3, Skor=15
3. `scoreFromQuestionValue` — I=5, L=3, Skor=15
4. `scoreFromScale` — I=5, L=4, Skor=20
5. `normalizeToFive` — I=5, L=3, Skor=15
6. `calculateSurveyScore` — I=5, L=4, Skor=20
7. `scoreFromResponseItem` — I=5, L=4, Skor=20

## 6.2 Fungsi Unit Whitebox (Medium)

8. `periodRange` — I=4, L=3, Skor=12
9. `rollingReportRange` — I=4, L=3, Skor=12
10. `periodStart` — I=4, L=3, Skor=12
11. `scoreFromYesNo` — I=3, L=3, Skor=9
12. `addPeriods` — I=3, L=3, Skor=9
13. `buildEntityPreferenceOverview` — I=3, L=3, Skor=9
14. `periodDiff` — I=3, L=3, Skor=9

## 6.3 Rekap Keseluruhan

1. Total fungsi dianalisis: `288`.
2. Total file dianalisis: `34`.
3. Whitebox unit test yang dipilih oleh RBT: `14` fungsi (7 High + 7 Medium).
4. Blackbox + UAT: `274` fungsi.
5. Modul high-risk tetap konsisten: `Auth & Session`, `Ticket Lifecycle & Upload`, `Survey Management & Scoring`, dan `Reporting/Dashboard/Cohort Analytics`.

## 7. Rencana Pengujian (Sesuai Format Skripsi)

## 7.1 Whitebox Unit Testing

Objek uji: 14 fungsi pada Bab 6.1 dan 6.2.  
Fokus: branch valid/invalid, boundary value, normalisasi nilai, dan determinisme hasil.

Penekanan whitebox:

1. Auth: pembatasan admin web-only.
2. Ticket: ownership dan aturan akses tiket.
3. Survey scoring: dispatcher skor pertanyaan, konversi yes/no, normalisasi skala, dan rata-rata skor survei.
4. Reporting: penentuan window dan rentang periode laporan, aritmetika tanggal, interpretasi jawaban response item, serta agregasi preferensi entitas.
5. Cohort: penghitungan jarak antar periode untuk penentuan bucket.

## 7.2 Blackbox System Testing Berbasis User Story

Format pelaporan akhir blackbox adalah `user story`, bukan fungsi pure dan bukan modul internal.
Eksekusi blackbox dilakukan melalui `HTTP request` ke backend yang sedang berjalan, sehingga objek validasinya adalah kontrak request-response, aturan akses, dan perilaku bisnis dari sisi luar sistem.
Endpoint, payload, query, dan status code dipakai sebagai traceability teknis di bawah tiap story, bukan sebagai format utama pelaporan.
RBT tidak dipakai sebagai unit grouping blackbox; risiko hanya dipakai untuk menentukan prioritas story dan kedalaman variasi kasus.
Detail decision table per story disimpan di `docs/blackbox_decision_table_test_cases.md`.
Artefak eksekusi HTTP yang dapat dijalankan berada di `..\unila_helpdesk_backend\docs\blackbox\unila_helpdesk_blackbox.postman_collection.json` dengan environment lokal pada `..\unila_helpdesk_backend\docs\blackbox\unila_helpdesk_blackbox.local.postman_environment.json`.

Matriks pelaporan blackbox per user story:

| User Story | Aktor | Endpoint Utama | Payload/Query Utama | I | L | Skor | Prioritas | Paket Eksekusi |
|---|---|---|---|---:|---:|---:|---|---|
| `US01` Login dan sesi | Pengguna terdaftar, admin | `/auth/login`, `/auth/refresh`, `/auth/logout`, `/tickets` | `username`, `password`, `refresh_token`, `X-Client-Type` | 5 | 4 | 20 | High | Smoke, Happy, Full |
| `US02` Tamu membuat tiket akun | Tamu | `/categories/guest`, `/uploads`, `/tickets/guest`, `/tickets/search` | `name`, `numberId`, `entity`, `serviceId`, `notes`, `priority`, `lamp1`, `lamp2`, `q` | 5 | 4 | 20 | High | Smoke, Happy, Full |
| `US03` Pengguna terdaftar membuat tiket layanan | Pengguna terdaftar | `/categories`, `/uploads`, `/tickets` | `serviceId`, `notes`, `priority`, `lamp1` | 5 | 3 | 15 | High | Smoke, Happy, Full |
| `US04` Pengguna meninjau tiket | Pengguna | `/tickets`, `/tickets/:id` | - | 5 | 3 | 15 | High | Happy |
| `US05` Pengguna menerima notifikasi | Pengguna terdaftar | `/notifications`, `/notifications/fcm`, `/notifications/fcm/unregister` | token FCM register/unregister, list notifikasi | 3 | 3 | 9 | Medium | Happy, Full |
| `US06` Pengguna mengelola umpan balik | Pengguna terdaftar | `/tickets`, `/tickets/:id`, `/surveys/categories/:categoryId`, `/surveys/responses` | `ticket_id`, `answers`, state `surveyRequired` | 5 | 4 | 20 | High | Smoke, Happy, Full |
| `US07` Admin mengelola template survei | Admin | `/surveys`, `/surveys/templates/:id`, `/categories/:id/template` | `title`, `description`, `framework`, `questions`, `templateId` | 4 | 3 | 12 | Medium | Happy, Full |
| `US08` Admin melihat rekap hasil survei | Admin | `/reports/summary`, `/reports/satisfaction-summary`, `/reports/satisfaction`, `/reports/satisfaction/export`, `/reports` | `period`, `periods`, `categoryId`, `templateId` | 5 | 4 | 20 | High | Smoke, Happy, Full |
| `US09` Admin melihat analisis cohort | Admin | `/reports/cohort`, `/reports/usage`, `/reports/entity-service` | `period`, `periods`, `lookback`, `buckets` | 5 | 4 | 20 | High | Smoke, Happy, Full |
| `US10` Admin melihat riwayat survei | Admin | `/surveys/responses` | `q`, `categoryId`, `templateId`, `start`, `end`, `page`, `limit` | 3 | 3 | 9 | Medium | Happy, Full |

Paket eksekusi:

1. `Smoke`: kumpulan `HTTP request` valid paling kritis pada story high-risk.
2. `Happy`: seluruh alur utama `US01-US10`, plus request invalid representatif untuk validasi aturan akses dan payload.
3. `Full`: seluruh rule decision table.

Aturan eksekusi:

1. Defect pada `Smoke` memblokir lanjut ke `Happy` dan `Full` untuk story yang sama.
2. `Full` wajib dijalankan untuk seluruh story `High` dan untuk story `Medium` yang menjadi pendukung langsung jalur business flow utama sebelum UAT final.
3. Kontrak backend pendukung yang tidak tertulis eksplisit pada user story ditempatkan pada story terdekat: upload di `US02/US03` dan binding kategori-template di `US07`.
4. Eksekusi dapat dilakukan dengan tool `HTTP client` seperti Postman atau Newman, tetapi metode yang dicatat pada dokumen tetap `blackbox backend berbasis HTTP request`.
5. Collection otomatis diposisikan sebagai `core suite`; rule `Full` yang lebih interpretatif tetap mengacu pada decision table per story.

## 7.3 UAT

Objek uji: alur end-to-end sistem final berdasarkan `US01-US10` dengan aktor:

1. Pengguna tamu: `US02`.
2. Pengguna terdaftar: `US01`, `US03`, `US04`, `US05`, `US06`.
3. Admin helpdesk: `US01`, `US07`, `US08`, `US09`, `US10`.
4. Acceptance criteria yang murni UI, routing, empty state visual, validasi sisi klien, dan navigasi layar divalidasi pada tahap ini. Skenario UAT-only dari `user_stories.md` v1.1 meliputi: US01 Skenario 4 (sesi kedaluwarsa), US01 Skenario 6 (validasi input klien), US05 Skenario 3 (FCM skip behavior), dan US06 Skenario C (tab riwayat).

## 8. Narasi Siap Pakai Untuk Bab Metodologi Skripsi

Contoh narasi:

"Analisis risiko pengujian backend dilakukan dalam dua tahap. Tahap pertama adalah pemetaan risiko per modul berdasarkan codebase aktual untuk menentukan prioritas area uji. Tahap kedua adalah analisis detail terhadap fungsi-fungsi pure pada modul prioritas tersebut. Landasan teori risk-based testing mengacu pada Amland (1999); implementasi pengukurannya mengikuti standar ISTQB dengan parameter impact dan likelihood pada skala 1 sampai 5. Penilaian tetap dilakukan pada level objek uji yang sebenarnya, sehingga helper kecil yang hanya melakukan normalisasi sederhana tidak otomatis mewarisi severity modul induknya. Likelihood juga mempertimbangkan keragaman tipe input, risiko boundary/default, aritmetika tanggal, dan fan-out ke lebih dari satu flow kritis. Seluruh fungsi pure yang berada pada level high-risk maupun medium-risk dipilih sebagai objek whitebox unit testing, sehingga total terdapat 14 fungsi yang diuji secara whitebox (7 High + 7 Medium). Fungsi pure low-risk tetap tercakup melalui blackbox system test dan UAT. Pada sisi blackbox, unit analisis tidak lagi berupa modul internal, melainkan user story agar validasi sistem mengikuti alur bisnis yang benar-benar digunakan pengguna. Eksekusi blackbox backend dilakukan melalui HTTP request ke endpoint backend yang sedang berjalan, sehingga yang divalidasi adalah kontrak request-response, aturan akses, serta perilaku bisnis dari perspektif eksternal sistem. RBT tetap dipakai untuk menentukan prioritas story dan kedalaman variasi kasus, sedangkan detail endpoint, payload, query parameter, dan aturan akses diturunkan dari codebase backend aktual. Dengan pendekatan ini, seluruh fungsi sistem tetap tercakup dalam analisis, dan aturan seleksi whitebox bersifat konsisten: pure + high atau medium = whitebox, sisanya = blackbox + UAT."

## Lampiran A - Inventaris Semua Fungsi (288 Fungsi)

Format: `namaFungsi@line`.

- `..\unila_helpdesk_backend\internal\config\config.go` (5): `Load@32`, `envRequiredString@135`, `envRequiredBool@143`, `envRequiredInt@158`, `envRequiredDuration@173`
- `..\unila_helpdesk_backend\internal\db\db.go` (5): `Connect@16`, `EnsureDatabase@34`, `quoteIdentifier@74`, `AutoMigrate@78`, `MustAutoMigrate@84`
- `..\unila_helpdesk_backend\internal\domain\dto.go` (1): `ToUserDTO@258`
- `..\unila_helpdesk_backend\internal\domain\models.go` (1): `TableName@96`
- `..\unila_helpdesk_backend\internal\fcm\client.go` (4): `NewClient@21`, `resolveCredentialOption@43`, `SendToTokens@63`, `isInvalidTokenError@133`
- `..\unila_helpdesk_backend\internal\handler\auth_handler.go` (5): `NewAuthHandler@25`, `RegisterRoutes@29`, `login@35`, `refreshToken@54`, `logout@73`
- `..\unila_helpdesk_backend\internal\handler\category_handler.go` (6): `NewCategoryHandler@15`, `RegisterRoutes@19`, `RegisterAdminRoutes@24`, `listAll@28`, `listGuest@37`, `assignTemplate@50`
- `..\unila_helpdesk_backend\internal\handler\helpers.go` (3): `parseOptionalTime@13`, `parsePageAndLimit@26`, `parsePositiveIntQuery@39`
- `..\unila_helpdesk_backend\internal\handler\notification_handler.go` (5): `NewNotificationHandler@16`, `RegisterRoutes@20`, `listNotifications@26`, `registerFcm@40`, `unregisterFcm@58`
- `..\unila_helpdesk_backend\internal\handler\report_handler.go` (17): `NewReportHandler@23`, `RegisterRoutes@27`, `dashboardSummary@41`, `serviceTrends@50`, `satisfactionSummary@80`, `satisfactionOverview@90`, `cohortReport@100`, `surveySatisfaction@110`, `surveySatisfactionExport@122`, `templatesByCategory@181`, `surveyCategories@191`, `usageCohort@200`, `entityService@210`, `parsePeriodParams@220`, `parseCohortParams@234`, `sanitizeFilename@265`, `formatAnswerValue@273`
- `..\unila_helpdesk_backend\internal\handler\response.go` (3): `respondOK@9`, `respondCreated@13`, `respondError@17`
- `..\unila_helpdesk_backend\internal\handler\survey_handler.go` (9): `NewSurveyHandler@18`, `RegisterRoutes@22`, `listTemplates@33`, `templateByCategory@42`, `createTemplate@52`, `updateTemplate@66`, `deleteTemplate@81`, `submitResponse@90`, `listResponses@112`
- `..\unila_helpdesk_backend\internal\handler\ticket_handler.go` (11): `NewTicketHandler@20`, `RegisterRoutes@24`, `listTickets@35`, `listTicketsPaged@49`, `parseTicketStatus@95`, `searchTickets@109`, `getTicket@125`, `createTicket@140`, `createGuestTicket@159`, `updateTicket@173`, `deleteTicket@192`
- `..\unila_helpdesk_backend\internal\handler\upload_handler.go` (4): `NewUploadHandler@21`, `RegisterRoutes@28`, `upload@33`, `download@65`
- `..\unila_helpdesk_backend\internal\middleware\auth.go` (3): `AuthMiddleware@16`, `RequireRole@63`, `GetUser@79`
- `..\unila_helpdesk_backend\internal\middleware\cors.go` (1): `CORSMiddleware@10`
- `..\unila_helpdesk_backend\internal\repository\category_repository.go` (8): `serviceIsGuestAllowed@17`, `NewCategoryRepository@26`, `List@30`, `FindByID@46`, `FindByName@60`, `Upsert@69`, `UpdateTemplate@82`, `BindTemplateToCategory@102`
- `..\unila_helpdesk_backend\internal\repository\notification_repository.go` (8): `NewNotificationRepository@13`, `ListByUser@17`, `Create@25`, `NewFCMTokenRepository@33`, `Upsert@37`, `ListTokens@46`, `DeleteByUserAndTokens@54`, `DeleteByUserAndToken@61`
- `..\unila_helpdesk_backend\internal\repository\refresh_token_repository.go` (6): `NewRefreshTokenRepository@14`, `Create@18`, `FindByHash@22`, `DeleteByID@30`, `DeleteByHash@34`, `DeleteExpired@41`
- `..\unila_helpdesk_backend\internal\repository\report_repository.go` (23): `NewReportRepository@48`, `ListSurveyResponsesByCreatedRange@52`, `ListRegisteredSurveyEvents@62`, `ListActiveUsersInRange@82`, `ListTicketTotalsByCategory@97`, `CountTickets@110`, `CountOpenTickets@118`, `CountResolvedTicketsInRange@131`, `AveragePositiveSurveyScore@142`, `ListServiceSatisfactionRows@153`, `ListEntitySatisfactionRows@170`, `FindTemplateWithOrderedQuestions@193`, `ListSurveyResponsesByTicketCategoryAndTemplate@203`, `ListResponseItemsByResponseIDs@234`, `ListUsedTemplateIDsByCategory@248`, `ListUsedCategoryIDs@265`, `ListTemplatesByIDsWithQuestions@276`, `CountTicketsInRange@289`, `CountSurveysInRange@299`, `ListRegisteredTicketRowsByEntityCategory@309`, `ListRegisteredSurveyRowsByEntityCategory@325`, `ListRegisteredEntities@341`, `ListRegisteredCategories@354`
- `..\unila_helpdesk_backend\internal\repository\survey_repository.go` (10): `NewSurveyRepository@41`, `ListTemplates@45`, `FindByCategory@53`, `FindByID@72`, `CreateTemplate@80`, `ReplaceTemplate@84`, `DeleteTemplate@120`, `SaveResponse@136`, `HasResponse@153`, `ListResponses@163`
- `..\unila_helpdesk_backend\internal\repository\ticket_repository.go` (15): `NewTicketRepository@27`, `Create@31`, `Update@35`, `nullableTrimmed@60`, `nullableStringValue@71`, `SoftDelete@75`, `FindByID@79`, `ListByUser@88`, `ListAll@102`, `Search@113`, `ListFiltered@132`, `ExistsTicketNumber@193`, `UpdateStatus@201`, `GetSurveyScores@212`, `ticketStatusFlags@235`
- `..\unila_helpdesk_backend\internal\repository\user_repository.go` (3): `NewUserRepository@15`, `FindByID@19`, `FindByUsername@27`
- `..\unila_helpdesk_backend\internal\service\auth_service.go` (10): `NewAuthService@37`, `IssueToken@59`, `LoginWithPasswordClient@116`, `RefreshWithTokenClient@144`, `LogoutWithRefreshToken@171`, `ensureAdminAllowed@181`, `ParseToken@191`, `generateRefreshToken@204`, `hashToken@212`, `cleanupExpiredRefreshTokens@217`
- `..\unila_helpdesk_backend\internal\service\category_service.go` (5): `NewCategoryService@16`, `ListAll@20`, `ListGuest@28`, `AssignTemplate@42`, `toCategoryDTOs@53`
- `..\unila_helpdesk_backend\internal\service\cohort_analysis_service.go` (29): `NewCohortService@21`, `UsageCohort@32`, `EntityServiceMatrix@65`, `buildSatisfactionOverview@129`, `categoryNameMap@137`, `listRegisteredCategories@148`, `CohortReport@162`, `ensureCohortAccumulator@298`, `cohortRowsFromAccumulators@326`, `rowKeyForLabel@385`, `buildCohortBucketLabels@397`, `periodDiff@415`, `roundTo@431`, `bucketDropOff@439`, `bucketScoreDelta@447`, `buildCohortInsights@468`, `bestRetentionRows@527`, `largestDropOffRows@562`, `mostStableRow@593`, `strongestScoreShiftRow@613`, `bucketRetention@628`, `bucketRetentionValue@635`, `retentionStability@640`, `formatSignedFloat@658`, `nearlyEqual@665`, `tieAwareTitle@669`, `tieAwareVerb@676`, `formatRowLabelGroup@683`, `formatLabelGroup@691`
- `..\unila_helpdesk_backend\internal\service\notification_service.go` (4): `NewNotificationService@27`, `List@35`, `RegisterToken@54`, `UnregisterToken@72`
- `..\unila_helpdesk_backend\internal\service\report_service.go` (33): `NewReportService@26`, `normalizePeriod@39`, `periodStart@52`, `addPeriods@70`, `formatCohortLabel@83`, `defaultCohortLookback@96`, `defaultCohortBuckets@109`, `normalizeCohortLookback@122`, `normalizeCohortBuckets@129`, `calculateCohortScores@136`, `ServiceTrends@162`, `DashboardSummary@193`, `ServiceSatisfactionSummary@231`, `SatisfactionOverview@268`, `buildSatisfactionOverview@273`, `buildSatisfactionOverviewData@281`, `SurveySatisfaction@343`, `SurveySatisfactionExport@432`, `TemplatesByCategory@508`, `SurveyCategoriesWithResponses@532`, `periodRange@569`, `rollingReportRange@580`, `nowInWIB@597`, `resolveTemplate@601`, `categoryNameMap@628`, `resolveCategoryName@639`, `pickSatisfactionOverviewItem@651`, `isBetterSatisfactionOverviewItem@668`, `buildEntityPreferenceOverview@688`, `surveyResponseIDs@755`, `groupResponseItemsByResponseID@763`, `scoreFromResponseItem@773`, `buildAnswerPayload@790`
- `..\unila_helpdesk_backend\internal\service\score_utils.go` (5): `scoreFromQuestionValue@10`, `scoreFromYesNo@28`, `scoreFromScale@47`, `normalizeToFive@70`, `scoreToFivePoint@85`
- `..\unila_helpdesk_backend\internal\service\seed_service.go` (1): `DefaultCategories@18`
- `..\unila_helpdesk_backend\internal\service\survey_service.go` (13): `NewSurveyService@40`, `ListTemplates@51`, `TemplateByCategory@59`, `CreateTemplate@67`, `UpdateTemplate@88`, `buildSurveyQuestions@113`, `DeleteTemplate@140`, `SubmitSurvey@147`, `ListResponsesPaged@211`, `mapSurveyTemplates@257`, `mapSurveyTemplate@265`, `calculateSurveyScore@288`, `buildSurveyResponseItems@310`
- `..\unila_helpdesk_backend\internal\service\ticket_service.go` (30): `NewTicketService@59`, `CreateTicket@78`, `CreateGuestTicket@134`, `UpdateTicket@188`, `DeleteTicket@264`, `GetTicket@279`, `ListTickets@307`, `ListTicketsPaged@327`, `SearchTickets@363`, `resolveCategoryID@375`, `generateTicketNumber@386`, `randomDigits@404`, `applyStatus@420`, `surveyRequiredForTicket@443`, `ticketIsGuest@449`, `ticketOwnedByUser@453`, `normalizePriority@458`, `normalizeEntity@469`, `toTicketDTO@483`, `normalizeInitialTicketStatus@525`, `statusLabel@534`, `statusChangeNotification@549`, `mapTickets@568`, `isGuestServiceID@581`, `ticketIDs@590`, `parseTicketID@598`, `notifyTicketStatus@606`, `cleanOptionalString@658`, `stringOrEmpty@666`, `scoreZero@673`
- `..\unila_helpdesk_backend\internal\util\ids.go` (1): `NewID@9`
- `..\unila_helpdesk_backend\internal\util\pagination.go` (1): `CalcTotalPages@4`

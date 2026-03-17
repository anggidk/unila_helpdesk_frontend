# Dokumen Pengujian Backend Berbasis RBT (Struktur Per Modul) — v2

Tanggal revisi: 12 Maret 2026  
Versi sebelumnya: `rbt_backend_test_plan.md` (18 Februari 2026)  
Sistem: Unila Helpdesk Backend (`..\unila_helpdesk_backend`)  
Strategi: `Tahap 1 RBT per modul -> Tahap 2 RBT fungsi pure pada modul terkait -> penentuan whitebox unit vs blackbox/UAT`

## Catatan Revisi

Perubahan dari v1 (18 Februari 2026):

| Item | v1 | v2 |
|---|---|---|
| Total fungsi (non-test) | 244 | 294 |
| Total file (non-test) | 33 | 34 |
| Modul | 7 | 8 |
| File dihapus | — | `attachment_repository.go` (−6 fungsi) |
| File baru | — | `cohort_analysis_service.go` (+29 fungsi) |
| Fungsi whitebox unit test terlaksana | 9 | 14 |

---

## 1. Tujuan Dokumen

Dokumen ini disusun supaya narasi skripsi jelas:

1. Semua fungsi backend tetap dianalisis.
2. Analisis awal dilakukan per modul (bukan langsung loncat ke pure function).
3. Di modul yang memiliki pure function, dilakukan pemecahan analisis sampai level fungsi.
4. Hanya fungsi `pure + High risk` yang dipilih untuk unit testing whitebox.

---

## 2. Sumber Data dan Traceability

Sumber data fungsi diambil langsung dari kode:

```powershell
Get-ChildItem -Recurse -Filter "*.go" -Path "internal" -Exclude "*_test.go" | Select-String -Pattern "^func "
```

Hasil inventaris:

1. Total fungsi: `294`.
2. Total file: `34`.
3. Semua fungsi tercantum pada Lampiran A (per file dan nama fungsi).

---

## 3. Metode RBT

Parameter:

- `Impact (I)` skala 1-5.
- `Likelihood (L)` skala 1-5.
- `Risk Score = I x L`.

Klasifikasi:

- `High` = 15-25
- `Medium` = 8-14
- `Low` = 1-7

Aturan level pengujian:

1. `Pure + High` -> `Whitebox Unit Test`.
2. `Pure + Medium/Low` -> `Blackbox + UAT`.
3. `Non-pure` -> `Blackbox + UAT`.

---

## 4. Tahap 1 - RBT Per Modul

| Modul | Cakupan File (Ringkas) | Jumlah Fungsi | I | L | Skor | Level | Strategi Uji Dominan |
|---|---|---:|---:|---:|---:|---|---|
| Auth & Session | `service/auth`, `handler/auth`, `middleware/auth`, `repo/user`, `repo/refresh` | 27 | 5 | 4 | 20 | High | Blackbox + UAT, plus drill-down pure |
| Ticket & Attachment | `service/ticket`, `handler/ticket`, `repo/ticket`, `handler/upload` | 59 | 5 | 4 | 20 | High | Blackbox + UAT, plus drill-down pure |
| Survey & Scoring | `service/survey`, `service/score_utils`, `handler/survey`, `repo/survey` | 38 | 5 | 4 | 20 | High | Blackbox + UAT, plus drill-down pure |
| Reporting & Export | `service/report`, `handler/report`, `repo/report` | 73 | 4 | 4 | 16 | High | Blackbox + UAT, plus drill-down pure |
| Cohort Analysis | `service/cohort_analysis` | 29 | 4 | 3 | 12 | Medium | Blackbox + UAT, plus drill-down pure |
| Notification & FCM | `service/notification`, `handler/notification`, `repo/notification`, `fcm/client` | 25 | 3 | 3 | 9 | Medium | Blackbox + UAT |
| Category & Master Data | `service/category`, `handler/category`, `repo/category`, `service/seed` | 20 | 3 | 3 | 9 | Medium | Blackbox + UAT |
| Platform/Core | `config`, `db`, `util`, `handler/helpers`, `handler/response`, `middleware/cors`, `domain` | 23 | 3 | 3 | 9 | Medium | Blackbox + UAT |

Kesimpulan Tahap 1:

1. Modul prioritas tinggi: Auth, Ticket, Survey, Reporting.
2. Cohort Analysis masuk Medium — fungsionalitas baru, risiko data salah-hitung sedang.
3. Modul medium tetap dianalisis penuh, tetapi tidak menjadi target unit test utama kecuali ada pure function dengan risiko High.

---

## 5. Tahap 2 - RBT Fungsi Pure Pada Modul Terkait

Definisi pure function yang dipakai:

1. Deterministik dari input.
2. Tidak akses DB/network/file/context HTTP.
3. Tidak bergantung state runtime non-deterministik (`time.Now`, random, UUID langsung).
4. Tidak punya side effect.

## 5.1 Auth & Session (Pure Function)

| Fungsi | Lokasi | I | L | Skor | Level | Keputusan |
|---|---|---:|---:|---:|---|---|
| `ensureAdminAllowed` | `internal\service\auth_service.go@181` | 5 | 3 | 15 | High | Unit test ✅ |
| `hashToken` | `internal\service\auth_service.go@212` | 5 | 3 | 15 | High | Unit test (belum ada test) |

## 5.2 Ticket & Attachment (Pure Function)

| Fungsi | Lokasi | I | L | Skor | Level | Keputusan |
|---|---|---:|---:|---:|---|---|
| `ticketOwnedByUser` | `internal\service\ticket_service.go` | 5 | 3 | 15 | High | Unit test ✅ |
| `normalizeInitialTicketStatus` | `internal\service\ticket_service.go` | 5 | 3 | 15 | High | Unit test (belum ada test) |
| `normalizeEntity` | `internal\service\ticket_service.go` | 4 | 3 | 12 | Medium | Blackbox + UAT |
| `normalizePriority` | `internal\service\ticket_service.go` | 3 | 3 | 9 | Medium | Blackbox + UAT |
| `surveyRequiredForTicket` | `internal\service\ticket_service.go` | 4 | 3 | 12 | Medium | Blackbox + UAT |
| `ticketIsGuest` | `internal\service\ticket_service.go` | 3 | 3 | 9 | Medium | Blackbox + UAT |
| `isGuestServiceID` | `internal\service\ticket_service.go` | 3 | 3 | 9 | Medium | Blackbox + UAT |
| `parseTicketID` | `internal\service\ticket_service.go` | 3 | 2 | 6 | Low | Blackbox + UAT |
| `statusLabel` | `internal\service\ticket_service.go` | 3 | 3 | 9 | Medium | Blackbox + UAT |
| `statusChangeNotification` | `internal\service\ticket_service.go` | 3 | 3 | 9 | Medium | Blackbox + UAT |
| `cleanOptionalString` | `internal\service\ticket_service.go` | 2 | 2 | 4 | Low | Blackbox + UAT |
| `stringOrEmpty` | `internal\service\ticket_service.go` | 2 | 2 | 4 | Low | Blackbox + UAT |
| `ticketIDs` | `internal\service\ticket_service.go` | 2 | 2 | 4 | Low | Blackbox + UAT |
| `scoreZero` | `internal\service\ticket_service.go` | 1 | 1 | 1 | Low | Blackbox + UAT |
| `parseTicketStatus` | `internal\handler\ticket_handler.go@96` | 3 | 3 | 9 | Medium | Blackbox + UAT |
| `nullableTrimmed` | `internal\repository\ticket_repository.go` | 2 | 2 | 4 | Low | Blackbox + UAT |
| `nullableStringValue` | `internal\repository\ticket_repository.go` | 2 | 2 | 4 | Low | Blackbox + UAT |
| `ticketStatusFlags` | `internal\repository\ticket_repository.go` | 3 | 2 | 6 | Low | Blackbox + UAT |

## 5.3 Survey & Scoring (Pure Function)

| Fungsi | Lokasi | I | L | Skor | Level | Keputusan |
|---|---|---:|---:|---:|---|---|
| `scoreFromQuestionValue` | `internal\service\score_utils.go@10` | 5 | 4 | 20 | High | Unit test ✅ |
| `scoreFromYesNo` | `internal\service\score_utils.go@28` | 4 | 4 | 16 | High | Unit test ✅ |
| `scoreFromScale` | `internal\service\score_utils.go@47` | 5 | 4 | 20 | High | Unit test ✅ |
| `normalizeToFive` | `internal\service\score_utils.go@70` | 5 | 3 | 15 | High | Unit test ✅ |
| `calculateSurveyScore` | `internal\service\survey_service.go` | 5 | 4 | 20 | High | Unit test ✅ |
| `buildSurveyQuestions` | `internal\service\survey_service.go` | 4 | 3 | 12 | Medium | Blackbox + UAT |
| `shouldSkipSurveyAnswer` | `internal\service\survey_service.go` | 3 | 3 | 9 | Medium | Blackbox + UAT |
| `scoreToFivePoint` | `internal\service\score_utils.go@85` | 3 | 3 | 9 | Medium | Blackbox + UAT |
| `mapSurveyTemplate` | `internal\service\survey_service.go` | 3 | 3 | 9 | Medium | Blackbox + UAT |
| `mapSurveyTemplates` | `internal\service\survey_service.go` | 2 | 2 | 4 | Low | Blackbox + UAT |

## 5.4 Reporting & Export (Pure Function)

| Fungsi | Lokasi | I | L | Skor | Level | Keputusan |
|---|---|---:|---:|---:|---|---|
| `scoreFromResponseItem` | `internal\service\report_service.go` | 5 | 3 | 15 | High | Unit test ✅ |
| `buildEntityPreferenceOverview` | `internal\service\report_service.go` | 4 | 3 | 12 | Medium | Unit test ✅ |
| `periodRange` | `internal\service\report_service.go` | 4 | 3 | 12 | Medium | Unit test ✅ |
| `rollingReportRange` | `internal\service\report_service.go` | 4 | 3 | 12 | Medium | Unit test ✅ |
| `periodStart` | `internal\service\report_service.go` | 3 | 3 | 9 | Medium | Unit test ✅ |
| `addPeriods` | `internal\service\report_service.go` | 3 | 3 | 9 | Medium | Unit test ✅ |
| `pickSatisfactionOverviewItem` | `internal\service\report_service.go` | 3 | 3 | 9 | Medium | Blackbox + UAT |
| `isBetterSatisfactionOverviewItem` | `internal\service\report_service.go` | 3 | 3 | 9 | Medium | Blackbox + UAT |
| `calculateCohortScores` | `internal\service\report_service.go` | 4 | 3 | 12 | Medium | Blackbox + UAT |
| `normalizePeriod` | `internal\service\report_service.go` | 3 | 3 | 9 | Medium | Blackbox + UAT |
| `defaultCohortLookback` | `internal\service\report_service.go` | 2 | 2 | 4 | Low | Blackbox + UAT |
| `defaultCohortBuckets` | `internal\service\report_service.go` | 2 | 2 | 4 | Low | Blackbox + UAT |
| `normalizeCohortLookback` | `internal\service\report_service.go` | 2 | 2 | 4 | Low | Blackbox + UAT |
| `normalizeCohortBuckets` | `internal\service\report_service.go` | 2 | 2 | 4 | Low | Blackbox + UAT |
| `buildAnswerPayload` | `internal\service\report_service.go` | 3 | 3 | 9 | Medium | Blackbox + UAT |
| `formatCohortLabel` | `internal\service\report_service.go` | 2 | 2 | 4 | Low | Blackbox + UAT |
| `surveyResponseIDs` | `internal\service\report_service.go` | 2 | 2 | 4 | Low | Blackbox + UAT |
| `groupResponseItemsByResponseID` | `internal\service\report_service.go` | 2 | 2 | 4 | Low | Blackbox + UAT |
| `nowInWIB` | `internal\service\report_service.go` | 2 | 2 | 4 | Low | Blackbox + UAT |
| `sanitizeFilename` | `internal\handler\report_handler.go` | 2 | 2 | 4 | Low | Blackbox + UAT |
| `formatAnswerValue` | `internal\handler\report_handler.go` | 2 | 2 | 4 | Low | Blackbox + UAT |

## 5.5 Cohort Analysis (Pure Function) — Modul Baru

| Fungsi | Lokasi | I | L | Skor | Level | Keputusan |
|---|---|---:|---:|---:|---|---|
| `periodDiff` | `internal\service\cohort_analysis_service.go@415` | 4 | 3 | 12 | Medium | Unit test ✅ |
| `buildCohortInsights` | `internal\service\cohort_analysis_service.go@468` | 4 | 3 | 12 | Medium | Blackbox + UAT |
| `bestRetentionRows` | `internal\service\cohort_analysis_service.go@527` | 3 | 3 | 9 | Medium | Blackbox + UAT |
| `largestDropOffRows` | `internal\service\cohort_analysis_service.go@562` | 3 | 3 | 9 | Medium | Blackbox + UAT |
| `mostStableRow` | `internal\service\cohort_analysis_service.go@593` | 3 | 3 | 9 | Medium | Blackbox + UAT |
| `strongestScoreShiftRow` | `internal\service\cohort_analysis_service.go@613` | 3 | 3 | 9 | Medium | Blackbox + UAT |
| `bucketRetention` | `internal\service\cohort_analysis_service.go@628` | 3 | 3 | 9 | Medium | Blackbox + UAT |
| `bucketRetentionValue` | `internal\service\cohort_analysis_service.go@635` | 3 | 3 | 9 | Medium | Blackbox + UAT |
| `retentionStability` | `internal\service\cohort_analysis_service.go@640` | 3 | 3 | 9 | Medium | Blackbox + UAT |
| `roundTo` | `internal\service\cohort_analysis_service.go@431` | 2 | 2 | 4 | Low | Blackbox + UAT |
| `bucketDropOff` | `internal\service\cohort_analysis_service.go@439` | 2 | 2 | 4 | Low | Blackbox + UAT |
| `bucketScoreDelta` | `internal\service\cohort_analysis_service.go@447` | 2 | 2 | 4 | Low | Blackbox + UAT |
| `buildCohortBucketLabels` | `internal\service\cohort_analysis_service.go@397` | 2 | 2 | 4 | Low | Blackbox + UAT |
| `rowKeyForLabel` | `internal\service\cohort_analysis_service.go@385` | 2 | 2 | 4 | Low | Blackbox + UAT |
| `nearlyEqual` | `internal\service\cohort_analysis_service.go@665` | 2 | 2 | 4 | Low | Blackbox + UAT |
| `formatSignedFloat` | `internal\service\cohort_analysis_service.go@658` | 2 | 2 | 4 | Low | Blackbox + UAT |
| `tieAwareTitle` | `internal\service\cohort_analysis_service.go@669` | 2 | 2 | 4 | Low | Blackbox + UAT |
| `tieAwareVerb` | `internal\service\cohort_analysis_service.go@676` | 2 | 2 | 4 | Low | Blackbox + UAT |
| `formatRowLabelGroup` | `internal\service\cohort_analysis_service.go@683` | 2 | 2 | 4 | Low | Blackbox + UAT |
| `formatLabelGroup` | `internal\service\cohort_analysis_service.go@691` | 2 | 2 | 4 | Low | Blackbox + UAT |

## 5.6 Modul Medium/Low Lain Yang Memiliki Pure Function

| Fungsi | Lokasi | I | L | Skor | Level | Keputusan |
|---|---|---:|---:|---:|---|---|
| `toCategoryDTOs` | `internal\service\category_service.go` | 2 | 2 | 4 | Low | Blackbox + UAT |
| `serviceIsGuestAllowed` | `internal\repository\category_repository.go@17` | 3 | 2 | 6 | Low | Blackbox + UAT |
| `isInvalidTokenError` | `internal\fcm\client.go@214` | 3 | 2 | 6 | Low | Blackbox + UAT |
| `normalizeWebAppURL` | `internal\fcm\client.go@184` | 2 | 2 | 4 | Low | Blackbox + UAT |
| `copyStringMap` | `internal\fcm\client.go@192` | 1 | 1 | 1 | Low | Blackbox + UAT |
| `copyInterfaceMap` | `internal\fcm\client.go@203` | 1 | 1 | 1 | Low | Blackbox + UAT |
| `CalcTotalPages` | `internal\util\pagination.go@4` | 2 | 3 | 6 | Low | Blackbox + UAT |
| `quoteIdentifier` | `internal\db\db.go@74` | 2 | 2 | 4 | Low | Blackbox + UAT |
| `firstConcreteOrigin` | `internal\config\config.go@195` | 2 | 2 | 4 | Low | Blackbox + UAT |

---

## 6. Keputusan Final Level Pengujian

## 6.1 Fungsi Unit Whitebox (Terlaksana — 14 fungsi)

| # | Fungsi | File | Skor | Keterangan |
|---|---|---|---:|---|
| 1 | `ensureAdminAllowed` | auth_service.go | 15 | High — guard admin |
| 2 | `ticketOwnedByUser` | ticket_service.go | 15 | High — guard ownership |
| 3 | `scoreFromQuestionValue` | score_utils.go | 20 | High — konversi jawaban |
| 4 | `scoreFromYesNo` | score_utils.go | 16 | High — konversi yes/no |
| 5 | `scoreFromScale` | score_utils.go | 20 | High — konversi skala |
| 6 | `normalizeToFive` | score_utils.go | 15 | High — normalisasi |
| 7 | `calculateSurveyScore` | survey_service.go | 20 | High — agregasi skor |
| 8 | `scoreFromResponseItem` | report_service.go | 15 | High — skor per respons |
| 9 | `periodRange` | report_service.go | 12 | Medium — range waktu laporan |
| 10 | `rollingReportRange` | report_service.go | 12 | Medium — rolling window |
| 11 | `periodStart` | report_service.go | 9 | Medium — titik awal periode |
| 12 | `addPeriods` | report_service.go | 9 | Medium — kalkulasi periode |
| 13 | `buildEntityPreferenceOverview` | report_service.go | 12 | Medium — agregasi entitas |
| 14 | `periodDiff` | cohort_analysis_service.go | 12 | Medium — selisih periode cohort |

## 6.2 Fungsi High Risk Yang Belum Diuji Unit

| # | Fungsi | File | Skor | Status |
|---|---|---|---:|---|
| 1 | `hashToken` | auth_service.go | 15 | Target, belum ada test |
| 2 | `normalizeInitialTicketStatus` | ticket_service.go | 15 | Target, belum ada test |

## 6.3 Rekap Keseluruhan

1. Total fungsi dianalisis: `294`.
2. Whitebox unit test terlaksana: `14` fungsi.
3. Whitebox unit test belum terlaksana (High risk): `2` fungsi.
4. Blackbox + UAT: `278` fungsi.

---

## 7. Rencana Pengujian (Sesuai Format Skripsi)

## 7.1 Whitebox Unit Testing

Objek uji: 14 fungsi pada §6.1.  
Fokus: branch valid/invalid, boundary value, dan determinisme hasil.

## 7.2 Blackbox System Testing Berbasis RBT (Modul dan Input)

Unit analisis blackbox adalah `user story` dengan `acceptance criteria` sebagai kelas input, diturunkan via `Decision Table Testing`.

Teknik desain kasus uji:

1. `Decision table` untuk menentukan kombinasi kondisi yang benar-benar dieksekusi berdasarkan acceptance criteria.
2. `Equivalence partitioning` untuk memecah nilai valid/invalid.
3. `Boundary value` untuk nilai batas penting (contoh: ukuran file, page/limit, periods).

Matriks modul untuk blackbox:

| Modul System Test | Kelas Input Yang Diuji | I | L | Skor | Prioritas | Paket Eksekusi |
|---|---|---:|---:|---:|---|---|
| Auth & Session | username/password (valid, kosong, salah), role admin/non-admin, client channel (web/non-web), refresh token (valid/invalid/expired) | 5 | 4 | 20 | High | Smoke, Happy, Full |
| Ticket Lifecycle | role pelapor (registered/guest/admin), kelengkapan field wajib, kategori guest/non-guest, ownership akses, status update | 5 | 4 | 20 | High | Smoke, Happy, Full |
| Survey Lifecycle | role user, status tiket (resolved/non-resolved), ownership, kondisi duplicate submit | 5 | 4 | 20 | High | Smoke, Happy, Full |
| Reporting & Export | role akses report, period (valid/invalid), periods (batas/nilai invalid), mode export/non-export | 4 | 4 | 16 | High | Smoke, Happy, Full |
| Notification | token notifikasi (valid/invalid), register/unregister flow | 3 | 3 | 9 | Medium | Happy, Full |
| Category Master | data kategori publik/guest, assign template oleh admin/non-admin | 2 | 3 | 6 | Low | Happy, Full |

## 7.3 UAT

Objek uji: alur end-to-end sistem final dengan aktor:

1. Admin helpdesk.
2. Pengguna terdaftar.
3. Pengguna tamu.

---

## 8. Narasi Siap Pakai Untuk Bab Metodologi Skripsi

"Analisis risiko pengujian dilakukan dalam dua tahap. Tahap pertama adalah pemetaan risiko per modul backend untuk menentukan prioritas area uji, menghasilkan delapan modul dengan skor risiko I×L berkisar antara 9 hingga 20. Tahap kedua adalah analisis detail pada fungsi-fungsi pure di modul berisiko tinggi dan medium. Berdasarkan hasil RBT, empat belas fungsi dengan karakteristik pure dan level risiko High atau Medium dipilih dan dieksekusi sebagai unit test whitebox, dengan delapan fungsi di antaranya berskor High (≥15). Pada sisi blackbox system test, setiap test case diturunkan langsung dari acceptance criteria user story menggunakan teknik Decision Table Testing, sehingga seluruh kombinasi kondisi yang relevan tercakup tanpa redundansi. Sebelum UAT final, modul berisiko tinggi wajib lulus seluruh rule decision table, sedangkan modul medium/rendah minimal lulus skenario utama."

---

## Lampiran A - Inventaris Semua Fungsi (294 Fungsi, 34 File)

- `internal\config\config.go` (7): `Load@33`, `envRequiredString@141`, `envOptionalString@149`, `envRequiredBool@153`, `envRequiredInt@168`, `envRequiredDuration@183`, `firstConcreteOrigin@195`
- `internal\db\db.go` (5): `Connect@16`, `EnsureDatabase@34`, `quoteIdentifier@74`, `AutoMigrate@78`, `MustAutoMigrate@96`
- `internal\domain\dto.go` (1): `ToUserDTO@258`
- `internal\domain\models.go` (1): `TableName@96`
- `internal\fcm\client.go` (8): `NewClient@23`, `resolveCredentialOption@49`, `SendToTokens@69`, `webNotificationLink@165`, `normalizeWebAppURL@184`, `copyStringMap@192`, `copyInterfaceMap@203`, `isInvalidTokenError@214`
- `internal\handler\auth_handler.go` (5): `NewAuthHandler@25`, `RegisterRoutes@29`, `login@35`, `refreshToken@54`, `logout@73`
- `internal\handler\category_handler.go` (6): `NewCategoryHandler@15`, `RegisterRoutes@19`, `RegisterAdminRoutes@24`, `listAll@28`, `listGuest@37`, `assignTemplate@50`
- `internal\handler\helpers.go` (3): `parseOptionalTime@13`, `parsePageAndLimit@26`, `parsePositiveIntQuery@39`
- `internal\handler\notification_handler.go` (5): `NewNotificationHandler@16`, `RegisterRoutes@20`, `listNotifications@26`, `registerFcm@40`, `unregisterFcm@58`
- `internal\handler\report_handler.go` (17): `NewReportHandler@24`, `RegisterRoutes@31`, `dashboardSummary@45`, `serviceTrends@54`, `satisfactionSummary@84`, `satisfactionOverview@94`, `cohortReport@104`, `surveySatisfaction@114`, `surveySatisfactionExport@126`, `templatesByCategory@185`, `surveyCategories@195`, `usageCohort@204`, `entityService@214`, `parsePeriodParams@224`, `parseCohortParams@238`, `sanitizeFilename@269`, `formatAnswerValue@277`
- `internal\handler\response.go` (3): `respondOK@9`, `respondCreated@13`, `respondError@17`
- `internal\handler\survey_handler.go` (9): `NewSurveyHandler@18`, `RegisterRoutes@22`, `listTemplates@33`, `templateByCategory@42`, `createTemplate@52`, `updateTemplate@66`, `deleteTemplate@81`, `submitResponse@90`, `listResponses@112`
- `internal\handler\ticket_handler.go` (11): `NewTicketHandler@21`, `RegisterRoutes@25`, `listTickets@36`, `listTicketsPaged@50`, `parseTicketStatus@96`, `searchTickets@110`, `getTicket@126`, `createTicket@141`, `createGuestTicket@160`, `updateTicket@175`, `deleteTicket@194`
- `internal\handler\upload_handler.go` (3): `NewUploadHandler@16`, `RegisterRoutes@20`, `upload@27`
- `internal\middleware\auth.go` (3): `AuthMiddleware@16`, `RequireRole@63`, `GetUser@79`
- `internal\middleware\cors.go` (1): `CORSMiddleware@10`
- `internal\repository\category_repository.go` (8): `serviceIsGuestAllowed@17`, `NewCategoryRepository@26`, `List@30`, `FindByID@46`, `FindByName@60`, `Upsert@69`, `UpdateTemplate@82`, `BindTemplateToCategory@102`
- `internal\repository\notification_repository.go` (8): `NewNotificationRepository@13`, `ListByUser@17`, `Create@25`, `NewFCMTokenRepository@33`, `Upsert@37`, `ListTokens@46`, `DeleteByUserAndTokens@54`, `DeleteByUserAndToken@61`
- `internal\repository\refresh_token_repository.go` (6): `NewRefreshTokenRepository@14`, `Create@18`, `FindByHash@22`, `DeleteByID@30`, `DeleteByHash@34`, `DeleteExpired@41`
- `internal\repository\report_repository.go` (23): `NewReportRepository@48`, `ListSurveyResponsesByCreatedRange@52`, `ListRegisteredSurveyEvents@62`, `ListActiveUsersInRange@82`, `ListTicketTotalsByCategory@97`, `CountTickets@110`, `CountOpenTickets@118`, `CountResolvedTicketsInRange@131`, `AveragePositiveSurveyScore@142`, `ListServiceSatisfactionRows@153`, `ListEntitySatisfactionRows@170`, `FindTemplateWithOrderedQuestions@193`, `ListSurveyResponsesByTicketCategoryAndTemplate@203`, `ListResponseItemsByResponseIDs@234`, `ListUsedTemplateIDsByCategory@248`, `ListUsedCategoryIDs@265`, `ListTemplatesByIDsWithQuestions@276`, `CountTicketsInRange@289`, `CountSurveysInRange@299`, `ListRegisteredTicketRowsByEntityCategory@309`, `ListRegisteredSurveyRowsByEntityCategory@325`, `ListRegisteredEntities@341`, `ListRegisteredCategories@354`
- `internal\repository\survey_repository.go` (10): `NewSurveyRepository@41`, `ListTemplates@45`, `FindByCategory@53`, `FindByID@72`, `CreateTemplate@80`, `ReplaceTemplate@84`, `DeleteTemplate@120`, `SaveResponse@159`, `HasResponse@176`, `ListResponses@186`
- `internal\repository\ticket_repository.go` (15): `NewTicketRepository@27`, `Create@31`, `Update@35`, `SoftDelete@60`, `FindByID@71`, `ListByUser@75`, `ListAll@79`, `Search@88`, `ListFiltered@102`, `ExistsTicketNumber@113`, `ListFiltered@132`, `ExistsTicketNumber@193`, `UpdateStatus@201`, `GetSurveyScores@212`, `nullableTrimmed@235`, `nullableStringValue`, `ticketStatusFlags`
- `internal\repository\user_repository.go` (3): `NewUserRepository@15`, `FindByID@19`, `FindByUsername@27`
- `internal\service\auth_service.go` (10): `NewAuthService@37`, `IssueToken@59`, `LoginWithPasswordClient@116`, `RefreshWithTokenClient@144`, `LogoutWithRefreshToken@171`, `ensureAdminAllowed@181`, `ParseToken@191`, `generateRefreshToken@204`, `hashToken@212`, `cleanupExpiredRefreshTokens@217`
- `internal\service\category_service.go` (5): `NewCategoryService@16`, `ListAll@20`, `ListGuest@28`, `AssignTemplate@42`, `toCategoryDTOs@53`
- `internal\service\cohort_analysis_service.go` (29): `NewCohortService@21`, `UsageCohort@32`, `EntityServiceMatrix@65`, `buildSatisfactionOverview@129`, `categoryNameMap@137`, `listRegisteredCategories@148`, `CohortReport@162`, `ensureCohortAccumulator@298`, `cohortRowsFromAccumulators@326`, `rowKeyForLabel@385`, `buildCohortBucketLabels@397`, `periodDiff@415`, `roundTo@431`, `bucketDropOff@439`, `bucketScoreDelta@447`, `buildCohortInsights@468`, `bestRetentionRows@527`, `largestDropOffRows@562`, `mostStableRow@593`, `strongestScoreShiftRow@613`, `bucketRetention@628`, `bucketRetentionValue@635`, `retentionStability@640`, `formatSignedFloat@658`, `nearlyEqual@665`, `tieAwareTitle@669`, `tieAwareVerb@676`, `formatRowLabelGroup@683`, `formatLabelGroup@691`
- `internal\service\notification_service.go` (4): `NewNotificationService@27`, `List@35`, `RegisterToken@54`, `UnregisterToken@72`
- `internal\service\report_service.go` (33): `NewReportService@26`, `normalizePeriod@39`, `periodStart@52`, `addPeriods@70`, `formatCohortLabel@83`, `defaultCohortLookback@96`, `defaultCohortBuckets@109`, `normalizeCohortLookback@122`, `normalizeCohortBuckets@129`, `calculateCohortScores@136`, `ServiceTrends@162`, `DashboardSummary@193`, `ServiceSatisfactionSummary@231`, `SatisfactionOverview@268`, `buildSatisfactionOverview@273`, `buildSatisfactionOverviewData@281`, `SurveySatisfaction@343`, `SurveySatisfactionExport@443`, `TemplatesByCategory@531`, `SurveyCategoriesWithResponses@555`, `periodRange@592`, `rollingReportRange@603`, `nowInWIB@620`, `resolveTemplate@624`, `categoryNameMap@651`, `resolveCategoryName@662`, `pickSatisfactionOverviewItem@674`, `isBetterSatisfactionOverviewItem@691`, `buildEntityPreferenceOverview@711`, `surveyResponseIDs@778`, `groupResponseItemsByResponseID@786`, `scoreFromResponseItem@796`, `buildAnswerPayload@813`
- `internal\service\score_utils.go` (5): `scoreFromQuestionValue@10`, `scoreFromYesNo@28`, `scoreFromScale@47`, `normalizeToFive@70`, `scoreToFivePoint@85`
- `internal\service\seed_service.go` (1): `DefaultCategories@18`
- `internal\service\survey_service.go` (14): `NewSurveyService@40`, `ListTemplates@51`, `TemplateByCategory@59`, `CreateTemplate@67`, `UpdateTemplate@91`, `buildSurveyQuestions@116`, `DeleteTemplate@143`, `SubmitSurvey@150`, `ListResponsesPaged@217`, `mapSurveyTemplates@263`, `mapSurveyTemplate@271`, `calculateSurveyScore@294`, `buildSurveyResponseItems@316`, `shouldSkipSurveyAnswer@355`
- `internal\service\ticket_service.go` (30): `NewTicketService@59`, `CreateTicket@78`, `CreateGuestTicket@134`, `UpdateTicket@188`, `DeleteTicket@264`, `GetTicket@279`, `ListTickets@307`, `ListTicketsPaged@327`, `SearchTickets@363`, `resolveCategoryID@375`, `generateTicketNumber@386`, `randomDigits@404`, `applyStatus@420`, `surveyRequiredForTicket@443`, `ticketIsGuest@449`, `ticketOwnedByUser@453`, `normalizePriority@458`, `normalizeEntity@469`, `toTicketDTO@483`, `normalizeInitialTicketStatus@525`, `statusLabel@534`, `statusChangeNotification@549`, `mapTickets@568`, `isGuestServiceID@581`, `ticketIDs@590`, `parseTicketID@598`, `notifyTicketStatus@606`, `cleanOptionalString@658`, `stringOrEmpty@666`, `scoreZero@673`
- `internal\util\ids.go` (1): `NewID@9`
- `internal\util\pagination.go` (1): `CalcTotalPages@4`

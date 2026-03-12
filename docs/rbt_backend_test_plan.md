# Dokumen Pengujian Backend Berbasis RBT (Struktur Per Modul)

Tanggal: 18 Februari 2026  
Sistem: Unila Helpdesk Backend (`..\unila_helpdesk_backend`)  
Strategi: `Tahap 1 RBT per modul -> Tahap 2 RBT fungsi pure pada modul terkait -> penentuan whitebox unit vs blackbox/UAT`

## 1. Tujuan Dokumen

Dokumen ini disusun supaya narasi skripsi jelas:

1. Semua fungsi backend tetap dianalisis.
2. Analisis awal dilakukan per modul (bukan langsung loncat ke pure function).
3. Di modul yang memiliki pure function, dilakukan pemecahan analisis sampai level fungsi.
4. Hanya fungsi `pure + High risk` yang dipilih untuk unit testing whitebox.

## 2. Sumber Data dan Traceability

Sumber data fungsi diambil langsung dari kode:

```powershell
rg -n "^func " internal
```

Hasil inventaris:

1. Total fungsi: `244`.
2. Total file: `33`.
3. Semua fungsi tercantum pada Lampiran A (per file, nama fungsi, dan line).

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

## 4. Tahap 1 - RBT Per Modul

| Modul | Cakupan File (Ringkas) | Jumlah Fungsi | I | L | Skor | Level | Strategi Uji Dominan |
|---|---|---:|---:|---:|---:|---|---|
| Auth & Session | `service/auth`, `handler/auth`, `middleware/auth`, `repo/user`, `repo/refresh` | 27 | 5 | 4 | 20 | High | Blackbox + UAT, plus drill-down pure |
| Ticket & Attachment | `service/ticket`, `handler/ticket`, `repo/ticket`, `repo/attachment`, `handler/upload` | 59 | 5 | 4 | 20 | High | Blackbox + UAT, plus drill-down pure |
| Survey & Scoring | `service/survey`, `service/score_utils`, `handler/survey`, `repo/survey` | 36 | 5 | 4 | 20 | High | Blackbox + UAT, plus drill-down pure |
| Reporting & Export | `service/report`, `handler/report`, `repo/report` | 62 | 4 | 4 | 16 | High | Blackbox + UAT, plus drill-down pure |
| Notification & FCM | `service/notification`, `handler/notification`, `repo/notification`, `fcm/client` | 21 | 3 | 3 | 9 | Medium | Blackbox + UAT |
| Category & Master Data | `service/category`, `handler/category`, `repo/category`, `service/seed` | 19 | 3 | 3 | 9 | Medium | Blackbox + UAT |
| Platform/Core | `config`, `db`, `util`, `handler/helpers`, `handler/response`, `middleware/cors`, `domain/dto` | 20 | 3 | 3 | 9 | Medium | Blackbox + UAT |

Kesimpulan Tahap 1:

1. Modul prioritas tinggi: Auth, Ticket, Survey, Reporting.
2. Modul medium tetap dianalisis penuh, tetapi tidak menjadi target unit test utama kecuali ada pure function dengan risiko High.

## 5. Tahap 2 - RBT Fungsi Pure Pada Modul Terkait

Definisi pure function yang dipakai:

1. Deterministik dari input.
2. Tidak akses DB/network/file/context HTTP.
3. Tidak bergantung state runtime non-deterministik (`time.Now`, random, UUID langsung).
4. Tidak punya side effect.

## 5.1 Auth & Session (Pure Function)

| Fungsi | Lokasi | I | L | Skor | Level | Keputusan |
|---|---|---:|---:|---:|---|---|
| `ensureAdminAllowed` | `..\unila_helpdesk_backend\internal\service\auth_service.go:181` | 5 | 3 | 15 | High | Unit test |
| `hashToken` | `..\unila_helpdesk_backend\internal\service\auth_service.go:212` | 5 | 3 | 15 | High | Unit test |

## 5.2 Ticket & Attachment (Pure Function)

| Fungsi | Lokasi | I | L | Skor | Level | Keputusan |
|---|---|---:|---:|---:|---|---|
| `normalizeInitialTicketStatus` | `..\unila_helpdesk_backend\internal\service\ticket_service.go:551` | 5 | 3 | 15 | High | Unit test |
| `attachmentIDsFromRefs` | `..\unila_helpdesk_backend\internal\service\ticket_service.go:519` | 4 | 3 | 12 | Medium | Blackbox + UAT |
| `isDuplicateTicketIdentifierError` | `..\unila_helpdesk_backend\internal\service\ticket_service.go:539` | 4 | 2 | 8 | Medium | Blackbox + UAT |
| `statusLabel` | `..\unila_helpdesk_backend\internal\service\ticket_service.go:560` | 3 | 3 | 9 | Medium | Blackbox + UAT |
| `statusChangeNotification` | `..\unila_helpdesk_backend\internal\service\ticket_service.go:573` | 3 | 3 | 9 | Medium | Blackbox + UAT |
| `statusHistoryDescription` | `..\unila_helpdesk_backend\internal\service\ticket_service.go:592` | 3 | 3 | 9 | Medium | Blackbox + UAT |
| `ticketIDs` | `..\unila_helpdesk_backend\internal\service\ticket_service.go:618` | 2 | 2 | 4 | Low | Blackbox + UAT |
| `scoreZero` | `..\unila_helpdesk_backend\internal\service\ticket_service.go:689` | 1 | 1 | 1 | Low | Blackbox + UAT |
| `parseTicketStatus` | `..\unila_helpdesk_backend\internal\handler\ticket_handler.go:94` | 3 | 3 | 9 | Medium | Blackbox + UAT |
| `nullableTrimmed` | `..\unila_helpdesk_backend\internal\repository\ticket_repository.go:245` | 2 | 2 | 4 | Low | Blackbox + UAT |

## 5.3 Survey & Scoring (Pure Function)

| Fungsi | Lokasi | I | L | Skor | Level | Keputusan |
|---|---|---:|---:|---:|---|---|
| `scoreFromQuestionValue` | `..\unila_helpdesk_backend\internal\service\score_utils.go:10` | 5 | 4 | 20 | High | Unit test |
| `scoreFromYesNo` | `..\unila_helpdesk_backend\internal\service\score_utils.go:28` | 4 | 4 | 16 | High | Unit test |
| `scoreFromScale` | `..\unila_helpdesk_backend\internal\service\score_utils.go:47` | 5 | 4 | 20 | High | Unit test |
| `normalizeToFive` | `..\unila_helpdesk_backend\internal\service\score_utils.go:70` | 5 | 3 | 15 | High | Unit test |
| `calculateSurveyScore` | `..\unila_helpdesk_backend\internal\service\survey_service.go:292` | 5 | 4 | 20 | High | Unit test |
| `scoreToFivePoint` | `..\unila_helpdesk_backend\internal\service\score_utils.go:85` | 3 | 3 | 9 | Medium | Blackbox + UAT |
| `mapSurveyTemplate` | `..\unila_helpdesk_backend\internal\service\survey_service.go:269` | 3 | 3 | 9 | Medium | Blackbox + UAT |
| `mapSurveyTemplates` | `..\unila_helpdesk_backend\internal\service\survey_service.go:261` | 2 | 2 | 4 | Low | Blackbox + UAT |

## 5.4 Reporting & Export (Pure Function)

| Fungsi | Lokasi | I | L | Skor | Level | Keputusan |
|---|---|---:|---:|---:|---|---|
| `scoreFromResponseItem` | `..\unila_helpdesk_backend\internal\service\report_service.go:696` | 5 | 3 | 15 | High | Unit test |
| `periodRange` | `..\unila_helpdesk_backend\internal\service\report_service.go:621` | 4 | 3 | 12 | Medium | Blackbox + UAT |
| `normalizePeriod` | `..\unila_helpdesk_backend\internal\service\report_service.go:107` | 3 | 3 | 9 | Medium | Blackbox + UAT |
| `periodStart` | `..\unila_helpdesk_backend\internal\service\report_service.go:120` | 3 | 3 | 9 | Medium | Blackbox + UAT |
| `addPeriods` | `..\unila_helpdesk_backend\internal\service\report_service.go:138` | 3 | 3 | 9 | Medium | Blackbox + UAT |
| `calculateCohortScores` | `..\unila_helpdesk_backend\internal\service\report_service.go:164` | 4 | 3 | 12 | Medium | Blackbox + UAT |
| `buildAnswerPayload` | `..\unila_helpdesk_backend\internal\service\report_service.go:713` | 3 | 3 | 9 | Medium | Blackbox + UAT |
| `formatCohortLabel` | `..\unila_helpdesk_backend\internal\service\report_service.go:151` | 2 | 2 | 4 | Low | Blackbox + UAT |
| `surveyResponseIDs` | `..\unila_helpdesk_backend\internal\service\report_service.go:678` | 2 | 2 | 4 | Low | Blackbox + UAT |
| `groupResponseItemsByResponseID` | `..\unila_helpdesk_backend\internal\service\report_service.go:686` | 2 | 2 | 4 | Low | Blackbox + UAT |
| `nowInWIB` | `..\unila_helpdesk_backend\internal\service\report_service.go:632` | 2 | 2 | 4 | Low | Blackbox + UAT |
| `sanitizeFilename` | `..\unila_helpdesk_backend\internal\handler\report_handler.go:223` | 2 | 2 | 4 | Low | Blackbox + UAT |
| `formatAnswerValue` | `..\unila_helpdesk_backend\internal\handler\report_handler.go:231` | 2 | 2 | 4 | Low | Blackbox + UAT |

## 5.5 Modul Medium Lain Yang Memiliki Pure Function

| Fungsi | Lokasi | I | L | Skor | Level | Keputusan |
|---|---|---:|---:|---:|---|---|
| `toCategoryDTOs` | `..\unila_helpdesk_backend\internal\service\category_service.go:47` | 2 | 2 | 4 | Low | Blackbox + UAT |
| `isInvalidTokenError` | `..\unila_helpdesk_backend\internal\fcm\client.go:133` | 3 | 2 | 6 | Low | Blackbox + UAT |
| `CalcTotalPages` | `..\unila_helpdesk_backend\internal\util\pagination.go:4` | 2 | 3 | 6 | Low | Blackbox + UAT |
| `quoteIdentifier` | `..\unila_helpdesk_backend\internal\db\db.go:74` | 2 | 2 | 4 | Low | Blackbox + UAT |

## 6. Keputusan Final Level Pengujian

## 6.1 Fungsi Unit Whitebox (Pure + High)

1. `ensureAdminAllowed`
2. `hashToken`
3. `normalizeInitialTicketStatus`
4. `scoreFromQuestionValue`
5. `scoreFromYesNo`
6. `scoreFromScale`
7. `normalizeToFive`
8. `calculateSurveyScore`
9. `scoreFromResponseItem`

## 6.2 Rekap Keseluruhan

1. Total fungsi dianalisis: `244`.
2. Whitebox unit test: `9` fungsi.
3. Blackbox + UAT: `235` fungsi.

## 7. Rencana Pengujian (Sesuai Format Skripsi)

## 7.1 Whitebox Unit Testing

Objek uji: 9 fungsi pada Bab 6.1.  
Fokus: branch valid/invalid, boundary value, dan determinisme hasil.

## 7.2 Blackbox System Testing Berbasis RBT (Modul dan Input)

Unit analisis blackbox adalah `modul sistem` dengan `kelas input valid/invalid`, bukan endpoint tunggal.
Setiap system test dapat melibatkan beberapa endpoint dalam satu alur bisnis.

Teknik desain kasus uji:

1. `Equivalence partitioning` untuk memecah nilai valid/invalid.
2. `Boundary value` untuk nilai batas penting (contoh: ukuran file, page/limit, periods).
3. `Decision table` untuk menentukan kombinasi kondisi yang benar-benar dieksekusi.

Skoring RBT blackbox:

1. `Impact (I)` 1-5.
2. `Likelihood (L)` 1-5.
3. `Risk Score = I x L`.

Aturan pembatasan jumlah rule decision table berdasarkan RBT:

| Level Risiko | Skor | Smoke | Happy | Full |
|---|---:|---|---|---|
| High | 15-25 | 1 rule valid paling kritis | rule valid + invalid utama | seluruh rule modul |
| Medium | 8-14 | opsional (jika modul kritis operasional) | rule valid utama + 1 invalid representatif | opsional pendalaman |
| Low | 1-7 | tidak wajib | smoke-like validasi singkat | opsional pendalaman |

Matriks modul untuk pembatasan kasus uji berbasis input:

| Modul System Test | Kelas Input Yang Diuji | I | L | Skor | Prioritas | Paket Eksekusi |
|---|---|---:|---:|---:|---|---|
| Auth & Session | username/password (valid, kosong, salah), role admin/non-admin, client channel (web/non-web), refresh token (valid/invalid/expired) | 5 | 4 | 20 | High | Smoke, Happy, Full |
| Ticket Lifecycle | role pelapor (registered/guest/admin), kelengkapan field wajib, kategori guest/non-guest, ownership akses, status update | 5 | 4 | 20 | High | Smoke, Happy, Full |
| Survey Lifecycle | role user, status tiket (resolved/non-resolved), ownership, kondisi duplicate submit | 5 | 4 | 20 | High | Smoke, Happy, Full |
| Reporting & Export | role akses report, period (valid/invalid), periods (batas/nilai invalid), mode export/non-export | 4 | 4 | 16 | High | Smoke, Happy, Full |
| Notification | token notifikasi (valid/invalid), register/unregister flow | 3 | 3 | 9 | Medium | Happy, Full |
| Upload Attachment | ukuran file (<=5MB, >5MB), metadata file valid/invalid, keterhubungan lampiran ke alur tiket | 3 | 3 | 9 | Medium | Happy, Full |
| Category Master | data kategori publik/guest, assign template oleh admin/non-admin | 2 | 3 | 6 | Low | Happy, Full |

Paket eksekusi:

1. `Smoke`: hanya rule valid paling kritis dari modul risiko High.
2. `Happy`: seluruh alur utama (High) + invalid representatif pada Medium/Low.
3. `Full`: seluruh rule decision table untuk modul High (modul Medium/Low dapat diperdalam bila diperlukan).

Aturan eksekusi:

1. Defect pada `Smoke` memblokir lanjut ke `Happy` dan `Full`.
2. `Full` wajib dijalankan untuk modul High sebelum UAT final; modul Medium/Low minimal `Happy`.
3. Seluruh modul diuji minimal pada skenario utama, sedangkan modul risiko tinggi diuji lebih mendalam melalui variasi rule decision table.
4. Detail decision table per modul disimpan di `docs/blackbox_decision_table_test_cases.md`.

## 7.3 UAT

Objek uji: alur end-to-end sistem final dengan aktor:

1. Admin helpdesk.
2. Pengguna terdaftar.
3. Pengguna tamu.

## 8. Narasi Siap Pakai Untuk Bab Metodologi Skripsi

Contoh narasi:

"Analisis risiko pengujian dilakukan dalam dua tahap. Tahap pertama adalah pemetaan risiko per modul backend untuk menentukan prioritas area uji. Tahap kedua adalah analisis detail pada fungsi-fungsi pure di modul terkait. Berdasarkan hasil RBT, fungsi dengan karakteristik pure dan level risiko tinggi dipilih sebagai objek unit testing whitebox. Pada sisi blackbox system test, RBT digunakan untuk membatasi kombinasi kasus uji berdasarkan kelas nilai input valid/invalid per modul melalui decision table, sehingga jumlah test case tetap terkontrol namun risiko utama tetap tercakup. Sebelum UAT final, modul berisiko tinggi wajib lulus paket Full, sedangkan modul medium/rendah minimal lulus paket Happy. Dengan pendekatan ini, seluruh fungsi sistem tetap tercakup dalam analisis, namun kedalaman teknik pengujian disesuaikan dengan tingkat risiko masing-masing fungsi."

## Lampiran A - Inventaris Semua Fungsi (244 Fungsi)

Format: `namaFungsi@line`.

- `internal\config\config.go` (5): `Load@32`, `envRequiredString@135`, `envRequiredBool@143`, `envRequiredInt@158`, `envRequiredDuration@173`
- `internal\db\db.go` (5): `Connect@16`, `EnsureDatabase@34`, `quoteIdentifier@74`, `AutoMigrate@78`, `MustAutoMigrate@84`
- `internal\domain\dto.go` (1): `ToUserDTO@198`
- `internal\fcm\client.go` (4): `NewClient@21`, `resolveCredentialOption@43`, `SendToTokens@63`, `isInvalidTokenError@133`
- `internal\handler\auth_handler.go` (5): `NewAuthHandler@25`, `RegisterRoutes@29`, `login@35`, `refreshToken@54`, `logout@73`
- `internal\handler\category_handler.go` (6): `NewCategoryHandler@15`, `RegisterRoutes@19`, `RegisterAdminRoutes@24`, `listAll@28`, `listGuest@37`, `assignTemplate@50`
- `internal\handler\helpers.go` (3): `parseOptionalTime@13`, `parsePageAndLimit@26`, `parsePositiveIntQuery@39`
- `internal\handler\notification_handler.go` (5): `NewNotificationHandler@16`, `RegisterRoutes@20`, `listNotifications@26`, `registerFcm@40`, `unregisterFcm@58`
- `internal\handler\report_handler.go` (15): `NewReportHandler@23`, `RegisterRoutes@27`, `dashboardSummary@40`, `serviceTrends@49`, `satisfactionSummary@79`, `cohortReport@89`, `surveySatisfaction@99`, `surveySatisfactionExport@111`, `templatesByCategory@170`, `surveyCategories@180`, `usageCohort@189`, `entityService@199`, `parsePeriodParams@209`, `sanitizeFilename@223`, `formatAnswerValue@231`
- `internal\handler\response.go` (3): `respondOK@9`, `respondCreated@13`, `respondError@17`
- `internal\handler\survey_handler.go` (9): `NewSurveyHandler@18`, `RegisterRoutes@22`, `listTemplates@33`, `templateByCategory@42`, `createTemplate@52`, `updateTemplate@66`, `deleteTemplate@81`, `submitResponse@90`, `listResponses@112`
- `internal\handler\ticket_handler.go` (11): `NewTicketHandler@19`, `RegisterRoutes@23`, `listTickets@34`, `listTicketsPaged@48`, `parseTicketStatus@94`, `searchTickets@106`, `getTicket@122`, `createTicket@137`, `createGuestTicket@156`, `updateTicket@170`, `deleteTicket@189`
- `internal\handler\upload_handler.go` (4): `NewUploadHandler@22`, `RegisterRoutes@29`, `upload@34`, `download@87`
- `internal\middleware\auth.go` (3): `AuthMiddleware@16`, `RequireRole@63`, `GetUser@79`
- `internal\middleware\cors.go` (1): `CORSMiddleware@10`
- `internal\repository\attachment_repository.go` (6): `NewAttachmentRepository@13`, `Create@17`, `FindByID@25`, `ListByTicketID@33`, `ListByTicketIDs@44`, `AttachToTicket@59`
- `internal\repository\category_repository.go` (7): `NewCategoryRepository@17`, `List@21`, `FindByID@34`, `FindByName@47`, `Upsert@55`, `UpdateTemplate@70`, `BindTemplateToCategory@91`
- `internal\repository\notification_repository.go` (8): `NewNotificationRepository@13`, `ListByUser@17`, `Create@25`, `NewFCMTokenRepository@33`, `Upsert@37`, `ListTokens@46`, `DeleteByUserAndTokens@54`, `DeleteByUserAndToken@61`
- `internal\repository\refresh_token_repository.go` (6): `NewRefreshTokenRepository@14`, `Create@18`, `FindByHash@22`, `DeleteByID@30`, `DeleteByHash@34`, `DeleteExpired@41`
- `internal\repository\report_repository.go` (21): `NewReportRepository@32`, `ListSurveyResponsesByCreatedRange@36`, `ListActiveUsersInRange@46`, `ListTicketTotalsByCategory@61`, `CountTickets@74`, `CountOpenTickets@82`, `CountResolvedTicketsInRange@95`, `AveragePositiveSurveyScore@106`, `ListServiceSatisfactionRows@117`, `FindTemplateWithOrderedQuestions@134`, `ListSurveyResponsesByTicketCategoryAndTemplate@144`, `ListResponseItemsByResponseIDs@171`, `ListUsedTemplateIDsByCategory@185`, `ListUsedCategoryIDs@197`, `ListTemplatesByIDsWithQuestions@209`, `CountTicketsInRange@222`, `CountSurveysInRange@232`, `ListRegisteredTicketRowsByEntityCategory@242`, `ListRegisteredSurveyRowsByEntityCategory@257`, `ListRegisteredEntities@273`, `ListRegisteredCategories@286`
- `internal\repository\survey_repository.go` (10): `NewSurveyRepository@39`, `ListTemplates@43`, `FindByCategory@51`, `FindByID@64`, `CreateTemplate@72`, `ReplaceTemplate@76`, `DeleteTemplate@117`, `SaveResponse@133`, `HasResponse@150`, `ListResponses@158`
- `internal\repository\ticket_repository.go` (14): `NewTicketRepository@27`, `Create@31`, `Update@53`, `SoftDelete@73`, `FindByID@77`, `ListByUser@87`, `ListAll@95`, `Search@103`, `ListFiltered@119`, `NextTicketSequence@171`, `AddHistory@211`, `UpdateStatus@215`, `GetSurveyScores@222`, `nullableTrimmed@245`
- `internal\repository\user_repository.go` (3): `NewUserRepository@15`, `FindByID@19`, `FindByUsername@27`
- `internal\service\auth_service.go` (10): `NewAuthService@37`, `IssueToken@59`, `LoginWithPasswordClient@116`, `RefreshWithTokenClient@144`, `LogoutWithRefreshToken@171`, `ensureAdminAllowed@181`, `ParseToken@191`, `generateRefreshToken@204`, `hashToken@212`, `cleanupExpiredRefreshTokens@217`
- `internal\service\category_service.go` (5): `NewCategoryService@14`, `ListAll@18`, `ListGuest@26`, `AssignTemplate@40`, `toCategoryDTOs@47`
- `internal\service\notification_service.go` (4): `NewNotificationService@26`, `List@34`, `RegisterToken@53`, `UnregisterToken@71`
- `internal\service\report_service.go` (26): `NewReportService@25`, `CohortReport@38`, `normalizePeriod@107`, `periodStart@120`, `addPeriods@138`, `formatCohortLabel@151`, `calculateCohortScores@164`, `ServiceTrends@190`, `DashboardSummary@221`, `ServiceSatisfactionSummary@259`, `SurveySatisfaction@296`, `SurveySatisfactionExport@385`, `TemplatesByCategory@461`, `SurveyCategoriesWithResponses@485`, `UsageCohort@521`, `EntityServiceMatrix@554`, `listRegisteredCategories@617`, `periodRange@621`, `nowInWIB@632`, `resolveTemplate@636`, `categoryNameMap@659`, `resolveCategoryName@670`, `surveyResponseIDs@678`, `groupResponseItemsByResponseID@686`, `scoreFromResponseItem@696`, `buildAnswerPayload@713`
- `internal\service\score_utils.go` (5): `scoreFromQuestionValue@10`, `scoreFromYesNo@28`, `scoreFromScale@47`, `normalizeToFive@70`, `scoreToFivePoint@85`
- `internal\service\seed_service.go` (1): `DefaultCategories@18`
- `internal\service\survey_service.go` (12): `NewSurveyService@39`, `ListTemplates@50`, `TemplateByCategory@58`, `CreateTemplate@66`, `UpdateTemplate@107`, `DeleteTemplate@152`, `SubmitSurvey@159`, `ListResponsesPaged@215`, `mapSurveyTemplates@261`, `mapSurveyTemplate@269`, `calculateSurveyScore@292`, `buildSurveyResponseItems@317`
- `internal\service\ticket_service.go` (24): `NewTicketService@59`, `createTicketCore@97`, `CreateTicket@174`, `CreateGuestTicket@209`, `UpdateTicket@241`, `DeleteTicket@321`, `GetTicket@332`, `ListTickets@356`, `ListTicketsPaged@378`, `SearchTickets@420`, `resolveCategory@436`, `generateTicketNumber@451`, `toTicketDTO@460`, `attachmentIDsFromRefs@519`, `isDuplicateTicketIdentifierError@539`, `normalizeInitialTicketStatus@551`, `statusLabel@560`, `statusChangeNotification@573`, `statusHistoryDescription@592`, `mapTickets@605`, `ticketIDs@618`, `addHistory@626`, `notifyTicketStatus@636`, `scoreZero@689`
- `internal\util\ids.go` (1): `NewID@9`
- `internal\util\pagination.go` (1): `CalcTotalPages@4`

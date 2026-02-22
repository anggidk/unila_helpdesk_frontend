# Plan: Dokumentasi Strategi Pengujian Berbasis RBT — Unila Helpdesk Backend

**TL;DR:** Hasilkan satu file `docs/test_plan_rbt.md` berisi dokumentasi pengujian backend sistem helpdesk Unila menggunakan pendekatan RBT dua tahap: (1) analisis risiko per modul, (2) drill-down analisis fungsi pure pada modul High, dilanjutkan penentuan whitebox unit test (9 fungsi) vs blackbox+UAT (235 fungsi). Bahasa Indonesia formal akademik.

---

## Steps

1. **Bab 1 — Tujuan Dokumen**
   Nyatakan 4 tujuan: semua fungsi dianalisis, analisis dimulai dari modul (bukan langsung ke fungsi), modul dengan pure function dipecah ke level fungsi, hanya `pure + High` yang menjadi objek unit testing whitebox

2. **Bab 2 — Sumber Data dan Traceability**
   Cantumkan perintah ekstraksi: `rg -n "^func " internal` pada direktori `unila_helpdesk_backend\internal`. Hasil: **244 fungsi** dari **33 file**. Lampiran A memuat inventaris lengkap

3. **Bab 3 — Metode RBT**
   Parameter: `Impact (I)` skala 1–5, `Likelihood (L)` skala 1–5, `Risk Score = I × L`.
   Klasifikasi: High = 15–25 | Medium = 8–14 | Low = 1–7.
   Aturan pengujian:
   - `Pure + High` → Whitebox Unit Test
   - `Pure + Medium/Low` → Blackbox + UAT
   - `Non-pure` → Blackbox + UAT

4. **Bab 4 — Tahap 1: RBT Per Modul**
   Tabel 7 modul fungsional (bukan per file — digabung sesuai domain) dengan kolom: Modul, Cakupan File, Jumlah Fungsi, I, L, Skor, Level, Strategi Uji Dominan.
   Modul: Auth & Session (27 fungsi, I=5, L=4, Skor=20, High), Ticket & Attachment (59 fungsi, I=5, L=4, Skor=20, High), Survey & Scoring (36 fungsi, I=5, L=4, Skor=20, High), Reporting & Export (62 fungsi, I=4, L=4, Skor=16, High), Notification & FCM (21 fungsi, I=3, L=3, Skor=9, Medium), Category & Master Data (19 fungsi, I=3, L=3, Skor=9, Medium), Platform/Core (20 fungsi, I=3, L=3, Skor=9, Medium).
   Kesimpulan: 4 modul High menjadi target drill-down; 3 modul Medium dianalisis tapi tidak ada unit test kecuali muncul pure function dengan skor ≥15

5. **Bab 5 — Tahap 2: RBT Fungsi Pure Per Modul High**
   Awali dengan definisi pure function yang dipakai (4 kriteria: deterministik, tidak akses DB/network/HTTP, tidak bergantung state non-deterministik, tidak ada side effect).
   Sub-bab per modul High (5.1–5.4) + satu sub-bab modul Medium yang memiliki pure function (5.5):

   **5.1 Auth & Session** — tabel 2 fungsi pure (keduanya High → Unit test):
   `ensureAdminAllowed` (auth_service.go:181, I=5, L=3, Skor=15, High),
   `hashToken` (auth_service.go:212, I=5, L=3, Skor=15, High).
   `ParseToken` bukan termasuk karena menggunakan external JWT library dengan side-effect validasi waktu via `time.Now` saat verifikasi claims `exp`.

   **5.2 Ticket & Attachment** — tabel 10 fungsi pure, 1 High (Unit test) + Medium/Low (Blackbox):
   `normalizeInitialTicketStatus` (ticket_service.go:551, I=5, L=3, Skor=15, High → Unit test),
   `attachmentIDsFromRefs` (ticket_service.go:519, I=4, L=3, Skor=12, Medium → Blackbox),
   `isDuplicateTicketIdentifierError` (ticket_service.go:539, I=4, L=2, Skor=8, Medium → Blackbox),
   `statusLabel` (ticket_service.go:560, I=3, L=3, Skor=9, Medium → Blackbox),
   `statusChangeNotification` (ticket_service.go:573, I=3, L=3, Skor=9, Medium → Blackbox),
   `statusHistoryDescription` (ticket_service.go:592, I=3, L=3, Skor=9, Medium → Blackbox),
   `parseTicketStatus` (handler/ticket_handler.go:94, I=3, L=3, Skor=9, Medium → Blackbox),
   `ticketIDs` (ticket_service.go:618, I=2, L=2, Skor=4, Low → Blackbox),
   `nullableTrimmed` (repo/ticket_repository.go:245, I=2, L=2, Skor=4, Low → Blackbox),
   `scoreZero` (ticket_service.go:689, I=1, L=1, Skor=1, Low → Blackbox).
   Catatan: `toTicketDTO`, `mapTickets` tidak pure karena memeriksa nil FK dan memformat URL dinamis.

   **5.3 Survey & Scoring** — tabel 8 fungsi pure, 5 High + 3 Medium/Low:
   `scoreFromQuestionValue` (score_utils.go:10, I=5, L=4, Skor=20, High → Unit test),
   `scoreFromScale` (score_utils.go:47, I=5, L=4, Skor=20, High → Unit test),
   `calculateSurveyScore` (survey_service.go:292, I=5, L=4, Skor=20, High → Unit test),
   `scoreFromYesNo` (score_utils.go:28, I=4, L=4, Skor=16, High → Unit test),
   `normalizeToFive` (score_utils.go:70, I=5, L=3, Skor=15, High → Unit test),
   `scoreToFivePoint` (score_utils.go:85, I=3, L=3, Skor=9, Medium → Blackbox),
   `mapSurveyTemplate` (survey_service.go:269, I=3, L=3, Skor=9, Medium → Blackbox),
   `mapSurveyTemplates` (survey_service.go:261, I=2, L=2, Skor=4, Low → Blackbox).
   Catatan: `buildSurveyResponseItems` bukan pure karena memanggil `util.NewID` (UUID random).

   **5.4 Reporting & Export** — tabel 13 fungsi pure, 1 High + 12 Medium/Low:
   `scoreFromResponseItem` (report_service.go:696, I=5, L=3, Skor=15, High → Unit test),
   `calculateCohortScores` (report_service.go:164, I=4, L=3, Skor=12, Medium → Blackbox),
   `periodRange` (report_service.go:621, I=4, L=3, Skor=12, Medium → Blackbox),
   `normalizePeriod` (report_service.go:107, I=3, L=3, Skor=9, Medium → Blackbox),
   `periodStart` (report_service.go:120, I=3, L=3, Skor=9, Medium → Blackbox),
   `addPeriods` (report_service.go:138, I=3, L=3, Skor=9, Medium → Blackbox),
   `buildAnswerPayload` (report_service.go:713, I=3, L=3, Skor=9, Medium → Blackbox),
   `formatCohortLabel` (report_service.go:151, I=2, L=2, Skor=4, Low → Blackbox),
   `surveyResponseIDs` (report_service.go:678, I=2, L=2, Skor=4, Low → Blackbox),
   `groupResponseItemsByResponseID` (report_service.go:686, I=2, L=2, Skor=4, Low → Blackbox),
   `nowInWIB` (report_service.go:632, I=2, L=2, Skor=4, Low → Blackbox),
   `sanitizeFilename` (handler/report_handler.go:223, I=2, L=2, Skor=4, Low → Blackbox),
   `formatAnswerValue` (handler/report_handler.go:231, I=2, L=2, Skor=4, Low → Blackbox).

   **5.5 Modul Medium — Pure Function** — tabel 4 fungsi, semua Low → Blackbox:
   `toCategoryDTOs` (category_service.go:47, I=2, L=2, Skor=4, Low),
   `isInvalidTokenError` (fcm/client.go:133, I=3, L=2, Skor=6, Low),
   `CalcTotalPages` (util/pagination.go:4, I=2, L=3, Skor=6, Low),
   `quoteIdentifier` (db/db.go:74, I=2, L=2, Skor=4, Low).

6. **Bab 6 — Keputusan Final Level Pengujian**
   Sub-bab 6.1: daftar **9 fungsi whitebox** (Pure + High) bernomor urut.
   Sub-bab 6.2: rekap: total dianalisis 244, whitebox unit test 9, blackbox+UAT 235.

7. **Bab 7 — Rencana Pengujian**
   **7.1 Whitebox Unit Testing** — objek uji 9 fungsi dari 6.1; fokus: branch valid/invalid, boundary value, determinisme hasil; pseudocode Go test (`func TestNamaFungsi(t *testing.T)` + subtests `t.Run`) per fungsi lengkap dengan tabel kasus uji (ID, Input, Expected Output, Justifikasi)
   **7.2 Blackbox Testing** — objek uji endpoint dan alur fitur semua modul: Auth (login, refresh, logout, role restriction), Ticket (CRUD, list, search, akses role), Survey (template CRUD, submit, list response), Reporting (summary, satisfaction, cohort, usage, export), Notification (list, FCM register/unregister), Upload (validasi ukuran, upload, download)
   **7.3 UAT** — objek uji alur end-to-end dengan 3 aktor: Admin helpdesk, Pengguna terdaftar, Pengguna tamu

8. **Bab 8 — Narasi Siap Pakai (Bab Metodologi Skripsi)**
   Template paragraf menjelaskan pendekatan RBT dua tahap, dasar pemilihan whitebox, dan jaminan cakupan keseluruhan fungsi

9. **Lampiran A — Inventaris Semua Fungsi (244 Fungsi)**
   Format per baris: `namaFungsi@line` dikelompokkan per file sumber. Semua 33 file dicantumkan dengan jumlah fungsi di setiap file

---

## Verification

- File output: `c:\Users\anggi\Documents\Skripsi\unila_helpdesk_backend\docs\test_plan_rbt.md`
- Jumlah fungsi white-box final: **9**
- Jumlah fungsi blackbox+UAT: **235**
- Total: **244** (sesuai `rg -n "^func " internal` pada backend workspace)
- Line number tiap fungsi pada Lampiran A dikros-cek dengan sumber aktual di workspace

---

## Decisions

- **Metode RBT**: Impact × Likelihood (I×L), bukan 5-dimensi kualitatif — numerik lebih mudah dipertahankan di sidang
- **Pengelompokan modul**: fungsional/domain (7 modul gabungan), bukan per file — lebih representatif untuk narasi skripsi
- **`ParseToken`**: dikecualikan dari pure function karena validasi `exp` di JWT bergantung `time.Now()` saat runtime
- **`toTicketDTO` / `mapTickets`**: dikecualikan karena memformat URL dinamis dan membaca pointer nullable FK
- **`buildSurveyResponseItems`**: dikecualikan karena memanggil `util.NewID` (UUID random = non-deterministik)
- **Modul Medium** (Notification, Category, Platform/Core): dianalisis di 5.5 untuk kelengkapan dokumen, hasilnya semua Low → tidak ada tambahan unit test
- **Format**: satu file `.md`, Bahasa Indonesia formal akademik
- **Detail unit test**: Full spec — tabel kasus uji + pseudocode Go `t.Run` per fungsi

---

## Context: 9 Fungsi Whitebox Final

| # | Fungsi | File | Baris | I | L | Skor |
|---|---|---|---|---|---|---|
| 1 | `ensureAdminAllowed` | `service/auth_service.go` | 181 | 5 | 3 | 15 |
| 2 | `hashToken` | `service/auth_service.go` | 212 | 5 | 3 | 15 |
| 3 | `normalizeInitialTicketStatus` | `service/ticket_service.go` | 551 | 5 | 3 | 15 |
| 4 | `scoreFromQuestionValue` | `service/score_utils.go` | 10 | 5 | 4 | 20 |
| 5 | `scoreFromScale` | `service/score_utils.go` | 47 | 5 | 4 | 20 |
| 6 | `calculateSurveyScore` | `service/survey_service.go` | 292 | 5 | 4 | 20 |
| 7 | `scoreFromYesNo` | `service/score_utils.go` | 28 | 4 | 4 | 16 |
| 8 | `normalizeToFive` | `service/score_utils.go` | 70 | 5 | 3 | 15 |
| 9 | `scoreFromResponseItem` | `service/report_service.go` | 696 | 5 | 3 | 15 |

---

## Context: Inventaris Fungsi Per File (244 Total)

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

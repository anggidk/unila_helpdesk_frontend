# Dokumen Pengujian Backend Berbasis RBT

Tanggal: 12 Maret 2026  
Sistem: Unila Helpdesk Backend (`..\unila_helpdesk_backend`)  
Strategi: `Tahap 1 RBT per modul -> Tahap 2 RBT fungsi pure pada modul prioritas -> whitebox unit test terpilih -> blackbox dan UAT`

## 1. Tujuan Dokumen

Dokumen ini dipakai sebagai baseline pengujian backend yang sinkron dengan codebase saat ini. Tujuannya:

1. Menetapkan jumlah fungsi backend produksi yang benar.
2. Menyelaraskan analisis RBT dengan struktur modul backend yang aktif.
3. Menetapkan target objek whitebox unit test berdasarkan skor risiko.
4. Menjadi acuan narasi metodologi, traceability, dan lampiran skripsi.

## 2. Sumber Data dan Traceability

Inventaris fungsi produksi diambil langsung dari kode backend:

```powershell
rg -n --glob '!**/*_test.go' '^func ' ..\unila_helpdesk_backend\internal
```

Hasil inventaris saat ini:

1. Total fungsi produksi: `294`.
2. Total file produksi: `34`.

Catatan metodologis:

1. Dokumen ini sengaja memakai `fungsi produksi` saja sebagai objek RBT formal.
2. Jika `*_test.go` ikut dihitung, total berubah menjadi `314` fungsi pada `40` file.
3. Baseline dokumen ini mengasumsikan `belum ada file testing`, sehingga coverage test tidak dipakai untuk mengubah skor.
4. Angka `244` pada dokumen lama sudah tidak sesuai dengan repo sekarang.

## 3. Metode RBT

Parameter yang dipakai:

- `Impact (I)` skala 1-5
- `Likelihood (L)` skala 1-5
- `Risk Score = I x L`

Klasifikasi:

- `High` = 15-25
- `Medium` = 8-14
- `Low` = 1-7

Aturan level pengujian:

1. `Pure + High` -> `Whitebox Unit Test` wajib.
2. `Pure + Medium` -> `Whitebox Unit Test` dipilih bila langsung mempengaruhi aturan bisnis/perhitungan modul High.
3. `Pure + Low` -> `Blackbox + UAT`.
4. `Non-pure` -> `Blackbox + UAT`.

Prinsip penilaian jujur yang dipakai:

1. Skor tidak dinaikkan atau diturunkan untuk menyesuaikan jumlah test yang sudah ada.
2. Fungsi sederhana yang deterministik (misal wrapper hash/formatter) diberi `Likelihood` rendah walaupun berada di modul kritis.
3. Rekap dipisah antara `hasil scoring` dan `status implementasi test`, supaya gap terlihat jelas.

Definisi `pure function` yang dipakai:

1. Deterministik dari input.
2. Tidak akses DB, network, file, random, UUID, atau context HTTP.
3. Tidak menghasilkan side effect.
4. Dapat diuji langsung tanpa mock eksternal.

## 4. Tahap 1 - RBT Per Modul

| Modul | Cakupan File | Jumlah Fungsi | I | L | Skor | Level | Strategi Dominan |
|---|---|---:|---:|---:|---:|---|---|
| Auth & Session | `service/auth`, `handler/auth`, `middleware/auth`, `repo/user`, `repo/refresh` | 27 | 5 | 4 | 20 | High | Blackbox + UAT, plus drill-down pure |
| Ticket Lifecycle & Upload | `service/ticket`, `handler/ticket`, `handler/upload`, `repo/ticket` | 59 | 5 | 4 | 20 | High | Blackbox + UAT, plus drill-down pure |
| Survey Management & Scoring | `service/survey`, `service/score_utils`, `handler/survey`, `repo/survey` | 38 | 5 | 4 | 20 | High | Blackbox + UAT, plus drill-down pure |
| Reporting & Dashboard | `service/report`, `handler/report`, `repo/report` | 73 | 4 | 4 | 16 | High | Blackbox + UAT, plus drill-down pure |
| Cohort Analytics | `service/cohort_analysis` | 29 | 4 | 3 | 12 | Medium | Blackbox + UAT, plus drill-down pure |
| Notification & FCM | `service/notification`, `handler/notification`, `repo/notification`, `fcm/client` | 25 | 3 | 3 | 9 | Medium | Blackbox + UAT |
| Category & Template Binding | `service/category`, `handler/category`, `repo/category`, `service/seed` | 20 | 3 | 3 | 9 | Medium | Blackbox + UAT |
| Platform/Core | `config`, `db`, `domain`, `handler/helpers`, `handler/response`, `middleware/cors`, `util` | 23 | 3 | 3 | 9 | Medium | Blackbox + UAT |

Kesimpulan Tahap 1:

1. Prioritas tertinggi ada pada `Auth`, `Ticket`, `Survey`, dan `Reporting`.
2. `Cohort Analytics` diperlakukan sebagai modul medium terpisah dengan prioritas analisis fungsi pure yang mempengaruhi tren.
3. Modul medium tetap dianalisis penuh, tetapi whitebox hanya diambil bila ada helper pure yang benar-benar kritis.
4. Dengan struktur terpisah, modul terbesar adalah `Reporting & Dashboard` (`73` fungsi), sedangkan `Cohort Analytics` terukur sebagai domain analitik tersendiri (`29` fungsi).

## 5. Tahap 2 - Drill-Down Pure Per Modul (Asumsi Belum Ada Testing File)

Asumsi pada dokumen ini:

1. Belum ada file unit test yang dilaksanakan.
2. Skor murni berdasarkan dampak dan peluang defect, bukan berdasarkan coverage yang sudah ada.
3. Keputusan whitebox di bawah ini adalah target implementasi, bukan status realisasi.

## 5.1 Auth & Session

| Fungsi | Lokasi | I | L | Skor | Level | Keputusan RBT |
|---|---|---:|---:|---:|---|---|
| `ensureAdminAllowed` | `internal\service\auth_service.go:181` | 5 | 3 | 15 | High | Whitebox Unit (target) |
| `hashToken` | `internal\service\auth_service.go:212` | 4 | 1 | 4 | Low | Blackbox + UAT |

## 5.2 Ticket Lifecycle & Upload

| Fungsi | Lokasi | I | L | Skor | Level | Keputusan RBT |
|---|---|---:|---:|---:|---|---|
| `ticketOwnedByUser` | `internal\service\ticket_service.go:453` | 5 | 3 | 15 | High | Whitebox Unit (target) |
| `surveyRequiredForTicket` | `internal\service\ticket_service.go:443` | 3 | 2 | 6 | Low | Blackbox + UAT |
| `ticketIsGuest` | `internal\service\ticket_service.go:449` | 2 | 1 | 2 | Low | Blackbox + UAT |
| `normalizePriority` | `internal\service\ticket_service.go:458` | 2 | 1 | 2 | Low | Blackbox + UAT |
| `normalizeEntity` | `internal\service\ticket_service.go:469` | 3 | 2 | 6 | Low | Blackbox + UAT |
| `normalizeInitialTicketStatus` | `internal\service\ticket_service.go:525` | 2 | 1 | 2 | Low | Blackbox + UAT |
| `statusLabel` | `internal\service\ticket_service.go:534` | 1 | 1 | 1 | Low | Blackbox + UAT |
| `statusChangeNotification` | `internal\service\ticket_service.go:549` | 2 | 1 | 2 | Low | Blackbox + UAT |
| `isGuestServiceID` | `internal\service\ticket_service.go:581` | 1 | 1 | 1 | Low | Blackbox + UAT |
| `ticketIDs` | `internal\service\ticket_service.go:590` | 1 | 1 | 1 | Low | Blackbox + UAT |
| `parseTicketID` | `internal\service\ticket_service.go:598` | 2 | 1 | 2 | Low | Blackbox + UAT |
| `cleanOptionalString` | `internal\service\ticket_service.go:658` | 1 | 1 | 1 | Low | Blackbox + UAT |
| `stringOrEmpty` | `internal\service\ticket_service.go:666` | 1 | 1 | 1 | Low | Blackbox + UAT |
| `scoreZero` | `internal\service\ticket_service.go:673` | 1 | 1 | 1 | Low | Blackbox + UAT |
| `parseTicketStatus` | `internal\handler\ticket_handler.go:96` | 3 | 2 | 6 | Low | Blackbox + UAT |
| `nullableTrimmed` | `internal\repository\ticket_repository.go:60` | 2 | 1 | 2 | Low | Blackbox + UAT |
| `nullableStringValue` | `internal\repository\ticket_repository.go:71` | 1 | 1 | 1 | Low | Blackbox + UAT |
| `ticketStatusFlags` | `internal\repository\ticket_repository.go:235` | 2 | 1 | 2 | Low | Blackbox + UAT |

## 5.3 Survey Management & Scoring

| Fungsi | Lokasi | I | L | Skor | Level | Keputusan RBT |
|---|---|---:|---:|---:|---|---|
| `scoreFromQuestionValue` | `internal\service\score_utils.go:10` | 5 | 3 | 15 | High | Whitebox Unit (target) |
| `scoreFromYesNo` | `internal\service\score_utils.go:28` | 3 | 3 | 9 | Medium | Whitebox Unit (target) |
| `scoreFromScale` | `internal\service\score_utils.go:47` | 5 | 4 | 20 | High | Whitebox Unit (target) |
| `normalizeToFive` | `internal\service\score_utils.go:70` | 5 | 3 | 15 | High | Whitebox Unit (target) |
| `scoreToFivePoint` | `internal\service\score_utils.go:85` | 3 | 1 | 3 | Low | Blackbox + UAT |
| `mapSurveyTemplates` | `internal\service\survey_service.go:263` | 1 | 1 | 1 | Low | Blackbox + UAT |
| `mapSurveyTemplate` | `internal\service\survey_service.go:271` | 1 | 1 | 1 | Low | Blackbox + UAT |
| `calculateSurveyScore` | `internal\service\survey_service.go:294` | 5 | 4 | 20 | High | Whitebox Unit (target) |
| `shouldSkipSurveyAnswer` | `internal\service\survey_service.go:355` | 2 | 1 | 2 | Low | Blackbox + UAT |

## 5.4 Reporting & Dashboard

| Fungsi | Lokasi | I | L | Skor | Level | Keputusan RBT |
|---|---|---:|---:|---:|---|---|
| `periodStart` | `internal\service\report_service.go:52` | 4 | 3 | 12 | Medium | Whitebox Unit (target) |
| `addPeriods` | `internal\service\report_service.go:70` | 3 | 3 | 9 | Medium | Whitebox Unit (target) |
| `periodRange` | `internal\service\report_service.go:592` | 4 | 3 | 12 | Medium | Whitebox Unit (target) |
| `rollingReportRange` | `internal\service\report_service.go:603` | 4 | 3 | 12 | Medium | Whitebox Unit (target) |
| `scoreFromResponseItem` | `internal\service\report_service.go:796` | 5 | 4 | 20 | High | Whitebox Unit (target) |
| `buildEntityPreferenceOverview` | `internal\service\report_service.go:711` | 3 | 3 | 9 | Medium | Whitebox Unit (target) |
| `normalizePeriod` | `internal\service\report_service.go:39` | 3 | 2 | 6 | Low | Blackbox + UAT |
| `calculateCohortScores` | `internal\service\report_service.go:136` | 2 | 2 | 4 | Low | Blackbox + UAT |
| `pickSatisfactionOverviewItem` | `internal\service\report_service.go:674` | 3 | 2 | 6 | Low | Blackbox + UAT |
| `isBetterSatisfactionOverviewItem` | `internal\service\report_service.go:691` | 3 | 2 | 6 | Low | Blackbox + UAT |
| `surveyResponseIDs` | `internal\service\report_service.go:778` | 1 | 1 | 1 | Low | Blackbox + UAT |
| `groupResponseItemsByResponseID` | `internal\service\report_service.go:786` | 2 | 1 | 2 | Low | Blackbox + UAT |
| `buildAnswerPayload` | `internal\service\report_service.go:813` | 2 | 1 | 2 | Low | Blackbox + UAT |
| `sanitizeFilename` | `internal\handler\report_handler.go:269` | 2 | 1 | 2 | Low | Blackbox + UAT |
| `formatAnswerValue` | `internal\handler\report_handler.go:277` | 1 | 1 | 1 | Low | Blackbox + UAT |

## 5.5 Cohort Analytics

| Fungsi | Lokasi | I | L | Skor | Level | Keputusan RBT |
|---|---|---:|---:|---:|---|---|
| `periodDiff` | `internal\service\cohort_analysis_service.go:415` | 3 | 3 | 9 | Medium | Whitebox Unit (target) |
| `buildCohortInsights` | `internal\service\cohort_analysis_service.go:468` | 3 | 2 | 6 | Low | Blackbox + UAT |
| `bestRetentionRows` | `internal\service\cohort_analysis_service.go:527` | 3 | 2 | 6 | Low | Blackbox + UAT |
| `largestDropOffRows` | `internal\service\cohort_analysis_service.go:562` | 3 | 2 | 6 | Low | Blackbox + UAT |
| `mostStableRow` | `internal\service\cohort_analysis_service.go:593` | 2 | 2 | 4 | Low | Blackbox + UAT |
| `strongestScoreShiftRow` | `internal\service\cohort_analysis_service.go:613` | 2 | 2 | 4 | Low | Blackbox + UAT |
| `bucketRetention` | `internal\service\cohort_analysis_service.go:628` | 2 | 1 | 2 | Low | Blackbox + UAT |
| `bucketRetentionValue` | `internal\service\cohort_analysis_service.go:635` | 1 | 1 | 1 | Low | Blackbox + UAT |
| `retentionStability` | `internal\service\cohort_analysis_service.go:640` | 2 | 1 | 2 | Low | Blackbox + UAT |
| `bucketDropOff` | `internal\service\cohort_analysis_service.go:439` | 3 | 2 | 6 | Low | Blackbox + UAT |
| `bucketScoreDelta` | `internal\service\cohort_analysis_service.go:447` | 3 | 2 | 6 | Low | Blackbox + UAT |
| `buildCohortBucketLabels` | `internal\service\cohort_analysis_service.go:397` | 1 | 1 | 1 | Low | Blackbox + UAT |

## 5.6 Notification & FCM

| Fungsi | Lokasi | I | L | Skor | Level | Keputusan RBT |
|---|---|---:|---:|---:|---|---|
| `normalizeWebAppURL` | `internal\fcm\client.go:184` | 1 | 1 | 1 | Low | Blackbox + UAT |
| `copyStringMap` | `internal\fcm\client.go:192` | 1 | 1 | 1 | Low | Blackbox + UAT |
| `copyInterfaceMap` | `internal\fcm\client.go:203` | 1 | 1 | 1 | Low | Blackbox + UAT |
| `isInvalidTokenError` | `internal\fcm\client.go:214` | 2 | 1 | 2 | Low | Blackbox + UAT |

## 5.7 Category & Template Binding

| Fungsi | Lokasi | I | L | Skor | Level | Keputusan RBT |
|---|---|---:|---:|---:|---|---|
| `toCategoryDTOs` | `internal\service\category_service.go:53` | 1 | 1 | 1 | Low | Blackbox + UAT |
| `serviceIsGuestAllowed` | `internal\repository\category_repository.go:17` | 2 | 1 | 2 | Low | Blackbox + UAT |

## 5.8 Platform/Core

| Fungsi | Lokasi | I | L | Skor | Level | Keputusan RBT |
|---|---|---:|---:|---:|---|---|
| `quoteIdentifier` | `internal\db\db.go:74` | 2 | 1 | 2 | Low | Blackbox + UAT |
| `firstConcreteOrigin` | `internal\config\config.go:195` | 2 | 1 | 2 | Low | Blackbox + UAT |
| `CalcTotalPages` | `internal\util\pagination.go:4` | 1 | 1 | 1 | Low | Blackbox + UAT |
| `ToUserDTO` | `internal\domain\dto.go:258` | 1 | 1 | 1 | Low | Blackbox + UAT |
| `TableName` | `internal\domain\models.go:96` | 1 | 1 | 1 | Low | Blackbox + UAT |

## 5.9 Ringkasan Drill-Down Pure

1. Target whitebox berdasarkan RBT: `14` fungsi pure (`7 High`, `7 Medium`).
2. Total fungsi pure level `Low` yang tetap dianalisis: `53`.
3. Karena asumsi belum ada testing file, seluruh target whitebox pada tahap ini berstatus rencana.
4. Semua fungsi non-target tetap diuji melalui blackbox system test dan UAT.

## 6. Rencana Unit Test (Asumsi Belum Ada File Testing)

Rencana implementasi unit test disusun dari target whitebox pada Bagian 5:

| Rencana File | Fungsi Target |
|---|---|
| `internal\service\auth_service_test.go` | `ensureAdminAllowed` |
| `internal\service\ticket_service_test.go` | `ticketOwnedByUser` |
| `internal\service\score_utils_test.go` | `scoreFromQuestionValue`, `scoreFromYesNo`, `scoreFromScale`, `normalizeToFive` |
| `internal\service\survey_service_test.go` | `calculateSurveyScore` |
| `internal\service\report_service_test.go` | `periodStart`, `addPeriods`, `periodRange`, `rollingReportRange`, `scoreFromResponseItem`, `buildEntityPreferenceOverview` |
| `internal\service\cohort_analysis_service_test.go` | `periodDiff` |

Catatan:

1. Status saat ini diasumsikan `belum ada file test`.
2. Angka target whitebox tetap `14` fungsi pure.
3. Pelaksanaan test tidak mengubah skor risiko, hanya mengubah status coverage.

## 7. Keputusan Final Level Pengujian

Rekap formal (dengan asumsi belum ada file testing):

1. Total fungsi produksi yang dianalisis: `294`.
2. Target whitebox unit test: `14` fungsi pure (`7 High` + `7 Medium`).
3. Whitebox yang sudah terlaksana: `0`.
4. Whitebox yang belum terlaksana: `14`.
5. Fungsi lain tetap berada pada domain `blackbox + UAT` dominan.

Implikasi untuk dokumen skripsi:

1. Angka RBT tetap berbasis risiko murni dan tidak bergantung pada coverage yang sudah dibuat.
2. Status pengujian harus ditulis eksplisit sebagai `target` vs `terlaksana`.
3. Detail system test blackbox tetap dirujuk ke `docs/blackbox_decision_table_test_cases.md`.

## 8. Narasi Siap Pakai Untuk Metodologi

Contoh narasi yang sinkron dengan asumsi ini:

"Analisis pengujian backend dilakukan dengan pendekatan Risk-Based Testing (RBT) dua tahap. Tahap pertama memetakan seluruh 294 fungsi produksi backend ke dalam delapan modul utama untuk menentukan area berisiko tinggi. Modul Reporting dan Cohort Analytics dipisahkan agar risiko analitik tidak tercampur dengan risiko pelaporan operasional. Tahap kedua melakukan drill-down pada fungsi-fungsi pure per modul dengan skor IxL yang ditetapkan secara independen dari coverage test. Berdasarkan scoring tersebut, ditetapkan 14 fungsi pure sebagai target whitebox unit testing formal, terdiri atas 7 fungsi level High dan 7 fungsi level Medium. Pada baseline dokumen ini diasumsikan belum ada file testing, sehingga seluruh target whitebox masih berstatus rencana implementasi, sementara fungsi lain tetap diuji dengan blackbox system test dan UAT."

## Lampiran A - Inventaris Fungsi Produksi (294 Fungsi)

Format: `namaFungsi@line`.

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
- `internal\repository\ticket_repository.go` (15): `NewTicketRepository@27`, `Create@31`, `Update@35`, `nullableTrimmed@60`, `nullableStringValue@71`, `SoftDelete@75`, `FindByID@79`, `ListByUser@88`, `ListAll@102`, `Search@113`, `ListFiltered@132`, `ExistsTicketNumber@193`, `UpdateStatus@201`, `GetSurveyScores@212`, `ticketStatusFlags@235`
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

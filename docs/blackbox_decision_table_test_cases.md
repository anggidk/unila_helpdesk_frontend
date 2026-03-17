# Blackbox System Test Cases (Decision Table Per User Story)

Dokumen ini menurunkan setiap test case **langsung dari Acceptance Criteria** pada `user_stories.md` (v1.1) menggunakan teknik **Decision Table Testing**.
Fitur yang tidak tercantum pada user story (search tiket, update tiket, hapus tiket, inactive account, dll) tidak diuji.

> Catatan implementasi aktual: pada sistem ini, lampiran dienkode oleh klien sebagai data URI base64 dengan format `{filename}|data:{mime};base64,{data}` dan dikirim langsung pada field `lamp1`/`lamp2` saat pembuatan tiket. Backend menyimpan nilai tersebut pada kolom `TEXT` di database.

## 1. Prinsip Pengelompokan

1. Unit analisis blackbox adalah **user story** dan **skenario** (acceptance criteria) yang didefinisikan pada `user_stories.md` v1.1.
2. Setiap TC-ID diturunkan langsung dari satu atau lebih skenario (acceptance criteria) menggunakan teknik Decision Table Testing.
3. Skenario yang murni UI, routing, navigasi layar, atau validasi sisi klien divalidasi pada **UAT**, bukan API blackbox.
4. Langkah setup/cleanup (login, upload lampiran, create ticket, set DONE, delete) bukan test case dan tidak memiliki TC-ID.
5. Skenario yang memerlukan endpoint yang belum tersedia di backend saat ini dicatat sebagai gap dan tidak memiliki TC-ID.

## 2. Matriks User Story

| Story | Aktor | Skenario | Endpoint Utama | TC |
|---|---|---|---|---|
| US01 | Pengguna terdaftar, admin | 7 skenario | `/auth/login`, `/auth/refresh`, `/auth/logout`, `/tickets` | 7 |
| US02 | Tamu | 2 skenario | `/categories/guest`, `/uploads`, `/tickets/guest` | 3 |
| US03 | Pengguna terdaftar | 3 skenario | `/categories`, `/uploads`, `/tickets` | 3 |
| US04 | Pengguna | 3 skenario | `/tickets`, `/tickets/:id` | 3 |
| US05 | Pengguna terdaftar | 3 skenario | `/notifications/fcm`, `/notifications`, `/notifications/fcm/unregister` | 4 |
| US06 | Pengguna terdaftar | 6 skenario | `/tickets/:id`, `/surveys/responses` | 8 |
| US07 | Admin | 4 skenario | `/surveys/templates`, `/categories/:id/template`, `/surveys/categories/:id` | 5 |
| US08 | Admin | 3 skenario | `/reports/summary`, `/reports/satisfaction-summary`, `/reports/satisfaction`, `/reports/satisfaction/export` | 5 |
| US09 | Admin | 3 skenario | `/reports/cohort`, `/reports/usage`, `/reports/entity-service` | 5 |
| US10 | Admin | 2 skenario | `/surveys/responses` | 2 |
| **Total** | | **36 skenario** | | **45** |

## 3. Decision Table Per User Story

---

### DT-US01 Login & Logout

**Skenario (dari user story):**
- Skenario 1 (Login Berhasil): Akun valid + data benar → sesi dibuat, halaman utama sesuai role.
- Skenario 2 (Login Gagal): Data salah → pesan kesalahan, sesi tidak dibuat.
- Skenario 3 (Pemulihan Sesi): Sesi masih aktif → verifikasi token → halaman utama tanpa login ulang.
- Skenario 4 (Sesi Kedaluwarsa): Token expired → hapus sesi, arahkan ke login. **UAT** (API: 401 pada expired token; tercakup implisit oleh TC-US01-05).
- Skenario 5 (Logout): Hapus token sesi + token FCM, akhiri sesi server.
- Skenario 6 (Validasi Input): Field kosong → pesan validasi sebelum request. **UAT** (validasi sisi klien).
- Skenario 7 (Login Admin Non-Web Ditolak): Admin login dari luar antarmuka web → ditolak 403. Diuji sebagai TC-US01-03.

**Kondisi:**
- C1: Username dan password valid.
- C2: Refresh token valid dan belum expired.
- C3: Access token valid.
- C4: User berperan admin.
- C5: Header `X-Client-Type=web`.

**Aksi:**
- A1: Login sukses, sesi dibuat.
- A2: Login ditolak, pesan kesalahan.
- A3: Admin non-web ditolak.
- A4: Refresh sukses, token baru diterbitkan.
- A5: Refresh gagal, sesi tidak dibuat.
- A6: Akses endpoint terproteksi diizinkan.
- A7: Logout sukses, refresh token tidak lagi valid.

| Kondisi/Aksi | R1 | R2 | R3 | R4 | R5 | R6 | R7 |
|---|---|---|---|---|---|---|---|
| C1 kredensial valid | Y | N | Y | - | - | - | - |
| C4 role admin | N | - | Y | - | - | - | - |
| C5 client type web | - | - | N | - | - | - | - |
| C2 refresh token valid | - | - | - | Y | N | - | Y |
| C3 access token valid | - | - | - | - | - | Y | - |
| A1 login sukses | Y | N | N | N | N | N | N |
| A2 login ditolak | N | Y | N | N | N | N | N |
| A3 admin non-web ditolak | N | N | Y | N | N | N | N |
| A4 refresh sukses | N | N | N | Y | N | N | N |
| A5 refresh gagal | N | N | N | N | Y | N | N |
| A6 endpoint diizinkan | N | N | N | N | N | Y | N |
| A7 logout + invalidasi | N | N | N | N | N | N | Y |

| TC ID | Rule | Skenario | Contoh Input | Expected |
|---|---|---|---|---|
| TC-US01-01 | R1 | Skenario 1 | Login registered + admin dengan kredensial valid | Sesi dibuat, token diterbitkan, role sesuai |
| TC-US01-02 | R2 | Skenario 2 | Username/password kosong atau salah | Pesan kesalahan, sesi tidak dibuat |
| TC-US01-03 | R3 | Skenario 7 | Admin login dengan `X-Client-Type=mobile` | Admin non-web ditolak |
| TC-US01-04 | R4 | Skenario 3 | Refresh dengan token valid | Sesi diverifikasi, token baru |
| TC-US01-05 | R5 | Skenario 3 (neg) / Skenario 4 proxy | Refresh dengan token invalid/expired | Sesi tidak dibuat |
| TC-US01-06 | R6 | Skenario 3 | GET /tickets dengan access token valid | Endpoint terproteksi dapat diakses |
| TC-US01-07 | R7 | Skenario 5 | Logout dengan refresh_token lalu refresh lagi | Logout sukses, refresh token lama invalid |

---

### DT-US02 Tamu Membuat Tiket Akun

**Skenario (dari user story):**
- Skenario 1 (Tiket Berhasil Dibuat): Tamu mengisi semua data wajib → tiket baru + nomor pelacakan.
- Skenario 2 (Validasi Field Wajib): Field wajib belum diisi → validasi ditampilkan.

Catatan: Untuk guest ticket, `lamp1` dan `lamp2` berisi data URI base64 yang dienkode oleh klien dengan format `{filename}|data:{mime};base64,{data}`. Payload `POST /tickets/guest` membawa nilai ini langsung.

**Kondisi:**
- C1: Semua field wajib terisi (name, numberId, email, entity, notes).
- C2: Lampiran wajib (lamp1, lamp2) tersedia.

**Aksi:**
- A1: Tiket baru dibuat, nomor pelacakan ditampilkan.
- A2: Validasi field wajib — ditolak.

| Kondisi/Aksi | R1 | R2 | R3 |
|---|---|---|---|
| C1 field wajib valid | Y | N | Y |
| C2 lampiran tersedia | Y | Y | N |
| A1 tiket dibuat | Y | N | N |
| A2 validasi ditolak | N | Y | Y |

| TC ID | Rule | Skenario | Contoh Input | Expected |
|---|---|---|---|---|
| TC-US02-01 | R1 | Skenario 1 | Payload guest lengkap + `lamp1`/`lamp2` berisi data URI base64 | Tiket dibuat, nomor pelacakan |
| TC-US02-02 | R2 | Skenario 2 | name/numberId/email/entity kosong | Validasi field wajib |
| TC-US02-03 | R3 | Skenario 2 | lamp1/lamp2 kosong | Validasi lampiran wajib |

---

### DT-US03 Pengguna Terdaftar Membuat Tiket Layanan

**Skenario (dari user story):**
- Skenario 1 (Tiket Berhasil Dibuat): Mengisi form dan submit → tiket berhasil dibuat, nomor tiket.
- Skenario 2 (Validasi Input): Input tidak valid (kategori kosong/deskripsi kosong) → menolak, pesan validasi.
- Skenario 3 (Lampiran Tidak Valid): Upload lampiran gagal (mis. file kosong atau melebihi batas ukuran) → pesan error spesifik.

Catatan: Pada sistem ini, lampiran dienkode oleh klien sebagai data URI base64 dengan format `{filename}|data:{mime};base64,{data}` dan dikirim langsung sebagai nilai `lamp1` saat `POST /tickets`.

**Kondisi:**
- C1: Pengguna sudah login.
- C2: Input valid (notes terisi).
- C3: Lampiran valid (data URI base64 terformat dengan benar dan dikirim pada field `lamp1`).

**Aksi:**
- A1: Tiket dibuat, nomor tiket ditampilkan.
- A2: Ditolak, pesan validasi input.
- A3: Ditolak, pesan validasi lampiran.

| Kondisi/Aksi | R1 | R2 | R3 |
|---|---|---|---|
| C1 sudah login | Y | Y | Y |
| C2 input valid | Y | N | Y |
| C3 lampiran valid | Y | Y | N |
| A1 tiket dibuat | Y | N | N |
| A2 validasi input | N | Y | N |
| A3 validasi lampiran | N | N | Y |

| TC ID | Rule | Skenario | Contoh Input | Expected |
|---|---|---|---|---|
| TC-US03-01 | R1 | Skenario 1 | serviceId + notes valid | Tiket dibuat, nomor tiket |
| TC-US03-02 | R2 | Skenario 2 | notes kosong | Ditolak, pesan validasi |
| TC-US03-03 | R3 | Skenario 3 | `lamp1` kosong atau data URI base64 tidak valid | Ditolak, pesan validasi lampiran |

---

### DT-US04 Daftar & Detail Tiket

**Skenario (dari user story):**
- Skenario 1 (Menampilkan Daftar Tiket): Membuka menu Tiket → daftar tiket yang pernah dibuat.
- Skenario 2 (Detail Tiket): Membuka salah satu tiket → detail (nomor, kategori, deskripsi, tanggal, status).
- Skenario 3 (Daftar Kosong): Belum ada tiket → kondisi kosong.

**Kondisi:**
- C1: Pengguna login.
- C2: Pengguna memiliki tiket.

**Aksi:**
- A1: Daftar tiket tampil.
- A2: Detail tiket lengkap.
- A3: Kondisi kosong.

| Kondisi/Aksi | R1 | R2 | R3 |
|---|---|---|---|
| C1 login | Y | Y | Y |
| C2 ada tiket | Y | Y | N |
| A1 daftar tampil | Y | N | N |
| A2 detail lengkap | N | Y | N |
| A3 kondisi kosong | N | N | Y |

| TC ID | Rule | Skenario | Contoh Input | Expected |
|---|---|---|---|---|
| TC-US04-01 | R1 | Skenario 1 | GET /tickets | Daftar tiket tampil |
| TC-US04-02 | R2 | Skenario 2 | GET /tickets/:id | Detail: nomor, kategori, deskripsi, tanggal, status |
| TC-US04-03 | R3 | Skenario 3 | GET /tickets (akun tanpa tiket) | Kondisi kosong |

---

### DT-US05 Notifikasi Push

**Skenario (dari user story):**
- Skenario 1 (Notifikasi Terkirim): Token FCM tersimpan + sistem memicu notifikasi → notifikasi dikirim ke perangkat.
- Skenario 2 (Navigasi dari Notifikasi): Pengguna membuka notifikasi → halaman detail tiket terkait.
- Skenario 3 (Token FCM Tidak Tersimpan): Pengguna belum izinkan notifikasi atau sudah logout → sistem melewati pengiriman. **UAT / server-side behavior** — tidak ada respons API yang bisa divalidasi langsung.

Catatan UAT: Pengiriman push ke perangkat fisik dan navigasi ke halaman detail divalidasi saat UAT.

**Kondisi:**
- C1: Token FCM tersimpan.
- C2: Notifikasi tersedia.
- C3: Notifikasi terkait tiket.

**Aksi:**
- A1: Token FCM tersimpan.
- A2: Daftar notifikasi tampil.
- A3: Notifikasi mengandung ticketId untuk navigasi.
- A4: Token FCM dihapus (unregister).

| Kondisi/Aksi | R1 | R2 | R3 | R4 |
|---|---|---|---|---|
| C1 FCM tersimpan | Y | Y | Y | Y |
| C2 notifikasi ada | - | Y | Y | - |
| C3 terkait tiket | - | - | Y | - |
| A1 token tersimpan | Y | N | N | N |
| A2 list tampil | N | Y | N | N |
| A3 ticketId tersedia | N | N | Y | N |
| A4 token dihapus | N | N | N | Y |

| TC ID | Rule | Skenario | Contoh Input | Expected |
|---|---|---|---|---|
| TC-US05-01 | R1 | Skenario 1 | POST /notifications/fcm | Token FCM tersimpan |
| TC-US05-02 | R2 | Skenario 1 | GET /notifications | Daftar notifikasi tampil |
| TC-US05-03 | R3 | Skenario 2 | GET /notifications → cek ticketId | Notifikasi mengandung ticketId |
| TC-US05-04 | R4 | Skenario 5 (US01) | POST /notifications/fcm/unregister | Token dihapus, tidak menerima notifikasi lagi |

---

### DT-US06 Pengisian Survei Kepuasan

**Skenario (dari user story):**
- Skenario A (Akses via Detail Tiket): Tiket selesai + survei belum diisi → form survei aktif.
- Skenario B (Akses via Menu Umpan Balik): Pending → pilih → form → submit → hilang dari pending, muncul di riwayat.
- Skenario C (Riwayat Survei): Tab Riwayat → daftar survei yang sudah diisi. **UAT** (navigasi tab).
- Skenario D (Survei Sudah Diisi): Tombol umpan balik tidak ditampilkan, tidak bisa mengisi ulang. Diuji sebagai duplikat dicegah.
- Skenario E (Template Belum Diset): Kategori belum memiliki template survei yang ditetapkan → pesan survei belum tersedia.
- Skenario F (Validasi Jawaban Tidak Lengkap): Pertanyaan wajib belum dijawab → validasi ditampilkan.

**Kondisi:**
- C1: Tiket berstatus DONE.
- C2: Survei belum pernah diisi.
- C3: Jawaban lengkap.
- C4: Tiket adalah registered ticket (bukan guest).
- C5: Kategori tiket memiliki template survei yang ditetapkan.

**Aksi:**
- A1: Form survei aktif / pending terlihat.
- A2: Submit survei sukses, pending hilang.
- A3: Submit ditolak (tiket belum selesai).
- A4: Submit ditolak (jawaban belum lengkap).
- A5: Submit ditolak (duplikat).
- A6: Submit ditolak (guest ticket tidak bisa disurvey).
- A7: Submit ditolak (template belum diset untuk kategori).

| Kondisi/Aksi | R1 | R2 | R3 | R4 | R5 | R6 | R7 | R8 |
|---|---|---|---|---|---|---|---|---|
| C4 registered ticket | Y | Y | Y | Y | Y | Y | N | Y |
| C1 tiket DONE | Y | N | Y | Y | Y | Y | Y | Y |
| C5 template ditetapkan | Y | Y | Y | Y | Y | Y | Y | N |
| C2 belum diisi | Y | Y | Y | Y | N | Y | Y | Y |
| C3 jawaban lengkap | - | - | N | Y | Y | - | - | - |
| A1 pending/form aktif | Y | N | N | N | N | N | N | N |
| A2 submit sukses | N | N | N | Y | N | N | N | N |
| A3 ditolak belum selesai | N | Y | N | N | N | N | N | N |
| A4 ditolak jawaban | N | N | Y | N | N | N | N | N |
| A5 duplikat dicegah | N | N | N | N | Y | N | N | N |
| A6 guest ditolak | N | N | N | N | N | N | Y | N |
| A7 template belum diset | N | N | N | N | N | N | N | Y |
| Pending hilang | N | N | N | Y | N | N | N | N |

| TC ID | Rule | Skenario | Contoh Input | Expected |
|---|---|---|---|---|
| TC-US06-01 | R1 | Skenario A | GET /tickets/:id (DONE, surveyRequired=true) | Form survei aktif |
| TC-US06-02 | R2 | Skenario A (neg) | POST /surveys/responses untuk tiket belum DONE | Ditolak |
| TC-US06-03 | R3 | Skenario F | POST /surveys/responses dengan answers kosong | Validasi jawaban |
| TC-US06-04 | R4 | Skenario B | POST /surveys/responses lengkap | Submit sukses |
| TC-US06-05 | R4 | Skenario B | GET /tickets/:id setelah submit | Pending hilang, riwayat tersimpan |
| TC-US06-06 | R5 | Skenario D | POST /surveys/responses duplikat | Duplikat dicegah |
| TC-US06-07 | R6 | Skenario A (negative: aktor bukan pengguna terdaftar) | POST /surveys/responses untuk guest ticket | Guest ticket tidak bisa disurvey |
| TC-US06-08 | R8 | Skenario E | POST /surveys/responses untuk tiket DONE di kategori tanpa template | Template belum diset, survei tidak tersedia |

---

### DT-US07 Kelola Template Survei (Admin)

**Skenario (dari user story):**
- Skenario 1 (Buat Template Baru): Membuat template dan pertanyaan → tersimpan.
- Skenario 2 (Tetapkan Template ke Kategori): Memilih template untuk kategori → kategori memiliki template yang ditetapkan.
- Skenario 3 (Ubah Template / Pertanyaan): Mengubah template/pertanyaan → perubahan tersimpan.
- Skenario 4 (Validasi Template Kosong): Menyimpan template tanpa pertanyaan → validasi ditampilkan.

**Kondisi:**
- C1: Admin login.
- C2: Payload template valid (minimal 1 pertanyaan).
- C3: Binding kategori-template eksplisit.

**Aksi:**
- A1: Template tersimpan.
- A2: Kategori memiliki template yang ditetapkan.
- A3: Template diperbarui.
- A4: Validasi ditolak (template tanpa pertanyaan).

| Kondisi/Aksi | R1 | R2 | R3 | R4 | R5 |
|---|---|---|---|---|---|
| C1 admin | Y | Y | Y | Y | Y |
| C2 payload valid | Y | - | - | Y | N |
| C3 binding eksplisit | - | Y | Y | - | - |
| A1 template dibuat | Y | N | N | N | N |
| A2 kategori punya template | N | Y | N | N | N |
| Template sesuai binding | N | N | Y | N | N |
| A3 perubahan tersimpan | N | N | N | Y | N |
| A4 validasi tanpa pertanyaan | N | N | N | N | Y |

| TC ID | Rule | Skenario | Contoh Input | Expected |
|---|---|---|---|---|
| TC-US07-01 | R1 | Skenario 1 | POST /surveys/templates | Template tersimpan |
| TC-US07-02 | R2 | Skenario 2 | PUT /categories/:id/template | Kategori punya template yang ditetapkan |
| TC-US07-03 | R3 | Skenario 2 | GET /surveys/categories/:id | Template sesuai binding |
| TC-US07-04 | R4 | Skenario 3 | PUT /surveys/templates/:id | Perubahan tersimpan |
| TC-US07-05 | R5 | Skenario 4 | POST /surveys/templates dengan questions kosong | Ditolak, template harus memiliki minimal satu pertanyaan |

---

### DT-US08 Rekap Hasil Survei (Admin)

**Skenario (dari user story):**
- Skenario 1 (Tampilkan Rekap): Memilih rentang waktu dan/atau kategori → rekap survei dalam tabel/grafik.
- Skenario 2 (Export CSV): Filter sudah dipilih → klik Export CSV → file .csv diunduh.
- Skenario 3 (Tidak Ada Data): Tidak ada data untuk filter → empty state, Export CSV dinonaktifkan.

**Kondisi:**
- C1: Admin login.
- C2: Filter waktu/kategori diterapkan.
- C3: Data tersedia.

**Aksi:**
- A1: Rekap survei tampil.
- A2: Export CSV berhasil.
- A3: Empty state.

| Kondisi/Aksi | R1 | R2 | R3 | R4 | R5 |
|---|---|---|---|---|---|
| C1 admin | Y | Y | Y | Y | Y |
| C2 filter waktu | Y | Y | N | Y | Y |
| C2 filter kategori | N | N | Y | Y | N |
| C3 data tersedia | Y | Y | Y | Y | N |
| A1 rekap tampil | Y | Y | Y | N | N |
| A2 export CSV | N | N | N | Y | N |
| A3 empty state | N | N | N | N | Y |

| TC ID | Rule | Skenario | Contoh Input | Expected |
|---|---|---|---|---|
| TC-US08-01 | R1 | Skenario 1 | GET /reports/summary | Dashboard rekap tampil |
| TC-US08-02 | R2 | Skenario 1 | GET /reports/satisfaction-summary?period=monthly&periods=6 | Rekap berdasarkan waktu |
| TC-US08-03 | R3 | Skenario 1 | GET /reports/satisfaction?categoryId=... | Rekap berdasarkan kategori |
| TC-US08-04 | R4 | Skenario 2 | GET /reports/satisfaction/export?categoryId=...&period=monthly&periods=6 | CSV berhasil diunduh |
| TC-US08-05 | R5 | Skenario 3 | GET /reports (rentang tanpa data) | Empty state |

---

### DT-US09 Analisis Cohort Kepuasan (Admin)

**Skenario (dari user story):**
- Skenario 1 (Tampilkan Visualisasi Cohort): Parameter waktu/layanan → tren kepuasan berdasarkan cohort.
- Skenario 2 (Perubahan Filter): Filter diubah → output berubah sesuai parameter baru.
- Skenario 3 (Tidak Ada Data): Tidak ada data → empty state.

**Kondisi:**
- C1: Admin login.
- C2: Parameter waktu/layanan dipilih.
- C3: Filter diubah.
- C4: Data tersedia.

**Aksi:**
- A1: Tren cohort tampil.
- A2: Output berubah sesuai parameter.
- A3: Empty state.

| Kondisi/Aksi | R1 | R2 | R3 | R4 | R5 |
|---|---|---|---|---|---|
| C1 admin | Y | Y | Y | Y | Y |
| C2 parameter dipilih | Y | Y | Y | Y | Y |
| C3 filter diubah | N | N | N | Y | N |
| C4 data tersedia | Y | Y | Y | Y | N |
| A1 tren tampil | Y | Y | Y | N | N |
| A2 output berubah | N | N | N | Y | N |
| A3 empty state | N | N | N | N | Y |

| TC ID | Rule | Skenario | Contoh Input | Expected |
|---|---|---|---|---|
| TC-US09-01 | R1 | Skenario 1 | GET /reports/cohort?period=monthly | Tren cohort tampil |
| TC-US09-02 | R2 | Skenario 1 | GET /reports/usage?period=monthly&periods=6 | Tren penggunaan tampil |
| TC-US09-03 | R3 | Skenario 1 | GET /reports/entity-service?period=monthly&periods=6 | Distribusi entitas-layanan tampil |
| TC-US09-04 | R4 | Skenario 2 | GET /reports/cohort?period=weekly (ubah filter) | Output berubah |
| TC-US09-05 | R5 | Skenario 3 | GET /reports/usage (rentang tanpa data) | Empty state |

---

### DT-US10 Riwayat Survei (Admin)

**Skenario (dari user story):**
- Skenario 1 (Tampilkan Riwayat): Mengatur filter → riwayat survei tampil sesuai filter.
- Skenario 2 (Tidak Ada Data): Tidak ada entri → empty state.

**Kondisi:**
- C1: Admin login.
- C2: Filter diterapkan.
- C3: Data tersedia.

**Aksi:**
- A1: Riwayat survei tampil sesuai filter.
- A2: Empty state.

| Kondisi/Aksi | R1 | R2 |
|---|---|---|
| C1 admin | Y | Y |
| C2 filter diterapkan | Y | Y |
| C3 data tersedia | Y | N |
| A1 riwayat tampil | Y | N |
| A2 empty state | N | Y |

| TC ID | Rule | Skenario | Contoh Input | Expected |
|---|---|---|---|---|
| TC-US10-01 | R1 | Skenario 1 | GET /surveys/responses?page=1&limit=10 | Riwayat tampil sesuai filter |
| TC-US10-02 | R2 | Skenario 2 | GET /surveys/responses?categoryId=nonexistent&page=1&limit=10 | Empty state |

---

## 4. Ringkasan

| Item | Jumlah |
|---|---|
| User Stories | 10 |
| Skenario (acceptance criteria) total | 36 |
| Skenario UAT-only (tidak di-API-test) | 4 |
| Skenario gap (endpoint belum tersedia) | 0 |
| Test Cases (TC-ID unik) | **45** |

### Catatan Gap Endpoint

Tidak ada gap endpoint. Seluruh skenario pada user story v1.1 telah tercakup oleh backend.

### Catatan UAT-Only

| Skenario | Alasan |
|---|---|
| US01 Skenario 4 (Sesi Kedaluwarsa) | Redirect ke halaman login — perilaku UI. API mengembalikan 401 (tercakup oleh TC-US01-05). |
| US01 Skenario 6 (Validasi Input) | Validasi sisi klien sebelum request ke server. |
| US05 Skenario 3 (Token FCM Tidak Tersimpan) | Server-side skip behavior — tidak ada respons API yang bisa divalidasi. |
| US06 Skenario C (Riwayat Survei) | Navigasi tab UI — bukan kontrak API. |

Setiap TC-ID diturunkan langsung dari skenario (acceptance criteria) menggunakan teknik Decision Table Testing. Tidak ada test case untuk fitur di luar scope user story.

## 5. Artefak Eksekusi

- Collection: `..\unila_helpdesk_backend\docs\blackbox\unila_helpdesk_blackbox.postman_collection.json`
- Environment: `..\unila_helpdesk_backend\docs\blackbox\unila_helpdesk_blackbox.local.postman_environment.json`

# Blackbox System Test Cases (Decision Table Per Modul)

Dokumen ini menurunkan RBT blackbox ke level `modul + kombinasi input valid/invalid`.
Fokusnya adalah system test end-to-end, bukan API point test.

## 1. Paket Eksekusi

1. `Smoke`: rule valid paling kritis pada modul High.
2. `Happy`: rule valid utama + invalid representatif.
3. `Full`: seluruh rule pada modul High; modul Medium/Low minimal Happy sebelum UAT final.

## 2. Decision Table Per Modul

## DT-M01 Modul Auth & Session (High)

Kondisi:

- `C1`: kredensial login valid (`username`, `password`).
- `C2`: akun aktif.
- `C3`: user role admin.
- `C4`: kanal admin adalah web.
- `C5`: refresh token valid dan belum expired.

Aksi:

- `A1`: login sukses.
- `A2`: login ditolak unauthorized.
- `A3`: login ditolak forbidden karena admin non-web.
- `A4`: refresh sukses.
- `A5`: refresh gagal.

| Kondisi/Aksi | R1 | R2 | R3 | R4 | R5 | R6 |
|---|---|---|---|---|---|---|
| C1 kredensial valid | Y | N | Y | Y | - | - |
| C2 akun aktif | Y | - | N | Y | - | - |
| C3 role admin | N | - | - | Y | - | - |
| C4 kanal admin web | - | - | - | N | - | - |
| C5 refresh token valid | - | - | - | - | Y | N |
| A1 login sukses | Y | N | N | N | N | N |
| A2 unauthorized | N | Y | Y | N | N | N |
| A3 forbidden admin channel | N | N | N | Y | N | N |
| A4 refresh sukses | N | N | N | N | Y | N |
| A5 refresh gagal | N | N | N | N | N | Y |

| TC ID | Rule | Contoh Nilai Input | Paket | Expected |
|---|---|---|---|---|
| TC-M01-01 | R1 | `username=valid`, `password=valid`, `active=true` | Smoke, Happy, Full | login sukses |
| TC-M01-02 | R2 | `username=""` atau `password=""` | Happy, Full | unauthorized |
| TC-M01-03 | R3 | `active=false` | Happy, Full | unauthorized |
| TC-M01-04 | R4 | `role=admin`, `clientType=mobile` | Happy, Full | forbidden admin channel |
| TC-M01-05 | R5 | `refreshToken=valid` | Happy, Full | refresh sukses |
| TC-M01-06 | R6 | `refreshToken=invalid/expired` | Happy, Full | refresh gagal |

## DT-M02A Modul Ticket Creation (High)

Kondisi:

- `C1`: mode registered.
- `C2`: mode guest.
- `C3`: field wajib terisi valid (`title`, `description`, `category`, identitas pelapor).
- `C4`: kategori guest-allowed (khusus guest).

Aksi:

- `A1`: create tiket registered sukses.
- `A2`: create tiket guest sukses.
- `A3`: create ditolak karena validasi payload.
- `A4`: create ditolak karena kategori guest tidak valid.

| Kondisi/Aksi | R1 | R2 | R3 | R4 | R5 |
|---|---|---|---|---|---|
| C1 mode registered | Y | Y | N | N | N |
| C2 mode guest | N | N | Y | Y | Y |
| C3 field wajib valid | Y | N | Y | N | Y |
| C4 kategori guest-allowed | - | - | Y | - | N |
| A1 create registered sukses | Y | N | N | N | N |
| A2 create guest sukses | N | N | Y | N | N |
| A3 create ditolak validasi | N | Y | N | Y | N |
| A4 create ditolak kategori | N | N | N | N | Y |

| TC ID | Rule | Contoh Nilai Input | Paket | Expected |
|---|---|---|---|---|
| TC-M02A-01 | R1 | registered + payload valid | Smoke, Happy, Full | tiket registered sukses dibuat |
| TC-M02A-02 | R2 | registered + `title=""` | Happy, Full | ditolak validasi |
| TC-M02A-03 | R3 | guest + payload valid + kategori guest | Happy, Full | tiket guest sukses dibuat |
| TC-M02A-04 | R4 | guest + `description=""` | Happy, Full | ditolak validasi |
| TC-M02A-05 | R5 | guest + kategori non-guest | Happy, Full | ditolak aturan kategori |

## DT-M02B Modul Ticket Access & Status Update (High)

Kondisi:

- `C1`: requester owner tiket.
- `C2`: requester admin.
- `C3`: requester bukan owner dan bukan admin.
- `C4`: update status dilakukan admin dengan status target valid.

Aksi:

- `A1`: akses tiket diizinkan.
- `A2`: akses tiket ditolak.
- `A3`: update status sukses.
- `A4`: update status ditolak.

| Kondisi/Aksi | R1 | R2 | R3 | R4 | R5 |
|---|---|---|---|---|---|
| C1 requester owner | Y | N | N | N | Y |
| C2 requester admin | N | Y | N | Y | N |
| C3 outsider | N | N | Y | N | N |
| C4 admin status valid | - | - | - | Y | - |
| A1 akses diizinkan | Y | Y | N | N | Y |
| A2 akses ditolak | N | N | Y | N | N |
| A3 update status sukses | N | N | N | Y | N |
| A4 update status ditolak | N | N | N | N | Y |

| TC ID | Rule | Contoh Nilai Input | Paket | Expected |
|---|---|---|---|---|
| TC-M02B-01 | R1 | owner baca detail tiket | Happy, Full | akses diizinkan |
| TC-M02B-02 | R2 | admin baca detail tiket | Happy, Full | akses diizinkan |
| TC-M02B-03 | R3 | outsider baca detail tiket | Happy, Full | akses ditolak |
| TC-M02B-04 | R4 | admin ubah status waiting->resolved | Happy, Full | update status sukses |
| TC-M02B-05 | R5 | owner coba ubah status | Happy, Full | update status ditolak |

## DT-M03 Modul Survey Lifecycle (High)

Kondisi:

- `C1`: role user registered.
- `C2`: tiket status resolved.
- `C3`: user owner tiket.
- `C4`: survey belum pernah dikirim.

Aksi:

- `A1`: submit survey sukses.
- `A2`: submit ditolak karena role/status/ownership.
- `A3`: submit ditolak karena duplikasi.

| Kondisi/Aksi | R1 | R2 | R3 |
|---|---|---|---|
| C1 role registered | Y | N | Y |
| C2 status resolved | Y | Y | Y |
| C3 owner tiket | Y | Y | Y |
| C4 belum submit | Y | Y | N |
| A1 submit sukses | Y | N | N |
| A2 submit ditolak | N | Y | N |
| A3 duplicate ditolak | N | N | Y |

| TC ID | Rule | Contoh Nilai Input | Paket | Expected |
|---|---|---|---|---|
| TC-M03-01 | R1 | registered + resolved + owner + first submit | Smoke, Happy, Full | submit survey sukses |
| TC-M03-02 | R2 | guest/non-owner/non-resolved | Happy, Full | submit ditolak |
| TC-M03-03 | R3 | submit kedua tiket sama | Happy, Full | duplicate ditolak |

## DT-M04 Modul Reporting & Export (High)

Kondisi:

- `C1`: role admin valid.
- `C2`: `period` valid.
- `C3`: `periods` valid (`>0` dan dalam batas).
- `C4`: mode export.

Aksi:

- `A1`: report JSON sukses.
- `A2`: export sukses.
- `A3`: request ditolak.

| Kondisi/Aksi | R1 | R2 | R3 | R4 |
|---|---|---|---|---|
| C1 role admin valid | Y | Y | N | Y |
| C2 period valid | Y | N | - | Y |
| C3 periods valid | Y | Y | - | N |
| C4 mode export | N | N | N | Y |
| A1 report JSON sukses | Y | N | N | N |
| A2 export sukses | N | N | N | Y |
| A3 request ditolak | N | Y | Y | N |

| TC ID | Rule | Contoh Nilai Input | Paket | Expected |
|---|---|---|---|---|
| TC-M04-01 | R1 | `period=monthly`, `periods=6` | Smoke, Happy, Full | report tampil normal |
| TC-M04-02 | R2 | `period=unknown` | Happy, Full | request ditolak/ditangani invalid |
| TC-M04-03 | R3 | non-admin akses report | Happy, Full | ditolak otorisasi |
| TC-M04-04 | R4 | admin + mode export valid | Happy, Full | export berhasil |

## DT-M05 Modul Medium/Low (Notification, Upload, Category)

Kondisi:

- `C1`: token notifikasi valid.
- `C2`: ukuran file upload valid (`<=5MB`).
- `C3`: assign kategori dilakukan admin.

Aksi:

- `A1`: register/unregister notifikasi sukses.
- `A2`: upload/download lampiran sukses.
- `A3`: assign template kategori sukses.
- `A4`: request ditolak.

| Kondisi/Aksi | R1 | R2 | R3 | R4 |
|---|---|---|---|---|
| C1 token valid | Y | N | - | - |
| C2 ukuran file valid | - | Y | N | - |
| C3 role admin valid | - | - | Y | N |
| A1 notif sukses | Y | N | N | N |
| A2 upload sukses | N | Y | N | N |
| A3 assign sukses | N | N | Y | N |
| A4 request ditolak | N | N | N | Y |

| TC ID | Rule | Contoh Nilai Input | Paket | Expected |
|---|---|---|---|---|
| TC-M05-01 | R1 | token FCM valid | Happy, Full | register/unregister sukses |
| TC-M05-02 | R2 | upload file 1MB | Happy, Full | upload dan download sukses |
| TC-M05-03 | R3 | admin assign template kategori valid | Happy, Full | assign sukses |
| TC-M05-04 | R4 | token invalid / upload 6MB / non-admin assign | Full | request ditolak |

## 3. Ringkasan Cakupan Per Paket

1. `Smoke`: `TC-M01-01`, `TC-M02A-01`, `TC-M03-01`, `TC-M04-01`.
2. `Happy`: seluruh rule modul High + rule utama modul Medium/Low.
3. `Full`: seluruh test case modul High + pendalaman Medium/Low bila diperlukan (`TC-M05-04`).

# Product Requirements Document (PRD)

## Aplikasi Keuangan untuk Ojol

**Versi:** 1.2
**Platform:** Flutter / Mobile
**Arsitektur:** Offline-first
**Target pengguna:** Driver ojol / pekerja dengan pendapatan tidak tetap

---

# 1. Status Definitions

## 1.1 Status Hari

Setiap tanggal memiliki status aktivitas.

### `WORKING`

User melakukan aktivitas narik pada tanggal tersebut dan memiliki pendapatan.

Contoh:

> 18 September
> Pendapatan Rp200.000

---

### `OFF`

User tidak narik pada tanggal tersebut.

Tidak ada pendapatan.

Contoh:

> 19 September
> Libur

Hari `OFF` tidak dianggap sebagai hari gagal mencapai target.

---

### `NO_DATA`

Tidak ada informasi yang cukup untuk menentukan apakah user bekerja atau libur.

Status ini terutama digunakan untuk tanggal yang belum memiliki aktivitas.

Contoh:

> 20 September
> Belum ada transaksi.

### Aturan

* `WORKING` dapat ditentukan otomatis ketika terdapat pendapatan pada tanggal tersebut.
* `OFF` dapat ditentukan berdasarkan konfigurasi hari libur atau input user.
* `NO_DATA` digunakan untuk tanggal masa lalu/masa kini yang belum memiliki informasi aktivitas.
* Hari `OFF` tidak menghasilkan pendapatan Rp0 secara otomatis.
* Hari `OFF` tidak masuk denominator target hari narik.
* User tetap dapat mencatat pendapatan pada hari yang sebelumnya ditandai sebagai `OFF`. Jika terjadi, status menjadi `WORKING`.

---

# 2. Status Pendapatan

Pendapatan memiliki status sederhana.

### `ACTIVE`

Transaksi pendapatan aktif dan masuk ke perhitungan.

### `DELETED`

Transaksi telah dihapus oleh user dan tidak lagi masuk perhitungan.

MVP tidak memerlukan status `PENDING` karena pendapatan dicatat sebagai pendapatan bersih yang sudah diterima menurut catatan user.

---

# 3. Status Pengeluaran

### `ACTIVE`

Pengeluaran valid dan masuk ke perhitungan.

### `DELETED`

Pengeluaran telah dihapus dan tidak lagi masuk perhitungan.

---

# 4. Status Alokasi

Alokasi memiliki status berdasarkan hubungan antara nominal yang dialokasikan dan tujuan.

### `ACTIVE`

Alokasi masih tersedia dan belum direalisasikan sebagai pembayaran/pengeluaran.

### `PARTIALLY_USED`

Sebagian dana alokasi sudah digunakan.

### `FULLY_USED`

Seluruh dana alokasi sudah digunakan.

### `CANCELLED`

Alokasi dibatalkan.

Alokasi yang `CANCELLED` tidak dihitung sebagai uang yang sedang diamankan.

---

# 5. Status Kewajiban

Status kewajiban harus menggambarkan kondisi kewajiban terhadap target nominal dan jatuh tempo.

## `UPCOMING`

Kewajiban belum jatuh tempo dan belum mencapai tanggal peringatan.

Contoh:

> Cicilan motor
> Jatuh tempo 30 September
> Hari ini 18 September

---

## `IN_PROGRESS`

Kewajiban sedang dipersiapkan dan sudah memiliki sebagian alokasi.

Contoh:

> Target Rp500.000
> Alokasi Rp200.000

---

## `READY`

Nominal kewajiban telah dialokasikan penuh, tetapi belum dibayar.

Contoh:

> Target Rp500.000
> Alokasi Rp500.000
> Pembayaran Rp0

Artinya:

> Uang sudah siap, tinggal dibayar.

---

## `PAID`

Kewajiban telah dibayar penuh.

---

## `PARTIALLY_PAID`

Sebagian kewajiban telah dibayar tetapi masih memiliki sisa.

Contoh:

> Target Rp500.000
> Sudah dibayar Rp300.000
> Sisa Rp200.000

---

## `OVERDUE`

Tanggal jatuh tempo telah lewat dan kewajiban belum terpenuhi.

---

## `CANCELLED`

Kewajiban dihentikan oleh user dan tidak lagi aktif.

---

# 6. Prioritas Status Kewajiban

Status dihitung berdasarkan kondisi aktual.

Urutan evaluasi:

```text
CANCELLED
    ↓
PAID
    ↓
OVERDUE
    ↓
PARTIALLY_PAID
    ↓
READY
    ↓
IN_PROGRESS
    ↓
UPCOMING
```

Namun status tidak hanya ditentukan oleh urutan tersebut. Sistem harus menggunakan kondisi nominal dan tanggal.

---

# 7. Aturan Status Kewajiban

Misalkan:

```text
targetAmount = Rp500.000
allocatedAmount = Rp300.000
paidAmount = Rp0
dueDate = 30 September
today = 18 September
```

Maka:

> `IN_PROGRESS`

Jika:

```text
allocatedAmount = Rp500.000
paidAmount = Rp0
```

Maka:

> `READY`

Jika:

```text
paidAmount = Rp500.000
```

Maka:

> `PAID`

Jika:

```text
paidAmount = Rp300.000
```

Maka:

> `PARTIALLY_PAID`

Jika tanggal sudah melewati jatuh tempo dan:

```text
paidAmount < targetAmount
```

Maka:

> `OVERDUE`

---

# 8. Financial Calculation Rules

## 8.1 Total Pendapatan

```text
Total Income =
SUM(active income transactions)
```

Hanya transaksi pendapatan dengan status `ACTIVE` yang dihitung.

---

# 9. Total Pengeluaran

```text
Total Expense =
SUM(active expense transactions)
```

Transaksi `DELETED` tidak dihitung.

---

# 10. Total Alokasi

```text
Total Allocation =
SUM(active allocations)
```

Alokasi `CANCELLED` tidak dihitung.

---

# 11. Total Pembayaran Kewajiban

```text
Total Obligation Paid =
SUM(active obligation payment transactions)
```

Pembayaran yang telah dihapus tidak dihitung.

---

# 12. Sisa Kewajiban

Untuk setiap kewajiban:

```text
Remaining Obligation =
Target Amount - Paid Amount
```

Minimum:

```text
Remaining Obligation >= 0
```

Jika pembayaran melebihi target, kelebihan harus diperlakukan sebagai pembayaran berlebih/penanganan khusus dan tidak boleh membuat sisa kewajiban menjadi negatif.

Untuk MVP, sistem sebaiknya **menolak pembayaran yang menyebabkan total pembayaran melebihi target**, kecuali user memang mengubah target kewajiban.

---

# 13. Progress Kewajiban

```text
Payment Progress =
Paid Amount / Target Amount × 100%
```

Contoh:

Target:

Rp500.000

Dibayar:

Rp300.000

Progress:

60%

---

# 14. Allocation Progress

Alokasi dan pembayaran harus dipisahkan.

```text
Allocation Progress =
Allocated Amount / Target Amount × 100%
```

Contoh:

Target:

Rp500.000

Alokasi:

Rp400.000

Pembayaran:

Rp0

Maka:

> Allocation Progress = 80%

Tetapi:

> Payment Progress = 0%

Hal ini penting karena:

> **uang sudah disiapkan ≠ kewajiban sudah dibayar.**

---

# 15. Unallocated Income

Pendapatan yang belum diberikan tujuan:

```text
Unallocated Income =
Total Income - Total Allocation
```

Namun formula ini hanya valid jika allocation merupakan alokasi terhadap uang yang benar-benar tersedia.

Jika hasil negatif:

```text
Unallocated Income = 0
```

Sistem tidak boleh menampilkan nilai negatif sebagai uang bebas.

---

# 16. Available Money

Konsep ini harus dibedakan dari saldo rekening aktual.

Untuk MVP:

```text
Available Money =
Total Income
- Total Actual Expense
```

Sedangkan:

```text
Allocated Money =
Total active allocation
```

Dan:

```text
Unallocated Money =
Available Money - Allocated Money
```

Minimum:

```text
Unallocated Money >= 0
```

Namun ada kondisi penting ketika user melakukan pengeluaran dari dana yang sudah dialokasikan.

---

# 17. Allocation vs Actual Expense

Contoh:

Pendapatan:

Rp600.000

Alokasi:

Rp600.000

Pengeluaran aktual:

Rp0

Maka:

```text
Available Money = Rp600.000
Allocated Money = Rp600.000
Unallocated Money = Rp0
```

Artinya:

> User masih memiliki Rp600.000 secara fisik, tetapi seluruhnya sudah memiliki tujuan.

---

# 18. Pengeluaran dari Dana Bebas

Contoh:

Pendapatan:

Rp600.000

Alokasi:

Rp500.000

Dana bebas:

Rp100.000

User mengeluarkan:

Rp50.000

Maka:

```text
Available Money = Rp550.000
Allocated Money = Rp500.000
Unallocated Money = Rp50.000
```

---

# 19. Pengeluaran dari Dana yang Sudah Dialokasikan

Ini merupakan kasus penting.

Contoh:

Pendapatan:

Rp600.000

Alokasi:

Rp500.000

Dana bebas:

Rp100.000

Kemudian user membutuhkan Rp150.000 untuk anak sakit.

User menggunakan:

* Rp100.000 dana bebas;
* Rp50.000 dari alokasi kewajiban.

Maka:

```text
Available Money = Rp450.000
Allocated Money = Rp450.000
Unallocated Money = Rp0
```

Alokasi kewajiban terkait berkurang Rp50.000.

Sistem kemudian menghitung kembali kekurangan kewajiban.

---

# 20. Recommended Allocation

Untuk MVP, sistem rekomendasi alokasi dapat menggunakan kebutuhan kewajiban sebagai salah satu dasar.

Konsep awal:

```text
Required Allocation =
Remaining Obligation / Remaining Working Days
```

Contoh:

Sisa kewajiban:

Rp500.000

Hari narik tersisa:

5

Maka:

```text
Rp500.000 / 5
= Rp100.000
```

Rekomendasi:

> Sisihkan ±Rp100.000 setiap hari narik.

Ini merupakan rekomendasi, bukan kewajiban.

User dapat memilih nominal lain.

---

# 21. Multiple Obligations

Jika terdapat beberapa kewajiban:

```text
Listrik      Rp100.000
Motor        Rp500.000
Kontrakan    Rp800.000
```

Sistem tidak boleh hanya melihat total nominal.

Prioritas rekomendasi mempertimbangkan:

1. tanggal jatuh tempo;
2. kekurangan nominal;
3. jumlah hari narik tersisa.

Contoh:

```text
Listrik
Rp100.000
Jatuh tempo 3 hari lagi

Motor
Rp500.000
Jatuh tempo 15 hari lagi
```

Rekomendasi harus mempertimbangkan listrik sebagai kebutuhan yang lebih dekat jatuh tempo.

**Catatan:** ini adalah aturan prioritas perhitungan, bukan kewajiban user untuk mengikuti rekomendasi.

---

# 22. Working Days

Target pendapatan menggunakan jumlah hari narik.

Misalnya:

```text
Target bulanan = Rp4.000.000
Hari narik = 26
```

Maka:

```text
Daily Target =
Rp4.000.000 / 26
= Rp153.846
```

Pembulatan hanya untuk tampilan.

Perhitungan internal menggunakan nilai presisi penuh.

---

# 23. Remaining Working Days

Sistem menghitung jumlah hari narik yang masih tersisa dalam periode target.

Hari yang dihitung:

* hari yang direncanakan sebagai hari narik;
* belum berlalu;
* belum selesai sebagai hari narik.

Hari `OFF` tidak dihitung.

---

# 24. Dynamic Daily Target

Misalnya:

```text
Monthly Target = Rp4.000.000
Income = Rp2.900.000
Remaining Target = Rp1.100.000

Remaining Working Days = 6
```

Maka:

```text
Required Daily Income =
Rp1.100.000 / 6
= Rp183.333
```

Dashboard menampilkan:

> Target berikutnya ±Rp183.333/hari narik.

---

# 25. Income Above Target

Jika pendapatan sudah melebihi target:

```text
Remaining Target <= 0
```

Maka target pendapatan dianggap:

> `ACHIEVED`

Tidak ada nilai target negatif.

Pendapatan tambahan tetap dicatat sebagai pendapatan normal.

---

# 26. Target Status

Target pendapatan memiliki status:

### `NOT_STARTED`

Belum ada pendapatan pada periode tersebut.

### `IN_PROGRESS`

Sudah ada pendapatan tetapi target belum tercapai.

### `ACHIEVED`

Pendapatan telah mencapai atau melebihi target.

### `ENDED`

Periode target telah selesai tetapi target belum tercapai.

`ENDED` bersifat informatif dan bukan penilaian terhadap user.

---

# 27. Income-to-Expense Ratio

Sistem dapat menghitung:

```text
Expense Ratio =
Total Expense / Total Income × 100%
```

Contoh:

Pendapatan:

Rp4.000.000

Pengeluaran:

Rp2.000.000

Maka:

> Expense Ratio = 50%

Rasio ini hanya informatif.

---

# 28. Fuel Ratio

Untuk bensin:

```text
Fuel Ratio =
Fuel Expense / Total Income × 100%
```

Contoh:

Pendapatan:

Rp4.000.000

Bensin:

Rp800.000

Maka:

> Fuel Ratio = 20%

---

# 29. Negative Available Money

Sistem harus mencegah kondisi uang tersedia menjadi negatif secara normal.

Namun pengeluaran mendadak dapat menyebabkan:

> uang yang tersedia lebih kecil dibanding dana yang sudah dialokasikan.

Dalam kondisi tersebut, sistem **tidak boleh membuat angka saldo fiktif**.

Sebaliknya, sistem harus menunjukkan:

```text
Available Money = Rp450.000
Allocated = Rp500.000
Allocation Shortfall = Rp50.000
```

Artinya:

> Rp50.000 dari alokasi sebelumnya sudah tidak lagi memiliki dana aktual.

---

# 30. Allocation Shortfall

Formula:

```text
Allocation Shortfall =
Allocated Money - Available Money
```

Jika hasil:

```text
<= 0
```

maka:

> tidak ada shortfall.

Jika:

```text
> 0
```

maka sistem menampilkan peringatan.

Contoh:

> ⚠️ Alokasi kurang Rp50.000

Ini dapat terjadi karena user menggunakan uang yang sebelumnya telah dialokasikan.

---

# 31. Cash Position

Untuk membedakan kondisi fisik uang dan tujuan uang:

### Cash Available

```text
Total Income - Total Actual Expense
```

### Allocated

```text
Total Active Allocation
```

### Free Cash

```text
MAX(0, Cash Available - Allocated)
```

### Allocation Shortfall

```text
MAX(0, Allocated - Cash Available)
```

Contoh:

```text
Cash Available      Rp450.000
Allocated           Rp500.000
Free Cash           Rp0
Shortfall           Rp50.000
```

---

# 32. Important Accounting Rule

Sistem **tidak boleh menyamakan**:

```text
Saldo fisik
```

dengan:

```text
Uang bebas
```

Contoh:

User memiliki uang tunai/rekening:

Rp600.000

Tetapi:

Rp500.000 sudah dialokasikan untuk kewajiban.

Maka:

> Cash Available = Rp600.000

tetapi:

> Free Cash = Rp100.000

Ini merupakan konsep utama aplikasi.

---

# 33. Pengeluaran dan Alokasi

Ketika user mencatat pengeluaran, sistem harus mengetahui sumber dana.

Pilihan:

### `FREE`

Pengeluaran berasal dari uang bebas.

### `ALLOCATED`

Pengeluaran berasal dari dana yang sudah dialokasikan.

### `MIXED`

Pengeluaran menggunakan kombinasi uang bebas dan dana yang dialokasikan.

Contoh:

Pengeluaran:

Rp150.000

Uang bebas:

Rp100.000

Alokasi:

Rp50.000

Maka:

```text
Source:
FREE = Rp100.000
ALLOCATED = Rp50.000
```

---

# 34. Rule untuk Pengeluaran dari Allocation

Jika user memilih menggunakan dana yang dialokasikan:

1. Cash Available berkurang.
2. Allocation terkait berkurang.
3. Progress allocation diperbarui.
4. Kekurangan kewajiban diperbarui.
5. Dashboard diperbarui.

Sistem tidak boleh menghapus histori alokasi sebelumnya.

Harus terdapat jejak transaksi agar data dapat diaudit.

---

# 35. Date Rule

Semua transaksi memiliki:

* transaction date;
* created timestamp;
* updated timestamp.

`transaction date` digunakan untuk laporan.

`created timestamp` digunakan untuk histori sistem.

---

# 36. Editing Transaction

Ketika user mengubah transaksi:

* sistem harus menghitung ulang seluruh nilai terkait;
* dashboard harus diperbarui;
* progress kewajiban harus diperbarui;
* laporan harus diperbarui.

Contoh:

Pendapatan:

Rp200.000 → Rp250.000

Maka seluruh perhitungan yang menggunakan pendapatan tersebut harus dihitung ulang.

---

# 37. Deleting Transaction

Penghapusan transaksi harus menggunakan confirmation.

Contoh:

> Hapus pendapatan Rp200.000 tanggal 18 September?

Setelah dihapus:

* transaksi tidak masuk perhitungan;
* allocation terkait harus divalidasi ulang;
* dashboard diperbarui;
* progress target diperbarui.

Jika penghapusan menyebabkan allocation shortfall, sistem harus menampilkan kondisi tersebut.

---

# 38. Rounding Rule

Perhitungan internal menggunakan presisi penuh.

Pembulatan hanya dilakukan pada tampilan.

Contoh:

```text
Rp4.000.000 / 26
= 153846.153846...
```

UI:

> Rp153.846

Nilai internal tidak dipotong menjadi Rp153.846 sebelum perhitungan berikutnya.

---

# 39. Zero Rules

Sistem harus menangani:

```text
Income = Rp0
Expense = Rp0
Allocation = Rp0
Target = Rp0
```

Tidak boleh terjadi:

* division by zero;
* NaN;
* infinity;
* nilai negatif akibat perhitungan sederhana.

Contoh:

Jika:

```text
Target = Rp0
```

maka daily target tidak dihitung.

---

# 40. Currency Rules

MVP menggunakan:

> **Indonesian Rupiah (IDR)**

Semua nominal:

* menggunakan bilangan bulat rupiah;
* tidak menggunakan decimal fraction;
* tidak menggunakan floating point untuk penyimpanan nominal jika dapat dihindari.

Contoh:

```text
200000
```

bukan:

```text
200000.00
```

---

# 41. Calculation Priority

Untuk menjaga konsistensi data, perhitungan dilakukan berdasarkan urutan:

```text
1. Transactions
       ↓
2. Cash Available
       ↓
3. Allocations
       ↓
4. Free Cash / Shortfall
       ↓
5. Obligations
       ↓
6. Targets
       ↓
7. Dashboard / Reports
```

Dashboard dan laporan **tidak menyimpan hasil perhitungan sebagai sumber kebenaran utama**.

Data transaksi merupakan source of truth.

---

# 42. Source of Truth

Data utama aplikasi:

```text
Income Transactions
Expense Transactions
Allocation Transactions
Obligation Definitions
Obligation Payment Transactions
User Configuration
Target Definitions
```

Nilai seperti:

* saldo;
* progress;
* uang bebas;
* shortfall;
* ratio;

sebaiknya dihitung dari data tersebut atau disimpan sebagai cache yang dapat dihitung ulang.

Tujuannya agar:

> **Jika database perlu direbuild/recalculate, hasil keuangan tetap konsisten.**

---

# 43. Financial Integrity Rules

Sistem harus menjaga beberapa invariant:

### FI-001

Pendapatan aktif tidak boleh dihitung dua kali.

### FI-002

Pengeluaran yang dihapus tidak boleh masuk perhitungan.

### FI-003

Alokasi yang dibatalkan tidak boleh dianggap sebagai dana yang diamankan.

### FI-004

Pembayaran kewajiban tidak boleh melebihi target pada MVP.

### FI-005

Uang bebas tidak boleh negatif.

### FI-006

Allocation shortfall harus dapat terjadi dan ditampilkan.

### FI-007

Alokasi tidak sama dengan pembayaran.

### FI-008

Hari libur tidak mengurangi jumlah uang.

### FI-009

Hari libur tidak dihitung sebagai hari narik.

### FI-010

Pengeluaran mendadak tetap merupakan transaksi aktual meskipun tidak memiliki alokasi sebelumnya.

---

# 44. Contoh End-to-End

## Kondisi Awal

Kewajiban:

> Listrik Rp100.000
> Motor Rp500.000

Pendapatan:

> Rp600.000

---

## Setelah Alokasi

```text
Cash Available = Rp600.000
Allocated = Rp600.000
Free Cash = Rp0
Shortfall = Rp0
```

Allocation:

```text
Listrik = Rp100.000
Motor = Rp500.000
```

---

## User Mengalami Pengeluaran Mendadak

Anak sakit:

> Rp150.000

User menggunakan:

> Rp100.000 dari bebas
> Rp50.000 dari alokasi motor

Maka:

```text
Cash Available = Rp450.000
Allocated = Rp550.000
```

Karena:

```text
550.000 - 450.000 = 100.000
```

Maka:

> Allocation Shortfall = Rp100.000

Motor:

```text
Target = Rp500.000
Allocated = Rp450.000
```

Aplikasi menunjukkan:

> ⚠️ Motor masih membutuhkan Rp50.000 untuk mencapai target alokasi.

Jika sebagian alokasi memang "dikonsumsi" oleh pengeluaran mendadak, sistem juga harus mencatat sumber penggunaan tersebut secara eksplisit agar shortfall tidak hanya menjadi angka agregat.

---

# 45. Prinsip Perhitungan Utama

Aplikasi harus selalu mampu menjawab empat pertanyaan:

### 1. Berapa uang saya?

> **Cash Available**

### 2. Berapa yang sudah saya amankan?

> **Allocated Money**

### 3. Berapa yang bebas saya gunakan?

> **Free Cash**

### 4. Apakah ada uang yang sudah saya janjikan tetapi sudah terpakai?

> **Allocation Shortfall**

Keempat angka ini merupakan konsep inti financial engine aplikasi.

---

# 46. Catatan Implementasi

Sebelum development dimulai, financial engine sebaiknya dibuat sebagai layer/domain terpisah dari UI.

Contoh konsep:

```text
Transaction Repository
        ↓
Financial Calculator
        ↓
Financial State
        ↓
Flutter UI
```

Dengan demikian:

* UI tidak menghitung saldo sendiri;
* dashboard tidak memiliki formula yang berbeda dengan laporan;
* acceptance criteria dapat diuji secara otomatis;
* perubahan UI tidak mengubah logika finansial.

---

# 47. Definition of Done untuk Financial Engine

Financial engine dianggap siap apabila test mencakup minimal:

1. pendapatan tunggal;
2. banyak pendapatan;
3. pengeluaran;
4. alokasi;
5. kewajiban;
6. pembayaran kewajiban;
7. pengeluaran mendadak;
8. pengeluaran dari dana bebas;
9. pengeluaran dari dana teralokasi;
10. allocation shortfall;
11. hari libur;
12. target berdasarkan hari narik;
13. target tercapai;
14. target tidak tercapai;
15. edit transaksi;
16. delete transaksi;
17. restore backup;
18. nilai nol;
19. pembulatan;
20. beberapa kewajiban dengan tanggal jatuh tempo berbeda.

Tujuan akhirnya adalah memastikan **angka yang ditampilkan aplikasi dapat ditelusuri kembali ke transaksi sumbernya dan selalu menghasilkan perhitungan yang konsisten.**

# 48. LOCAL PUSH NOTIFICATION / PENGINGAT INPUT HARIAN

1. Tujuan

Fitur ini membantu pengguna mengingat untuk mencatat aktivitas keuangan harian, terutama pendapatan setelah selesai narik.

Masalah utama yang ingin diselesaikan:

Pengguna sering lupa atau malas mencatat pendapatan harian sehingga data keuangan menjadi tidak lengkap dan perhitungan target, alokasi, kewajiban, serta laporan menjadi kurang akurat.

Ojol Daily harus membantu membentuk kebiasaan:

Selesai narik → Dapat uang → Ingat untuk mencatat → Alokasikan uang

Fitur ini menggunakan local push notification sehingga tidak membutuhkan backend, internet, akun, maupun cloud service.

2. Prinsip Fitur

Pengingat harus:

sederhana
tidak mengganggu
tidak menghakimi
tidak terlalu sering
relevan dengan aktivitas pengguna
langsung mengarah ke input pendapatan
tetap berfungsi secara offline
dapat dimatikan sepenuhnya oleh pengguna

Ojol Daily tidak boleh membuat pengguna merasa bersalah karena belum mencatat.

Gunakan bahasa yang ringan dan manusiawi.

Contoh:

“Sudah selesai narik? Jangan lupa catat pendapatan hari ini.”

Hindari:

“Anda belum memasukkan pendapatan hari ini!”

3. Behavior Utama

Default:

Pengingat aktif
Pengingat pertama: 20:00
Pengingat kedua: 22:00
Maksimal 2 pengingat per hari

Pengguna dapat mengubah pengaturan tersebut.

Pengingat pertama

Dikirim apabila:

Pengingat aktif
Hari bukan OFF
Belum ada pendapatan hari ini
Waktu sekarang sudah mencapai waktu pengingat
Pengingat pertama hari tersebut belum dikirim

Notification:

Title

Jangan lupa catat pendapatan

Body

Sudah selesai narik? Catat pendapatan hari ini supaya targetmu tetap akurat.

Pengingat kedua

Pengingat kedua bersifat opsional.

Dikirim apabila:

Pengingat aktif
Hari bukan OFF
Belum ada pendapatan hari ini
Pengingat pertama sudah dikirim
Pengingat kedua belum dikirim
Waktu sekarang sudah mencapai waktu pengingat kedua

Notification:

Title

Pendapatan hari ini sudah dicatat?

Body

Cukup masukkan total pendapatan hari ini. Tidak perlu lama.

Maksimal:

2 notification / hari

4. Kondisi Tidak Mengirim Notification

Notification tidak boleh dikirim apabila:

4.1 Hari OFF

Jika user menandai hari sebagai:

OFF

Maka tidak ada pengingat pendapatan.

4.2 Sudah ada pendapatan hari ini

Jika terdapat minimal satu transaksi pendapatan ACTIVE pada tanggal hari ini:

Income Today > 0

Maka pengingat pendapatan tidak dikirim.

4.3 Pengingat dimatikan

Jika:

Reminder Enabled = FALSE

Maka seluruh local notification dinonaktifkan.

4.4 Batas pengingat tercapai

Jika:

Daily Reminder Count >= 2

Tidak boleh ada notification tambahan.

5. Kondisi Hari NO_DATA

Jika status hari masih:

NO_DATA

dan belum terdapat pendapatan hari ini, aplikasi dapat menggunakan pengingat netral.

Contoh:

Title

Sudah selesai aktivitas hari ini?

Body

Tandai hari ini sebagai narik atau libur supaya catatanmu tetap rapi.

Ketika notification ditekan, aplikasi membuka flow:

Hari ini narik atau libur?

Pilihan:

Narik
Libur

Jika user memilih:

Narik

Buka:

Quick Input Pendapatan

Jika user memilih:

Libur

Set status hari menjadi:

OFF

dan tidak mengirim reminder pendapatan berikutnya pada hari tersebut.

6. Notification → Quick Input

Notification harus memiliki deep link sederhana.

Flow:

Notification
↓
Quick Input
↓
Masukkan Pendapatan
↓
Simpan
↓
Selesai

Jangan mengarahkan user ke:

Dashboard → Pendapatan → Tambah → Form

Tujuan fitur ini adalah mengurangi friction sebanyak mungkin.

7. Quick Input Pendapatan

Ketika user membuka notification, tampilkan input sederhana.

Contoh:

Catat Pendapatan Hari Ini

Total pendapatan

Rp __________

Optional:

Tanggal: Hari ini
Catatan

Primary button:

Simpan Pendapatan

Setelah berhasil:

Pendapatan berhasil dicatat.

Kemudian:

notification hari tersebut dianggap selesai
reminder berikutnya tidak dikirim
dashboard diperbarui
target diperbarui
rekomendasi alokasi diperbarui
laporan diperbarui
8. Dashboard Reminder Banner

Selain local notification, Dashboard menampilkan reminder ringan apabila belum ada pendapatan hari ini.

Contoh:

Belum ada pendapatan hari ini

Setelah selesai narik, jangan lupa catat ya.

Button:

Catat Pendapatan

Banner hanya muncul apabila:

hari bukan OFF
belum ada income hari ini

Banner hilang setelah income hari ini tercatat.

Jika hari OFF:

Banner tidak ditampilkan.

9. Notification Settings

Tambahkan pengaturan berikut pada:

Pengaturan → Pengingat

Pengingat Input Harian

Toggle:

Pengingat input harian

Default:

ON

Description:

Ingatkan saya untuk mencatat pendapatan setelah selesai narik.

Waktu Pengingat

Default:

20:00

Input menggunakan time picker.

Pengingat Kedua

Toggle:

Pengingat kedua

Default:

ON

Description:

Kirim satu pengingat tambahan jika pendapatan hari ini belum dicatat.

Waktu Pengingat Kedua

Default:

22:00

Hanya aktif apabila pengingat kedua aktif.

Hari Pengingat

User dapat memilih hari kerja.

Contoh:

☑ Senin
☑ Selasa
☑ Rabu
☑ Kamis
☑ Jumat
☑ Sabtu
☐ Minggu

Namun jika user secara manual mengubah suatu tanggal menjadi OFF, tanggal tersebut tetap tidak mendapatkan reminder meskipun hari tersebut termasuk jadwal kerja.

10. Default Configuration

Saat pertama kali setup:

reminder_enabled = true

first_reminder_enabled = true
first_reminder_time = 20:00

second_reminder_enabled = true
second_reminder_time = 22:00

Pengaturan hari kerja mengikuti konfigurasi hari kerja pengguna.

11. Reminder Eligibility
First Reminder
Reminder Eligible =
    Reminder Enabled
    AND Day Status != OFF
    AND Income Today == 0
    AND Current Time >= First Reminder Time
    AND First Reminder Sent == FALSE
Second Reminder
Second Reminder Eligible =
    Reminder Enabled
    AND Day Status != OFF
    AND Income Today == 0
    AND First Reminder Sent == TRUE
    AND Second Reminder Sent == FALSE
    AND Current Time >= Second Reminder Time
Daily Limit
Daily Reminder Count <= 2
12. Notification State

Local database harus menyimpan state reminder per tanggal.

Minimal:

ReminderLog

id
date
first_reminder_sent
second_reminder_sent
first_reminder_sent_at
second_reminder_sent_at

Tujuan:

mencegah notification terkirim berulang kali
mengetahui apakah reminder pertama sudah dikirim
mengetahui apakah reminder kedua sudah dikirim
mempertahankan state ketika aplikasi dibuka kembali
13. Notification Permission

Saat fitur reminder pertama kali digunakan, aplikasi dapat meminta permission notification kepada user.

Jelaskan manfaat sebelum meminta permission.

Contoh:

“Ojol Daily bisa mengingatkan kamu untuk mencatat pendapatan setelah selesai narik.”

Button:

Aktifkan Pengingat

Secondary:

Nanti saja

Jika permission ditolak:

aplikasi tetap dapat digunakan
pencatatan keuangan tetap berjalan normal
tidak boleh terus-menerus meminta permission
user dapat mengaktifkan kembali melalui Settings perangkat jika diperlukan
14. Offline Behavior

Local notification harus tetap berfungsi tanpa:

login
backend
internet
cloud
API eksternal

Semua konfigurasi reminder disimpan secara lokal.

Perubahan konfigurasi reminder harus langsung memengaruhi jadwal notification lokal.

15. App Restart

Setelah aplikasi ditutup atau perangkat melakukan restart:

konfigurasi reminder tetap tersimpan
notification harus dijadwalkan kembali sesuai konfigurasi
state reminder harian tidak boleh hilang
tidak boleh terjadi duplicate notification
16. Perubahan Data

Jika user mencatat pendapatan setelah reminder dijadwalkan:

Reminder berikutnya harus dibatalkan / tidak dikirim.

Contoh:

20:00 reminder dikirim.

20:15 user mencatat pendapatan.

22:00 reminder kedua:

TIDAK DIKIRIM

Karena:

Income Today > 0
17. Jika User Menghapus Pendapatan

Jika user sebelumnya sudah mencatat pendapatan kemudian menghapus seluruh transaksi pendapatan hari tersebut:

Income Today = 0

Sistem boleh kembali menganggap user belum mencatat pendapatan.

Namun notification yang sudah lewat pada hari tersebut tidak boleh dikirim ulang secara otomatis berkali-kali.

Tujuan:

Menghindari spam notification akibat edit/delete transaksi.

18. Jika User Mengubah Hari Menjadi OFF

Jika sebelumnya hari tersebut dianggap WORKING kemudian user mengubahnya menjadi:

OFF

Maka:

reminder yang belum dikirim dibatalkan
tidak ada reminder berikutnya
Dashboard tidak menampilkan reminder input
hari tersebut tidak dihitung sebagai working day

Jika user mengubah kembali menjadi WORKING:

sistem dapat mengaktifkan kembali eligibility reminder
tetap mengikuti waktu reminder yang tersedia
tidak boleh mengirim notification berulang untuk waktu yang sudah lewat secara agresif
19. Jika User Mencatat Pendapatan Setelah Reminder

Contoh:

20:00 notification muncul.

User membuka notification.

User memasukkan:

Rp150.000

Setelah save:

Income Today = Rp150.000

Maka:

First Reminder = COMPLETED
Second Reminder = CANCELLED

Dashboard langsung menampilkan data terbaru.

20. Notification Copy Guidelines

Notification harus:

pendek
mudah dipahami
tidak menghakimi
tidak menggunakan bahasa formal
tidak menggunakan istilah akuntansi
fokus pada tindakan sederhana

Contoh yang diperbolehkan:

“Sudah selesai narik? Jangan lupa catat pendapatan hari ini.”

“Pendapatan hari ini sudah dicatat?”

“Cukup masukkan total pendapatan hari ini.”

Contoh yang dihindari:

“Anda gagal memenuhi kewajiban pencatatan finansial harian.”

“Data keuangan Anda belum lengkap.”

“Segera lakukan input transaksi.”

21. Acceptance Criteria
AC-01

User dapat mengaktifkan dan menonaktifkan reminder.

AC-02

User dapat mengatur waktu reminder pertama.

AC-03

User dapat mengaktifkan dan menonaktifkan reminder kedua.

AC-04

User dapat mengatur waktu reminder kedua.

AC-05

Reminder tidak dikirim pada hari OFF.

AC-06

Reminder tidak dikirim jika sudah terdapat income ACTIVE hari ini.

AC-07

Maksimal terdapat 2 reminder per hari.

AC-08

Notification dapat membuka Quick Input Pendapatan.

AC-09

Pendapatan yang disimpan dari Quick Input langsung memperbarui Dashboard.

AC-10

Setelah pendapatan dicatat, reminder berikutnya tidak dikirim.

AC-11

Reminder tetap dapat bekerja tanpa internet.

AC-12

Pengaturan reminder tetap tersimpan setelah aplikasi ditutup.

AC-13

Notification tidak boleh duplicate akibat app restart.

AC-14

Jika permission notification ditolak, fitur keuangan lainnya tetap berfungsi normal.

AC-15

Dashboard menampilkan reminder banner jika belum ada income hari ini dan hari bukan OFF.

AC-16

Banner hilang setelah income hari ini tercatat.

AC-17

Jika user menghapus seluruh income hari ini, sistem tidak mengirim ulang notification yang sama secara berulang.

22. Non-Goal

Fitur ini TIDAK mencakup:

server push notification
Firebase Cloud Messaging
WhatsApp reminder
SMS reminder
email reminder
AI reminder
reminder berdasarkan prediksi perilaku
reminder berdasarkan lokasi
sinkronisasi cloud
integrasi Gojek/Grab/Maxim

Semua reminder pada MVP bersifat:

Local + Rule-Based + Offline

23. Dampak terhadap Produk

F-022 bukan sekadar fitur tambahan.

Fitur ini merupakan bagian dari mekanisme utama pembentukan kebiasaan Ojol Daily:

Selesai Narik
      ↓
Reminder
      ↓
Catat Pendapatan
      ↓
Alokasi
      ↓
Pantau Target
      ↓
Ulangi Besok

Tujuan akhirnya bukan hanya membuat data keuangan lebih lengkap, tetapi membantu pengguna membentuk kebiasaan:

“Setiap uang yang masuk punya tujuan sebelum digunakan.”
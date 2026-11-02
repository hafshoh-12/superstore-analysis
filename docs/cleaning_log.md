# Cleaning Log — SuperStore

Dihasilkan oleh `notebook/02_superstore_data_preparation.ipynb`.

| No | Langkah | Baris sebelum | Baris sesudah | Keterangan |
|---|---|---|---|---|
| 1 | Data mentah dibaca | 9,994 | 9,994 | SuperStore.xlsx, 20 kolom |
| 2 | Hapus duplikat penuh | 9,994 | 9,993 | Baris identik pada semua kolom (order US-2017-150119) |
| 3 | Tinjau Order_ID + Product_ID berulang | 9,993 | 9,993 | 7 pasangan dipertahankan: harga per unit dan diskon sama, hanya Quantity berbeda |
| 4 | Perbaiki Postal_Code | 9,993 | 9,993 | 449 kode pos diberi nol di depan (zfill 5) |
| 5 | Rapikan nama kolom | 9,993 | 9,993 | Semua kolom menjadi snake_case huruf kecil |
| 6 | Buang kolom country | 9,993 | 9,993 | Hanya satu nilai (United States) |
| 7 | Validasi product_id sebagai kunci | 9,993 | 9,993 | Tiap product_id punya 1 nama, 1 kategori, 1 sub-kategori |
| 8 | Buat order_line_id | 9,993 | 9,993 | order_id + nomor urut baris, contoh CA-2019-152156-01 |
| 9 | Buat fitur waktu | 9,993 | 9,993 | order_year, order_quarter, order_month, order_month_start |
| 10 | Buat ship_days | 9,993 | 9,993 | ship_date - order_date (hari) |
| 11 | Buat profit_margin dan is_loss | 9,993 | 9,993 | profit/sales dan penanda rugi 0/1 |
| 12 | Buat discount_band | 9,993 | 9,993 | 5 kelompok: 0%, 1-20%, 21-40%, 41-60%, 61-80% |
| 13 | Buat fitur pelanggan | 9,993 | 9,993 | first_order_date dan cohort_year |

## Hasil akhir
- Baris: 9,993 (mentah: 9,994)
- Kolom: 30
- Output: `data/clean/superstore_clean.csv`
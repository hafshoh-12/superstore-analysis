-- =====================================================================
-- 01_create_schema_staging.sql
-- Tujuan : membuat schema dan tabel staging untuk menampung CSV bersih
-- Jalankan di: database superstore_db (BUKAN database "postgres" bawaan)
-- Cara run : buka file di DBeaver lalu tekan Alt+X (Execute Script)
-- =====================================================================

CREATE SCHEMA IF NOT EXISTS superstore;
SET search_path TO superstore;

-- Tabel staging = "ruang tunggu" data mentah hasil import CSV.
-- Semua kolom sengaja bertipe TEXT supaya proses import di DBeaver tidak
-- salah menebak tipe (misalnya kode pos 06824 menjadi angka 6824) dan tidak
-- terpengaruh pengaturan bahasa/desimal komputer. Konversi tipe dilakukan
-- di script 02.
DROP TABLE IF EXISTS stg_superstore;

CREATE TABLE stg_superstore (
    order_line_id      TEXT,
    order_id           TEXT,
    order_date         TEXT,
    ship_date          TEXT,
    ship_mode          TEXT,
    order_year         TEXT,
    order_quarter      TEXT,
    order_month        TEXT,
    order_month_start  TEXT,
    ship_days          TEXT,
    customer_id        TEXT,
    customer_name      TEXT,
    segment            TEXT,
    first_order_date   TEXT,
    cohort_year        TEXT,
    region             TEXT,
    state              TEXT,
    city               TEXT,
    postal_code        TEXT,
    product_id         TEXT,
    product_name       TEXT,
    category           TEXT,
    sub_category       TEXT,
    sales              TEXT,
    quantity           TEXT,
    discount           TEXT,
    discount_band      TEXT,
    profit             TEXT,
    profit_margin      TEXT,
    is_loss            TEXT
);

-- Setelah script ini selesai: import data/clean/superstore_clean.csv ke tabel
-- stg_superstore lewat DBeaver (klik kanan tabel > Import Data).
-- Lalu cek jumlah barisnya, harus 9993:
-- SELECT COUNT(*) FROM stg_superstore;

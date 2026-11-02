-- =====================================================================
-- 02_build_star_schema.sql
-- Tujuan : membangun star schema (4 dimensi + 1 fakta) dari stg_superstore
-- Prasyarat: stg_superstore sudah berisi 9993 baris (hasil import CSV)
-- Aman dijalankan ulang: tabel lama dihapus lalu dibuat lagi
-- =====================================================================

set search_path to superstore;

-- Hapus dari fakta dulu (karena fakta bergantung pada dimensi).
-- CASCADE ikut menghapus view yang bergantung pada tabel-tabel ini.

drop table if exists fact_sales cascade;
drop table if exists dim_date cascade;
drop table if exists dim_customer cascade;
drop table if exists dim_product cascade;
drop table if exists dim_ego cascade;

-- =====================================================================
-- dim_date : satu baris per tanggal kalender
-- date_key berbentuk angka YYYYMMDD (ex: 20190315)
create table dim_date(
	date_key INT primary key,
	full_date DATE not null,
	calendar_year INT not null,
	calendar_quarter INT not null,
	calendar_month INT not null,
	month_name TEXT not null,
	month_start DATE not null,
	day_of_week INT not null,   -- 1 = Senin ... 7 = Minggu
	day_name TEXT not null
);


-- Rentang dibuat sedikit lebih lebar dari data (order sampai 30 Des 2020,
-- pengiriman sampai 5 Jan 2021) supaya semua tanggal order dan kirim punya pasangan.
insert into dim_date
select
	TO_CHAR(d, 'YYYYMMDD')::INT,
	d::DATE,
	EXTRACT(year from d)::INT,
	EXTRACT(quarter from d)::INT,
	EXTRACT(month from d)::INT,
	TRIM(TO_CHAR(d, 'Month')),
	DATE_TRUNC('month', d)::DATE,
	EXTRACT(ISODOW from d):: INT,
	TRIM(TO_CHAR(d, 'Day'))
from generate_series(TIMESTAMP '2017-01-01', TIMESTAMP '2021-01-31', interval '1 day') as d;

-- ---------------------------------------------------------------------
-- dim_customer : satu baris per pelanggan
-- MIN() dipakai karena tiap pelanggan hanya punya satu nilai (sudah dicek di
-- notebook 01 dan 02); MIN() cuma cara memilih satu nilai itu.
-- ---------------------------------------------------------------------

create table dim_customer (
	customer_id  TEXT primary key,
	customer_name TEXT not null,
	segment TEXT not null,
	first_order_date DATE not null,
	cohort_year INT not NULL
);

insert into dim_customer
select 
	customer_id,
	MIN(customer_name),
	MIN(segment),
	MIN(first_order_date::DATE),
	MIN(cohort_year::INT)
from stg_superstore
group by customer_id;

---------------------------------------------------------------------
-- dim_product : satu baris per Product_ID (kunci produk yang sudah divalidasi)
-- ---------------------------------------------------------------------

create table dim_product (
	product_id TEXT primary KEY,
	product_name TEXT not null,
	category TEXT not null,
	sub_category TEXT not null
);

insert into dim_product
select
	product_id,
	MIN(product_name),
	MIN(category),
	MIN(sub_category)
from stg_superstore
group by product_id;


---------------------------------------------------------------------
-- dim_geo : satu baris per kode pos (tiap kode pos hanya punya 1 kota,
-- state, dan region, sehingga kode pos bisa jadi kunci)
-- ---------------------------------------------------------------------


create table  dim_geo(
	postal_code TEXT primary key check (LENGTH(postal_code) = 5),
	city TEXT not null,
	state TEXT not null,
	region TEXT not NULL
);


insert into dim_geo
select
	postal_code,
	MIN(city),
	MIN(state),
	MIN(region)
from stg_superstore
group by postal_code;

---------------------------------------------------------------------
-- fact_sales : satu baris per order line (sama dengan satu baris CSV)
-- Berisi kunci ke dimensi + angka yang dihitung (measure)
-- ---------------------------------------------------------------------

CREATE TABLE fact_sales (
	order_line_id TEXT primary key,
	order_id TEXT not null,
	order_date_key INT not null references dim_date (date_key),
	ship_date_key INT not null references dim_date (date_key),
	customer_id TEXT not null references dim_customer (customer_id),
	product_id TEXT not null references dim_product (product_id),
	postal_code TEXT not null references dim_geo (postal_code),
	ship_mode TEXT not null,
	sales NUMERIC NOT NULL,
    quantity INT NOT NULL,
    discount NUMERIC NOT NULL,
    discount_band TEXT    NOT NULL,
    profit NUMERIC NOT NULL,
    profit_margin NUMERIC NOT NULL,
    is_loss INT NOT NULL,
    ship_days INT NOT NULL
);

insert into fact_sales
select
    order_line_id,
    order_id,
    TO_CHAR(order_date::DATE, 'YYYYMMDD')::INT,
    TO_CHAR(ship_date::DATE,  'YYYYMMDD')::INT,
    customer_id,
    product_id,
    postal_code,
    ship_mode,
    sales::NUMERIC,
    quantity::INT,
    discount::NUMERIC,
    discount_band,
    profit::NUMERIC,
    profit_margin::NUMERIC,
    is_loss::INT,
    ship_days::INT
from stg_superstore;

-- Index pada kolom kunci agar query join dan filter lebih cepat
create index idx_fact_order_date on fact_sales (order_date_key);
create index idx_fact_customer on fact_sales (customer_id);
create index idx_fact_product on fact_sales (product_id);
create index idx_fact_geo on fact_sales (postal_code);

-- Cek cepat jumlah baris tiap tabel
SELECT 'fact_sales'   AS tabel, COUNT(*) AS jumlah_baris FROM fact_sales
UNION ALL SELECT 'dim_customer', COUNT(*) FROM dim_customer
UNION ALL SELECT 'dim_product',  COUNT(*) FROM dim_product
UNION ALL SELECT 'dim_geo',      COUNT(*) FROM dim_geo
UNION ALL SELECT 'dim_date',     COUNT(*) FROM dim_date;

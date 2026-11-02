=====================================================================
-- 03_create_views.sql
-- Tujuan : membuat view (query tersimpan) untuk KPI dan analisis
-- Prasyarat: script 02 sudah dijalankan
-- Catatan : view tidak menyimpan data, hanya "resep" query; hasilnya
--           selalu mengikuti isi tabel fact_sales dan dimensi.
-- =====================================================================

set search_path to superstore;

---------------------------------------------------------------------
-- 1. vw_sales_flat : gabungan fakta + semua dimensi dalam satu tabel datar
--    (satu baris per order line). 
-- ---------------------------------------------------------------------

create or replace view vw_sales_flat as
select
	f.order_line_id,
    f.order_id,
    od.full_date          AS order_date,
    sd.full_date          AS ship_date,
    od.calendar_year      AS order_year,
    od.calendar_quarter   AS order_quarter,
    od.calendar_month     AS order_month,
    od.month_start        AS order_month_start,
    f.ship_mode,
    f.ship_days,
    c.customer_id,
    c.customer_name,
    c.segment,
    c.first_order_date,
    c.cohort_year,
    g.region,
    g.state,
    g.city,
    g.postal_code,
    p.product_id,
    p.product_name,
    p.category,
    p.sub_category,
    f.sales,
    f.quantity,
    f.discount,
    f.discount_band,
    f.profit,
    f.profit_margin,
    f.is_loss
from fact_sales f
join dim_date od on od.date_key = f.order_date_key
join dim_date sd on sd.date_key = f.ship_date_key
join dim_customer c on c.customer_id = f.customer_id
join dim_product p on p.product_id = f.product_id
join dim_geo g on g.postal_code = f.postal_code;
    
---------------------------------------------------------------------
-- 2. vw_kpi_overview : KPI total dalam satu baris
-- ---------------------------------------------------------------------   
    
create or replace view vw_kpi_overview as
select
	SUM(sales) as total_sales,
	SUM(profit) as total_profit,
	ROUND(100.0 * SUM(profit) / NULLIF(SUM(sales), 0) ,2) as profit_margin_pct,
	COUNT(distinct order_id) as orders,
	COUNT(distinct customer_id) as customers,
	ROUND(SUM(sales) / COUNT(distinct order_id), 2) as avg_order_value,
	ROUND(AVG(discount) * 100, 2) as avg_discount_pct
from fact_sales;

---------------------------------------------------------------------
-- 3. vw_kpi_monthly : KPI per bulan (untuk grafik tren / musiman, BQ1)
-- ---------------------------------------------------------------------

create or replace view vw_kpi_monthly as
select
   d.month_start,
   d.calendar_year,
   d.calendar_month,
   SUM(f.sales) as sales,
   SUM(f.profit) as profit,
   ROUND(100.0 * SUM(f.profit) / NULLIF(SUM(f.sales), 0), 2) as profit_margin_pct,
   COUNT(distinct f.order_id) as orders,
   COUNT(distinct f.customer_id) as customers
from fact_sales f
join dim_date d on d.date_key = f.order_date_key
group by d.month_start, d.calendar_year, d.calendar_month;

---------------------------------------------------------------------
-- 4. vw_kpi_yearly : KPI per tahun + pertumbuhan Sales tahun-ke-tahun (YoY)
--    LAG() mengambil nilai tahun sebelumnya
-- ---------------------------------------------------------------------
create or replace view vw_kpi_yearly as
with yearly as (
    select
        d.calendar_year,
        SUM(f.sales) as sales,
        SUM(f.profit) as profit,
        ROUND(100.0 * SUM(f.profit) / nullif(SUM(f.sales), 0), 2) as profit_margin_pct,
        COUNT(DISTINCT f.order_id) as orders,
        COUNT(DISTINCT f.customer_id) as customers
    from fact_sales f
    join dim_date d on d.date_key = f.order_date_key
    group by d.calendar_year
)
select
    calendar_year,
    sales,
    profit,
    profit_margin_pct,
    orders,
    customers,
    ROUND(100.0 * (sales / nullif(lag(sales) over (order by calendar_year), 0) - 1), 1) as sales_yoy_pct
from yearly;


---------------------------------------------------------------------
-- 5. vw_category_performance : kinerja per kategori dan sub-kategori (BQ2)
-- ---------------------------------------------------------------------

create or replace view vw_category_performance as 
select
    p.category,
    p.sub_category,
    SUM(f.sales) as sales,
    SUM(f.profit) as profit,
    ROUND(100.0 * SUM(f.profit) / nullif(SUM(f.sales), 0), 2) as profit_margin_pct,
    COUNT(*) as order_lines,
    SUM(f.is_loss) as loss_lines,
    ROUND(AVG(f.discount) * 100, 2) as avg_discount_pct
from fact_sales f
join dim_product p on p.product_id = f.product_id
group by p.category, p.sub_category;


---------------------------------------------------------------------
-- 6. vw_geo_performance : kinerja per region dan state (BQ2)
-- ---------------------------------------------------------------------

create or replace view vw_geo_performance as 
select
    g.region,
    g.state,
    SUM(f.sales) as sales,
    SUM(f.profit) as profit,
    ROUND(100.0 * SUM(f.profit) / nullif(SUM(f.sales), 0), 2) as profit_margin_pct,
    COUNT(distinct f.order_id) as orders,
    ROUND(AVG(f.discount) * 100, 2) as avg_discount_pct
from fact_sales f
join dim_geo g on g.postal_code = f.postal_code
group by g.region, g.state;

---------------------------------------------------------------------
-- 7. vw_discount_band : kinerja per kelompok diskon (BQ3)
--    band_order dipakai untuk mengurutkan kelompok di dashboard
-- ---------------------------------------------------------------------

create or replace view vw_discount_band as
select 
	f.discount_band,
    case f.discount_band
        when '0%' then 1
        when '1-20%'  then 2
        when '21-40%' then 3
        when '41-60%' then 4
        else 5
    end as band_order,
    COUNT(*) as order_lines,
    SUM(f.sales) as sales,
    SUM(f.profit) as profit,
    ROUND(AVG(f.profit), 2) as avg_profit_per_line,
    ROUND(100.0 * SUM(f.profit) / nullif(SUM(f.sales), 0), 2) as profit_margin_pct
from fact_sales f
group by f.discount_band;


---------------------------------------------------------------------
-- 8. vw_customer_summary : ringkasan per pelanggan (BQ4)
--    Dasar untuk segmentasi RFM di notebook 03:
--      recency_days = jarak hari dari order terakhir ke tanggal acuan
--      frequency    = jumlah order
--      monetary     = total sales
--    Tanggal acuan = 1 hari setelah order terakhir di seluruh data.
-- ---------------------------------------------------------------------

CREATE OR REPLACE VIEW vw_customer_summary AS
WITH ref AS (
    SELECT MAX(d.full_date) + 1 AS reference_date
    FROM fact_sales f
    JOIN dim_date d ON d.date_key = f.order_date_key
)
SELECT
    c.customer_id,
    c.customer_name,
    c.segment,
    c.cohort_year,
    MIN(d.full_date)                                AS first_order_date,
    MAX(d.full_date)                                AS last_order_date,
    (SELECT reference_date FROM ref) - MAX(d.full_date) AS recency_days,
    COUNT(DISTINCT f.order_id)                      AS frequency,
    SUM(f.sales)                                    AS monetary_sales,
    SUM(f.profit)                                   AS total_profit
FROM fact_sales f
JOIN dim_customer c ON c.customer_id = f.customer_id
JOIN dim_date     d ON d.date_key    = f.order_date_key
GROUP BY c.customer_id, c.customer_name, c.segment, c.cohort_year;

-- Cek cepat: lihat isi satu view
-- SELECT * FROM vw_kpi_overview;

select * from superstore.vw_kpi_overview;
select * from superstore.vw_kpi_yearly order by calendar_year;
SELECT * FROM superstore.vw_discount_band ORDER BY band_order;
SELECT category, sub_category, profit, profit_margin_pct
FROM superstore.vw_category_performance ORDER BY profit LIMIT 3;
SELECT COUNT(*) FROM superstore.vw_geo_performance WHERE profit < 0;
SELECT COUNT(*) FROM superstore.vw_customer_summary;

-- =====================================================================
-- 04_validation.sql
-- Tujuan : membuktikan angka di PostgreSQL sama dengan angka di Python
--          (notebook 02). Semua baris hasil harus berstatus OK.
-- Prasyarat: script 02 dan 03 sudah dijalankan
-- Nilai "expected" berasal dari data/clean/superstore_clean.csv
-- =====================================================================

SET search_path TO superstore;

WITH actual AS (
    SELECT 'fact_sales: jumlah baris'          AS check_name, COUNT(*)::NUMERIC AS actual_value FROM fact_sales
    UNION ALL SELECT 'orders unik',            COUNT(DISTINCT order_id)    FROM fact_sales
    UNION ALL SELECT 'pelanggan unik (fakta)', COUNT(DISTINCT customer_id) FROM fact_sales
    UNION ALL SELECT 'dim_customer: baris',    COUNT(*) FROM dim_customer
    UNION ALL SELECT 'dim_product: baris',     COUNT(*) FROM dim_product
    UNION ALL SELECT 'dim_geo: baris',         COUNT(*) FROM dim_geo
    UNION ALL SELECT 'dim_date: baris',        COUNT(*) FROM dim_date
    UNION ALL SELECT 'total sales',            SUM(sales)   FROM fact_sales
    UNION ALL SELECT 'total profit',           SUM(profit)  FROM fact_sales
    UNION ALL SELECT 'baris rugi (is_loss=1)', SUM(is_loss) FROM fact_sales
    UNION ALL SELECT 'vw_sales_flat: baris',   COUNT(*) FROM vw_sales_flat
    UNION ALL SELECT 'vw_kpi_monthly: total sales',        SUM(sales) FROM vw_kpi_monthly
    UNION ALL SELECT 'vw_category_performance: total profit', SUM(profit) FROM vw_category_performance
    UNION ALL SELECT 'vw_geo_performance: total sales',    SUM(sales) FROM vw_geo_performance
    UNION ALL SELECT 'vw_discount_band: total baris',      SUM(order_lines) FROM vw_discount_band
    UNION ALL SELECT 'vw_customer_summary: baris',         COUNT(*) FROM vw_customer_summary
    UNION ALL SELECT 'sales 2017', sales FROM vw_kpi_yearly WHERE calendar_year = 2017
    UNION ALL SELECT 'sales 2018', sales FROM vw_kpi_yearly WHERE calendar_year = 2018
    UNION ALL SELECT 'sales 2019', sales FROM vw_kpi_yearly WHERE calendar_year = 2019
    UNION ALL SELECT 'sales 2020', sales FROM vw_kpi_yearly WHERE calendar_year = 2020
),
expected AS (
    SELECT * FROM (VALUES
        ('fact_sales: jumlah baris',               9993::NUMERIC),
        ('orders unik',                            5009),
        ('pelanggan unik (fakta)',                 793),
        ('dim_customer: baris',                    793),
        ('dim_product: baris',                     1862),
        ('dim_geo: baris',                         632),
        ('dim_date: baris',                        1492),
        ('total sales',                            2296919.4883),
        ('total profit',                           286409.0805),
        ('baris rugi (is_loss=1)',                 1870),
        ('vw_sales_flat: baris',                   9993),
        ('vw_kpi_monthly: total sales',            2296919.4883),
        ('vw_category_performance: total profit',  286409.0805),
        ('vw_geo_performance: total sales',        2296919.4883),
        ('vw_discount_band: total baris',          9993),
        ('vw_customer_summary: baris',             793),
        ('sales 2017',                             483966.1261),
        ('sales 2018',                             470532.5090),
        ('sales 2019',                             609205.5980),
        ('sales 2020',                             733215.2552)
    ) AS e (check_name, expected_value)
)
SELECT
    a.check_name,
    e.expected_value,
    a.actual_value,
    CASE WHEN ABS(a.actual_value - e.expected_value) < 0.01 THEN 'OK' ELSE 'BERBEDA' END AS status
FROM actual a
JOIN expected e USING (check_name)
ORDER BY (CASE WHEN ABS(a.actual_value - e.expected_value) < 0.01 THEN 1 ELSE 0 END), a.check_name;


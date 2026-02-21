CREATE VIEW vw_sales_metrics AS
SELECT
	order_id,
	customer_id,
	order_date,
	region,
	product_category,
	customer_segment,
	quantity,
	unit_price,
	discount_rate,
	cost,
	payment_method,
	quantity * unit_price * (1 - discount_rate) AS revenue,
	quantity * unit_price * (1 - discount_rate) - cost AS profit,
	CASE
		WHEN (quantity * unit_price * (1 - discount_rate)) = 0 THEN 0
		ELSE
			((quantity * unit_price * (1 - discount_rate)) - cost) / (quantity * unit_price * (1 - discount_rate))
	END AS profit_margin
FROM sales; 

--- KPIS ---

-- Revenue total
SELECT
	ROUND(SUM(revenue), 2) AS total_revenue
FROM vw_sales_metrics;

-- Profil total
SELECT
	ROUND(SUM(profit), 2) AS total_profit
FROM vw_sales_metrics;

-- Margen de ganancia
SELECT
	ROUND(
		SUM(profit) / 
		NULLIF(SUM(revenue), 0)
	, 2) AS margen_ganancia
FROM vw_sales_metrics;

-- Precio de compra promedio sin descuento
SELECT
	ROUND(AVG(quantity * unit_price), 2) AS promedio_sin_descuento
FROM vw_sales_metrics;

-- Precio de compra promedio con descuento
SELECT
	ROUND(AVG(revenue), 2) AS promedio_con_descuento
FROM vw_sales_metrics;

-- Volumen de ventas
SELECT
	SUM(quantity) AS volumen_ventas
FROM vw_sales_metrics;

-- Total de clientes
SELECT
	COUNT(DISTINCT customer_id) AS total_clientes
FROM vw_sales_metrics;

-- Ganancia por cliente
SELECT 
	ROUND(SUM(profit) / NULLIF(COUNT(DISTINCT customer_id), 0), 2) AS ganancia_por_cliente
FROM vw_sales_metrics;

--- VIEW KPIS --- 
CREATE VIEW vw_kpis AS
SELECT
	ROUND(SUM(revenue), 2) AS revenue_total,
	ROUND(SUM(profit), 2) AS profit_total,
	ROUND(SUM(profit) / NULLIF(SUM(revenue), 0), 2) AS margen_ganancia,
	ROUND(AVG(quantity * unit_price), 2) AS promedio_sin_descuento,
	ROUND(AVG(revenue), 2) AS promedio_con_descuento,
	SUM(quantity) AS volumen_ventas,
	COUNT(DISTINCT customer_id) AS total_clientes,
	ROUND(SUM(profit) / NULLIF(COUNT(DISTINCT customer_id), 0), 2) AS ganancia_por_cliente
FROM vw_sales_metrics;

--- EDA ---

-- Evolución mensual de ganancia e ingresos
SELECT
	DATE_TRUNC('month', order_date) AS mes,
	ROUND(SUM(revenue), 2) AS revenue,
	ROUND(SUM(profit), 2) AS profit,
FROM vw_sales_metrics
GROUP BY mes
ORDER BY mes;

-- Top de clientes
SELECT
	customer_id,
	ROUND(SUM(revenue), 2) AS revenue,
	ROUND(
		SUM(revenue) * 100.0 / SUM(SUM(revenue)) OVER (), 
	2) AS pct_revenue,
	ROUND(SUM(profit), 2) AS profit,
	ROUND(
		SUM(profit) * 100.0 / SUM(SUM(profit)) OVER(), 
	2) AS pct_profit
FROM vw_sales_metrics
GROUP BY customer_id
ORDER BY profit DESC, revenue DESC
LIMIT 10;

-- Qué regiones generan mayor ganancia?
SELECT
	region,
	ROUND(SUM(revenue), 2) AS revenue,
	ROUND(
		SUM(revenue) * 100.0 / SUM(SUM(revenue)) OVER (), 
	2) AS pct_revenue,
	ROUND(SUM(profit), 2) AS profit,
	ROUND(
		SUM(profit) * 100.0 / SUM(SUM(profit)) OVER(), 
	2) AS pct_profit
FROM vw_sales_metrics
GROUP BY region
ORDER BY profit DESC, revenue DESC;

-- Cómo afectan los descuentos a la ganancia?
SELECT
	CASE
		WHEN COALESCE(discount_rate, 0) = 0 THEN 'Sin descuento'
		ELSE 'Con descuento'
	END AS descuento,
	ROUND(SUM(revenue), 2) AS revenue,
	ROUND(
		SUM(revenue) * 100.0 / SUM(SUM(revenue)) OVER (), 
	2) AS pct_revenue,
	ROUND(SUM(profit), 2) AS profit,
	ROUND(
		SUM(profit) * 100.0 / SUM(SUM(profit)) OVER(), 
	2) AS pct_profit
FROM vw_sales_metrics
GROUP BY descuento
ORDER BY profit DESC, revenue DESC;

-- Qué categorías son más rentables?
SELECT
	product_category,
	ROUND(SUM(revenue), 2) AS revenue,
	ROUND(
		SUM(revenue) * 100.0 / SUM(SUM(revenue)) OVER (), 
	2) AS pct_revenue,
	ROUND(SUM(profit), 2) AS profit,
	ROUND(
		SUM(profit) * 100.0 / SUM(SUM(profit)) OVER(), 
	2) AS pct_profit
FROM vw_sales_metrics
GROUP BY product_category
ORDER BY profit DESC, revenue DESC;

-- Qué método de pago es más usado?
SELECT
	payment_method,
	COUNT(*) AS veces_usado
FROM vw_sales_metrics
GROUP BY payment_method
ORDER BY veces_usado DESC;

-- Qué tipo de cliente contribuye más a la ganancia? Según el tipo de cliente
SELECT * FROM vw_sales_metrics;
SELECT
	customer_segment,
	ROUND(SUM(revenue), 2) AS revenue,
	ROUND(
		SUM(revenue) * 100.0 / SUM(SUM(revenue)) OVER (), 
	2) AS pct_revenue,
	ROUND(SUM(profit), 2) AS profit,
	ROUND(
		SUM(profit) * 100.0 / SUM(SUM(profit)) OVER(), 
	2) AS pct_profit
FROM vw_sales_metrics
GROUP BY customer_segment
ORDER BY profit DESC, revenue DESC;

-- Comparación entre clientes únicos y recurrentes
WITH tipo_cliente AS (
	SELECT
		customer_id,
		COUNT(*) AS cantidad_ordenes,
		CASE 
		WHEN COUNT(*) > 1 THEN 'Cliente recurrente'
			ELSE 'Único'
		END AS tipo_cliente
	FROM vw_sales_metrics
	GROUP BY customer_id
)
SELECT
	tc.tipo_cliente,
	ROUND(SUM(revenue), 2) AS revenue,
	ROUND(
		SUM(revenue) * 100.0 / SUM(SUM(revenue)) OVER (), 
	2) AS pct_revenue,
	ROUND(SUM(profit), 2) AS profit,
	ROUND(
		SUM(profit) * 100.0 / SUM(SUM(profit)) OVER(), 
	2) AS pct_profit,
	ROUND(SUM(v.profit) / NULLIF(SUM(v.revenue),0), 2) AS margen_promedio,
	COUNT(DISTINCT v.customer_id) AS cantidad_clientes
FROM vw_sales_metrics v
JOIN tipo_cliente tc
	ON v.customer_id = tc.customer_id
GROUP BY tc.tipo_cliente
ORDER BY profit DESC, revenue DESC;

-- Las ventas grándes representan mayor ganancia?
WITH tipo_compra AS (
	SELECT
		order_id,
		ROUND(SUM(revenue), 2) AS revenue_total,
		CASE
			WHEN SUM(revenue) >= 1500 THEN 'Compra grande'
			ELSE 'Compra normal'
		END AS tipo_compra
	FROM vw_sales_metrics
	GROUP BY order_id
)
SELECT
	tc.tipo_compra,
	ROUND(SUM(revenue), 2) AS revenue,
	ROUND(
		SUM(revenue) * 100.0 / SUM(SUM(revenue)) OVER (), 
	2) AS pct_revenue,
	ROUND(SUM(profit), 2) AS profit,
	ROUND(
		SUM(profit) * 100.0 / SUM(SUM(profit)) OVER(), 
	2) AS pct_profit,
	ROUND(SUM(profit) / NULLIF(SUM(revenue),0), 2) AS margen_ganancia
FROM vw_sales_metrics v
JOIN tipo_compra tc
	ON tc.order_id = v.order_id
GROUP BY tc.tipo_compra
ORDER BY profit DESC, revenue DESC;
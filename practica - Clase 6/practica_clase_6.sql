--JOINS (Group by, having, Subqueries, subq. correlacionados, outer joins, Temp tables)

-- 1. Mostrar el Código del fabricante, nombre del fabricante, tiempo de entrega y monto Total de productos vendidos, ordenado por nombre de fabricante.
-- En caso que el fabricante no tenga ventas, mostrar el total en NULO.

SELECT 
    m.manu_code,
    manu_name,
    lead_time,
    (quantity * unit_price) AS monto_total_ventas
FROM manufact m LEFT JOIN items i ON (m.manu_code = i.manu_code)  
GROUP BY m.manu_code, manu_name, lead_time
ORDER BY manu_name

-- 2. Mostrar una lista de a pares, de todos los fabricantes que fabriquen el mismo producto.
-- En el caso que haya un único fabricante deberá mostrar el Código de fabricante 2 en nulo.
-- El listado debe tener el siguiente formato:
    --  Nro. de Producto    Descripcion     Cód. de fabric. 1   Cód. de fabric. 2
    --  (stock_num)         (Description)   (manu_code)         (manu_code)

SELECT 
    s1.stock_num AS Nro_de_Producto,
    description AS Descripcion,
    s1.manu_code AS Cod_de_fab_1,
    s2.manu_code AS Cod_de_fab_2
FROM products s1 LEFT JOIN products s2 ON (s1.stock_num = s2.stock_num AND s1.manu_code != s2.manu_code)
                 JOIN product_types pt ON (s1.stock_num = pt.stock_num)
-- para que no salgan duplas repetidas
WHERE s1.manu_code > s2.manu_code OR s2.manu_code IS NULL 
-- el OR es para que tenga en cuenta los casos de 1 solo Fabricante
ORDER BY s1.stock_num

-- 3. Listar todos los clientes que hayan tenido más de una orden.
-- La consulta deberá tener el siguiente formato:
    --  Número_de_Cliente   Nombre      Apellido
    --  (customer_num)      (fname)     (lname)

-- a) En primer lugar, escribir una consulta usando una subconsulta.
SELECT
    customer_num AS Num_Cliente,
    fname AS Nombre,
    lname AS Apellido
FROM customer 
WHERE customer_num IN (SELECT customer_num 
						FROM orders 
						GROUP BY customer_num HAVING COUNT(order_num)>1)                       

-- b) Reescribir la consulta usando dos sentencias SELECT y una tabla temporal.
SELECT customer_num
INTO #customer_Temp
FROM orders
GROUP BY customer_num HAVING COUNT(order_num) > 1

SELECT
    customer_num AS Num_Cliente,
    fname AS Nombre,
    lname AS Apellido
FROM customer c1 JOIN #customer_Temp c2
ON c1.customer_num = c2.customer_num

-- c) Reescribir la consulta utilizando GROUP BY y HAVING.
SELECT
    customer_num AS Num_Cliente,
    fname AS Nombre,
    lname AS Apellido
FROM customer c JOIN orders o ON (c.customer_num = o.customer_num)
GROUP BY c.customer_num, fname, lname
HAVING COUNT(order_num) > 1
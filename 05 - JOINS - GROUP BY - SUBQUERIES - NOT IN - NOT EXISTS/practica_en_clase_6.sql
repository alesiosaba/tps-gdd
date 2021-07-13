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
						GROUP BY customer_num HAVING COUNT(*)>1)                       

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


-- 4. Seleccionar todas las Órdenes de compra cuyo Monto total (Suma de p x q de sus items)
-- sea menor al precio total promedio (avg p x q) de todos los ítems de todas las ordenes.

-- Formato de la salida: Nro. de Orden  Total
--                       (order_num)    (suma)

SELECT 
	o.order_num AS 'Numero de Orden',
	SUM(unit_price * quantity) AS Total
FROM orders o JOIN items i ON (o.order_num = i.order_num)
GROUP BY o.order_num
HAVING SUM(unit_price * quantity) < (SELECT AVG(unit_price * quantity) FROM items)


-- 5. Obtener por cada fabricante, el listado de todos los productos de stock con precio unitario (unit_price) 
-- mayor que el precio unitario promedio para dicho fabricante.
-- Los campos de salida serán: manu_code, manu_name, stock_num, description, unit_price.
    -- Por ejemplo:
-- El precio unitario promedio de los productos fabricados por ANZ es $180.23.
-- se debe incluir en su lista todos los productos de ANZ que tengan un precio unitario superior a dicho importe.

SELECT 
    m.manu_code, 
    manu_name, 
    p.stock_num, 
    description
FROM manufact m
    JOIN products p ON p.manu_code = m.manu_code
    JOIN product_types pt ON p.stock_num = pt.stock_num
WHERE p.unit_price > (SELECT AVG(unit_price) FROM products WHERE manu_code = m.manu_code)


-- 6. Usando el operador NOT EXISTS listar la información de órdenes de compra que NO incluyan ningún producto que
-- contenga en su descripción el string ‘baseball gloves’. Ordenar el resultado por compañía del cliente ascendente
-- y número de orden descendente.
    -- El formato de salida deberá ser:
--  Número de Cliente   Compañía    Número de Orden     Fecha de la Orden
--  (customer_num)      (company)   (order_num)         (order_date)

SELECT 
    c.customer_num 'Numero de Cliente',
    company 'Compañia',
    o.order_num 'Numero de Orden',
    order_date 'Fecha de Orden'
FROM customer c
    JOIN orders o ON (o.customer_num = c.customer_num)
WHERE NOT EXISTS (
        SELECT 1 FROM product_types pt JOIN items i ON (pt.stock_num = i.stock_num) 
            WHERE (description LIKE '%baseball gloves%') AND (i.order_num = o.order_num))
ORDER BY company, o.order_num DESC

-- 7. Obtener el número, nombre y apellido de los clientes que NO hayan comprado productos del fabricante ‘HSK’.

SELECT 
    c.customer_num,
    fname, 
    lname
FROM customer c
WHERE NOT EXISTS (
    SELECT 1 FROM orders o 
        JOIN items i ON o.order_num = i.order_num
    WHERE i.manu_code = 'HSK' AND o.customer_num = c.customer_num
)
ORDER BY c.customer_num

-- con NOT IN 
SELECT 
    c.customer_num,
    fname, 
    lname
FROM customer c
WHERE c.customer_num NOT IN (
    SELECT o.customer_num  FROM orders o 
        JOIN items i ON o.order_num = i.order_num
    WHERE i.manu_code = 'HSK' 
)
ORDER BY c.customer_num

-- 8. Obtener el número, nombre y apellido de los clientes que hayan comprado TODOS los productos del fabricante ‘HSK’.

SELECT 
    c.customer_num,
    c.fname,
    c.lname 
FROM customer C
   WHERE NOT EXISTS (
        SELECT p.stock_num
        FROM products p
        WHERE p.manu_code = 'HSK' AND NOT EXISTS (
                                -- todos los productos que el customer le compro a HSK
                                SELECT 1 
                                FROM orders o 
                                    JOIN items i ON o.order_num = i.order_num
                                WHERE   p.stock_num = i.stock_num 
                                        AND p.manu_code = i.manu_code 
                                        AND o.customer_num = c.customer_num))
                                        
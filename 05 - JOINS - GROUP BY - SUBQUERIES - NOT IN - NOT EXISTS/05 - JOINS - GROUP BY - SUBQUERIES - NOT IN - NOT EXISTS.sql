-- Práctica de JOINS (Group by, having, Subqueries, subq. correlacionados, outer joins, Temp tables)

-- 1. 
-- Mostrar el Código del fabricante, nombre del fabricante, tiempo de entrega y monto Total de productos vendidos, ordenado por nombre de fabricante.
-- En caso que el fabricante no tenga ventas, mostrar el total en NULO.

SELECT 
	i.manu_code AS Codigo_Fabricante,
	manu_name AS Fabricante,
	lead_time AS Tiempo_de_Entrega,
	SUM(quantity * unit_price) AS Monto_Total
FROM manufact m
	 LEFT JOIN items i  ON i.manu_code = m.manu_code
GROUP BY i.manu_code, manu_name, lead_time
ORDER BY manu_name

-- 2. 
-- Mostrar una lista de a pares, de todos los fabricantes que fabriquen el mismo producto.
-- En el caso que haya un único fabricante deberá mostrar el Código de fabricante 2 en nulo.
-- El listado debe tener el siguiente formato:
    --  Nro. de Producto    Descripcion     Cód. de fabric. 1   Cód. de fabric. 2
    --  (stock_num)         (Description)   (manu_code)         (manu_code)

-- No evita los pares repetidos, devuelve (A,B) y (B,A)

SELECT 
	p1.stock_num AS Nro_de_Producto,
	pt.description AS Producto,
	p1.manu_code AS Fabricante_1,
	p2.manu_code AS Fabricante_2
FROM products p1 
	JOIN product_types pt ON p1.stock_num = pt.stock_num
	LEFT JOIN products p2 ON (p1.stock_num = p2.stock_num AND p1.manu_code != p2.manu_code)
ORDER BY p1.stock_num

-- Evitando los pares repetidos

SELECT 
	p1.stock_num,
	pt.description,
	p1.manu_code, 
	p2.manu_code 
FROM products p1 
	JOIN product_Types pt ON p1.stock_num = pt.stock_num
	LEFT JOIN products p2 ON (p1.stock_num = p2.stock_num AND p1.manu_code != p2.manu_code)
-- De esta manera evitamos los pares repetidos
WHERE p1.manu_code < p2.manu_code OR p2.manu_code is NULL 
ORDER BY p1.stock_num


-- 3. 
-- Listar todos los clientes que hayan tenido más de una orden.
-- La consulta deberá tener el siguiente formato:

    --  Número_de_Cliente   Nombre      Apellido
    --  (customer_num)      (fname)     (lname)

-- a) En primer lugar, escribir una consulta usando una subconsulta.

SELECT 
	customer_num AS Numero_de_Cliente,
	fname AS Nombre,
	lname AS Apellido
FROM customer c
WHERE (SELECT COUNT(order_num) FROM orders o WHERE c.customer_num = o.customer_num) > 1

-- Otra resolución usando IN

SELECT 
	customer_num AS Numero_de_Cliente,
	fname AS Nombre,
	lname AS Apellido
FROM customer 
WHERE customer_num IN (SELECT customer_num FROM orders GROUP BY customer_num HAVING COUNT(order_num) > 1)

-- Otra resolución usando EXISTS

SELECT 
	customer_num AS Numero_de_Cliente,
	fname AS Nombre,
	lname AS Apellido
FROM customer c 
WHERE EXISTS(SELECT customer_num 
			 FROM orders o 
			 WHERE o.customer_num = c.customer_num 
			 GROUP BY customer_num HAVING COUNT(order_num) > 1)

-- b) Reescribir la consulta usando dos sentencias SELECT y una tabla temporal.

SELECT customer_num INTO #clientesConMasDeUnaOrden 
FROM orders GROUP BY customer_num HAVING COUNT(order_num) > 1 

SELECT c.customer_num, fname, lname 
FROM customer c 
	JOIN #clientesConMasDeUnaOrden c2 ON c.customer_num = c2.customer_num

-- c) Reescribir la consulta utilizando GROUP BY y HAVING.

SELECT 
	o.customer_num AS Numero_de_Cliente,
	fname AS Nombre,
	lname AS Apellido
FROM orders o
	JOIN customer c ON c.customer_num = o.customer_num
GROUP BY o.customer_num, fname, lname
HAVING COUNT(*) > 1

-- 4. 
-- Seleccionar todas las Órdenes de compra cuyo Monto total (Suma de p x q de sus items)
-- sea menor al precio total promedio (avg p x q) de todos los ítems de todas las ordenes.
-- Ojo con esto porque no es el promedio del monto de las ordenes, es el promedio de todos los items de todas las ordenes.

-- Formato de la salida: 

	-- Nro. de Orden  Total
	-- (order_num)    (suma)

SELECT
	order_num AS Nro_de_Orden,
	SUM(unit_price * quantity) AS Total
FROM items
GROUP BY order_num
HAVING SUM(unit_price * quantity) < 
		-- Esta subquery es precio total promedio (avg p x q) de todas las líneas de las ordenes
		(SELECT AVG(unit_price * quantity) FROM items)

-- 5. 
-- Obtener por cada fabricante, el listado de todos los productos de stock con precio unitario (unit_price) 
-- mayor que el precio unitario promedio para dicho fabricante.

-- Los campos de salida serán: manu_code, manu_name, stock_num, description, unit_price.

-- Por ejemplo:
-- El precio unitario promedio de los productos fabricados por ANZ es $180.23.
-- se debe incluir en su lista todos los productos de ANZ que tengan un precio unitario superior a dicho importe.

SELECT 
	m.manu_code AS Cod_Fabricante,
	manu_name AS Fabricante,
	p.stock_num AS Cod_Producto,
	description AS Producto,
	unit_price AS Precio_Unidad,
	(SELECT AVG(unit_price) FROM products p1 WHERE p1.manu_code = m.manu_code) AS Precio_Prom_Fab
FROM manufact m
	JOIN products p ON p.manu_code = m.manu_code
	JOIN product_types pt ON pt.stock_num = p.stock_num
-- comparo el precio unitario del producto con el precio promedio por unidad de los productos del fabricante 
WHERE unit_price > (SELECT AVG(unit_price) FROM products p1 WHERE p1.manu_code = m.manu_code)
ORDER BY m.manu_code


-- 6. 
-- Usando el operador NOT EXISTS listar la información de órdenes de compra que NO incluyan ningún producto que
-- contenga en su descripción el string ‘baseball gloves’. Ordenar el resultado por compañía del cliente ascendente
-- y número de orden descendente.
   
-- El formato de salida deberá ser:
--  Número de Cliente   Compañía    Número de Orden     Fecha de la Orden
--  (customer_num)      (company)   (order_num)         (order_date)

SELECT 
	o.customer_num AS Nro_Cliente,
	c.company AS Compañia,
	o.order_num AS Nro_Order,
	o.order_date AS Fecha_Orden 
FROM orders o 
	JOIN customer c ON c.customer_num = o.customer_num
WHERE NOT EXISTS (
	SELECT i2.item_num
	FROM items i2 
		JOIN product_types pt ON pt.stock_num = i2.stock_num
	WHERE i2.order_num = o.order_num AND pt.description LIKE '%baseball gloves%'
	)
ORDER BY c.company ASC, o.order_num DESC

-- 7. 
-- Obtener el número, nombre y apellido de los clientes que NO hayan comprado productos del fabricante ‘HSK’.

-- sin NOT IN

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

-- 8. 
-- Obtener el número, nombre y apellido de los clientes que hayan comprado TODOS los productos del fabricante ‘HSK’.

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

/*

Operador UNION
9. Reescribir la siguiente consulta utilizando el operador UNION:
SELECT * FROM products
WHERE manu_code = ‘HRO’ OR stock_num = 1
10. Desarrollar una consulta que devuelva las ciudades y compañías de todos los Clientes ordenadas alfabéticamente por Ciudad pero en la consulta deberán aparecer primero las compañías situadas en Redwood City y luego las demás.
Formato:
Clave de ordenamiento
Ciudad
Compañía
(sortkey)
(city)
(company)
11. Desarrollar una consulta que devuelva los dos tipos de productos más vendidos y los dos menos vendidos en función de las unidades totales vendidas.
Formato
Tipo Producto
Cantidad
101
999
189
888
24
…
4
1
VISTAS
12. Crear una Vista llamada ClientesConMultiplesOrdenes basada en la consulta realizada en el punto 3.b con los nombres de atributos solicitados en dicho punto.
13. Crear una Vista llamada Productos_HRO en base a la consulta
SELECT * FROM products
WHERE manu_code = “HRO”
La vista deberá restringir la posibilidad de insertar datos que no cumplan con su criterio de selección.
a. Realizar un INSERT de un Producto con manu_code=’ANZ’ y stock_num=303. Qué sucede?
b. Realizar un INSERT con manu_code=’HRO’ y stock_num=303. Qué sucede?
c. Validar los datos insertados a través de la vista.
TRANSACCIONES
14. Escriba una transacción que incluya las siguientes acciones:
• BEGIN TRANSACTION
o Insertar un nuevo cliente llamado “Fred Flintstone” en la tabla de clientes (customer).
o Seleccionar todos los clientes llamados Fred de la tabla de clientes (customer).
• ROLLBACK TRANSACTION
Luego volver a ejecutar la consulta
• Seleccionar todos los clientes llamados Fred de la tabla de clientes (customer).
• Completado el ejercicio descripto arriba. Observar que los resultados del segundo SELECT difieren con respecto al primero.
15. Se ha decidido crear un nuevo fabricante AZZ, quién proveerá parte de los mismos productos que provee el fabricante ANZ, los productos serán los que contengan el string ‘tennis’ en su descripción.
• Agregar las nuevas filas en la tabla manufact y la tabla products.
• El código del nuevo fabricante será “AZZ”, el nombre de la compañía “AZZIO SA” y el tiempo de envío será de 5 días (lead_time).
• La información del nuevo fabricante “AZZ” de la tabla Products será la misma que la del fabricante “ANZ” pero sólo para los productos que contengan 'tennis' en su descripción.
• Tener en cuenta las restricciones de integridad referencial existentes, manejar todo dentro de una misma transacción.
*/
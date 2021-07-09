-- Práctica - Clase 3 Instrucción SELECT para una sola tabla
USE stores7new;

-- 1. 
-- Obtener un listado de todos los clientes y sus direcciones.

SELECT 
	customer_num,
	fname,
	lname,
	address1,
	address2,
	city,
	state,
	zipcode 
FROM customer 

-- 2. 
-- Obtener el listado anterior pero sólo los clientes que viven en el estado de California “CA”.

SELECT 
	customer_num,
	fname,
	lname,
	address1,
	address2,
	city,
	state,
	zipcode 
FROM customer
WHERE state = 'CA'

-- 3. 
-- Listar todas las ciudades (city) de la tabla clientes que pertenecen al estado de “CA”, mostrar sólo una vez cada ciudad.

SELECT 
	DISTINCT city -- mostrar sólo una vez cada ciudad distinta
FROM customer
WHERE state = 'CA'

-- 4. 
-- Ordenar la lista anterior alfabéticamente.

SELECT 
	DISTINCT city 
FROM customer
WHERE state = 'CA'
ORDER BY city -- ordena alfabéticamente por defecto (ORDER BY ASC)

-- 5. 
-- Mostrar la dirección sólo del cliente 103. (customer_num)

SELECT 
	customer_num,
	fname,
	lname,
	address1,
	address2,
	city,
	state,
	zipcode 
FROM customer
WHERE customer_num = 103

-- 6. 
-- Mostrar la lista de productos que fabrica el fabricante “ANZ” ordenada por el campo Código de Unidad de Medida (unit_code)

SELECT 
	unit_code,
	manu_code,
	unit_price,
	stock_num
FROM products
WHERE manu_code = 'ANZ'
ORDER BY unit_code -- ordena de menor a mayor por defecto

-- 7.
-- Listar los códigos de fabricantes que tengan alguna orden de pedido ingresada, ordenados
-- alfabéticamente y no repetidos.

-- uso la tabla items porque están todos los productos que componen ordenes de pedidos ingresados
-- y cada item tiene el codigo de fabricante del producto

SELECT 
	DISTINCT manu_code	-- DISTINCT para evitar repetidos
FROM items
ORDER BY manu_code		-- ordenar alfabeticamente

-- 8. 
-- Escribir una sentencia SELECT que devuelva el número de orden, fecha de orden, número de cliente y
-- fecha de embarque de todas las órdenes que no han sido pagadas (paid_date es nulo), pero fueron
-- embarcadas (ship_date) durante los primeros seis meses de 2015.

SELECT 
	order_num,
	order_date,
	customer_num,
	ship_date
FROM orders
WHERE paid_date IS NULL -- órdenes que no han sido pagadas (paid_date es nulo)
	  AND 
	  -- órdenes embarcadas (ship_date) durante los primeros seis meses de 2015
	  YEAR(ship_date) = 2015 AND MONTH(ship_date) BETWEEN 1 AND 6
	
-- 9.
-- Obtener de la tabla cliente (customer) los número de clientes y nombres de las compañías, cuyos
-- nombres de compañías contengan la palabra “town”.

SELECT 
	customer_num,
	-- nombres de compañías contengan la palabra “town”
	company	
FROM customer
WHERE company LIKE '%town%'

-- 10. 
-- Obtener el precio máximo, mínimo y precio promedio pagado (ship_charge) por todos los embarques.
-- Se pide obtener la información de la tabla ordenes (orders).

SELECT
	MIN(ship_charge) AS precio_minimo,
	MAX(ship_charge) AS precio_maximo,
	AVG(ship_charge) AS precio_promedio
FROM orders

-- 11.
-- Realizar una consulta que muestre el número de orden, fecha de orden y fecha de embarque de todas
-- las órdenes que fueron embarcadas (ship_date) en el mismo mes que fue dada de alta la orden (order_date).

SELECT 
	order_num,
	order_date AS fecha_de_alta,
	ship_date AS fecha_de_embarque
FROM orders
WHERE 
	-- órdenes que fueron embarcadas (ship_date) en el mismo mes que fue dada de alta la orden (order_date)
	YEAR(ship_date) = YEAR(order_date)
	AND MONTH(ship_date) = MONTH(order_date)

-- 12. 
-- Obtener la Cantidad de embarques y Costo total (ship_charge) del embarque por número de cliente y
-- por fecha de embarque. Ordenar los resultados por el total de costo en orden inverso

SELECT 
	customer_num,
	ship_date,
	COUNT(*) AS Cantidad_de_Embarques,
	SUM(ship_charge) AS Costo_Total
FROM orders
GROUP BY customer_num, ship_date  -- agrupar por número de cliente y por fecha de embarque
ORDER BY Costo_Total DESC		  -- ordenar los resultados por el total de costo en orden inverso

-- 13.
-- Mostrar fecha de embarque (ship_date) y cantidad total de libras (ship_weight) por día, de aquellos
-- días cuyo peso de los embarques superen las 30 libras. Ordenar el resultado por el total de libras en
-- orden descendente.

SELECT
	ship_date,
	SUM(ship_weight) AS Cantidad_Total_de_Libras
FROM orders 
GROUP BY ship_date
    HAVING SUM(ship_weight) > 30 -- días cuyo peso total de embarques superen las 30 libras
ORDER BY Cantidad_Total_de_Libras DESC
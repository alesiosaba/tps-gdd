
-- Práctica - Clase 4
USE stores7new;

-- Más ejercicios de instrucción SELECT para una sola tabla
 
-- 14.
-- Crear una consulta que liste todos los clientes que vivan en California ordenados por compañía. 

SELECT * 
FROM customer
WHERE state = 'CA'
ORDER BY company

-- 15.
-- Obtener un listado de la cantidad de productos únicos comprados a cada fabricante, en donde el total comprado a cada fabricante sea mayor a 1500. 
-- El listado deberá estar ordenado por cantidad de productos comprados de mayor a menor. 

SELECT 
	manu_code AS Fabricante,
	COUNT(DISTINCT stock_num) Productos_Unicos,
	SUM(quantity * unit_price) Total_Comprado_Al_Fabricante -- total de dinero, no de cantidad
FROM items
GROUP BY manu_code
	HAVING SUM(quantity * unit_price) > 1500
ORDER BY Productos_Unicos DESC

-- 16.
-- Obtener un listado con el código de fabricante, nro de producto, la cantidad vendida (quantity), y el total vendido (quantity x unit_price),
-- para los fabricantes cuyo código tiene una “R” como segunda letra. Ordenar el listado por código de fabricante y nro de producto. 

SELECT 
	manu_code AS Cod_Fabricante,
	stock_num AS Nro_Producto,
	SUM(quantity) AS Cantidad_Vendida,
	SUM(quantity * unit_price) AS Total_Vendido
FROM items
WHERE manu_code LIKE '_[rR]%'	-- fabricantes cuyo código tiene una “r” o una “R” como segunda letra
GROUP BY manu_code, stock_num
ORDER BY manu_code, stock_num

-- 17.
-- Crear una tabla temporal OrdenesTemp que contenga las siguientes columnas: 
-- cantidad de órdenes por cada cliente, primera y última fecha de orden de compra (order_date) del cliente.

-- Opcion 1 creando la tabla temporal explicitamente

CREATE TABLE #OrdenesTemp (
	customer_num INTEGER,
	Cantidad_de_Ordenes INTEGER,
	Primer_Fecha_OC DATETIME,
	Ultima_Fecha_OC DATETIME
)

INSERT INTO #OrdenesTemp
SELECT 
	customer_num,
	COUNT(order_num),
	MIN(order_date),
	MAX(order_date)
FROM orders
GROUP BY customer_num

-- Opcion 2 creando la tabla temporal implicitamente en el INSERT INTO
-- Es obligatorio aclarar los ALIAS de las columnas calculadas

DROP TABLE #OrdenesTemp

SELECT 
	customer_num,
	COUNT(order_num) AS Cantidad_de_Ordenes,
	MIN(order_date) AS Primer_Fecha_OC,
	MAX(order_date) AS Ultima_Fecha_OC
INTO #OrdenesTemp
FROM orders
GROUP BY customer_num 

-- Realizar una consulta de la tabla temp OrdenesTemp en donde la primer fecha de compra sea anterior a '2015-05-23 00:00:00.000',
-- ordenada por fechaUltimaCompra en forma descendente. 

SELECT * FROM #OrdenesTemp 
WHERE 
	YEAR(Primer_Fecha_OC) <= 2015 
	AND MONTH(Primer_Fecha_OC) <= 05 
	AND DAY(Primer_Fecha_OC) < 23 
ORDER BY Ultima_Fecha_OC DESC

-- 18.
-- Consultar la tabla temporal del punto anterior y obtener la cantidad de clientes con igual cantidad de compras.
-- Ordenar el listado por cantidad de compras en orden descendente 

SELECT
	COUNT(customer_num) Cuantos_Clientes_Misma_Cant,
	Cantidad_de_Ordenes
FROM #OrdenesTemp 
GROUP BY Cantidad_de_Ordenes
ORDER BY Cantidad_de_Ordenes DESC

-- 19.
-- Desconectarse de la sesión. Volver a conectarse y ejecutar SELECT * from #ordenesTemp. Que sucede? 

	SELECT * from #OrdenesTemp
	-- Las tablas temporales se eliminan al desconectarse de la sesión

-- 20.
-- Se desea obtener la cantidad de clientes por cada state y city, donde los clientes contengan el string ‘ts’
-- en el nombre de compañía, el código postal este entre 93000 y 94100 y la ciudad no sea 'Mountain View'. Se desea el listado ordenado por ciudad 

SELECT 
	state,
	city,
	COUNT(customer_num) AS Cantidad_Clientes
FROM customer
WHERE 
	company LIKE '%ts%'
	AND zipcode BETWEEN 93000 AND 94100
	AND city <> 'Mountain View'
GROUP BY state, city
ORDER BY city

-- 21.
-- Para cada estado, obtener la cantidad de clientes referidos. ""Mostrar"" sólo los clientes que hayan sido referidos cuya compañía
-- empiece con una letra que este en el rango de ‘A’ a ‘L’. 

SELECT	
	state,
	COUNT(customer_num) Cant_Clientes_Referidos
FROM customer
WHERE 
	company LIKE '[A-L]%'
	AND customer_num_referedBy IS NOT NULL
GROUP BY state

-- 22.
-- Se desea obtener el promedio de lead_time por cada estado, donde los Fabricantes tengan una ‘e’ en manu_name y el lead_time sea entre 5 y 20. 

SELECT
	state,
	AVG(lead_time)
FROM manufact
WHERE 
	manu_name LIKE '%e%'
	AND lead_time BETWEEN 5 AND 20
GROUP BY state

-- 23.
-- Se tiene la tabla units, de la cual se quiere saber la cantidad de unidades que hay por cada tipo (unit) que no tengan en nulo el unit_descr,
-- y además se deben ""mostrar"" solamente los que cumplan que la cantidad mostrada se superior a 5.
-- Al resultado final se le debe sumar 1.

SELECT 
	unit,
	COUNT(unit_code) + 1 AS Cantidad_de_Unidades
FROM units
WHERE unit_descr IS NOT NULL
GROUP BY unit
	HAVING COUNT(unit_code) > 5

------------------------------------------------------------------------------------------------------------------------
-- Práctica de INSERT, UPDATE y DELETE.
------------------------------------------------------------------------------------------------------------------------

USE stores7new;

-- 1.
-- Crear una tabla temporal #clientes a partir de la siguiente consulta:	SELECT * FROM customer

SELECT * INTO #clientes FROM customer

SELECT * FROM #clientes

-- 2.
-- Insertar el siguiente cliente en la tabla #clientes
 
    -- Customer_num 144
    -- Fname Agustín
    -- Lname Creevy
    -- Company Jaguares SA
    -- State CA
    -- City Los Angeles

INSERT INTO #clientes (customer_num, fname, lname, company, state, city)
VALUES (144, 'Agustín', 'Creevy', 'Jaguares SA', 'CA', 'Los Angeles')

-- 3. 
-- Crear una tabla temporal #clientesCalifornia con la misma estructura de la tabla customer.
-- Realizar un insert masivo en la tabla #clientesCalifornia con todos los clientes de la tabla customer cuyo state sea CA.
	
SELECT * INTO #clientesCalifornia
FROM customer
WHERE state = 'CA'

-- También se puede hacer asi pero hay que crear la tabla antes

CREATE TABLE #clientesCalifornia(
    customer_num SMALLINT NOT NULL PRIMARY KEY,
    fname VARCHAR(15),
    lname VARCHAR(15),
    company VARCHAR(20),
    address1 VARCHAR(20),
    address2 VARCHAR(20),
    city VARCHAR(15),
    state CHAR(2),
    zipcode CHAR(5),
    phone VARCHAR(18),
    status CHAR(1)
)

INSERT INTO #clientesCalifornia 
SELECT * FROM customer WHERE state = 'CA'

-- 4. 
-- Insertar el siguiente cliente en la tabla #clientes un cliente que tenga los mismos datos del cliente 103,
-- pero cambiando en customer_num por 155

INSERT INTO #clientes (customer_num, fname, lname, company, address1, address2, city, state, zipcode, phone)
SELECT 155, fname, lname, company, address1, address2, city, state, zipcode, phone
FROM customer
WHERE customer_num = 103

-- Valide lo insertado. (Hago un SELECT para comparar los datos)

SELECT * FROM #clientes 
WHERE customer_num = 103 OR customer_num = 155

-- 5. 
-- Borrar de la tabla #clientes los clientes cuyo campo zipcode esté entre 94000 y 94050 y la ciudad comience con ‘M’.

	-- Validar los registros a borrar antes de ejecutar la acción.

SELECT * FROM #clientes 
WHERE zipcode BETWEEN 94000 AND 94050
        AND city LIKE '[M]%'

DELETE FROM #clientes
WHERE zipcode BETWEEN 94000 AND 94050
        AND city LIKE '[M]%'

-- 6. 
-- Borrar de la tabla #clientes todos los clientes que no posean órdenes de compra en la tabla orders. (Utilizar un subquery).

SELECT customer_num FROM #clientes
WHERE customer_num NOT IN (SELECT DISTINCT customer_num FROM orders)

DELETE FROM #clientes
WHERE customer_num NOT IN (SELECT DISTINCT customer_num FROM orders)

-- 7. 
-- Modificar los registros de la tabla #clientes cambiando el campo state por ‘AK’ y el campo address2 por ‘Barrio Las Heras’
-- para los clientes que vivan en el state 'CO'.

-- Validar previamente la cantidad de registros a modificar.
SELECT COUNT(*) FROM #clientes WHERE state = 'CO'

UPDATE #clientes
SET
	state = 'AK',
	address2 = 'Barrio Las Heras'
WHERE state = 'CO'

-- 8. 
-- Modificar todos los clientes de la tabla #clientes, agregando un dígito 1 delante de cada número telefónico, debido a un cambio de la compañía de teléfonos.

UPDATE #clientes
SET phone = '1' + phone

SELECT * FROM #clientes

-- 9. 
-- Comenzar una transacción, dentro de ella realizar:

BEGIN TRANSACTION

-- a. 
-- Insertar un registro en la tabla #clientes con los siguientes 4 datos

-- customer_num -> 166
-- lname 'apellido'
-- state 'CA'
-- company 'nombre empresa'

    INSERT INTO #clientes (customer_num, lname, state, company)
    VALUES (166, 'apellido', 'CA', 'nombre empresa')

-- b. 
-- Borrar los registros de la tabla #clientesCalifornia

    DELETE FROM #clientesCalifornia

-- Consultar los datos de las tablas #clientes y #clientesCalifornia, y asegurarse de que se haya realizado las operaciones.

    SELECT * FROM #clientes
    SELECT * FROM #clientesCalifornia

-- Realizar un ROLLBACK y volver a chequear la información, que pasó??

ROLLBACK TRANSACTION

    SELECT * FROM #clientes
    SELECT * FROM #clientesCalifornia

-- 10.
-- Ejecutar la misma transacción del punto 9.

BEGIN TRANSACTION
	
	-- Observamos los datos antes de las modificaciones

	SELECT * FROM #clientes
	SELECT * FROM #clientesCalifornia
    
    INSERT INTO #clientes (customer_num, lname, state, company)
    VALUES (166, 'apellido', 'CA', 'nombre empresa')

    DELETE FROM #clientesCalifornia

-- Realizar un COMMIT y volver a chequear la información, que pasó??
COMMIT TRANSACTION

SELECT * FROM #clientes
SELECT * FROM #clientesCalifornia
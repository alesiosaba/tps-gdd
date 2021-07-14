/* 
EJERCICIO 3
Seleccionar código de fabricante, nombre fabricante, cantidad de órdenes del fabricante,
Monto Total Vendido del fabricante sum(quantity * total_price) 
y el promedio de las Montos vendidos de todos los Fabricantes. 

SOLAMENTE MOSTRAR aquellos fabricantes cuyos Montos de ventas totales sean mayores al PROMEDIO de las ventas de TODOS los fabricantes.

Mostrar el resultado ordenado por cantidad total vendida en forma descendente.

IMPORTANTE: No se pueden usar procedures, ni Funciones de usuario.

manu_code   manu_name   CantOrdenes Total vendido 	Promedio de Todos
ANZ         Anza        11          11081.80        3972.85
SHM         Shimara     4           5677.91         3972.85

*/

SELECT 
	m.manu_code,
	m.manu_name,
	COUNT(DISTINCT i.order_num) AS CantOrdenes,
	SUM(i.quantity * i.unit_price) AS 'Total vendido',
	(SELECT 
		SUM(i2.quantity * i2.unit_price) / COUNT(DISTINCT i2.manu_code)
	FROM items i2) AS 'Promedio de Todos'
FROM manufact m
	LEFT JOIN items i ON (i.manu_code = m.manu_code)
GROUP BY m.manu_code, m.manu_name
HAVING 
	sum(i.quantity * i.unit_price) 
	>
	(SELECT SUM(i2.quantity * i2.unit_price) / COUNT(DISTINCT i2.manu_code)
	FROM items i2)
ORDER BY SUM(i.quantity * i.unit_price) DESC


/* 
EJERCICIO 4 - STORED PROCEDURE

Crear un procedimiento que reciba como parámetro una FECHA.
Este deberá guardar en la tabla VENTASxMES el Monto total y cantidad total de productos vendidos para el Año 
y mes (yyyymm) de la fecha ingresada con la siguiente particularidad.

Asuma que existen 3 tipos de unidades de productos y las cantidades deberán ser "ajustadas" según su tipo:
   1 unid (queda igual)
   2 par (multiplicar por 2)
   3 doc (multiplicar por 12)

Tabla VENTASxMES
    anioMes     decimal(6)
    stock_num   smallint
    manu_code   char(3)
    Cantidad    int
    Monto       decimal(10,2)

El procedimiento debe manejar TODO el proceso en una transacción y deshacer todo en caso de error.
*/

GO
CREATE TABLE VENTASxMES(
	anioMes decimal(6),
	stock_num smallint,
	manu_code char(3),
	Cantidad int,
	Monto decimal(10,2)
)
GO

GO
CREATE PROCEDURE llenadoVentasPorMes @fechaEjecucion DATETIME
AS
BEGIN
	-- declaración de variables
	DECLARE @unit char(4), @stock_num smallint, @manu_code char(3), @cantidad int, @montoTotal decimal(10,2),@cantidadResultante int;
	
	-- declaración de cursor
	DECLARE ventaCursor
	CURSOR FOR
	SELECT u.unit, p.stock_num, p.manu_code, sum(i.quantity) cantidad, sum (i.quantity * i.unit_price) montoTotal
	FROM orders o
		left join items i ON (o.order_num = i.order_num)
		left join products p ON (i.stock_num = p.stock_num AND i.manu_code= p.manu_code)
		left join units u ON (u.unit_code = i.unit_price)
	WHERE YEAR(o.order_date) = YEAR(@fechaEjecucion) AND
		MONTH(o.order_date) = MONTH(@fechaEjecucion)
	GROUP BY u.unit, p.stock_num, p.manu_code
	
	-- apertura de cursor
	OPEN ventaCursor
	
	FETCH NEXT FROM ventaCursor 
		INTO @unit, @stock_num, @manu_code , @cantidad , @montoTotal;
	
	BEGIN TRY
	BEGIN TRANSACTION
	WHILE @@FETCH_STATUS = 0
	BEGIN
	IF @unit NOT IN ('unid', 'par', 'doc')
	BEGIN	
		THROW 50000, 'Unidad errónea', 2
		SET @cantidadResultante = CASE @unit
		WHEN 'unid' THEN @cantidad
		WHEN 'par' THEN @cantidad * 2
		WHEN 'doc' THEN @cantidad * 12
	END
		INSERT INTO VENTASxMES
			(anioMes, stock_num, manu_code, Cantidad, Monto)
		VALUES(YEAR(@fechaEjecucion)*100 + MONTH(@fechaEjecucion),@stock_num, @manu_code, @cantidadResultante, @montoTotal)
		
	END
	
	COMMIT TRANSACTION
	
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
	END CATCH
	
	FETCH NEXT FROM ventaCursor
		INTO @unit, @stock_num, @manu_code , @cantidad , @montoTotal
	-- cierre de cursor
	CLOSE ventaCursor
	DEALLOCATE ventaCursor
END
GO


/*
EJERCICIO 5
Dada la vista:
	Create view ProductosV 
	 AS SELECT p.stock_num, pt.description, p.manu_code, p.unit_price, 
			   p.unit_code, u.unit_descr
	FROM products p JOIN product_types pt ON p.stock_num = pt.stock_num
					JOIN units u ON p.unit_code = u.unit_code;

	Realizar un trigger que realice los INSERTS en esta vista.
	
	En caso que ya exista el Producto, informar el mensaje "Clave duplicada".
	Si no existe el fabricante o el tipo de producto informar el error.
	Si no existe la unidad insertarla en la tabla correspondiente.
	
	Tener en cuenta que los 
		- INSERTs pueden ser masivos 
		- sólo se debe deshacer la operación del registro erróneo.
*/

GO
CREATE TRIGGER insertsProductosV ON ProductosV
INSTEAD OF INSERT
AS
BEGIN
	-- Declarado de variables
	DECLARE @stock_num smallint ,@description varchar(15), @manu_code char(3), @unit_price decimal, @unit_code smallint,@unit_descr varchar(15);
	
	-- Creación de cursor
	DECLARE insertedCursor
	CURSOR FOR
	SELECT stock_num, description, manu_code, unit_price, unit_code, unit_descr
	FROM inserted
	
	-- Apertura de cursor
	OPEN insertedCursor
	FETCH NEXT FROM insertedCursor 
		INTO @stock_num, @description, @manu_code, @unit_price, @unit_code, @unit_descr;
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
	BEGIN TRY
	BEGIN TRANSACTION
		IF EXISTS(SELECT * from products where stock_num = @stock_num AND manu_code = @manu_code)
			THROW 50000, 'Clave duplicada', 2
		
		IF @manu_code NOT IN (SELECT manu_code FROM manufact)
			THROW 51000, 'Fabricante no existente', 2
		
		IF @stock_num NOT IN (SELECT stock_num FROM product_types)
			THROW 51000, 'Tipo de Producto no existente', 2
		
		IF @unit_code NOT IN (SELECT unit_code FROM units)
			INSERT INTO units (unit_descr)
			VALUES (@unit_descr)
			
			INSERT INTO products (stock_num,manu_code,unit_price,unit_code)
			VALUES (@stock_num, @manu_code, @unit_price, @unit_code)

	COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
	END CATCH
	
	FETCH NEXT FROM insertedCursor 
		INTO @stock_num, @description, @manu_code, @unit_price, @unit_code, @unit_descr;
	
	END
	
	-- Cierre de cursor
	CLOSE insertedCursor
	DEALLOCATE insertedCursor
END
GO
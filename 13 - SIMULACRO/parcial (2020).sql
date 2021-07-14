/* 
EJERCICIO 3
Seleccionar código de fabricante, nombre fabricante, cantidad de órdenes del fabricante,
Monto Total Vendido del fabricante sum(quantity * total_price) 
y el promedio de los Montos vendidos de todos los Fabricantes. 

SOLAMENTE MOSTRAR aquellos fabricantes cuyos Montos de ventas totales sean mayores
al PROMEDIO de las ventas de TODOS los fabricantes.

Mostrar el resultado ordenado por cantidad total vendida en forma descendente.

IMPORTANTE: No se pueden usar procedures, ni Funciones de usuario.

manu_code	manu_name		CantOrdenes		Total vendido	Promedio de Todos 
  ANZ         Anza              11             11081.80         3972.85 
  SHM		 Shimara			4			   5677.91			3972.85

*/

SELECT 
	m.manu_code, 
	manu_name, 
	COUNT(DISTINCT i.order_num) AS CantOrdenes,
	SUM(i.quantity * i.unit_price) AS Total_Vendido,
	(SELECT SUM(quantity * unit_price) / COUNT(DISTINCT manu_code) FROM items) AS Promedio_De_Todos
FROM manufact m
	JOIN items i ON i.manu_code = m.manu_code
GROUP BY m.manu_code, manu_name
HAVING 
	SUM(i.quantity * i.unit_price) 
	> 
	(SELECT SUM(quantity * unit_price) / COUNT(DISTINCT i2.manu_code) FROM items i2)
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

CREATE TABLE VENTASxMES(
	anioMes DECIMAL(6),
	stock_num SMALLINT,
	manu_code CHAR(3),
	Cantidad INT,
	Monto DECIMAL(10,2)
)

GO
CREATE PROCEDURE ActualizarVentasxMes @fechaParam DATETIME
AS 
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION

		INSERT INTO VENTASxMES
		SELECT 
			YEAR(@fechaParam) * 100 + MONTH(@fechaParam), 
			i.stock_num,
			m.manu_code,
			SUM(i.quantity * (SELECT 'cant productos' = CASE WHEN u.unit = 'unid' THEN 1 WHEN u.unit = 'par' THEN 2 ELSE 12 END)),
			SUM(i.quantity * p.unit_price)
		FROM manufact m
			JOIN items i ON i.manu_code = m.manu_code
			JOIN orders o ON o.order_num = i.order_num
			JOIN products p ON p.stock_num = i.stock_num AND p.manu_code = i.manu_code
			JOIN units u ON u.unit_code = p.unit_code
		WHERE YEAR(o.order_date) = YEAR(@fechaParam) 
			  AND MONTH(o.order_date) = MONTH(@fechaParam)
		GROUP BY i.stock_num, m.manu_code

		COMMIT TRANSACTION
	END TRY

	BEGIN CATCH
		ROLLBACK TRANSACTION
	END CATCH
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
CREATE VIEW ProductosV 
AS 
SELECT 
	p.stock_num, 
	pt.description, 
	p.manu_code, 
	p.unit_price, 
	p.unit_code, 
	u.unit_descr 
FROM products p 
	JOIN product_types pt ON p.stock_num = pt.stock_num 
	JOIN units u ON p.unit_code = u.unit_code
GO

SELECT * FROM ProductosV

GO
CREATE TRIGGER inserts_ProductosV ON ProductosV
INSTEAD OF INSERT AS
BEGIN
	
	DECLARE 
		@stock_num SMALLINT, 
		@description VARCHAR(15), 
		@manu_code CHAR(3), 
		@unit_price DECIMAL, 
		@unit_code SMALLINT, 
		@unit_descr VARCHAR(15)

	DECLARE cursor_insert_ProdV CURSOR FOR
	SELECT 
		stock_num, 
		description, 
		manu_code, 
		unit_price, 
		unit_code, 
		unit_descr
	FROM inserted

	OPEN cursor_insert_ProdV

	FETCH NEXT FROM cursor_insert_ProdV
	INTO @stock_num, @description, @manu_code, @unit_price,	@unit_code,	@unit_descr

	WHILE @@FETCH_STATUS = 0
	BEGIN
		
		BEGIN TRY
			BEGIN TRANSACTION
				-- En caso que ya exista el Producto, informar el mensaje �Clave duplicada�.
				IF EXISTS(SELECT 1 FROM products WHERE stock_num = @stock_num AND manu_code = @manu_code)
					THROW 50000, 'Clave duplicada', 1
					
				-- Si no existe el fabricante o el tipo de producto informar el error. 
				IF NOT EXISTS(SELECT 1 FROM manufact WHERE manu_code = @manu_code)
					THROW 50000, 'No existe el fabricante', 1

				IF NOT EXISTS(SELECT 1 FROM product_types WHERE stock_num = @stock_num)
					THROW 50000, 'No existe el fabricante', 1

				-- Si no existe la unidad insertarla en la tabla correspondiente. 
				IF NOT EXISTS(SELECT 1 FROM units WHERE unit_code = @unit_code)
					INSERT INTO units (unit_code,unit_descr)
					VALUES(@unit_code, @unit_descr)
					
				INSERT INTO ProductosV (stock_num, description, manu_code, unit_price, unit_code, unit_descr)
				VALUES(@stock_num, @description, @manu_code, @unit_price, @unit_code, @unit_descr)

			COMMIT TRANSACTION
		END TRY

		BEGIN CATCH
			ROLLBACK TRANSACTION
		END CATCH

		FETCH NEXT FROM cursor_insert_ProdV
		INTO @stock_num, @description, @manu_code, @unit_price,	@unit_code,	@unit_descr

	END

	CLOSE cursor_insert_ProdV
	DEALLOCATE cursor_insert_ProdV
END
GO
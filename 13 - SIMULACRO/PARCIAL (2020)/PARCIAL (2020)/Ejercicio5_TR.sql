/*EJERCICIO 5
Dada la vista:
	Create view ProductosV 
	 AS SELECT p.stock_num, pt.description, p.manu_code, p.unit_price, 
			   p.unit_code, u.unit_descr
	FROM products p JOIN product_types pt ON p.stock_num = pt.stock_num
					JOIN units u ON p.unit_code = u.unit_code;

	Realizar un trigger que realice los INSERTS en esta vista.
	
	En caso que ya exista el Producto, informar el mensaje “Clave duplicada”.
	Si no existe el fabricante o el tipo de producto informar el error.
	Si no existe la unidad insertarla en la tabla correspondiente.
	
	Tener en cuenta que los 
		- INSERTs pueden ser masivos 
		- sólo se debe deshacer la operación del registro erróneo.
*/
Create view ProductosV 
AS SELECT p.stock_num, pt.description, p.manu_code, p.unit_price, 
	p.unit_code, u.unit_descr
FROM products p JOIN product_types pt ON p.stock_num = pt.stock_num
	JOIN units u ON p.unit_code = u.unit_code;
GO

DROP TRIGGER insertsProductosV 
GO

CREATE TRIGGER insertsProductosV ON ProductosV
INSTEAD OF INSERT
AS
BEGIN
	-- Declarado de variables
	DECLARE @stock_num smallint ,@description varchar(15), @manu_code char(3), @unit_price decimal, 
	@unit_code smallint,@unit_descr varchar(15);

	-- Creación de cursor
	DECLARE insertedCursor
	CURSOR FOR
		SELECT stock_num, description, manu_code, unit_price, unit_code, unit_descr
		FROM inserted

	-- Apertura de cursor
	OPEN insertedCursor

	FETCH NEXT FROM insertedCursor INTO @stock_num, @description, @manu_code, @unit_price, @unit_code, @unit_descr;

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
					INSERT INTO units (unit_descr) VALUES (@unit_descr)

				INSERT INTO products (stock_num,manu_code,unit_price,unit_code) VALUES
					(@stock_num, @manu_code, @unit_price, @unit_code)

			COMMIT TRANSACTION
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION
		END CATCH
		
		FETCH NEXT FROM insertedCursor INTO @stock_num, @description, @manu_code, @unit_price, @unit_code, @unit_descr;
	END

	-- Cierre de cursor
	CLOSE insertedCursor
	DEALLOCATE insertedCursor
END
GO

-- Fallo por prod existente
INSERT INTO ProductosV (stock_num, description, manu_code, unit_price, unit_code, unit_descr)
	VALUES (1, 'test', 'HRO', 15, 1, 'test')

-- Fallo por fabricante invalido
INSERT INTO ProductosV (stock_num, description, manu_code, unit_price, unit_code, unit_descr)
	VALUES (1, 'test', 'ZZP', 66, 2, 'test')

-- Fallo por tipo invalido
INSERT INTO ProductosV (stock_num, description, manu_code, unit_price, unit_code, unit_descr)
	VALUES (9999, 'test', 'AZZ', 66, 2, 'test')

-- Inserta bien con unit no existente
INSERT INTO ProductosV (stock_num, description, manu_code, unit_price, unit_code, unit_descr)
	VALUES (5, 'test', 'AZZ', 66, 99, 'test')

-- Inserta Bien
INSERT INTO ProductosV (stock_num, description, manu_code, unit_price, unit_code, unit_descr)
	VALUES (114, 'test', 'HRO', 66, 21, 'test')


select * from products
select * from units
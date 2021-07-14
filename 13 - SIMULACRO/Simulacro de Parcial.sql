USE stores7new;

-- c. SQL

-- Obtener los Tipos de Productos, monto total comprado por cliente y por sus referidos.
-- Mostrar: 
    -- descripción del Tipo de Producto,
    -- Nombre y apellido del cliente,
    -- monto total comprado de ese tipo de producto,
    -- Nombre y apellido de su cliente referido y el monto total comprado de su referido.
-- Ordenado por Descripción, Apellido y Nombre del cliente (Referente).

-- Nota: Si el Cliente no tiene referidos o sus referidos no compraron el mismo producto, 
-- mostrar ´--´ como nombre y apellido del referido y 0 (cero) en la cantidad vendida.

SELECT 
    pt.description,
    c1.lname AS Cliente_Apellido,
    c1.fname AS Cliente_Nombre,
    SUM(i1.quantity * i1.unit_price) AS Total_Comprado_Cliente,
    COALESCE(r.lname, '---') AS Referido_Apellido,					-- si viene nulo pongo '---'
    COALESCE(r.fname, '---') AS Referido_Nombre,					-- si viene nulo pongo '---'
    COALESCE(r.totalRef, 0)  AS Total_Comprado_Referido				-- si viene nulo pongo 0
FROM customer c1
	-- Cliente
	LEFT JOIN orders o1 ON (o1.customer_num = c1.customer_num)
	LEFT JOIN items i1 ON (i1.order_num = o1.order_num)
	JOIN product_types pt ON (pt.stock_num = i1.stock_num)
	-- Referido
    LEFT JOIN (SELECT c2.customer_num, c2.customer_num_referedBy, 
					  c2.lname, c2.fname, i2.stock_num, sum(i2.unit_price*i2.quantity) totalRef
				from customer c2 
				JOIN orders o2 ON (o2.customer_num = c2.customer_num)
				JOIN items i2 ON (i2.order_num = o2.order_num)
				group by c2.customer_num, c2.customer_num_referedBy, c2.lname, c2.fname, i2.stock_num
					) r ON c1.customer_num = r.customer_num_referedBy and pt.stock_num = r.stock_num
GROUP BY pt.description, c1.lname, c1.fname, r.lname, r.fname, r.totalRef
ORDER BY pt.description, c1.lname, c1.fname


-- PARTE 2 – StoredProcedures y Triggers

-- d.
-- Crear un procedimiento actualizaPrecios que reciba como parámetro una fecha a partir de la cual procesar los registros de una tabla Novedades
-- que contiene los nuevos precios de Productos con la siguiente estructura/información.

	-- FechaAlta, Manu_code, Stock_num, descTipoProducto, Unit_price

CREATE TABLE novedades(
	stock_num SMALLINT,
	manu_code CHAR(3),
	descTipoProducto VARCHAR(20),
	unit_price DECIMAL(6,2),
	unit_code SMALLINT, 
	fechaAlta DATETIME
)

-- Por cada fila de la tabla Novedades
	-- Si no existe el Fabricante, devolver un error de Fabricante inexistente y descartar la novedad.
	-- Si no existe el stock_num (pero existe el Manu_code) darlo de alta en la tabla Product_types
	-- Si ya existe el Producto actualizar su precio
	-- Si no existe, Insertarlo en la tabla de productos.

-- Nota: Manejar una transacción por novedad y errores no contemplados.

GO
CREATE PROCEDURE actualizaPrecios @fecha DATETIME
AS
BEGIN
	DECLARE @stock_num SMALLINT
	DECLARE @manu_code CHAR(3)
	DECLARE @descTipoProducto VARCHAR(15)
	DECLARE @unit_price DECIMAL(6,2)
	DECLARE @unit_code SMALLINT

	DECLARE cursor_novedades CURSOR FOR
		SELECT stock_num, manu_code, descTipoProducto, unit_price, unit_code
		FROM novedades
		WHERE fechaAlta >= @fecha

	OPEN cursor_novedades

	FETCH NEXT FROM cursor_novedades
		INTO @stock_num, @manu_code, @descTipoProducto, @unit_price, @unit_code

	WHILE @@FETCH_STATUS = 0
	BEGIN
		BEGIN TRY
		
		BEGIN TRANSACTION
		-- Si no existe el Fabricante, devolver un error de Fabricante inexistente y descartar la novedad.
		IF NOT EXISTS (SELECT 1 FROM manufact WHERE manu_code = @manu_code)
			THROW 50000, 'Fabricante inexistente', 2
		
		-- Si no existe el stock_num (pero existe el Manu_code) darlo de alta en la tabla Product_types
		IF NOT EXISTS (SELECT 1 FROM product_types WHERE stock_num = @stock_num)
			INSERT INTO product_types VALUES (@stock_num, @descTipoProducto)
		
		-- Si ya existe el Producto actualizar su precio
		IF EXISTS(SELECT 1 FROM products WHERE stock_num = @stock_num AND manu_code = @manu_code)
			UPDATE products
			SET unit_price = @unit_price
			WHERE stock_num = @stock_num AND manu_code = @manu_code
		-- Si no existe, Insertarlo en la tabla de productos.
		ELSE
			INSERT INTO products VALUES (@stock_num, @manu_code, @unit_price, @unit_code)
		
		COMMIT TRANSACTION
	
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION
		END CATCH

		FETCH NEXT FROM cursor_novedades
			INTO @stock_num, @manu_code, @descTipoProducto, @unit_price, @unit_code

	END

	CLOSE cursor_novedades
	DEALLOCATE cursor_novedades
END
GO

-- e. Triggers

-- Se desea llevar en tiempo real la cantidad de llamadas/reclamos (Cust_calls) de los Clientes (Customers)
-- que se producen por cada mes del año y por cada tipo (Call_code).

-- Ante este requerimiento, se solicita realizar un trigger que cada vez que se produzca un Alta o Modificación en la tabla Cust_calls,
-- se actualice una tabla ResumenLLamadas donde se lleve en tiempo real la cantidad de llamadas por Año, Mes y Tipo de llamada.

-- Nota: No se modifica la PK de la tabla de llamadas. Tener en cuenta altas y modificaciones múltiples.

	-- Ejemplo.
	-- Si se da de alta una llamada, se debe sumar 1 a la cantidad de ese Año, Mes y Tipo de llamada. 
	-- En caso de ser una modificación y se modifica el tipo de llamada (por ejemplo por una mala clasificación del operador),
	-- se deberá restar 1 al tipo anterior y sumarle 1 al tipo nuevo. Si no se modifica el tipo de llamada no se deberá hacer nada.

-- Tabla ResumenLLamadas
	-- Anio decimal(4) PK,
	-- Mes decimal(2) PK,
	-- Call_code char(1) PK,
	-- Cantidad int

CREATE TABLE resumenLLamadas (
	anio DECIMAL(4),
	mes DECIMAL(2),
	call_code CHAR(1),
	cantidad INT,
	PRIMARY KEY(anio, mes, call_code)
)

GO
CREATE TRIGGER trigger_llamadas ON cust_calls
AFTER INSERT, UPDATE AS
BEGIN
	DECLARE @call_code CHAR(1)
	DECLARE @call_dtime DATETIME

	DECLARE cursor_llamadas_insertadas CURSOR FOR 
		SELECT call_dtime, call_code FROM inserted

	FETCH NEXT FROM cursor_llamadas_insertadas
		INTO @call_code, @call_dtime

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF EXISTS(SELECT 1 FROM resumenLLamadas WHERE call_code = @call_code AND anio = YEAR(@call_dtime) AND mes = MONTH(@call_dtime))
			UPDATE resumenLLamadas
			SET cantidad = cantidad + 1
			WHERE call_code = @call_code AND anio = YEAR(@call_dtime) AND mes = MONTH(@call_dtime)
		ELSE
			INSERT INTO resumenLLamadas (anio, mes, call_code, cantidad)
			VALUES (YEAR(@call_dtime), MONTH(@call_dtime), @call_code, 1)
	END

	CLOSE cursor_llamadas_insertadas
	DEALLOCATE cursor_llamadas_insertadas
		
	-- En caso de ser una modificación y se modifica el tipo de llamada (por ejemplo por una mala clasificación del operador),
	-- se deberá restar 1 al tipo anterior y sumarle 1 al tipo nuevo. Si no se modifica el tipo de llamada no se deberá hacer nada.
	-- en caso de que se modifica el tipo de llamada
	
	DECLARE cursor_llamadas_modificadas CURSOR FOR 
		SELECT call_dtime, call_code FROM deleted 
	
	FETCH NEXT FROM cursor_llamadas_modificadas
		INTO @call_dtime, @call_code

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF EXISTS(SELECT 1 FROM resumenLLamadas WHERE call_code = @call_code AND anio = YEAR(@call_dtime) AND mes = MONTH(@call_dtime))
			UPDATE resumenLLamadas
			SET cantidad = cantidad - 1
			WHERE call_code = @call_code AND anio = YEAR(@call_dtime) AND mes = MONTH(@call_dtime)
		ELSE
			INSERT INTO resumenLLamadas (anio, mes, call_code, cantidad)
			VALUES (YEAR(@call_dtime), MONTH(@call_dtime), @call_code, 1)

		FETCH NEXT FROM cursor_llamadas_modificadas
			INTO @call_dtime, @call_code, @call_code
	END
		
	CLOSE cursor_llamadas_modificadas
	DEALLOCATE cursor_llamadas_modificadas
END
GO





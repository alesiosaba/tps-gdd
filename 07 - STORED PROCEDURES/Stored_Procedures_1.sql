-- Práctica 1 de Stored Procedures

USE stores7new

-- a.
-- Stored Procedures

-- Crear la siguiente tabla CustomerStatistics con los siguientes campos:
-- customer_num (entero y pk), ordersqty (entero), maxdate (date), uniqueProducts (entero)

CREATE TABLE CustomerStatistics (
    customer_num INTEGER PRIMARY KEY,
    ordersqty INTEGER,
    maxdate DATETIEM,
    uniqueProducts INTEGER
)

-- Crear un procedimiento ‘actualizaEstadisticas’ que reciba dos parámetros customer_numDES y customer_numHAS
-- y que en base a los datos de la tabla customer cuyo customer_num estén en el rango pasado por parámetro, 
-- inserte (si no existe) o modifique el registro de la tabla CustomerStatistics con la siguiente información:

    -- Ordersqty contedrá la cantidad de órdenes para cada cliente.
    -- Maxdate contedrá la fecha máxima de la última órden puesta por cada cliente. 
    -- uniqueProducts contendrá la cantidad única de tipos de productos adquiridos por cada cliente.

GO
CREATE PROCEDURE actualizaEstadisticas @customer_numDES INT, @customer_numHAS INT
AS
BEGIN
    DECLARE @customer_num INT, @ordersqty INT, @maxdate DATETIME, @uniqueManufact INT
    
    DECLARE CustomerCursor CURSOR FOR
        SELECT customer_num FROM customer
        WHERE customer_num BETWEEN @customer_numDES AND @customer_numHAS
    
    OPEN CustomerCursor
    
    FETCH NEXT FROM CustomerCursor 
        INTO @customer_num
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT @ordersqty = COUNT(*), @maxDate = MAX(order_date)
        FROM orders
        WHERE customer_num = @customer_num

        SELECT @uniqueProducts = COUNT(DISTINCT stock_num)
        FROM items i
            JOIN orders o ON o.order_num = i.order_num
        WHERE o.customer_num = @customer_num 

        IF NOT EXISTS (SELECT 1 FROM CustomerStatistics WHERE customer_num = @customer_num)
            INSERT INTO customerStatistics VALUES (@customer_num, @ordersQty, @maxDate, @uniqueManufact)
        ELSE
            UPDATE customerStatistics
            SET ordersQty = @ordersQty, maxDate = @maxDate, uniqueManufact = @uniqueManufact
            WHERE customer_num = @customer_num
        
        FETCH NEXT FROM CustomerCursor 
        INTO @customer_num
    END

    CLOSE CustomerCursor
    DEALLOCATE CustomerCursor
END
GO

-- Pruebas
SELECT * FROM CustomerStatistics
EXECUTE actualizaEstadisticas 101,110

-- b.
-- Crear un procedimiento ‘migraClientes’ que reciba dos parámetros customer_numDES y customer_numHAS y que dependiendo el tipo de cliente y la cantidad de órdenes
-- los inserte en las tablas clientesCalifornia, clientesNoCaBaja, clienteNoCAAlta.

    -- El procedimiento deberá migrar de la tabla customer todos los clientes de California a la tabla clientesCalifornia, 
    -- los clientes que no son de California pero tienen más de 999u$ en OC en
    -- clientesNoCaAlta y los clientes que tiene menos de 1000u$ en OC en la tablas clientesNoCaBaja.
    
    -- Se deberá actualizar un campo status en la tabla customer con valor
    -- ‘P’ Procesado, para todos aquellos clientes migrados.
    
    -- El procedimiento deberá contemplar toda la migración como un lote, en el caso que ocurra un error, 
    -- se deberá informar el error ocurrido y abortar y deshacer la operación.

CREATE TABLE [dbo].[clientesCalifornia](
    [customer_num] SMALLINT NOT NULL,
    [fname] VARCHAR(15),
    [lname] VARCHAR(15),
    [company] VARCHAR(20),
    [address1] VARCHAR(20),
    [address2] VARCHAR(20),
    [city] VARCHAR(15),
    [state] CHAR(2),
    [zipcode] CHAR(5),
    [phone] VARCHAR(18)
)

CREATE TABLE [dbo].[clientesNoCaBaja](
    [customer_num] SMALLINT NOT NULL,
    [fname] VARCHAR(15),
    [lname] VARCHAR(15),
    [company] VARCHAR(20),
    [address1] VARCHAR(20),
    [address2] VARCHAR(20),
    [city] VARCHAR(15),
    [state] CHAR(2),
    [zipcode] CHAR(5),
    [phone] VARCHAR(18)
)

CREATE TABLE [dbo].[clientesNoCaAlta](
    [customer_num] SMALLINT NOT NULL,
    [fname] VARCHAR(15),
    [lname] VARCHAR(15),
    [company] VARCHAR(20),
    [address1] VARCHAR(20),
    [address2] VARCHAR(20),
    [city] VARCHAR(15),
    [state] CHAR(2),
    [zipcode] CHAR(5),
    [phone] VARCHAR(18)
)

GO
CREATE PROCEDURE migraClientes @customer_numDES INT, @customer_numHAS INT
AS
BEGIN
BEGIN TRY
    DECLARE @customer_num INT
    DECLARE @lname VARCHAR(15), @fname VARCHAR(15), @company VARCHAR(20), @address1 VARCHAR(20), @address2 VARCHAR(20),@city VARCHAR(15)
    DECLARE @state CHAR(2), @zipcode CHAR(5), @phone VARCHAR(18), @status CHAR(1)
    
    DECLARE CustomerCursor CURSOR FOR
    
    SELECT customer_num, lname, fname, company, address1, address2, city, state, zipcode, phone
    FROM customer
    WHERE customer_num BETWEEN @customer_numDES AND @customer_numHAS

    OPEN CustomerCursor
    
    FETCH NEXT FROM CustomerCursor
        INTO @customer_num, @lname, @fname, @company, @address1, @address2, @city, @state, @zipcode, @phone
    
    BEGIN TRANSACTION
        WHILE @@FETCH_STATUS = 0
        BEGIN
            IF @state = 'CA'
            BEGIN
                INSERT INTO clientesCalifornia (customer_num,lname,fname,company,address1,address2,city,state,zipcode,phone)
                VALUES (@customer_num,@lname,@fname,@company,@address1,@address2,@city,@state,@zipcode,@phone)
            END
            ELSE
            BEGIN
                IF (SELECT sum(quantity * unit_price) FROM orders o JOIN items i ON (o.order_num = i.order_num) WHERE customer_num = @customer_num) > 999
                BEGIN
                    INSERT INTO clientesNoCaAlta (customer_num,lname,fname,company, address1,address2,city,state,zipcode,phone)
                    VALUES (@customer_num,@lname,@fname,@company,@address1,@address2,@city,@state,@zipcode,@phone)
                END
                ELSE
                BEGIN
                    INSERT INTO clientesNoCaBaja (customer_num,lname,fname,company,address1,address2,city,state,zipcode,phone)
                    VALUES (@customer_num,@lname,@fname,@company,@address1,@address2,@city,@state,@zipcode,@phone)
                END
            END
            
            UPDATE customer 
            SET status = 'P'
            WHERE customer_num = @customer_num
            
            FETCH NEXT FROM CustomerCursor
                INTO @customer_num,@lname,@fname,@company,@address1,@address2,@city,@state,@zipcode,@phone
        END
    
        CLOSE CustomerCursor
        DEALLOCATE CustomerCursor  
    
    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION

    DECLARE @errorDescripcion VARCHAR(100)
    
    SET @errorDescripcion = 'Error en Cliente ' + CAST(@customer_num AS CHAR(5))
    
    RAISERROR(@errorDescripcion,14,1)
END CATCH
END
GO

DROP PROCEDURE migraClientes

--Pruebas
SELECT count(*) FROM clientesCalifornia 
SELECT count(*) FROM customer

EXEC migraClientes 100,126

SELECT COUNT(*) FROM customer 
WHERE customer_num between 100 and 126

SELECT count(*) FROM clientesCalifornia 
SELECT count(*) FROM clientesNoCaAlta 
SELECT count(*) FROM clientesNoCaBaja 
SELECT count(*) FROM customer WHERE customer_num between 100 and 126 and status='P'

DELETE FROM clientesCalifornia DELETE FROM clientesNoCaAlta DELETE FROM clientesNoCaBaja


-- c.
-- Crear un procedimiento ‘actualizaPrecios’ que reciba como parámetros manu_codeDES, manu_codeHAS y porcActualizacion que dependiendo del tipo de cliente
-- y la cantidad de órdenes genere las siguientes tablas listaPrecioMayor y listaPreciosMenor. Ambas tienen las misma estructura que la tabla Productos.

CREATE TABLE [dbo].[listaPrecioMayor] (
    [stock_num] SMALLINT NOT NULL,
    [manu_code] CHAR(3) NOT NULL,
    [unit_price] DECIMAL(6,2) NULL,
    [unit_code] SMALLINT
)

CREATE TABLE [dbo].[listaPrecioMenor] (
    [stock_num] SMALLINT NOT NULL,
    [manu_code] CHAR(3) NOT NULL,
    [unit_price] DECIMAL(6, 2) NULL,
    [unit_code] SMALLINT
)

-- El procedimiento deberá tomar de la tabla products todos los productos que correspondan al rango de fabricantes asignados por parámetro.
-- Por cada producto del fabricante se evaluará la cantidad (quantity) comprada.
    
    -- Si la misma es mayor o igual a 500 se grabará el producto en la tabla listaPrecioMayor y el unit_price deberá ser actualizado
    -- con (unit_price * (porcActualización * 0,80)),
    
    -- Si la cantidad comprada del producto es menor a 500 se actualizará (o insertará) en la tabla listaPrecioMenor y el unit_price se actualizará
    -- con (unit_price * porcActualizacion)

-- Asimismo, se deberá actualizar un campo status de la tabla products con valor ‘A’ Actualizado, para todos aquellos productos con cambio de precio actualizado.

-- El procedimiento deberá contemplar todas las operaciones de cada fabricante como un lote, en el caso que ocurra un error,
-- se deberá informar el error ocurrido y deshacer la operación de ese fabricante.

ALTER TABLE products ADD status CHAR(1)

GO
ALTER PROCEDURE actualizaPrecios @manu_codeDES CHAR(3), @manu_codeHAS CHAR(3), @porcActualizacion decimal (5,3)
AS
BEGIN
    DECLARE @stock_num INT, @manu_code CHAR(3), @unit_price DECIMAL(6,2), @unit_code smallint, @manu_codeAux CHAR(3)
    
    DECLARE StockCursor CURSOR FOR
        SELECT p.stock_num, manu_code, unit_price, unit_code
        FROM products p
        WHERE manu_code BETWEEN @manu_codeDES AND @manu_codeHAS
        -- necesario ordenar por manufact para manejar los productos del fabricante como lote
        ORDER BY manu_code, p.stock_num 

    OPEN StockCursor
    
    FETCH NEXT FROM StockCursor 
        INTO @stock_num, @manu_code, @unit_price, @unit_code
    
    SET @manu_codeAux = @manu_code
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
        BEGIN TRANSACTION
            IF (SELECT SUM(quantity) FROM items WHERE stock_num = @stock_num AND manu_code = @manu_code) >= 500
            BEGIN
                INSERT INTO listaPrecioMayor
                VALUES (@stock_num, @manu_code, @unit_price * (@porcActualizacion * 0.80), @unit_code)
            END
            ELSE
            BEGIN
                INSERT INTO listaPrecioMenor 
                VALUES (@stock_num, @manu_code, @unit_price * (@porcActualizacion), @unit_code)
            END

            UPDATE products 
            SET status= 'A'
            WHERE manu_code = @manu_code AND stock_num = @stock_num
        
            FETCH NEXT FROM StockCursor 
                INTO @stock_num, @manu_code, @unit_price, @unit_code
        
            IF @manu_code != @manu_codeAux
            BEGIN
                COMMIT TRANSACTION
                SET @manu_codeAux = @manu_code
            END
        END TRY
        BEGIN CATCH
            ROLLBACK TRANSACTION
            
            DECLARE @errorDescripcion VARCHAR(100)
            
            SET @errorDescripcion = 'Error en Fabricante ' + @manu_code
            
            RAISERROR(@errorDescripcion,14,1)
        END CATCH
    END

    CLOSE StockCursor
    DEALLOCATE StockCursor
END

-- Pruebas
DELETE FROM listaPrecioMayor DELETE FROM listaPrecioMenor UPDATE products SET STATUS = ''
INSERT INTO items VALUES (2,1001,1,'HRO',1000,250.00)
EXEC actualizaPrecios 'HRO','HRO',0.10
SELECT * FROM listaPrecioMayor
SELECT * FROM products WHERE stock_num = 1 AND manu_code = 'HRO'
SELECT * FROM listaPrecioMenor WHERE stock_num=2 
SELECT * FROM products WHERE stock_num=2 AND manu_code='HRO' SELECT count(*) FROM listaPrecioMenor
SELECT * FROM products WHERE manu_code = 'ANZ'
EXEC actualizaPrecios 'ANZ','ANZ',0.05
SELECT * FROM products WHERE manu_code = 'ANZ'
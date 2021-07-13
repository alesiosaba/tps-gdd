-- Práctica de Triggers 1

USE stores7new

-- 1.
-- Dada la tabla products de la base de datos stores7new se requiere crear una tabla Products_historia_precios
-- y crear un trigger que registre los cambios de precios que se hayan producido en la tabla Products.

-- Tabla Products_historia_precios
    -- Stock_historia_Id Identity (PK)
    -- Stock_num
    -- Manu_code
    -- fechaHora (grabar fecha y hora del evento)
    -- usuario (grabar usuario que realiza el cambio de precios)
    -- unit_price_old
    -- unit_price_new
    -- estado char default ‘A’ check (estado IN (‘A’,’I’) 

CREATE TABLE 
    products_historia_precios ( 
    stock_historia_id INTEGER IDENTITY(1,1) PRIMARY KEY,
    stock_num SMALLINT,
    manu_code CHAR(3),
    fechaHora DATETIME DEFAULT GETDATE(),
    usuario VARCHAR(20) DEFAULT SUSER_SNAME(),
    unit_price_old DECIMAL(6,2),
    unit_price_new DECIMAL(6,2),
    estado CHAR DEFAULT 'A' CHECK(estado IN('A','I')), 
) 

-- opción simple sin cursor

GO
    CREATE TRIGGER cambio_precios_TR ON products 
    AFTER UPDATE AS
    BEGIN
		INSERT INTO products_historia_precios (stock_num, manu_code, unit_price_new, unit_price_old, fechaHora, usuario) 
            SELECT 
                i.stock_num,
                i.manu_code,
                i.unit_price,
                d.unit_price,
                GETDATE(),
                SUSER_SNAME() 
            FROM inserted i 
                JOIN deleted d ON (i.stock_num = d.stock_num AND i.manu_code = d.manu_code) 
            WHERE i.unit_price != d.unit_price
    END
GO

-- opción con cursor (en realidad no hace falta)

GO
	CREATE TRIGGER cambio_precios_TR_2 ON products
	AFTER UPDATE AS
    BEGIN
		DECLARE @unit_price_old decimal(6,2)
		DECLARE @unit_price_new decimal(6,2)
		DECLARE @stock_num smallint
		DECLARE @manu_code char(3)

		DECLARE precios_stock CURSOR FOR
		SELECT i.stock_num,i.manu_code, i.unit_price, d.unit_price
		FROM inserted i
        JOIN deleted d ON (i.stock_num = d.stock_num and i.manu_code = d.manu_code)
		WHERE i.unit_price != d.unit_price
		
        OPEN precios_stock
		
        FETCH NEXT FROM precios_stock
		INTO @stock_num, @manu_code, @unit_price_new, @unit_price_old
		
        WHILE @@FETCH_STATUS = 0
		BEGIN
		    INSERT INTO products_historia_precios
		    (stock_num, manu_code, unit_price_new, unit_price_old, fechaHora, usuario)
		    VALUES
		    (@stock_num, @manu_code, @unit_price_new, @unit_price_old, GETDATE(), SYSTEM_USER)
		
            FETCH NEXT FROM precios_stock
            INTO @stock_num, @manu_code, @unit_price_new, @unit_price_old
        END
		
        CLOSE precios_stock
		DEALLOCATE precios_stock
	END
GO

-- Instrucciones para probar los estos triggers
SELECT * FROM products

UPDATE products 
SET unit_price = 999
WHERE stock_num = 1 AND manu_code = 'HRO'

UPDATE products 
SET unit_code = 13
WHERE stock_num = 1 AND manu_code = 'HRO'

SELECT * FROM products_historia_precios


-- 2.
-- Crear un trigger sobre la tabla Products_historia_precios que ante un delete sobre la misma realice en su lugar un update
-- del campo estado de ‘A’ a ‘I’ (inactivo). 

GO
    CREATE TRIGGER delete_stock_historia ON products_historia_precios
    INSTEAD OF DELETE AS
    BEGIN 

        DECLARE @stock_historia_id INT 

        DECLARE stock_historia_borrado CURSOR FOR
            SELECT stock_historia_id FROM deleted 
            
        OPEN stock_historia_borrado
        
        FETCH NEXT FROM stock_historia_borrado 
        INTO @stock_historia_id
        
        WHILE @@FETCH_STATUS = 0 
        BEGIN 
            UPDATE products_historia_precios
                SET estado = 'I' WHERE stock_historia_id = @stock_historia_id 
        
            FETCH NEXT FROM stock_historia_borrado 
                INTO @stock_historia_id 
        END
        
        CLOSE stock_historia_borrado 
        DEALLOCATE stock_historia_borrado 
    END
GO

-- 3. 
-- Validar que sólo se puedan hacer inserts en la tabla products en un horario entre las 8:00 AM y 8:00 PM. En caso contrario enviar un error por pantalla.

GO
    CREATE TRIGGER inserts_stock ON products
    INSTEAD OF INSERT AS
    BEGIN
        IF(DATEPART(HOUR, GETDATE()) BETWEEN 8 AND 20)
            BEGIN
                INSERT INTO products (stock_num, manu_code, unit_price, unit_code)
                SELECT stock_num, manu_code, unit_price, unit_code 
                FROM inserted 
            END
        ELSE
            BEGIN 
                RAISERROR('Maestro que hace a esta hora laburando?', 16, 1) 
            END
    END
GO

-- 4.
-- Crear un trigger que ante un borrado sobre la tabla orders realice un borrado en cascada sobre la tabla ITEMS,
-- validando que sólo se borre 1 orden de compra.
-- Si detecta que están queriendo borrar más de una orden de compra, informará un error y abortará la operación.

GO
	CREATE TRIGGER delete_orders_and_items ON orders
	INSTEAD OF DELETE AS 
	BEGIN 
		DECLARE @order_num SMALLINT

		IF((SELECT COUNT(*) FROM deleted) > 1) 
			THROW 50000, 'No se pueden eliminar mas de una orden a la vez', 1 

		SELECT @order_num = order_num FROM deleted;
		DELETE FROM items WHERE order_num = @order_num; 
		DELETE FROM orders WHERE order_num = @order_num; 
	END
GO

-- Al intentar borrar más de una orden se dispara el THROW
DELETE FROM orders WHERE order_num = 1004 OR order_num = 1001

-- Para probar elimino la orden 1004 y en cadena se borraran sus items
SELECT * FROM orders WHERE order_num = 1004
SELECT * FROM items WHERE order_num = 1004

DELETE FROM orders WHERE order_num = 1004

-- 5. 
-- Crear un trigger de insert sobre la tabla ítems que al detectar que el código de fabricante (manu_code) del producto a comprar no existe en la tabla manufact,
-- inserte una fila en dicha tabla con el manu_code ingresado, en el campo manu_name la descripción ‘Manu Orden 999’ donde 999 corresponde 
-- al nro. de la orden de compra a la que pertenece el ítem y en el campo lead_time el valor 1.

GO
    CREATE TRIGGER insert_items ON items
    INSTEAD OF INSERT AS
    BEGIN 
		DECLARE @order_num SMALLINT
		DECLARE @manu_code CHAR(3)

        DECLARE cursor_items_ingresados CURSOR FOR
			SELECT order_num, manu_code
			FROM inserted

        OPEN cursor_items_ingresados

        FETCH NEXT FROM cursor_items_ingresados
        INTO @order_num, @manu_code

		WHILE @@FETCH_STATUS = 0 
		BEGIN
			-- Si no existe el fabricante en la tabla manufact
			IF NOT EXISTS (SELECT * FROM manufact WHERE manu_code = @manu_code)
			BEGIN
				INSERT INTO manufact (manu_code, manu_name, lead_time)
				VALUES(@manu_code, 'Manu Orden' + ' ' + CAST(@order_num AS VARCHAR(4)), 1)
			END

			FETCH NEXT FROM cursor_items_ingresados
				INTO @order_num, @manu_code
		END

		CLOSE cursor_items_ingresados
		DEALLOCATE cursor_items_ingresados
        
        -- En todo caso igual se inserta el item ingresado en la tabla items
        INSERT INTO items (item_num, order_num, stock_num, manu_code, quantity, unit_price)
        SELECT item_num, order_num, stock_num, manu_code, quantity, unit_price FROM inserted
    END
GO

-- 6.
-- Crear tres triggers (Insert, Update y Delete) sobre la tabla Products para replicar todas las operaciones en la tabla products_replica,
-- la misma deberá tener la misma estructura de la tabla Products.

CREATE TABLE products_replica(
    stock_num smallint,
    manu_code char(3),
    unit_price decimal(6,2),
    unit_code smallint,
    constraint pk_products_replica primary key (stock_num, manu_code)
) 

-- TRIGGER INSERT
GO
    CREATE TRIGGER replica_insert ON products 
    AFTER INSERT AS
        BEGIN 
            INSERT INTO products_replica (stock_num, manu_code, unit_price, unit_code)
            SELECT stock_num, manu_code, unit_price, unit_code
            FROM inserted 
    END 
GO

-- TRIGGER DELETE
GO
    CREATE TRIGGER replica_delete ON products 
    AFTER DELETE AS
        BEGIN
            DELETE pr FROM products_replica pr
                JOIN deleted d ON (pr.stock_num = d.stock_num AND pr.manu_code = d.manu_code)
    END
GO

-- TRIGGER UPDATE
GO
	CREATE TRIGGER replica_update ON products
	AFTER UPDATE AS
    BEGIN
        UPDATE pr 
        SET 
            pr.unit_price = i.unit_price,
            pr.unit_code = i.unit_code 
        FROM products_replica pr 
                JOIN inserted i ON (pr.stock_num = i.stock_num AND pr.manu_code = i.manu_code) 
	END
GO

-- 7.
-- Crear la vista Productos_x_fabricante que tenga los siguientes atributos:

    -- Stock_num,
    -- description,
    -- manu_code,
    -- manu_name,
    -- unit_price

GO
    CREATE VIEW v_productos_x_fabricante AS
        SELECT 
            p.stock_num,
            p.manu_code,
            tp.description,
            m.manu_name,
            p.unit_price 
        FROM products p 
            JOIN manufact m ON p.manu_code = m.manu_code 
            JOIN product_types tp on p.stock_num = tp.stock_num;
GO

-- Crear un trigger de Insert sobre la vista anterior que ante un insert, inserte una fila en la tabla Products,
-- pero si el manu_code no existe en la tabla manufact, inserte además una fila en dicha tabla con el campo lead_time en 1.

GO
    CREATE TRIGGER insertar_prod_x_fab ON v_productos_x_fabricante
    INSTEAD OF INSERT AS 
    BEGIN
        DECLARE @manu_code CHAR(3)
        DECLARE @manu_name VARCHAR(15)

        DECLARE cursor_fabricantes CURSOR FOR
        SELECT manu_code, manu_name FROM inserted

        OPEN cursor_fabricantes

        FETCH NEXT cursor_fabricantes 
            INTO @manu_code, @manu_name

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Si no existe el fabricante en la tabla manufact
            IF NOT EXISTS(SELECT manu_code FROM manufact WHERE manu_code = @manu_code)
            BEGIN
                INSERT INTO manufact (manu_code, manu_name, lead_time)
                VALUES (@manu_code, @manu_name, 1)
            END

            FETCH NEXT cursor_fabricantes 
                INTO @manu_code, @manu_name
        END

        CLOSE cursor_fabricantes
        DEALLOCATE cursor_fabricantes 

        -- insertamos una fila por cada producto que se quiso insertar en la vista    
        INSERT INTO products (stock_num, manu_code, unit_price)
        SELECT stock_num, manu_code, unit_price
        FROM inserted
    END
GO 

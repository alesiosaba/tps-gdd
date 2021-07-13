-- 1.
-- Se pide: Crear un trigger que valide que ante un insert de una o más filas en la tabla ítems, realice la siguiente validación:

-- Si la orden de compra a la que pertenecen los ítems ingresados corresponde a clientes del estado de California,
-- se deberá validar que estas órdenes puedan tener como máximo 5 registros en la tabla ítem.

-- Si se insertan más ítems de los definidos, el resto de los ítems se deberán insertar en la tabla items_error 
-- la cual contiene la misma estructura que la tabla ítems más un atributo fecha que deberá contener la fecha del día en que se trató de insertar.

-- Ej. Si la Orden de Compra tiene 3 items y se realiza un insert masivo de 3 ítems más, el trigger deberá insertar los 2 primeros en la tabla ítems
-- y el restante en la tabla ítems_error.
-- Supuesto: En el caso de un insert masivo los items son de la misma orden.

GO
    CREATE trigger Tr_temaA ON items
    INSTEAD OF INSERT AS 
        BEGIN 
        
        DECLARE @stock_num SMALLINT, @order_num SMALLINT, @item_num SMALLINT, @quantity SMALLINT
        DECLARE @unit_price DECIMAL(8,2) 
        DECLARE @manu_code CHAR(3), @state CHAR(2)

        DECLARE c_items CURSOR FOR 
            SELECT i.item_num, i.order_num, stock_num, manu_code, quantity, unit_price, state 
            FROM inserted i 
                JOIN orders o ON (i.order_num = o.order_num)
                JOIN customer c ON (o.customer_num = c.customer_num) 
        
        OPEN c_items
        
        FETCH c_items 
            INTO @item_num,@order_num,@stock_num,@manu_code, @quantity, @unit_price, @state

        WHILE @@FETCH_STATUS = 0 
        BEGIN 
            -- Si la orden de compra a la que pertenecen los ítems ingresados corresponde a clientes del estado de California,
            -- se deberá validar que estas órdenes puedan tener como máximo 5 registros en la tabla ítem.
            IF @state = 'CA' 
                BEGIN
                    -- para cada item se va a verificar que hayan 4 o menos items de esa orden 
                    IF (SELECT COUNT(*) FROM items WHERE order_num = @order_num) < 5 
                        BEGIN
                            INSERT INTO items (i.item_num, i.order_num, stock_num, manu_code, quantity, unit_price) 
                            VALUES(@item_num, @order_num, @stock_num, @manu_code, @quantity, @unit_price)
                        END
                    ELSE
                        BEGIN 
                            INSERT INTO items_error 
                            VALUES(@item_num, @order_num, @stock_num, @manu_code, @quantity, @unit_price, GETDATE())
                        END 
                END 
            ELSE 
                -- items que no son de ordenes de California
                BEGIN
                INSERT INTO items 
                VALUES(@item_num, @order_num, @stock_num, @manu_code, @quantity, @unit_price) 
                end
        
        FETCH FROM c_items 
        INTO @item_num, @order_num, @stock_num, @manu_code, @quantity, @unit_price, @state; 
        
        END 
        
        CLOSE c_items 
        DEALLOCATE c_items 
    END
GO

-- 2.
-- Triggers Dada la siguiente vista

GO
CREATE VIEW ProdPorFabricante AS
    SELECT m.manu_code, m.manu_name, COUNT(*)
    FROM manufact m 
        JOIN products p ON (m.manu_code = p.manu_code)
    GROUP BY manu_code, manu_name;
GO

-- Crear un trigger que permita ante un insert en la vista ProdPorFabricante insertar una fila en la tabla manufact.
-- Observaciones: el atributo leadtime deberá insertarse con un valor default 10
-- El trigger deberá contemplar inserts de varias filas, por ej. ante un INSERT / SELECT.

GO
    CREATE TRIGGER insFabric ON ProdPorFabricante 
    INSTEAD OF INSERT AS
    BEGIN
        INSERT INTO manufact (manu_code, manu_name, lead_time) 
            SELECT manu_code, manu_name, 10 
            FROM inserted
    END
GO

-- 3. 
-- Crear un trigger que ante un INSERT o UPDATE de una o más filas de la tabla Customer, realice la siguiente validación.

-- La cuota de clientes correspondientes al estado de California es de 20, 
-- si se supera dicha cuota se deberán grabar el resto de los clientes en la tabla customer_pend.

-- Validar que si de los clientes a modificar se modifica el Estado, no se puede superar dicha cuota.

    -- Si por ejemplo el estado de CA cuenta con 18 clientes y se realiza un update o insert masivo de 5 clientes con estado de CA,
    -- el trigger deberá modificar los 2 primeros en la tabla customer y los restantes grabarlos en la tabla customer_pend.
    -- La tabla customer_pend tendrá la misma estructura que la tabla customer con un atributo adicional fechaHora que deberá actualizarse con la fecha y hora del día.

    CREATE TABLE customer_updates_pend (
        customer_num SMALLINT NOT NULL,
        fname VARCHAR(15),
        lname VARCHAR(15),
        company VARCHAR(20),
        address1 VARCHAR(20),
        address2 VARCHAR(20),
        city VARCHAR(15),
        state CHAR(2),
        zipcode CHAR(5),
        phone VARCHAR(18),
        fecha DATETIME 
    )

GO
    CREATE TRIGGER temaB ON customer
    INSTEAD OF INSERT, UPDATE AS 
    BEGIN 
        DECLARE @customer_num SMALLINT
        DECLARE @fname VARCHAR(15), @lname VARCHAR(15), @city VARCHAR(15)
        DECLARE @company VARCHAR(20), @address1 VARCHAR(20), @address2 VARCHAR(20)
        DECLARE @state CHAR(2), @state_old CHAR(2)
        DECLARE @zipcode CHAR(5)
        DECLARE @phone VARCHAR(18)
        
        DECLARE c_call CURSOR FOR
            SELECT i.*, d.state
            FROM inserted I 
                LEFT JOIN deleted d ON (i.customer_num=d.customer_num)
        
        OPEN c_call 
        
        FETCH FROM c_call 
            INTO @customer_num, @fname, @lname, @company, @address1, @address2, @city, @state, @zipcode, @phone, @state_old 
        
        WHILE @@FETCH_STATUS = 0 
        BEGIN 
            IF @state = 'CA' AND @state != COALESCE(@state_old, 'ZZ')
            BEGIN 
                IF (SELECT COUNT(*) FROM customer where state='CA') < 20 
                BEGIN 
                    UPDATE customer
                    SET fname = @fname, lname = @lname, company = @company, adress1 = @address1, address2 = @address2, 
                        city = @city, state = @state, zipcode = @zipcode, phone = @phone
                    WHERE customer_num = @customer_num
                END 
                ELSE 
                BEGIN 
                    INSERT INTO customer_pend
                    VALUES (@customer_num, @fname, @lname, @company, @address1, @address2, @city, @state, @zipcode, @phone, getDate()) 
                END 
            END 
            ELSE 
            BEGIN 
                UPDATE customer 
                SET fname = @fname, lname = @lname, company = @company, address1 = @address1, address2 = @address2,
                    city = @city, state = @state, zipcode = @zipcode, phone = @phone 
                WHERE customer_num=@customer_num 
            END 
            
            FETCH NEXT FROM c_call 
                INTO @customer_num, @fname, @lname, @company, @address1 ,@address2, @city, @state, @zipcode, @phone, @state_old 
        END 
        
        CLOSE c_call 
        DEALLOCATE c_call 
    END 
GO

-- 4.
-- Dada la siguiente vista

GO 
CREATE VIEW ProdPorFabricanteDet AS
    SELECT m.manu_code, m.manu_name, pt.stock_num, pt.description 
    FROM manufact m 
        LEFT OUTER JOIN products p ON m.manu_code = p.manu_code 
        LEFT OUTER JOIN product_types pt ON p.stock_num = pt.stock_num
GO

-- Se pide: Crear un trigger que permita ante un DELETE en la vista ProdPorFabricante borrar los datos en la tabla manufact 
-- pero sólo de los fabricantes cuyo campo description sea NULO (o sea que no tienen stock).
-- Observaciones: El trigger deberá contemplar borrado de varias filas mediante un DELETE masivo.
-- En ese caso sólo borrará de la tabla los fabricantes que no tengan productos en stock, borrando los demás.

GO
    CREATE TRIGGER delFabric ON ProdPorFabricanteDet
    INSTEAD OF DELETE AS
    BEGIN
        DELETE FROM manufact 
        WHERE manu_code IN (SELECT manu_code FROM deleted WHERE description IS NULL)
    END
GO

-- 5.
-- Se pide crear un trigger que permita ante un delete de una sola fila en la vista ordenesPendientes valide:

-- Estructura de la vista: customer_num, fname, lname, Company, order_num, order_date WHERE paid_date IS NULL.

GO
    CREATE VIEW ordenesPendientes AS
        SELECT c.customer_num, fname, lname, company, o.order_num, order_date 
        FROM customer c 
            JOIN orders o ON c.customer_num=o.customer_num 
        WHERE paid_date IS NULL

-- Si el cliente asociado a la orden tiene sólo esa orden pendiente de pago (paid_date IS NULL), no permita realizar la Baja, informando el error.
-- Si la Orden tiene más de un ítem asociado, no permitir realizar la Baja, informando el error.
-- Ante cualquier otra condición borrar la Orden con sus ítems asociados, respetando la integridad referencial.

GO
    CREATE TRIGGER borrarOrden ON ordenesPendientes 
    INSTEAD OF DELETE AS 
    BEGIN 
        DECLARE @cantidadOrdenesPendientes INT 
        DECLARE @cantidadItems INT 
        
        SELECT @cantidadOrdenesPendientes = COUNT(o.order_num)
        FROM orders o 
            JOIN deleted d ON o.customer_num = d.customer_num AND o.paid_date IS NULL 
        
        SELECT @cantidadItems = COUNT(i.item_num)
        FROM items I 
            JOIN deleted d ON i.order_num = d.order_num 
            
        IF (@cantidadItems > 1)
            THROW 50001, 'Error: La Orden posee mas de un item', 1 
        
        IF(@cantidadOrdenesPendientes = 1) 
            THROW 50002,'Error: El cliente tiene solo 1 orden pendiente', 1 
        
        DELETE FROM items 
        WHERE order_num = (SELECT order_num FROM deleted) 
        
        DELETE FROM orders
        WHERE order_num = (SELECT order_num FROM deleted)
    END
GO
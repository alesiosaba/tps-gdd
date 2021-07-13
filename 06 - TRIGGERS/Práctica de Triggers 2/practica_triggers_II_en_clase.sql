-- 1. Se pide: Crear un trigger que valide que ante un insert de una o más filas en la tabla ítems, realice la siguiente validación:

-- Si la orden de compra a la que pertenecen los ítems ingresados corresponde a clientes del estado de California,
-- se deberá validar que estas órdenes puedan tener como máximo 5 registros en la tabla ítem.

-- Si se insertan más ítems de los definidos, el resto de los ítems se deberán insertar en la tabla items_error 
-- la cual contiene la misma estructura que la tabla ítems más un atributo fecha que deberá contener la fecha del día en que se trató de insertar.

-- Ej. Si la Orden de Compra tiene 3 items y se realiza un insert masivo de 3 ítems más, el trigger deberá insertar los 2 primeros en la tabla ítems
-- y el restante en la tabla ítems_error.
-- Supuesto: En el caso de un insert masivo los items son de la misma orden.

GO

create trigger Tr_temaA on items
instead of insert AS 
    BEGIN 
    
    declare @stock_num smallint, @order_num smallint, @item_num smallint, @quantity smallint
    declare @unit_price decimal(8,2) 
    declare @manu_code char(3),@state char(2)

    declare c_items cursor for 
        select i.item_num, i.order_num, stock_num, manu_code, quantity, unit_price, state 
        from inserted i 
            JOIN orders o ON (i.order_num=o.order_num)
            JOIN customer c ON (o.customer_num=c.customer_num); 
    
    open c_items
    
    fetch from c_items 
        into @item_num,@order_num,@stock_num,@manu_code, @quantity, @unit_price, @state

    while @@fetch_status=0 
    BEGIN 
        if @state='CA' 
            begin
                if (select COUNT(*) FROM items where order_num=@order_num) < 5 
                    begin
                    INSERT INTO items (i.item_num, i.order_num, stock_num, manu_code, quantity, unit_price) 
                    VALUES(@item_num,@order_num,@stock_num,@manu_code, @quantity,@unit_price)
                    end
                else
                    begin 
                    INSERT INTO items_error 
                    VALUES(@item_num, @order_num, @stock_num, @manu_code, @quantity, @unit_price, getDate())
                    end 
        end 
        else 
            begin
            INSERT INTO items 
            VALUES(@item_num, @order_num, @stock_num, @manu_code, @quantity, @unit_price) 
            end
    
    fetch from c_items 
    into @item_num, @order_num, @stock_num, @manu_code, @quantity, @unit_price, @state; 
    
    END 
    
    close c_items deallocate c_items 
END;

GO;

-- 2. Triggers Dada la siguiente vista

GO

CREATE VIEW ProdPorFabricante AS
    SELECT m.manu_code, m.manu_name, COUNT(*)
    FROM manufact m 
        INNER JOIN products p ON (m.manu_code = p.manu_code)
    GROUP BY manu_code, manu_name;

GO;

-- Crear un trigger que permita ante un insert en la vista ProdPorFabricante insertar una fila en la tabla manufact.
-- Observaciones: el atributo leadtime deberá insertarse con un valor default 10
-- El trigger deberá contemplar inserts de varias filas, por ej. ante un INSERT / SELECT.

GO

CREATE TRIGGER insFabric ON ProdPorFabricante 
INSTEAD OF INSERT AS
    BEGIN
    
    INSERT INTO manufact (manu_code, manu_name, lead_time) 
    select manu_code,manu_name,10 
    from inserted
END;

GO;


-- 3. Crear un trigger que ante un INSERT o UPDATE de una o más filas de la tabla Customer, realice la siguiente validación.

-- La cuota de clientes correspondientes al estado de California es de 20, 
--si se supera dicha cuota se deberán grabar el resto de los clientes en la tabla customer_pend.

-- Validar que si de los clientes a modificar se modifica el Estado, no se puede superar dicha cuota.

-- Si por ejemplo el estado de CA cuenta con 18 clientes y se realiza un update o insert masivo de 5 clientes con estado de CA,
-- el trigger deberá modificar los 2 primeros en la tabla customer y los restantes grabarlos en la tabla customer_pend.
-- La tabla customer_pend tendrá la misma estructura que la tabla customer con un atributo adicional fechaHora que deberá actualizarse con la fecha y hora del día.

GO

create trigger temaB on customer 
instead of insert, update AS
    BEGIN
    
    declare @customer_num smallint 
    declare @fname varchar(15), @lname varchar(15),@city varchar(15) 
    declare @company varchar(20),@address1 varchar(20), @address2 varchar(20) 
    declare @state char(2), @state_old char(2) declare @zipcode char(5) 
    declare @phone varchar(18) 
    
    declare c_call cursor
    for select i.*,d.state 
        from inserted I left join deleted d 
            on (i.customer_num=d.customer_num)
            
    open c_call 
    fetch from c_call 
    into @customer_num, @fname, @lname, @company, @address1, @address2, @city, @state, @zipcode, @phone, @state_old 
    
    while @@fetch_status=0
    BEGIN
        if @state='CA' and @state! = coalesce(@state_old, 'ZZ') 
        begin 
            if (select COUNT(*) FROM customer where state='CA') < 20 
            begin 
                UPDATE customer SET fname=@fname, lname=@lname, company=@company, adress1=@address1, address2=@address2, city=@city, state=@state, zipcode=@zipcode, phone=@phone WHERE customer_num=@customer_num; end else begin INSERT INTO customer_pend VALUES (@customer_num, @fname, @lname, @company, @address1, @address2, @city, @state, @zipcode, @phone, getDate()) end end else begin UPDATE customer SET fname=@fname, lname=@lname, company=@company, address1=@address1, address2=@address2, city=@city, state=@state, zipcode=@zipcode, phone=@phone WHERE customer_num=@customer_num 
            end 
            
            fetch NEXT from c_call into @customer_num, @fname, @lname, @company, @address1 ,@address2, @city, @state, @zipcode, @phone, @state_old
    END
    
    close c_call deallocate c_call
    
 END;

GO;

-- Pruebas

CREATE TABLE customer_updates_pend(
    customer_num smallint NOT NULL,
    fname varchar(15),
    lname varchar(15),
    company varchar(20),
    address1 varchar(20),
    address2 varchar(20),
    city varchar(15),
    state char(2),
    zipcode char(5),
    phone varchar(18),
    fecha datetime
);

select count(*) from customer
 where state = 'CA' 

select customer_num, state 
from customer where customer_num between 123 and 126 

update customer
    set state='CA'
    where customer_num between 122 and 126 select * from customer_updates_pend


-- 4. Dada la siguiente vista

GO 

CREATE VIEW ProdPorFabricanteDet AS
    SELECT m.manu_code, m.manu_name, pt.stock_num, pt.description 
    FROM manufact m 
        LEFT OUTER JOIN products p ON m.manu_code = p.manu_code 
        LEFT OUTER JOIN product_types pt ON p.stock_num = pt.stock_num;

GO;

-- Se pide: Crear un trigger que permita ante un DELETE en la vista ProdPorFabricante borrar los datos en la tabla manufact 
-- pero sólo de los fabricantes cuyo campo description sea NULO (o sea que no tienen stock).
-- Observaciones: El trigger deberá contemplar borrado de varias filas mediante un DELETE masivo.
-- En ese caso sólo borrará de la tabla los fabricantes que no tengan productos en stock, borrando los demás.

GO

CREATE TRIGGER delFabric ON ProdPorFabricanteDet 
INSTEAD OF DELETE AS
    BEGIN
    DELETE FROM manufact WHERE manu_code IN (select manu_code from deleted where description IS NULL)
END;

GO;


-- 5. Se pide crear un trigger que permita ante un delete de una sola fila en la vista ordenesPendientes valide:

    -- Si el cliente asociado a la orden tiene sólo esa orden pendiente de pago (paid_date IS NULL), no permita realizar la Baja, informando el error.

    -- Si la Orden tiene más de un ítem asociado, no permitir realizar la Baja, informando el error.

    -- Ante cualquier otra condición borrar la Orden con sus ítems asociados, respetando la integridad referencial.

-- Estructura de la vista: customer_num, fname, lname, Company, order_num, order_date WHERE paid_date IS NULL.

GO

CREATE VIEW ordenesPendientes AS
    SELECT c.customer_num, fname, lname, company, o.order_num, order_date 
    FROM customer c 
        JOIN orders o ON c.customer_num=o.customer_num 
    WHERE paid_date IS NULL;

GO;

GO

CREATE TRIGGER borrarOrden ON ordenesPendientes 
instead of delete AS
    BEGIN
    declare @cantidadOrdenesPendientes int 
    declare @cantidadItems int 
    
    select @cantidadOrdenesPendientes=COUNT(o.order_num) 
    from orders o
        JOIN deleted d ON o.customer_num = d.customer_num and o.paid_date is null 
        
    select @cantidadItems = COUNT(i.item_num) 
    from items I
    join deleted d on i.order_num = d.order_num 
    
    if(@cantidadItems > 1) 
        THROW 50001, 'Error: La Orden posee mas de un item', 1 
    
    if(@cantidadOrdenesPendientes = 1) 
        THROW 50002,'Error: El cliente tiene solo 1 orden pendiente', 1 
        
    delete from items where order_num=(select order_num from deleted) 
    
    delete from orders where order_num=(select order_num from deleted) 
END;

GO;

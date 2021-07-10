-- 1.
-- Dada la tabla Products de la base de datos stores7 se requiere crear una tabla Products_historia_precios
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


-- 2.
-- Crear un trigger sobre la tabla Products_historia_precios que ante un delete sobre la misma realice en su lugar un update
-- del campo estado de ‘A’ a ‘I’ (inactivo). 


-- 3. 
-- Validar que sólo se puedan hacer inserts en la tabla Products en un horario entre las 8:00 AM y 8:00 PM. En caso contrario enviar un error por pantalla.


-- 4.
-- Crear un trigger que ante un borrado sobre la tabla ORDERS realice un borrado en cascada sobre la tabla ITEMS,
-- validando que sólo se borre 1 orden de compra.
-- Si detecta que están queriendo borrar más de una orden de compra, informará un error y abortará la operación.


-- 5. 
-- Crear un trigger de insert sobre la tabla ítems que al detectar que el código de fabricante (manu_code) del producto a comprar no existe en la tabla manufact,
-- inserte una fila en dicha tabla con el manu_code ingresado, en el campo manu_name la descripción ‘Manu Orden 999’ donde 999 corresponde 
-- al nro. de la orden de compra a la que pertenece el ítem y en el campo lead_time el valor 1.


-- 6.
-- Crear tres triggers (Insert, Update y Delete) sobre la tabla Products para replicar todas las operaciones en la tabla Products _replica, la misma deberá tener la misma estructura de la tabla Products.

-- TRIGGER INSERT
-- TRIGGER DELETE
-- TRIGGER UPDATE


-- 7.
-- Crear la vista Productos_x_fabricante que tenga los siguientes atributos:

    -- Stock_num,
    -- description,
    -- manu_code,
    -- manu_name,
    -- unit_price

-- Crear un trigger de Insert sobre la vista anterior que ante un insert, inserte una fila en la tabla Products,
-- pero si el manu_code no existe en la tabla manufact, inserte además una fila en dicha tabla con el campo lead_time en 1.
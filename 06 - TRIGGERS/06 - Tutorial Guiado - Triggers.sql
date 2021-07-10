-- 1.
-- Crear la tabla audit_cust con la siguiente sentencia:
  
    CREATE TABLE audit_cust(
        id_audit INT Identity (1,1),
        customer_num INTEGER,
        operacion CHAR,
        usuario CHAR(20) DEFAULT suser_sname(),
        fechayhora DATETIME DEFAULT getdate(),
        PRIMARY KEY (id_audit)
    )

-- 2.
-- Crear un trigger de insert sobre la tabla customer, con la siguiente sentencia:
    
    GO
        CREATE TRIGGER cust_ins_1
        ON customer
        AFTER INSERT AS
        BEGIN
            INSERT INTO audit_cust(customer_num, operacion)
                SELECT customer_num,'I' FROM inserted
        END
    GO

-- 3.
-- Ejecutar la siguiente sentencia para insertar una fila en la tabla customer:

    INSERT INTO customer (customer_num, fname, lname)
    VALUES (1000, 'Mario' , 'Ledesma')

-- 4. Consultar la tabla audit_cust
-- a. Qué información observa dentro de ella?
 --b. Dada la acción insert que disparó el trigger, Cómo se actualizaron los campos id_audit, usuario y fechayhora?

-- 5.
-- Ejecutar la siguiente sentencia de inserción masiva
    
    INSERT INTO customer (customer_num, lname, fname)
    SELECT customer_num+1000, fname, lname
    FROM customer
    WHERE customer_num BETWEEN 100 AND 105

-- Esta sentencia vuelve a insertar en la tabla customer los mismos registros que esta contiene, pero sólo con los campos customer_num, fname y lname completos.
-- Qué observa en la tabla audit_cust?

-- 6.
-- En base a la sentencia de creación del trigger del punto 2, crear un trigger de DELETE con el nombre cust_del_1,
-- Tener en cuenta que para borrado se actualiza la tabla DELETED dentro del trigger
-- Modificar la acción INSERT del trigger a la tabla audit_cust, insertando los siguientes valores: VALUES (customer_num, ‘D’)

-- 7.
-- Realizar un DELETE sobre alguno de los registros insertados en el punto 5

    DELETE customer WHERE customer_num = 1000

-- 8.
-- Consultar la tabla audit_cust
-- Observa algún cambio en los registros que contiene?

-- 9. Realizar un borrado masivo de todas las filas de la tabla customer ejecutando la siguiente sentencia:
    
    DELETE FROM customer

-- El comando va a fallar en cuanto encuentre una fila que al querer borrar tenga referencias de claves foráneas en otras tablas (orders, cust_calls, etc.)
-- Qué pasó con los registros que efectivamente borró y las filas que insertó en audit_cust?

-- 10.
-- Consultar la tabla audit_cust
-- Observa algún cambio en los registros que contiene?

-- 11.
-- Crear un trigger de UPDATE que grabe dos filas en audit_cust
-- Tener en cuenta las tablas INSERTED y DELETED

    -- Crear dos acciones INSERT

    -- INSERT INTO audit_cust(customer_num, operacion)
        -- De la tabla INSERTED (customer_num, ‘N’)
    
    -- INSERT INTO audit_cust(customer_num, operacion)
        -- De la table DELETED (customer_num, ‘O’) )

-- 12.
-- Realizar un UPDATE sobre alguno de los registros insertados en el punto 5

-- 13.
-- Consultar la tabla audit_cust
-- Observa algún cambio en los registros que contiene?

-- 14.
-- Crear un trigger de delete “cust_del_1” para implementar el borrado en cascada de las siguientes tablas:

-- Orders -> Items

    -- Ejemplo para tomar como base:

    GO
    CREATE TRIGGER del_ordenes
    ON ordenes
    INSTEAD OF DELETE
    AS
    BEGIN
        DECLARE TrigDelCur CURSOR FOR
        SELECT * FROM deleted

        DECLARE @n_cliente, @c_estado, @n_orden, @f_orden
        
        OPEN TrigDelCur
        
        FETCH NEXT FROM TrigDelCur
            INTO @n_cliente, @c_estado, @n_orden, @f_orden
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            DELETE FROM items_ordenes
                WHERE n_orden = @n_orden;
            DELETE FROM ordenes
                WHERE n_orden = @n_orden;

            FETCH NEXT FROM TrigDelCur
                INTO @n_cliente, @c_estado, @n_orden, @f_orden
        END
        
        CLOSE TrigDelCur
        DEALLOCATE TrigDelCur
    END
    GO

-- 15.
-- Borrar una orden dentro de una transacción

    BEGIN TRANSACTION
    DELETE FROM orders WHERE order_num = 1004

-- 16.
-- Chequear las tablas orders y items. Se realizó la operación??

-- 17.
-- Ejecutar un ROLLBACK de la transacción. Chequear las tablas, que sucedió?

    ROLLBACK TRANSACTION

-- 18.
-- Abrir una nueva sesión y LOCKEAR EN MODO EXCLUSIVO LA TABLA cust_calls de la siguiente manera:

    BEGIN WORK;
    LOCK TABLE cust_calls IN EXCLUSIVE MODE;

-- 19.
-- En la sesión original, borrar un cliente de la tabla Customer sin transacción, explicar que sucedió con la ejecución?

    DELETE FROM customer WHERE customer_num = 103
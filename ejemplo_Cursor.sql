-- Estructura basica de un cursor

-- Declaración de variables necesarias
DECLARE @order_num SMALLINT
DECLARE @manu_code CHAR(3)

-- Declaración del cursor y especificacion de los valores que recorre
DECLARE cursor_items_ingresados CURSOR FOR
    SELECT order_num, manu_code
    FROM inserted

-- Apertura del cursor antes de ser recorrido
OPEN cursor_items_ingresados

-- Apuntamos al primer elemento del cursor
FETCH NEXT FROM cursor_items_ingresados
INTO @order_num, @manu_code

-- Comenzamos el ciclo para recorrer todos los elementos
WHILE @@FETCH_STATUS = 0 
BEGIN
    -- Ejemplo de uso de las variables contenidas en el vector
    IF NOT EXISTS (SELECT * FROM manufact WHERE manu_code = @manu_code)
    BEGIN
        INSERT INTO manufact (manu_code, manu_name, lead_time)
        VALUES(@manu_code, 'Manu Orden' + ' ' + CAST(@order_num AS VARCHAR(4)), 1)
    END

    -- Apuntamos al proximo elemento del cursor
    FETCH NEXT FROM cursor_items_ingresados
        INTO @order_num, @manu_code
END

-- Cerrar el cursor y liberar memoria cuando finaliza su uso 
CLOSE cursor_items_ingresados
DEALLOCATE cursor_items_ingresados


-----------------------------------------------------------------------------------------------
-- EJEMPLO DE ARTURO
-----------------------------------------------------------------------------------------------

DECLARE nombre_cursor CURSOR -- declaración, genera objeto en memoria (por sesion)

OPEN <nombre_cursor> -- abre la estructura en memoria para manejar el cursor

FETCH nombre_cursor INTO lista_variables -- trae las filas al buffer y les asigna a variables

WHILE (@@FETCH_STATUS = 0) -- analizo si obtuve una fila. @@ indica que es variable de sistema.
BEGIN
-- ...
FETCH nombre_cursor INTO lista_variables -- busco siguiente fila

CLOSE nombre_cursor -- elimina el buffer de memoria
DEALLOCATE nombre_cursor -- elimina lo allocado en el declare

-- Ejemplo
CREATE PROCEDURE guarder_items_tabla
@almacen INTEGER
AS
    DECLARE items_en_almacen CURSOR FOR
    
    SELECT id_item FROM item
    WHERE id_almacen = @almacen
    
    DECLARE @item_del_cursor INTEGER
    
    OPEN items_en_almacen
    
    FETCH items_en_almacen 
        INTO @item_del_cursor -- aridad debe coincidir con la del select
    
    WHILE (@@FETCH_STATUS = 0)
    BEGIN
        INSERT INTO ITEMS_AUX VALUES (@item_del_cursor)
        
        FETCH items_en_almacen 
            INTO @item_del_cursor -- busco siguiente item
    END
    
    CLOSE items_en_almacen
    DEALLOCATE items_en_almacen
    
END PROCEDURE
/*2.Query
Mostrar 
	el código y descripción del Estado,
	código y descripción del Tipo de Producto 
	y la cantidad de unidades vendidas 
	
	de aquellos tipos de productos más vendidos (por cantidad) en cada Estado. 

Si hubiese más de un tipo de producto en un mismo estado 
con la misma cantidad de unidades vendidas máxima, 
informarlos a todos.

Mostrar el resultado ordenado por cantidad total vendida en orden descendente y,
en caso que las cantidades de varios productos sean iguales,
por la Descripción del Estado en forma ascendente, 
si los productos con cantidades iguales son del mismo estado, 
ordenar además por descripción del tipo de producto en forma ascendente.
*/



------------------------------------------------------------------


/*3.Store Procedure
Desarrollar un stored procedure que realice la inserción o modificación de un producto determinado.

Parámetros de Entrada STOCK_NUM, MANU_CODE, UNIT_PRICE, UNIT_CODE, DESCRIPTION
Previamente a realizar alguna operación validar:
EXISTENCIA de MANU_CODE en Tabla MANUFACT - Informando Error por Fabricante Inexistente.
EXISTENCIA del atributo  UNIT_CODE en la Tabla UNITS - Informando Error por Código de Unidad Inexistente
EXISTENCIA en Tabla PRODUCT_TYPES – 
	Si no existe INSERTAR Registro en la tabla PRODUCT_TYPES
	Sino realizar el UPDATE del atributo ‘description’.

 Una vez validados los parámetros: 
 Si el producto no existe, insertarlo. 
 En caso que ya exista, actualizar los atributos no clave.
 */

GO
CREATE PROCEDURE punto3 @stock_num SMALLINT, @manu_code CHAR(3), @unit_price DECIMAL, @unit_code SMALLINT, @description VARCHAR(15)
AS
BEGIN 
	BEGIN TRY
		BEGIN TRANSACTION
			-- Previamente a realizar alguna operación validar:
			
			-- EXISTENCIA de MANU_CODE en Tabla MANUFACT - Informando Error por Fabricante Inexistente.
			IF NOT EXISTS(SELECT 1 FROM manufact WHERE manu_code = @manu_code)
				THROW 50000, 'Fabricante Inexistente' , 1

			-- EXISTENCIA del atributo  UNIT_CODE en la Tabla UNITS - Informando Error por Código de Unidad Inexistente
			IF NOT EXISTS(SELECT 1 FROM units WHERE unit_code = @unit_code)
				THROW 50001, 'Fabricante Inexistente' , 1
			
			-- EXISTENCIA en Tabla PRODUCT_TYPES – 
				-- Si no existe INSERTAR Registro en la tabla PRODUCT_TYPES
				-- Sino realizar el UPDATE del atributo ‘description’.
			IF NOT EXISTS(SELECT 1 FROM product_types WHERE stock_num = @stock_num)
				INSERT INTO product_types(stock_num, description)
				VALUES(@stock_num, @description)
			ELSE
				UPDATE product_types
					SET description = @description
					WHERE stock_num = @stock_num

			-- Una vez validados los parámetros: 
				-- Si el producto no existe, insertarlo. 
				-- En caso que ya exista, actualizar los atributos no clave.

			IF NOT EXISTS(SELECT 1 FROM products WHERE stock_num = @stock_num AND manu_code = @manu_code)
				INSERT INTO products(stock_num, manu_code, unit_price, unit_code)
				VALUES(@stock_num, @manu_code, @unit_price, @unit_code)
			ELSE 
				UPDATE products
					SET unit_price = @unit_price, unit_code = @unit_code
					WHERE stock_num = @stock_num AND manu_code = @manu_code

		COMMIT TRANSACTION
	END TRY

	BEGIN CATCH
		ROLLBACK TRANSACTION
	END CATCH
END


/*
4.Trigger
Dada la vista:
      CREATE VIEW OrdenItems AS 
      SELECT o.order_num, o.order_date, o.customer_num, o.paid_date, 
   i.item_num, i.stock_num, i.manu_code, i.quantity, i.unit_price 
        FROM orders o JOIN items i ON o.order_num = i.order_num;

Se desea manejar las operaciones de ALTA sobre la vista anterior.

Los controles a realizar son los siguientes:
	a.No se permitirá que una Orden contenga ítems de fabricantes de más de dos estados en la misma orden.
	b.Por otro parte los Clientes del estado de ALASKA no podrán realizar compras a fabricantes fuera de ALASKA.
Notas:
	 Las altas son de una misma Orden y de un mismo Cliente pero pueden venir varias líneas de ítems en una ORDEN.
	 Ante el incumplimiento de una validación, deshacer TODA la transacción y finalizar la ejecución.
*/

GO
CREATE VIEW OrdenItems AS 
	SELECT 
		o.order_num,
		o.order_date,
		o.customer_num,
		o.paid_date, 
		i.item_num,
		i.stock_num,
		i.manu_code,
		i.quantity,
		i.unit_price 
FROM orders o
	JOIN items i ON o.order_num = i.order_num

GO
CREATE TRIGGER insert_OrdenItems ON OrdenItems
INSTEAD OF INSERT AS
BEGIN

	BEGIN TRY 
		
		BEGIN TRANSACTION

		DECLARE @order_num SMALLINT, @order_date DATETIME, @customer_num SMALLINT, @paid_date DATETIME, @item_num SMALLINT, @stock_num SMALLINT, @manu_code CHAR(3), @quantity SMALLINT, @unit_price DECIMAL

		DECLARE cursor_inserted CURSOR FOR
		SELECT order_num, order_date, customer_num, paid_date, item_num, stock_num, manu_code, quantity, unit_price 
		FROM inserted

		OPEN cursor_inserted

		FETCH NEXT FROM cursor_inserted
		INTO @order_num, @order_date, @customer_num, @paid_date, @item_num, @stock_num, @manu_code, @quantity, @unit_price

		WHILE @@FETCH_STATUS = 0
		BEGIN 

			-- Los controles a realizar son los siguientes:

			-- a.No se permitirá que una Orden contenga ítems de fabricantes de más de dos estados en la misma orden.


			IF( (SELECT COUNT(DISTINCT m.state) FROM items i JOIN manufact m ON m.manu_code = i.manu_code WHERE order_num = @order_num) > 2)
				THROW 50000, 'Una orden no puede contener ítems de fabricantes de más de dos estados en la misma orden' , 1
			
			-- b.Por otro parte los Clientes del estado de ALASKA no podrán realizar compras a fabricantes fuera de ALASKA.
			IF ( (SELECT state FROM customer WHERE customer_num = @customer_num) = 'AK' AND EXISTS( SELECT 1 FROM manufact WHERE manu_code = @manu_code AND state != 'AK') )
				THROW 50000, 'Los Clientes del estado de ALASKA no podrán realizar compras a fabricantes fuera de ALASKA' , 1

			INSERT INTO OrdenItems(order_num, order_date, customer_num, paid_date, item_num, stock_num, manu_code, quantity, unit_price)
			VALUES(@order_num, @order_date, @customer_num, @paid_date, @item_num, @stock_num, @manu_code, @quantity, @unit_price)


			FETCH NEXT FROM cursor_inserted
			INTO @order_num, @order_date, @customer_num, @paid_date, @item_num, @stock_num, @manu_code, @quantity, @unit_price

		END

		COMMIT TRANSACTION
	END TRY

	BEGIN CATCH
		ROLLBACK TRANSACTION
	END CATCH

	CLOSE cursor_inserted
	DEALLOCATE cursor_inserted
	
	
END

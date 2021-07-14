/* EJERCICIO 4 - STORED PROCEDURE
Crear un procedimiento que reciba como parámetro una FECHA.
Este deberá guardar en la tabla VENTASxMES el Monto total y cantidad total de productos vendidos para el Año 
y mes (yyyymm) de la fecha ingresada con la siguiente particularidad.

Asuma que existen 3 tipos de unidades de productos y las cantidades deberán ser “ajustadas” según su tipo:
   1 unid (queda igual)
   2 par (multiplicar por 2)
   3 doc (multiplicar por 12)

Tabla VENTASxMES
    anioMes       decimal(6)
    stock_num   smallint
    manu_code  char(3)
    Cantidad      int
    Monto           decimal(10,2)

El procedimiento debe manejar TODO el proceso en una transacción y deshacer todo en caso de error.
*/

DROP TABLE VENTASXMES
CREATE TABLE VENTASxMES(
    anioMes decimal(6),
    stock_num smallint,
    manu_code char(3),
    Cantidad int,
    Monto decimal(10,2)
);
GO

DROP PROCEDURE llenadoVentasPorMes
GO

CREATE PROCEDURE llenadoVentasPorMes @fechaEjecucion DATETIME AS
BEGIN
	-- declaración de variables
	DECLARE @unit char(4), @stock_num smallint, @manu_code char(3), @cantidad int, @montoTotal decimal(10,2),@cantidadResultante int; 

	-- declaración de cursor
	DECLARE ventaCursor
	CURSOR FOR
		SELECT u.unit, p.stock_num, p.manu_code, sum(i.quantity) cantidad, sum (i.quantity * i.unit_price) montoTotal 
		FROM orders o
			left join items i ON  (o.order_num = i.order_num)
			left join products p ON (i.stock_num = p.stock_num AND i.manu_code= p.manu_code)
			left join units u ON (u.unit_code = i.unit_price)
		WHERE YEAR(o.order_date) = YEAR(@fechaEjecucion) AND
			MONTH(o.order_date) = MONTH(@fechaEjecucion)
		GROUP BY u.unit, p.stock_num, p.manu_code
	
	-- apertura de cursor
	OPEN ventaCursor
	FETCH NEXT FROM ventaCursor INTO @unit, @stock_num, @manu_code , @cantidad , @montoTotal;
	
	
	BEGIN TRY
		BEGIN TRANSACTION
			WHILE @@FETCH_STATUS = 0
			BEGIN 
				IF @unit NOT IN ('unid', 'par', 'doc') throw 50000, 'Unidad errónea', 2

				SET @cantidadResultante = CASE @unit
					WHEN 'unid' THEN @cantidad
					WHEN 'par' THEN @cantidad * 2
					WHEN 'doc' THEN @cantidad * 12
				END

				INSERT INTO VENTASxMES (anioMes, stock_num, manu_code, Cantidad, Monto)
				VALUES(Year(@fechaEjecucion)*100 + MONTH(@fechaEjecucion),
					@stock_num, @manu_code, @cantidadResultante, @montoTotal)
				
				FETCH NEXT FROM ventaCursor INTO @unit, @stock_num, @manu_code , @cantidad , @montoTotal;
			END
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
	END CATCH

	-- cierre de cursor
	CLOSE ventaCursor
	DEALLOCATE ventaCursor
END
GO
USE stores7new;

-- Query

SELECT
    c1.lname AS Referido_Apellido,
    c1.fname AS Referido_Nombre,
	(SELECT SUM(i2.quantity * i2.unit_price) / COUNT(DISTINCT o2.order_num) 
		FROM items i2 JOIN orders o2 ON (o2.order_num = i2.order_num)
		WHERE o2.customer_num =  c1.customer_num ) AS Promedio_Referido,
	referente.lname AS Referente_Apellido,
    referente.fname AS Referente_Nombre,
	referente.Promedio_Referente
FROM customer c1
    JOIN orders o1 ON (o1.customer_num = c1.customer_num)
	JOIN items i1 ON (i1.order_num = o1.order_num)
	
	JOIN (SELECT 
			c2.customer_num,
			lname,
			fname,
			SUM(i3.quantity * i3.unit_price) / COUNT(DISTINCT o3.order_num) AS Promedio_Referente
			FROM customer c2
				JOIN orders o3 ON (o3.customer_num = c2.customer_num) 
				JOIN items i3 ON (i3.order_num = o3.order_num)
			GROUP BY c2.customer_num, lname, fname
			) referente ON (referente.customer_num = c1.customer_num_referedBy)

GROUP BY c1.lname, c1.fname, referente.lname, referente.fname, referente.Promedio_Referente
	HAVING 
		(SELECT SUM(i2.quantity * i2.unit_price) / COUNT(DISTINCT o2.order_num) 
		FROM items i2 JOIN orders o2 ON (o2.order_num = i2.order_num)
		WHERE o2.customer_num =  c1.customer_num )
		>
		referente.Promedio_Referente
ORDER BY c1.lname, c1.fname		




---- Stored Procedure

CREATE TABLE audit_fabricante(
	nro_audit BIGINT IDENTITY PRIMARY KEY,
	fecha DATETIME DEFAULT getDate(),
	accion CHAR(1) CHECK (accion IN ('I','O','N','D')),
	manu_code char(3),
	manu_name varchar(30),
	lead_time smallint,
	state char(2),
	usuario VARCHAR(20) DEFAULT USER,
)

GO
CREATE PROCEDURE deshacer_operaciones @fechaLimite DATETIME
AS
BEGIN
BEGIN TRY
	DECLARE @nro_audit BIGINT 
	DECLARE @fecha DATETIME
	DECLARE @accion CHAR(1)
	DECLARE @manu_code CHAR(3)
	DECLARE @manu_name VARCHAR(30)
	DECLARE @lead_time SMALLINT
	DECLARE @state CHAR(2)
	DECLARE @usuario VARCHAR(20)
		
	DECLARE cursor_audit CURSOR FOR
		SELECT nro_audit, fecha, accion, manu_code, manu_name, lead_time, state, usuario
		FROM audit_fabricante
		WHERE fecha < @fechaLimite
		
	OPEN cursor_audit

	FETCH NEXT FROM cursor_audit
		INTO @nro_audit, @fecha, @accion, @manu_code, @manu_name, @lead_time, @state, @usuario
			
	BEGIN TRANSACTION
		
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF(@accion = 'I')
			DELETE FROM manufact
			WHERE manu_code = @manu_code

		ELSE IF(@accion = 'D')
			INSERT INTO manufact (manu_code, manu_name, lead_time, state, f_alta_audit, d_usualta_audit)
			VALUES (@manu_code, @manu_name, @lead_time, @state, @fecha, @usuario)

		ELSE IF (@accion = 'N')
			UPDATE manufact
			SET 
				manu_code = (SELECT manu_code FROM audit_fabricante WHERE nro_audit = @nro_audit AND accion = 'O'),
				manu_name = (SELECT manu_name FROM audit_fabricante WHERE nro_audit = @nro_audit AND accion = 'O'),
				lead_time = (SELECT lead_time FROM audit_fabricante WHERE nro_audit = @nro_audit AND accion = 'O'),
				state = (SELECT state FROM audit_fabricante WHERE nro_audit = @nro_audit AND accion = 'O'),
				f_alta_audit = (SELECT f_alta_audit FROM audit_fabricante WHERE nro_audit = @nro_audit AND accion = 'O'),
				d_usualta_audit = (SELECT d_usualta_audit FROM audit_fabricante WHERE nro_audit = @nro_audit AND accion = 'O')
			WHERE manu_code = @manu_code
	END

	COMMIT TRANSACTION


END TRY
BEGIN CATCH
	RAISERROR('Error al deshacer operaciones de fabricantes.', 14, 1)
	ROLLBACK TRANSACTION
END CATCH

CLOSE cursor_audit
DEALLOCATE cursor_audit
END
GO

-- Trigger

GO
CREATE TRIGGER borrado_de_OC ON orders
INSTEAD OF DELETE
AS 
BEGIN
BEGIN TRY
DECLARE @order_num SMALLINT
DECLARE @customer_num SMALLINT
DECLARE @user VARCHAR(15) = SUSER_SNAME()
DECLARE @fecha DATETIME = GETDATE()

DECLARE cursor_borrado_logico CURSOR FOR
		SELECT order_num, customer_num
		FROM deleted
		
OPEN cursor_borrado_logico

FETCH NEXT FROM cursor_borrado_logico
	INTO @order_num, @customer_num

WHILE @@FETCH_STATUS = 0
BEGIN
	IF(SELECT COUNT(DISTINCT order_num) FROM orders WHERE customer_num = @customer_num) < 5
		UPDATE orders
		SET 
			flag_baja = 1,
			fecha_baja = @fecha,
			user_baja = @user
		WHERE order_num = @order_num
	ELSE 
		INSERT INTO BorradosFallidos (customer_num, order_num, fecha_baja, user_baja)
		VALUES (@customer_num, @order_num, @fecha, @user)

	FETCH NEXT FROM cursor_borrado_logico
		INTO @order_num, @customer_num
END
	   
END TRY
BEGIN CATCH
	RAISERROR('Ocurri� un error al realizar el borrado l�gico.', 14, 1)
END CATCH

CLOSE cursor_borrado_logico
DEALLOCATE cursor_borrado_logico
END
GO


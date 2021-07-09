/*
Práctica - Clase 4
14. Crear una consulta que liste todos los clientes que vivan en California ordenados por compañía.
15. Obtener un listado de la cantidad de productos únicos comprados a cada fabricante, en donde el total comprado a cada fabricante sea mayor a 1500. El listado deberá estar ordenado por cantidad de productos comprados de mayor a menor.
16. Obtener un listado con el código de fabricante, nro de producto, la cantidad vendida (quantity), y el total vendido (quantity x unit_price), para los fabricantes cuyo código tiene una “R” como segunda letra. Ordenar el listado por código de fabricante y nro de producto.
17. Crear una tabla temporal OrdenesTemp que contenga las siguientes columnas: cantidad de órdenes por cada cliente, primera y última fecha de orden de compra (order_date) del cliente. Realizar una consulta de la tabla temp OrdenesTemp en donde la primer fecha de compra sea anterior a '2015-05-23 00:00:00.000', ordenada por fechaUltimaCompra en forma descendente.
18. Consultar la tabla temporal del punto anterior y obtener la cantidad de clientes con igual cantidad de compras. Ordenar el listado por cantidad de compras en orden descendente
19. Desconectarse de la sesión. Volver a conectarse y ejecutar SELECT * from #ordenesTemp. Que sucede?
20. Se desea obtener la cantidad de clientes por cada state y city, donde los clientes contengan el string
‘ts’ en el nombre de compañía, el código postal este entre 93000 y 94100 y la ciudad no sea 'Mountain View'. Se desea el listado ordenado por ciudad
21. Para cada estado, obtener la cantidad de clientes referidos. Mostrar sólo los clientes que hayan sido referidos cuya compañía empiece con una letra que este en el rango de ‘A’ a ‘L’.
22. Se desea obtener el promedio de lead_time por cada estado, donde los Fabricantes tengan una ‘e’ en manu_name y el lead_time sea entre 5 y 20.
23. Se tiene la tabla units, de la cual se quiere saber la cantidad de unidades que hay por cada tipo (unit) que no tengan en nulo el descr_unit, y además se deben mostrar solamente los que cumplan que la cantidad mostrada se superior a 5. Al resultado final se le debe sumar 1
*/

-- Práctica de INSERT, UPDATE y DELETE.

USE stores7new;

-- 1. Crear una tabla temporal #clientes a partir de la siguiente consulta:
--SELECT * FROM customer

SELECT *
    INTO #clientes
FROM customer

SELECT * FROM #clientes

-- 2. Insertar el siguiente cliente en la tabla #clientes
/* 
Customer_num 144
Fname Agustín
Lname Creevy
Company Jaguares SA
State CA
City Los Angeles
*/

INSERT INTO #clientes 
	(Customer_num, Fname, Lname, Company, State, City)
VALUES
	(144,'Agustín','Creevy','Jaguares SA','CA','Los Angeles')

SELECT * FROM #clientes WHERE Customer_num = 144

-- 3. Crear una tabla temporal #clientesCalifornia con la misma estructura de la tabla customer.
-- Realizar un insert masivo en la tabla #clientesCalifornia con todos los clientes de la tabla customer cuyo state sea CA.

SELECT *
    INTO #clientesCalifornia
FROM customer
WHERE State = 'CA'

SELECT * FROM #clientesCalifornia 

-- 4. Insertar el siguiente cliente en la tabla #clientes un cliente que tenga los mismos datos del cliente 103,
-- pero cambiando en customer_num por 155
-- Valide lo insertado.

INSERT INTO #clientes
(customer_num,fname, lname, company,address1,address2,city,state,zipcode,phone,customer_num_referedBy,status)
    SELECT
        155, fname, lname, company,address1,address2,city,state,zipcode,phone,customer_num_referedBy,status
    FROM customer
    WHERE customer_num = 103

SELECT * FROM #clientes


-- 5. Borrar de la tabla #clientes los clientes cuyo campo zipcode esté entre 94000 y 94050 y la ciudad comience con ‘M’.
-- Validar los registros a borrar antes de ejecutar la acción.

DELETE FROM #clientes 
WHERE (zipcode BETWEEN 94000 AND 94050) AND (city LIKE 'M%') 

SELECT * FROM #clientes

-- 6. Borrar de la tabla #clientes todos los clientes que no posean órdenes de compra en la tabla orders. (Utilizar un subquery).
DELETE FROM #clientes 
WHERE customer_num NOT IN (SELECT DISTINCT customer_num FROM orders)

SELECT * FROM #clientes

-- 7. Modificar los registros de la tabla #clientes cambiando el campo state por ‘AK’ y el campo address2 por ‘Barrio Las Heras’
-- para los clientes que vivan en el state 'CO'. Validar previamente la cantidad de registros a modificar.


-- 8. Modificar todos los clientes de la tabla #clientes, agregando un dígito 1 delante de cada número telefónico, debido a un cambio de la compañía de teléfonos.


-- 9. Comenzar una transacción, dentro de ella realizar:

    -- a. Insertar un registro en la tabla #clientes con los siguientes 4 datos


        -- i. Customer_num 166


        -- ii. Lname apellido


        -- iii. State CA


        -- iv. Company nombre empresa


    -- b. Borrar los registros de la tabla #clientesCalifornia


-- Consultar los datos de las tablas #clientes y #clientesCalifornia, y asegurarse de que se haya realizado las operaciones.


-- Realizar un ROLLBACK y volver a chequear la información, que pasó??


-- 10. Ejecutar la misma transacción del punto 9.


-- Realizar un COMMIT y volver a chequear la información, que pasó??

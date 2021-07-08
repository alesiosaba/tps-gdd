-- 1. Listar Número de Cliente, apellido y nombre, Total Comprado por el cliente ‘Total del Cliente’,
-- Cantidad de Órdenes de Compra del cliente ‘OCs del Cliente’ y la Cant. de Órdenes de Compra solicitadas 
-- por todos los clientes ‘Cant. Total OC’, de todos aquellos clientes cuyo promedio de compra por Orden 
-- supere al promedio de órdenes de compra general, tengan al menos 2 órdenes y cuyo zipcode comience con 94.

SELECT
    c.customer_num,
    fname,
    lname,
    SUM(unit_price*quantity) AS 'Total del Cliente',
    COUNT(DISTINCT i.order_num) AS 'OCs del Cliente',
    (SELECT COUNT(o2.order_num) FROM orders o2) AS 'Cant Total OC' 
FROM customer c 
    JOIN orders o ON (c.customer_num = o.customer_num) 
    JOIN items i ON (o.order_num = i.order_num) 
WHERE zipcode LIKE '94%'
GROUP by c.customer_num, fname, lname 
HAVING 
        (SUM(unit_price*quantity) / COUNT(DISTINCT i.order_num)) 
            > 
        (SELECT (SUM(unit_price*quantity) / COUNT(DISTINCT i3.order_num)) FROM items i3) 
    AND 
        COUNT(DISTINCT i.order_num) >=2

-- 2.a Se requiere crear una tabla temporal #ABC_Productos un ABC de Productos ordenado por cantidad de venta en u$, los datos solicitados son:
-- Nro. de Stock, Código de fabricante, descripción del producto, Nombre de Fabricante, Total del producto pedido 'u$ por Producto', 
-- Cant. de producto pedido 'Unid. por Producto', para los productos que pertenezcan a fabricantes que fabriquen
-- al menos 10 productos diferentes.

-- 2.a.1 
SELECT
    i.stock_num,
    i.manu_code,
    description,
    manu_name,
    SUM(unit_price*quantity) 'u$ por Producto',
    SUM(quantity) 'Unid. por Producto'
INTO #ABC_Productos
FROM items i 
    JOIN manufact m ON (i.manu_code = m.manu_code) 
    JOIN product_types s ON (i.stock_num = s.stock_num) 
WHERE 
    i.manu_code IN (SELECT s2.manu_code FROM products s2 GROUP BY s2.manu_code HAVING COUNT(*) >= 10) 
GROUP BY i.stock_num, i.manu_code, description, manu_name

-- 2.a.2 
SELECT 
    i.stock_num,
    i.manu_code,
    description,
    manu_name,
    SUM(unit_price*quantity) 'u$ por Producto',
    SUM(quantity) 'Unid. por Producto'
INTO #ABC_Productos 
FROM items i
    JOIN manufact m ON (i.manu_code = m.manu_code)
    JOIN product_types s ON (i.stock_num = s.stock_num) 
    JOIN (SELECT s2.manu_code FROM products s2 GROUP BY s2.manu_code HAVING COUNT(*) >= 10) s3 
        ON (i.manu_code=s3.manu_code) 
GROUP BY i.stock_num, i.manu_code, description, manu_name

-- 2.b Listar los datos generados en la tablas #ABC_Productos ordenados en forma descendente por 'u$ por Producto'
-- y en forma ascendente por stock_num y manu_code.

SELECT * FROM #ABC_Productos order by 'u$ por producto' desc, stock_num, manu_code


-- 3. En función a la tabla temporal generada en el punto 2, obtener un listado que detalle para cada tipo de producto existente
-- en #ABC_Producto, la descripción del producto, el mes en el que fue solicitado,
-- el cliente que lo solicitó (en formato 'Apellido, Nombre'), la cantidad de órdenes de compra 'Cant OC por mes',
-- la cantidad del producto solicitado 'Unid Producto por mes' y el total en u$ solicitado 'u$ Producto por mes'.

-- Mostrar sólo aquellos clientes que vivan en el estado con mayor cantidad de clientes, ordenado por mes 
-- y descripción del tipo de producto en forma ascendente y por cantidad de productos por mes en forma descendente.

SELECT 
    description,
    MONTH(order_date) 'Mes',
    lname + ', ' + fname 'Apellido y Nombre',
    COUNT(DISTINCT i.order_num) 'Cant OC por mes',
    SUM(quantity) 'Unid Producto x mes', 
    SUM(unit_price) 'u$ Producto x mes' 
FROM orders o 
    JOIN customer c ON (o.customer_num=c.customer_num) 
    JOIN items i ON (o.order_num = i.order_num) 
    JOIN #ABC_Productos ABC ON (i.stock_num = ABC.stock_num AND i.manu_code = ABC.manu_code) 
WHERE 
    state = (SELECT TOP 1 state
             FROM customer 
             GROUP BY state 
             ORDER BY COUNT(customer_num) DESC) 
GROUP BY description, MONTH(order_date), lname, fname 
ORDER BY MONTH(order_date), description, SUM(quantity) DESC


-- 4. Dado los productos con nro de stock 5, 6 y 9 del fabricante 'ANZ' listar de a pares los clientes que hayan solicitado 
-- el mismo producto, siempre y cuando, el primer cliente haya solicitado más cantidad del producto que el 2do cliente.
-- Se deberá informar nro de stock, código de fabricante, Nro de Cliente y Apellido del primer cliente,
-- Nro de cliente y apellido del 2do cliente ordenado por stock_num y manu_code

-- SOLUCION CON GROUP BY (innecesario?)

SELECT
    i1.stock_num,
    i1.manu_code, 
    c1.customer_num, 
    c1.lname, 
    c2.customer_num, 
    c2.lname 
FROM items i1 
    JOIN orders o1 ON (o1.order_num = i1.order_num) 
    JOIN customer c1 ON (o1.customer_num = c1.customer_num) 
    JOIN items i2 ON (i1.stock_num = i2.stock_num AND i1.manu_code = i2.manu_code) 
    JOIN orders o2 ON (o2.order_num = i2.order_num) 
    JOIN customer c2 ON (o2.customer_num = c2.customer_num) -- AND c1.customer_num != c2.customer_num) 
WHERE 
    i1.stock_num IN (5,6,9) 
    AND 
    i1.manu_code = 'ANZ' 
    AND 
        (SELECT SUM(quantity) 
            FROM items i11 
            JOIN orders o11 ON (i11.order_num = o11.order_num) 
        WHERE i11.stock_num = i1.stock_num AND i11.manu_code = i1.manu_code AND o11.customer_num = c1.customer_num) 
        > 
        (SELECT SUM(quantity) 
            FROM items i12 
            JOIN orders o12 ON (i12.order_num=o12.order_num) 
            WHERE i12.stock_num = i2.stock_num AND i12.manu_code = i2.manu_code AND o12.customer_num = c2.customer_num) 
GROUP BY 
	i1.stock_num,
    i1.manu_code, 
    c1.customer_num, 
    c1.lname, 
    c2.customer_num, 
    c2.lname 
ORDER BY i1.stock_num, i1.manu_code

-- SOLUCION CON DISTINCT (no terminamos de entender la funcion de DISTINCT)

SELECT
    DISTINCT i1.stock_num,
    i1.manu_code, 
    c1.customer_num, 
    c1.lname, 
    c2.customer_num, 
    c2.lname 
FROM items i1 
    JOIN orders o1 ON (o1.order_num = i1.order_num) 
    JOIN customer c1 ON (o1.customer_num = c1.customer_num) 
    JOIN items i2 ON (i1.stock_num = i2.stock_num AND i1.manu_code = i2.manu_code) 
    JOIN orders o2 ON (o2.order_num = i2.order_num) 
    JOIN customer c2 ON (o2.customer_num = c2.customer_num) -- AND c1.customer_num != c2.customer_num) 
WHERE 
    i1.stock_num IN (5,6,9) 
    AND 
    i1.manu_code = 'ANZ' 
    AND 
        (SELECT SUM(quantity) 
            FROM items i11 
            JOIN orders o11 ON (i11.order_num = o11.order_num) 
        WHERE i11.stock_num = i1.stock_num AND i11.manu_code = i1.manu_code AND o11.customer_num = c1.customer_num) 
        > 
        (SELECT SUM(quantity) 
            FROM items i12 
            JOIN orders o12 ON (i12.order_num=o12.order_num) 
            WHERE i12.stock_num = i2.stock_num AND i12.manu_code = i2.manu_code AND o12.customer_num = c2.customer_num) 
ORDER BY i1.stock_num, i1.manu_code


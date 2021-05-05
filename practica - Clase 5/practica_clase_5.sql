USE stores7new;

-- 1. Obtener el número de cliente, la compañía, y número de orden de todos los clientes que tengan órdenes. Ordenar el resultado por número de cliente.
SELECT  
    c.customer_num,
    company,
    order_num 
FROM customer c JOIN orders o ON (c.customer_num = o.customer_num)
ORDER BY c.customer_num

-- 2. Listar los ítems de la orden número 1004, incluyendo una descripción de cada uno. 
-- El listado debe contener: Número de orden (order_num), Número de Item (item_num), Descripción del producto (product_types.description),
-- Código del fabricante (manu_code), Cantidad (quantity), Precio total (unit_price*quantity).
SELECT
    order_num,
    item_num,
    p.description,
    manu_code,
    quantity,
    (unit_price*quantity) AS total_price
FROM items i JOIN product_types p ON (i.stock_num = p.stock_num)
WHERE order_num = 1004

-- 3. Listar los items de la orden número 1004, incluyendo una descripción de cada uno. 
-- El listado debe contener: Número de orden (order_num), Número de Item (item_num), Descripción del Producto (product_types.description),
-- Código del fabricante (manu_code), Cantidad (quantity), precio total (unit_price*quantity) y Nombre del fabricante (manu_name).
SELECT
    order_num,
    item_num,
    p.description,
    m.manu_code,
    m.manu_name,
    quantity,
    (unit_price*quantity) AS total_price
FROM items i 
        JOIN product_types p ON (i.stock_num = p.stock_num)
        JOIN manufact m ON (i.manu_code = m.manu_code)
WHERE order_num = 1004

-- 4. Se desea listar todos los clientes que posean órdenes de compra.
-- Los datos a listar son los siguientes: número de orden, número de cliente, nombre, apellido y compañía.
SELECT  
    order_num, 
    c.customer_num,
    fname,
    lname,
    company
FROM customer c JOIN orders o ON (c.customer_num = o.customer_num)

-- 5. Se desea listar todos los clientes que posean órdenes de compra.
-- Los datos a listar son los siguientes: número de cliente, nombre, apellido y compañía. Se requiere sólo una fila por cliente.
SELECT  
	DISTINCT c.customer_num,
    order_num, 
    fname,
    lname,
    company
FROM customer c JOIN orders o ON (c.customer_num = o.customer_num)
ORDER BY customer_num

-- 6. Se requiere listar para armar una nueva lista de precios de los productos los siguientes datos: nombre del fabricante (manu_name), número de stock (stock_num), 
-- descripción (product_types.description), unidad (units.unit), precio unitario (unit_price) y Precio Junio (precio unitario + 20%).
SELECT 
    manu_name,
    stock_num,
    pt.description,
    u.unit,
    unit_price,
 -- (precio unitario + 20%)
    (1.2 * unit_price) AS precio_junio
FROM products p JOIN product_types pt ON (p.stock_num = pt.stock_num)
                JOIN manufact m ON (p.manu_code = m.manu_code)
                JOIN units u ON (p.unit_code = u.unit_code)
    

--7. Se requiere un listado de los items de la orden de pedido Nro. 1004 con los siguientes datos:
-- Número de item (item_num), descripción de cada producto (product_types.description), cantidad (quantity) y precio total (unit_price*quantity).
SELECT
    item_num,
    p.description,
    quantity,
    (unit_price*quantity) AS total_price
FROM items i JOIN product_types p ON (i.stock_num = p.stock_num)
WHERE order_num = 1004

--8. Informar el nombre del fabricante (manu_name) y el tiempo de envío (lead_time) de los ítems de las Órdenes del cliente 104.


--9. Se requiere un listado de las todas las órdenes de pedido con los siguientes datos: Número de orden (order_num), fecha de la orden (order_date), número de ítem (item_num), descripción de cada producto (description), cantidad (quantity) y precio total (unit_price*quantity).


--10. Obtener un listado con la siguiente información: Apellido (lname) y Nombre (fname) del Cliente separado por coma, Número de teléfono (phone) en formato (999) 999-9999. Ordenado por apellido y nombre.


--11. Obtener la fecha de embarque (ship_date), Apellido (lname) y Nombre (fname) del Cliente separado por coma y la cantidad de órdenes del cliente. Para aquellos clientes que viven en el estado con descripción (sname) “California” y el código postal está entre 94000 y 94100 inclusive. Ordenado por fecha de embarque y, Apellido y nombre.


--12. Obtener por cada fabricante (manu_name) y producto (description), la cantidad vendida y el Monto Total vendido (unit_price * quantity). Sólo se deberán mostrar los ítems de los fabricantes ANZ, HRO, HSK y SMT, para las órdenes correspondientes a los meses de mayo y junio del 2015. Ordenar el resultado por el monto total vendido de mayor a menor.


--13. Emitir un reporte con la cantidad de unidades vendidas y el importe total por mes de productos, ordenado por importe total en forma descendente.
-- Formato: Año/Mes Cantidad Monto_Total
/*EJERCICIO 3
Seleccionar código de fabricante, nombre fabricante, cantidad de órdenes del fabricante,
Monto Total Vendido del fabricante sum(quantity*total_price) 
y el promedio de las Montos vendidos de todos los Fabricantes. 

SOLAMENTE MOSTRAR aquellos fabricantes cuyos Montos de ventas totales sean mayores al PROMEDIO de las ventas de TODOS los fabricantes.

Mostrar el resultado ordenado por cantidad total vendida en forma descendente.

IMPORTANTE: No se pueden usar procedures, ni Funciones de usuario.

manu_code   manu_name 	CantOrdenes 	Total vendido 	Promedio de Todos
ANZ            	 Anza                	       11                     11081.80                      3972.85
SHM             	Shimara      	        4                        5677.91                      3972.85

*/

SELECT m.manu_code, m.manu_name,
	count(distinct i.order_num) CantOrdenes,
	sum(i.quantity * i.unit_price)'Total vendido',
	(SELECT sum(i2.quantity * i2.unit_price) / count(distinct i2.manu_code) FROM items i2) 'Promedio de Todos'
FROM manufact m
	left join items i on (i.manu_code = m.manu_code)
GROUP BY m.manu_code, m.manu_name 
HAVING sum(i.quantity * i.unit_price) >
	(SELECT sum(i2.quantity * i2.unit_price) / count(distinct i2.manu_code) FROM items i2)
ORDER BY sum(i.quantity * i.unit_price) DESC
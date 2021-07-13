-- Práctica de queries complejas 3

USE stores7new;

-- 9. Listar el Número, nombre, apellido, estado, cantidad de Órdenes, monto total comprado
-- por Cliente durante el año 2015 que no sean del estado de Florida.

-- Mostrar sólo aquellos clientes cuyo monto total comprado sea mayor que el promedio del monto total comprado
-- por Cliente que no sean del estado Florida. Ordenado por total comprado en forma descendente.

select
    c.customer_num,
    c.fname,
    c.lname,
    c.state,
    count(distinct o.order_num) cantOrdenes,
    sum(i.unit_price * i.quantity) MontoOrdenes
from
    customer c
    join orders o on c.customer_num = o.customer_num
    join items i on o.order_num = i.order_num
where
    c.state != 'FL'
    and o.order_date between '20150101'
    and '20151231'
group by
    c.customer_num,
    c.fname,
    c.lname,
    c.state
having
    sum(i.unit_price * i.quantity) >= (
        select
            sum(i.unit_price * i.quantity) / count(distinct c.customer_num)
        from
            customer c
            join orders o on c.customer_num = o.customer_num
            join items i on o.order_num = i.order_num
        where
            c.state != 'FL'
    )
order by
    MontoOrdenes DESC;

-- 10. Seleccionar todos los clientes cuyo monto total comprado sea mayor al de su refererente durante el año 2015.
-- Mostrar número, nombre, apellido y los montos totales comprados de ambos durante ese año. Tener en cuenta que un cliente puede no tener referente y que el referente pudo no haber comprado nada durante el año 2015, mostrarlo igual.

select
    c.customer_num,
    c.fname,
    c.lname,
    sum(i.unit_price * i.quantity) MontoOrdenes,
    cr.customer_num,
    cr.fname,
    cr.lname,
    cr.totalRef
from
    customer c
    join orders o on c.customer_num = o.customer_num
    join items i on o.order_num = i.order_num
    left join (
        select
            r.customer_num,
            r.fname,
            r.lname,
            sum(i2.unit_price * i2.quantity) totalRef
        from
            customer r
            left join orders o2 on r.customer_num = o2.customer_num
            left join items i2 on o2.order_num = i2.order_num
        where
            o2.order_date between '20150101'
            and '20151231'
        group by
            r.customer_num,
            r.fname,
            r.lname
    ) cr on cr.customer_num = c.customer_num_referedBy
where
    o.order_date between '20150101'
    and '20151231'
group by
    c.customer_num,
    c.fname,
    c.lname,
    cr.customer_num,
    cr.fname,
    cr.lname,
    cr.totalRef
having
    sum(i.unit_price * i.quantity) > coalesce(cr.totalRef, 0)
order by
    MontoOrdenes DESC;
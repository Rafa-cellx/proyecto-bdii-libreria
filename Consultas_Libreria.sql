-- ============================================================
-- PROYECTO FINAL - SISTEMAS DE BASE DE DATOS II
-- Archivo 03: Transacciones + Cuadernillo de 30 Consultas
-- Usuario: LIBRERIA | Sufijo: _CRAM
-- Nota: Correr query por query con F9 en SQL Developer
-- ============================================================


-- ============================================================
-- ACTIVIDAD 4: CONTROL DE TRANSACCIONES
-- ============================================================


-- ============================================================
-- ESCENARIO 1: SAVEPOINT y ROLLBACK TO SAVEPOINT
-- Un empleado registra un préstamo y una multa,
-- pero se arrepiente de la multa y hace rollback parcial.
-- ============================================================

-- Ver estado actual
SELECT * FROM PRESTAMOS_CRAM WHERE ID_MIEMBRO = 1;
SELECT * FROM MULTAS_CRAM WHERE ID_MIEMBRO = 1;

-- Insertar un préstamo nuevo
INSERT INTO PRESTAMOS_CRAM (ID_PRESTAMO, ID_MIEMBRO, ISBN, ID_BIBLIOTECA, FECHA_PRESTAMO, FECHA_LIMITE, ESTADO)
VALUES (PRE_CRAM_ID_PRE_SEQ.NEXTVAL, 1, 9780307474728, 1, SYSDATE, SYSDATE + 14, 'Activo');

-- Guardar punto de control
SAVEPOINT ANTES_MULTA;

-- Insertar una multa (error, no corresponde)
INSERT INTO MULTAS_CRAM (ID_MULTA, ID_PRESTAMO, ID_MIEMBRO, MONTO, FECHA_MULTA, PAGADA)
VALUES (MUL_CRAM_ID_MUL_SEQ.NEXTVAL,
        (SELECT MAX(ID_PRESTAMO) FROM PRESTAMOS_CRAM),
        1, 100, SYSDATE, 'N');

-- Ver el estado (multa existe temporalmente)
SELECT * FROM MULTAS_CRAM WHERE ID_MIEMBRO = 1;

-- Deshacer solo la multa, conservar el préstamo
ROLLBACK TO SAVEPOINT ANTES_MULTA;

-- Verificar: préstamo sí quedó, multa no
SELECT * FROM PRESTAMOS_CRAM WHERE ID_MIEMBRO = 1;
SELECT * FROM MULTAS_CRAM WHERE ID_MIEMBRO = 1;

-- Confirmar el préstamo de forma permanente
COMMIT;


-- ============================================================
-- ESCENARIO 2: ROLLBACK total
-- Se intenta registrar una reservación pero hay un error
-- y se revierte todo.
-- ============================================================

-- Ver estado actual
SELECT * FROM RESERVACIONES_CRAM WHERE ID_MIEMBRO = 3;

-- Insertar una reservación
INSERT INTO RESERVACIONES_CRAM (ID_RESERVACION, ID_MIEMBRO, ISBN, FECHA_RESERVACION, FECHA_EXPIRACION, ESTADO)
VALUES (RES_CRAM_ID_RES_SEQ.NEXTVAL, 3, 9780307474728, SYSDATE, SYSDATE + 7, 'Pendiente');

-- Ver el cambio (aún sin confirmar)
SELECT * FROM RESERVACIONES_CRAM WHERE ID_MIEMBRO = 3;

-- Se detecta un error: el libro no está disponible, se revierte todo
ROLLBACK;

-- Verificar: la reservación no existe
SELECT * FROM RESERVACIONES_CRAM WHERE ID_MIEMBRO = 3;


-- ============================================================
-- ESCENARIO 3: COMMIT permanente
-- Se actualiza el estado de un préstamo y se confirma.
-- Luego se intenta un ROLLBACK pero ya no revierte nada.
-- ============================================================

-- Ver estado actual del préstamo 2
SELECT ID_PRESTAMO, ESTADO, FECHA_DEVOLUCION
FROM PRESTAMOS_CRAM
WHERE ID_PRESTAMO = 2;

-- Actualizar el préstamo como devuelto
UPDATE PRESTAMOS_CRAM
SET ESTADO = 'Devuelto',
    FECHA_DEVOLUCION = SYSDATE
WHERE ID_PRESTAMO = 2;

-- Confirmar permanentemente
COMMIT;

-- Intentar revertir (ya no tiene efecto)
ROLLBACK;

-- Verificar: el cambio es permanente
SELECT ID_PRESTAMO, ESTADO, FECHA_DEVOLUCION
FROM PRESTAMOS_CRAM
WHERE ID_PRESTAMO = 2;


-- ============================================================
-- ACTIVIDADES 5 Y 6: CUADERNILLO DE 30 CONSULTAS
-- ============================================================


-- -------------------------------------------------------
-- 1. Mostrar el título del libro, el nombre del autor
--    y la categoría de cada libro.
-- -------------------------------------------------------
SELECT L.TITULO,
       A.NOMBRE || ' ' || A.APELLIDO AS AUTOR,
       C.NOMBRE_CATEGORIA AS CATEGORIA
FROM LIBROS_CRAM L
JOIN LIBROS_POR_AUTOR_CRAM LA ON L.ISBN = LA.ISBN
JOIN AUTORES_CRAM A ON LA.ID_AUTOR = A.ID_AUTOR
JOIN LIBROS_POR_CATEGORIA_CRAM LC ON L.ISBN = LC.ISBN
JOIN CATEGORIAS_CRAM C ON LC.ID_CATEGORIA = C.ID_CATEGORIA
ORDER BY L.TITULO;


-- -------------------------------------------------------
-- 2. Mostrar los miembros que tienen préstamos activos
--    junto con el título del libro que tienen prestado.
-- -------------------------------------------------------
SELECT M.NOMBRE || ' ' || M.APELLIDO AS MIEMBRO,
       L.TITULO,
       P.FECHA_PRESTAMO,
       P.FECHA_LIMITE
FROM MIEMBROS_CRAM M
JOIN PRESTAMOS_CRAM P ON M.ID_MIEMBRO = P.ID_MIEMBRO
JOIN LIBROS_CRAM L ON P.ISBN = L.ISBN
WHERE P.ESTADO = 'Activo'
ORDER BY M.APELLIDO;


-- -------------------------------------------------------
-- 3. Mostrar el nombre de la biblioteca y cuántos libros
--    distintos tiene en stock.
-- -------------------------------------------------------
SELECT B.NOMBRE_BIBLIOTECA,
       COUNT(LB.ISBN) AS TOTAL_TITULOS,
       SUM(LB.CANTIDAD_EN_STOCK) AS TOTAL_EJEMPLARES
FROM BIBLIOTECAS_CRAM B
JOIN LIBROS_EN_BIBLIOTECA_CRAM LB ON B.ID_BIBLIOTECA = LB.ID_BIBLIOTECA
GROUP BY B.NOMBRE_BIBLIOTECA
ORDER BY TOTAL_EJEMPLARES DESC;


-- -------------------------------------------------------
-- 4. Mostrar los miembros que tienen multas sin pagar
--    junto con el monto total de su deuda.
-- -------------------------------------------------------
SELECT M.NOMBRE || ' ' || M.APELLIDO AS MIEMBRO,
       COUNT(MU.ID_MULTA) AS TOTAL_MULTAS,
       SUM(MU.MONTO) AS DEUDA_TOTAL
FROM MIEMBROS_CRAM M
JOIN MULTAS_CRAM MU ON M.ID_MIEMBRO = MU.ID_MIEMBRO
WHERE MU.PAGADA = 'N'
GROUP BY M.NOMBRE, M.APELLIDO
ORDER BY DEUDA_TOTAL DESC;


-- -------------------------------------------------------
-- 5. Mostrar el título del libro más prestado.
-- -------------------------------------------------------
SELECT L.TITULO,
       COUNT(P.ID_PRESTAMO) AS TOTAL_PRESTAMOS
FROM LIBROS_CRAM L
JOIN PRESTAMOS_CRAM P ON L.ISBN = P.ISBN
GROUP BY L.TITULO
HAVING COUNT(P.ID_PRESTAMO) = (
    SELECT MAX(COUNT(P2.ID_PRESTAMO))
    FROM PRESTAMOS_CRAM P2
    GROUP BY P2.ISBN
);


-- -------------------------------------------------------
-- 6. Mostrar los empleados y la biblioteca donde trabajan,
--    mostrando cuántos años llevan contratados.
-- -------------------------------------------------------
SELECT E.NOMBRE || ' ' || E.APELLIDO AS EMPLEADO,
       E.PUESTO,
       B.NOMBRE_BIBLIOTECA,
       TRUNC(MONTHS_BETWEEN(SYSDATE, E.FECHA_CONTRATACION) / 12) AS ANIOS_SERVICIO
FROM EMPLEADOS_CRAM E
JOIN BIBLIOTECAS_CRAM B ON E.ID_BIBLIOTECA = B.ID_BIBLIOTECA
ORDER BY ANIOS_SERVICIO DESC;


-- -------------------------------------------------------
-- 7. Mostrar los libros que NO han sido prestados nunca.
-- -------------------------------------------------------
SELECT L.ISBN, L.TITULO, ED.NOMBRE_EDITORIAL
FROM LIBROS_CRAM L
JOIN EDITORIALES_CRAM ED ON L.ID_EDITORIAL = ED.ID_EDITORIAL
WHERE L.ISBN NOT IN (
    SELECT DISTINCT P.ISBN FROM PRESTAMOS_CRAM P
)
ORDER BY L.TITULO;


-- -------------------------------------------------------
-- 8. Mostrar el miembro con más préstamos registrados.
-- -------------------------------------------------------
SELECT M.NOMBRE || ' ' || M.APELLIDO AS MIEMBRO,
       COUNT(P.ID_PRESTAMO) AS TOTAL_PRESTAMOS
FROM MIEMBROS_CRAM M
JOIN PRESTAMOS_CRAM P ON M.ID_MIEMBRO = P.ID_MIEMBRO
GROUP BY M.NOMBRE, M.APELLIDO
HAVING COUNT(P.ID_PRESTAMO) = (
    SELECT MAX(COUNT(P2.ID_PRESTAMO))
    FROM PRESTAMOS_CRAM P2
    GROUP BY P2.ID_MIEMBRO
);


-- -------------------------------------------------------
-- 9. Mostrar todos los libros con su editorial y precio,
--    indicando si el precio Amazon es menor al precio lista.
-- -------------------------------------------------------
SELECT L.TITULO,
       ED.NOMBRE_EDITORIAL,
       TO_CHAR(L.PRECIO_LISTA, '$99,999') AS PRECIO_LISTA,
       TO_CHAR(L.PRECIO_AMAZON, '$99,999') AS PRECIO_AMAZON,
       CASE
           WHEN L.PRECIO_AMAZON < L.PRECIO_LISTA THEN 'Precio Amazon menor'
           WHEN L.PRECIO_AMAZON = L.PRECIO_LISTA THEN 'Mismo precio'
           ELSE 'Precio Amazon mayor'
       END AS COMPARACION
FROM LIBROS_CRAM L
JOIN EDITORIALES_CRAM ED ON L.ID_EDITORIAL = ED.ID_EDITORIAL
ORDER BY L.TITULO;


-- -------------------------------------------------------
-- 10. Mostrar los préstamos vencidos y cuántos días
--     llevan vencidos.
-- -------------------------------------------------------
SELECT M.NOMBRE || ' ' || M.APELLIDO AS MIEMBRO,
       L.TITULO,
       P.FECHA_LIMITE,
       TRUNC(SYSDATE - P.FECHA_LIMITE) AS DIAS_VENCIDO
FROM PRESTAMOS_CRAM P
JOIN MIEMBROS_CRAM M ON P.ID_MIEMBRO = M.ID_MIEMBRO
JOIN LIBROS_CRAM L ON P.ISBN = L.ISBN
WHERE P.ESTADO = 'Vencido'
ORDER BY DIAS_VENCIDO DESC;


-- -------------------------------------------------------
-- 11. Mostrar el título, autor y calificación de Amazon
--     de los libros con calificación mayor al promedio.
-- -------------------------------------------------------
SELECT L.TITULO,
       A.NOMBRE || ' ' || A.APELLIDO AS AUTOR,
       L.CALIFICACION_AMAZON
FROM LIBROS_CRAM L
JOIN LIBROS_POR_AUTOR_CRAM LA ON L.ISBN = LA.ISBN
JOIN AUTORES_CRAM A ON LA.ID_AUTOR = A.ID_AUTOR
WHERE L.CALIFICACION_AMAZON > (
    SELECT AVG(CALIFICACION_AMAZON) FROM LIBROS_CRAM
)
ORDER BY L.CALIFICACION_AMAZON DESC;


-- -------------------------------------------------------
-- 12. Mostrar las reservaciones pendientes con el nombre
--     del miembro y el título del libro.
-- -------------------------------------------------------
SELECT M.NOMBRE || ' ' || M.APELLIDO AS MIEMBRO,
       L.TITULO,
       R.FECHA_RESERVACION,
       NVL(TO_CHAR(R.FECHA_EXPIRACION, 'DD/MM/YYYY'), 'Sin fecha') AS FECHA_EXPIRACION
FROM RESERVACIONES_CRAM R
JOIN MIEMBROS_CRAM M ON R.ID_MIEMBRO = M.ID_MIEMBRO
JOIN LIBROS_CRAM L ON R.ISBN = L.ISBN
WHERE R.ESTADO = 'Pendiente'
ORDER BY R.FECHA_RESERVACION;


-- -------------------------------------------------------
-- 13. Mostrar el nombre de la editorial con más libros.
-- -------------------------------------------------------
SELECT ED.NOMBRE_EDITORIAL,
       COUNT(L.ISBN) AS TOTAL_LIBROS
FROM EDITORIALES_CRAM ED
JOIN LIBROS_CRAM L ON ED.ID_EDITORIAL = L.ID_EDITORIAL
GROUP BY ED.NOMBRE_EDITORIAL
HAVING COUNT(L.ISBN) = (
    SELECT MAX(COUNT(L2.ISBN))
    FROM LIBROS_CRAM L2
    GROUP BY L2.ID_EDITORIAL
);


-- -------------------------------------------------------
-- 14. Mostrar todos los miembros y si tienen multas sin
--     pagar mostrar el monto; si no, mostrar 'Sin deuda'.
-- -------------------------------------------------------
SELECT M.NOMBRE || ' ' || M.APELLIDO AS MIEMBRO,
       NVL(TO_CHAR(SUM(MU.MONTO), '$99,999'), 'Sin deuda') AS DEUDA
FROM MIEMBROS_CRAM M
LEFT OUTER JOIN MULTAS_CRAM MU ON M.ID_MIEMBRO = MU.ID_MIEMBRO
AND MU.PAGADA = 'N'
GROUP BY M.NOMBRE, M.APELLIDO
ORDER BY M.APELLIDO;


-- -------------------------------------------------------
-- 15. Mostrar los libros cuyo stock sea mayor al promedio.
-- -------------------------------------------------------
SELECT B.NOMBRE_BIBLIOTECA,
       L.TITULO,
       LB.CANTIDAD_EN_STOCK
FROM LIBROS_EN_BIBLIOTECA_CRAM LB
JOIN BIBLIOTECAS_CRAM B ON LB.ID_BIBLIOTECA = B.ID_BIBLIOTECA
JOIN LIBROS_CRAM L ON LB.ISBN = L.ISBN
WHERE LB.CANTIDAD_EN_STOCK > (
    SELECT AVG(CANTIDAD_EN_STOCK) FROM LIBROS_EN_BIBLIOTECA_CRAM
)
ORDER BY LB.CANTIDAD_EN_STOCK DESC;


-- -------------------------------------------------------
-- 16. Mostrar el nombre del autor con más libros escritos.
-- -------------------------------------------------------
SELECT A.NOMBRE || ' ' || A.APELLIDO AS AUTOR,
       COUNT(LA.ISBN) AS TOTAL_LIBROS
FROM AUTORES_CRAM A
JOIN LIBROS_POR_AUTOR_CRAM LA ON A.ID_AUTOR = LA.ID_AUTOR
GROUP BY A.NOMBRE, A.APELLIDO
HAVING COUNT(LA.ISBN) = (
    SELECT MAX(COUNT(LA2.ISBN))
    FROM LIBROS_POR_AUTOR_CRAM LA2
    GROUP BY LA2.ID_AUTOR
);


-- -------------------------------------------------------
-- 17. Mostrar el historial de préstamos del miembro 1.
-- -------------------------------------------------------
SELECT M.NOMBRE || ' ' || M.APELLIDO AS MIEMBRO,
       L.TITULO,
       TO_CHAR(P.FECHA_PRESTAMO, 'DD/MM/YYYY') AS FECHA_PRESTAMO,
       TO_CHAR(P.FECHA_LIMITE, 'DD/MM/YYYY') AS FECHA_LIMITE,
       NVL(TO_CHAR(P.FECHA_DEVOLUCION, 'DD/MM/YYYY'), 'No devuelto') AS FECHA_DEVOLUCION,
       P.ESTADO
FROM PRESTAMOS_CRAM P
JOIN MIEMBROS_CRAM M ON P.ID_MIEMBRO = M.ID_MIEMBRO
JOIN LIBROS_CRAM L ON P.ISBN = L.ISBN
WHERE P.ID_MIEMBRO = 1
ORDER BY P.FECHA_PRESTAMO;


-- -------------------------------------------------------
-- 18. Mostrar los miembros que tienen tanto préstamos
--     activos COMO reservaciones pendientes (INTERSECT).
-- -------------------------------------------------------
SELECT ID_MIEMBRO
FROM PRESTAMOS_CRAM
WHERE ESTADO = 'Activo'
INTERSECT
SELECT ID_MIEMBRO
FROM RESERVACIONES_CRAM
WHERE ESTADO = 'Pendiente';


-- -------------------------------------------------------
-- 19. Mostrar los miembros que tienen préstamos pero
--     NO tienen ninguna reservación (MINUS).
-- -------------------------------------------------------
SELECT DISTINCT P.ID_MIEMBRO
FROM PRESTAMOS_CRAM P
MINUS
SELECT DISTINCT R.ID_MIEMBRO
FROM RESERVACIONES_CRAM R;


-- -------------------------------------------------------
-- 20. Mostrar un listado completo de préstamos y
--     reservaciones con su tipo (UNION ALL).
-- -------------------------------------------------------
SELECT M.NOMBRE || ' ' || M.APELLIDO AS MIEMBRO,
       L.TITULO,
       TO_CHAR(P.FECHA_PRESTAMO, 'DD/MM/YYYY') AS FECHA,
       'Prestamo' AS TIPO,
       P.ESTADO
FROM PRESTAMOS_CRAM P
JOIN MIEMBROS_CRAM M ON P.ID_MIEMBRO = M.ID_MIEMBRO
JOIN LIBROS_CRAM L ON P.ISBN = L.ISBN
UNION ALL
SELECT M2.NOMBRE || ' ' || M2.APELLIDO,
       L2.TITULO,
       TO_CHAR(R.FECHA_RESERVACION, 'DD/MM/YYYY'),
       'Reservacion',
       R.ESTADO
FROM RESERVACIONES_CRAM R
JOIN MIEMBROS_CRAM M2 ON R.ID_MIEMBRO = M2.ID_MIEMBRO
JOIN LIBROS_CRAM L2 ON R.ISBN = L2.ISBN
ORDER BY FECHA DESC;


-- -------------------------------------------------------
-- 21. Mostrar la categoría con más libros registrados.
-- -------------------------------------------------------
SELECT C.NOMBRE_CATEGORIA,
       COUNT(LC.ISBN) AS TOTAL_LIBROS
FROM CATEGORIAS_CRAM C
JOIN LIBROS_POR_CATEGORIA_CRAM LC ON C.ID_CATEGORIA = LC.ID_CATEGORIA
GROUP BY C.NOMBRE_CATEGORIA
HAVING COUNT(LC.ISBN) = (
    SELECT MAX(COUNT(LC2.ISBN))
    FROM LIBROS_POR_CATEGORIA_CRAM LC2
    GROUP BY LC2.ID_CATEGORIA
);


-- -------------------------------------------------------
-- 22. Mostrar los libros publicados antes de 1970
--     con su autor y editorial.
-- -------------------------------------------------------
SELECT L.TITULO,
       A.NOMBRE || ' ' || A.APELLIDO AS AUTOR,
       ED.NOMBRE_EDITORIAL,
       TO_CHAR(L.FECHA_PUBLICACION, 'DD/MM/YYYY') AS FECHA_PUBLICACION
FROM LIBROS_CRAM L
JOIN LIBROS_POR_AUTOR_CRAM LA ON L.ISBN = LA.ISBN
JOIN AUTORES_CRAM A ON LA.ID_AUTOR = A.ID_AUTOR
JOIN EDITORIALES_CRAM ED ON L.ID_EDITORIAL = ED.ID_EDITORIAL
WHERE L.FECHA_PUBLICACION < TO_DATE('01/01/1970', 'DD/MM/YYYY')
ORDER BY L.FECHA_PUBLICACION;


-- -------------------------------------------------------
-- 23. Mostrar los empleados que llevan más de 5 años.
-- -------------------------------------------------------
SELECT E.NOMBRE || ' ' || E.APELLIDO AS EMPLEADO,
       E.PUESTO,
       B.NOMBRE_BIBLIOTECA,
       TO_CHAR(E.FECHA_CONTRATACION, 'DD/MM/YYYY') AS FECHA_CONTRATACION,
       TRUNC(MONTHS_BETWEEN(SYSDATE, E.FECHA_CONTRATACION) / 12) AS ANIOS
FROM EMPLEADOS_CRAM E
JOIN BIBLIOTECAS_CRAM B ON E.ID_BIBLIOTECA = B.ID_BIBLIOTECA
WHERE MONTHS_BETWEEN(SYSDATE, E.FECHA_CONTRATACION) / 12 > 5
ORDER BY ANIOS DESC;


-- -------------------------------------------------------
-- 24. Mostrar el nombre del miembro, el título del libro
--     y la multa, indicando si fue pagada con DECODE.
-- -------------------------------------------------------
SELECT M.NOMBRE || ' ' || M.APELLIDO AS MIEMBRO,
       L.TITULO,
       TO_CHAR(MU.MONTO, '$99,999') AS MONTO,
       DECODE(MU.PAGADA, 'S', 'Pagada', 'N', 'Pendiente de pago', 'Sin dato') AS ESTADO_MULTA
FROM MULTAS_CRAM MU
JOIN MIEMBROS_CRAM M ON MU.ID_MIEMBRO = M.ID_MIEMBRO
JOIN PRESTAMOS_CRAM P ON MU.ID_PRESTAMO = P.ID_PRESTAMO
JOIN LIBROS_CRAM L ON P.ISBN = L.ISBN
ORDER BY M.APELLIDO;


-- -------------------------------------------------------
-- 25. Mostrar los libros disponibles en al menos una
--     biblioteca con stock mayor a 0 (EXISTS).
-- -------------------------------------------------------
SELECT L.ISBN, L.TITULO, ED.NOMBRE_EDITORIAL
FROM LIBROS_CRAM L
JOIN EDITORIALES_CRAM ED ON L.ID_EDITORIAL = ED.ID_EDITORIAL
WHERE EXISTS (
    SELECT 1
    FROM LIBROS_EN_BIBLIOTECA_CRAM LB
    WHERE LB.ISBN = L.ISBN
    AND LB.CANTIDAD_EN_STOCK > 0
)
ORDER BY L.TITULO;


-- -------------------------------------------------------
-- 26. Mostrar los libros que NO están disponibles en
--     ninguna biblioteca (NOT EXISTS).
-- -------------------------------------------------------
SELECT L.ISBN, L.TITULO, ED.NOMBRE_EDITORIAL
FROM LIBROS_CRAM L
JOIN EDITORIALES_CRAM ED ON L.ID_EDITORIAL = ED.ID_EDITORIAL
WHERE NOT EXISTS (
    SELECT 1
    FROM LIBROS_EN_BIBLIOTECA_CRAM LB
    WHERE LB.ISBN = L.ISBN
    AND LB.CANTIDAD_EN_STOCK > 0
)
ORDER BY L.TITULO;


-- -------------------------------------------------------
-- 27. Mostrar el nombre del miembro, su género con
--     descripción completa y su correo en mayúsculas.
-- -------------------------------------------------------
SELECT INITCAP(M.NOMBRE) || ' ' || INITCAP(M.APELLIDO) AS MIEMBRO,
       CASE M.GENERO
           WHEN 'M' THEN 'Masculino'
           WHEN 'F' THEN 'Femenino'
           ELSE 'No especificado'
       END AS GENERO,
       UPPER(M.CORREO) AS CORREO
FROM MIEMBROS_CRAM M
ORDER BY M.APELLIDO;


-- -------------------------------------------------------
-- 28. Mostrar la biblioteca con más empleados.
-- -------------------------------------------------------
SELECT B.NOMBRE_BIBLIOTECA,
       COUNT(E.ID_EMPLEADO) AS TOTAL_EMPLEADOS
FROM BIBLIOTECAS_CRAM B
JOIN EMPLEADOS_CRAM E ON B.ID_BIBLIOTECA = E.ID_BIBLIOTECA
GROUP BY B.NOMBRE_BIBLIOTECA
HAVING COUNT(E.ID_EMPLEADO) = (
    SELECT MAX(COUNT(E2.ID_EMPLEADO))
    FROM EMPLEADOS_CRAM E2
    GROUP BY E2.ID_BIBLIOTECA
);


-- -------------------------------------------------------
-- 29. Mostrar los miembros con más multas sin pagar
--     que el promedio.
-- -------------------------------------------------------
SELECT M.NOMBRE || ' ' || M.APELLIDO AS MIEMBRO,
       COUNT(MU.ID_MULTA) AS MULTAS_PENDIENTES
FROM MIEMBROS_CRAM M
JOIN MULTAS_CRAM MU ON M.ID_MIEMBRO = MU.ID_MIEMBRO
WHERE MU.PAGADA = 'N'
GROUP BY M.NOMBRE, M.APELLIDO
HAVING COUNT(MU.ID_MULTA) > (
    SELECT AVG(TOTAL)
    FROM (
        SELECT COUNT(*) AS TOTAL
        FROM MULTAS_CRAM
        WHERE PAGADA = 'N'
        GROUP BY ID_MIEMBRO
    )
)
ORDER BY MULTAS_PENDIENTES DESC;


-- -------------------------------------------------------
-- 30. Mostrar el resumen general de cada biblioteca:
--     nombre, empleados, títulos y ejemplares en stock.
-- -------------------------------------------------------
SELECT B.NOMBRE_BIBLIOTECA,
       COUNT(DISTINCT E.ID_EMPLEADO) AS TOTAL_EMPLEADOS,
       COUNT(DISTINCT LB.ISBN) AS TOTAL_TITULOS,
       SUM(LB.CANTIDAD_EN_STOCK) AS TOTAL_EJEMPLARES
FROM BIBLIOTECAS_CRAM B
LEFT OUTER JOIN EMPLEADOS_CRAM E ON B.ID_BIBLIOTECA = E.ID_BIBLIOTECA
LEFT OUTER JOIN LIBROS_EN_BIBLIOTECA_CRAM LB ON B.ID_BIBLIOTECA = LB.ID_BIBLIOTECA
GROUP BY B.NOMBRE_BIBLIOTECA
ORDER BY TOTAL_EJEMPLARES DESC;
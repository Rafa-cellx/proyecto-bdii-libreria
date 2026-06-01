-------------------------------------------------------------------
-------------------CONTROL DE TRANSACCIONES------------------------
-------------------------------------------------------------------


-- Verificar estado inicial
SELECT ID_PRESTAMO, ID_MIEMBRO, ESTADO 
FROM PRESTAMOS_CRAM 
WHERE ID_MIEMBRO = 237;

-- Iniciar transaccion
SAVEPOINT ANTES_PRESTAMO;

-- Insertar nuevo prestamo
INSERT INTO PRESTAMOS_CRAM(ID_PRESTAMO,ID_MIEMBRO,ISBN,ID_BIBLIOTECA,
    FECHA_PRESTAMO,FECHA_LIMITE,FECHA_DEVOLUCION,ESTADO)
VALUES(PRE_CRAM_ID_PRE_SEQ.NEXTVAL,237,9780333783047,26,
    '31/05/2026','21/06/2026',NULL,'Activo');

-- Verificar que se inserto correctamente
SELECT ID_PRESTAMO, ID_MIEMBRO, ISBN, ESTADO 
FROM PRESTAMOS_CRAM 
WHERE ID_MIEMBRO = 237;

-- Confirmar la transaccion permanentemente
COMMIT;

-- Verificar que persiste despues del commit
SELECT ID_PRESTAMO, ID_MIEMBRO, ISBN, ESTADO 
FROM PRESTAMOS_CRAM 
WHERE ID_MIEMBRO = 237;


-- =============================================
-- ESCENARIO 2: ROLLBACK TOTAL
-- Intentar registrar una multa incorrecta
-- y deshacer toda la operacion
-- =============================================

-- Verificar estado inicial de multas
SELECT ID_MULTA, ID_PRESTAMO, MONTO, PAGADA 
FROM MULTAS_CRAM;

-- Insertar multa con monto incorrecto
INSERT INTO MULTAS_CRAM(ID_MULTA,ID_PRESTAMO,ID_MIEMBRO,
    MONTO,FECHA_MULTA,PAGADA,FECHA_PAGO)
VALUES(MUL_CRAM_ID_MUL_SEQ.NEXTVAL,1,182,
    99999,'31/05/2026','N',NULL);

-- Verificar que aparece el registro incorrecto
SELECT ID_MULTA, ID_PRESTAMO, MONTO 
FROM MULTAS_CRAM 
ORDER BY ID_MULTA DESC;

-- Se detecto el error: monto incorrecto
-- Deshacer toda la transaccion
ROLLBACK;

-- Verificar que el registro fue eliminado
SELECT ID_MULTA, ID_PRESTAMO, MONTO 
FROM MULTAS_CRAM 
ORDER BY ID_MULTA DESC;


-- =============================================
-- ESCENARIO 3: SAVEPOINT + ROLLBACK PARCIAL
-- Actualizar estado de prestamo y registrar
-- devolucion, pero solo revertir la multa
-- si fue un error, conservando la devolucion
-- =============================================

-- Verificar estado inicial
SELECT ID_PRESTAMO, ID_MIEMBRO, ESTADO, FECHA_DEVOLUCION 
FROM PRESTAMOS_CRAM 
WHERE ID_PRESTAMO = 51;

-- Paso 1: Registrar devolucion del libro
UPDATE PRESTAMOS_CRAM
SET FECHA_DEVOLUCION = '31/05/2026',
    ESTADO = 'Devuelto'
WHERE ID_PRESTAMO = 51;

-- Verificar actualizacion
SELECT ID_PRESTAMO, ESTADO, FECHA_DEVOLUCION 
FROM PRESTAMOS_CRAM 
WHERE ID_PRESTAMO = 51;

-- Guardar punto de control DESPUES de la devolucion
SAVEPOINT DEVOLUCION_OK;

-- Paso 2: Intentar registrar multa (error: no corresponde multa)
INSERT INTO MULTAS_CRAM(ID_MULTA,ID_PRESTAMO,ID_MIEMBRO,
    MONTO,FECHA_MULTA,PAGADA,FECHA_PAGO)
VALUES(MUL_CRAM_ID_MUL_SEQ.NEXTVAL,51,232,
    150,'31/05/2026','N',NULL);

-- Verificar que se inserto la multa
SELECT ID_MULTA, ID_PRESTAMO, MONTO 
FROM MULTAS_CRAM 
ORDER BY ID_MULTA DESC;

-- Se detecto que la multa fue un error
-- Revertir SOLO la multa, conservar la devolucion
ROLLBACK TO SAVEPOINT DEVOLUCION_OK;

-- Verificar: devolucion persiste, multa revertida
SELECT ID_PRESTAMO, ESTADO, FECHA_DEVOLUCION 
FROM PRESTAMOS_CRAM 
WHERE ID_PRESTAMO = 51;

SELECT ID_MULTA, ID_PRESTAMO, MONTO 
FROM MULTAS_CRAM 
ORDER BY ID_MULTA DESC;

-- Confirmar definitivamente la devolucion
COMMIT;
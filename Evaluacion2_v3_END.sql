/*======================================================================
 BDY1103 - EVALUACION PARCIAL 2  (ciclo completo del negocio, modelo en 3FN)
 Proyecto: Tienda de videojuegos
 Codigo + orden de ejecucion + resultados esperados
======================================================================

CONTENIDO
  1. Orden de ejecucion
  2. Ciclo del negocio: que objeto cubre cada etapa
  3. Objetos por indicador de la rubrica
  3b. Normalizacion del modelo (1FN, 2FN, 3FN)
  4. SCRIPT 06_objetos_eval2.sql      (crear todo; se ejecuta UNA vez)
  5. SCRIPT 07_demostracion_eval2.sql (demo del ciclo; se repite cuando quieras)
  6. Resultados esperados de la demostracion
  7. (Opcional) Borrar los objetos de la Parte 2 para reinstalar


======================================================================
 1. ORDEN DE EJECUCION  (todo con F5 en SQL Developer)
======================================================================

  PASO 1 - 00_instalar_proyecto.sql  (Parte 1)
           Solo si el esquema esta vacio. Si ya lo instalaste, SALTALO.

  PASO 2 - 06_objetos_eval2.sql  (seccion 4 de este archivo)
           UNA sola vez. Al final: todos los objetos VALID y USER_ERRORS
           sin filas.
           * Si ya habias ejecutado la version ANTERIOR del 06, ejecuta
             primero la seccion 7 (borrar) y despues este 06.

  PASO 3 - 04_pruebas.sql  (Parte 1)
           Confirma que lo nuevo no rompio nada.
           Debe terminar con: PRUEBAS FINALIZADAS SIN FALLOS

  PASO 4 - 07_demostracion_eval2.sql  (seccion 5 de este archivo)
           Recorre el ciclo del negocio en 7 etapas y al final hace
           ROLLBACK. Saca una captura por etapa para el informe.

ORDEN INTERNO DEL 06 (por dependencias):
  a) Tablas y secuencias
  b) Datos iniciales (precios de lista y alertas de productos ya bajos)
  c) Funciones                 -> las usan packages y procedimientos
  d) Especificaciones          -> los procedimientos y triggers usan sus
     de los packages              elementos publicos
  e) Procedimientos            -> pkg_inventario.cierre_inventario llama
                                  a pr_generar_resumen_ventas
  f) Cuerpos de los packages
  g) Triggers                  -> al final


======================================================================
 2. CICLO DEL NEGOCIO: QUE OBJETO CUBRE CADA ETAPA
======================================================================

 #  ETAPA        QUE PASA EN LA TIENDA                OBJETOS
 1  Catalogo     Se agregan juegos con precio de      pkg_catalogo.agregar_videojuego
                 lista; se cambian precios            pkg_catalogo.actualizar_precio
                                                      fn_precio_videojuego
                                                      trg_historial_precio (fila)
 2  Clientes     Se registran clientes y se mide      pkg_catalogo.registrar_cliente
                 cuanto compra cada uno               fn_total_compras_cliente
                                                      pr_reporte_clientes (masivo)
 3  Venta        Se vende a precio de lista, con      pkg_ventas.vender
                 uno o varios productos               pkg_ventas.agregar_producto
                                                      pr_registrar_venta / pkg_tienda
 4  Control      Se validan datos y se audita         trg_venta_validar_fecha (fila)
                 quien cambia que                     trg_venta_sentencia (sentencia)
                                                      trg_auditoria_stock (fila)
 5  Correccion   Se anula una venta mal hecha y el    pkg_ventas.anular_venta
                 stock vuelve; el borrado directo     trg_venta_bloquear_borrado
                 esta prohibido                       (sentencia BEFORE)
 6  Alerta       Cuando el stock cae bajo el minimo   trg_alerta_reposicion (fila)
                 se abre una alerta automaticamente   fn_alertas_pendientes
 7  Reposicion   Llega mercaderia, sube el stock y    pkg_inventario.reponer_stock
                 la alerta se cierra sola             trg_alerta_reposicion
 8  Reportes     Ventas, ingresos, participacion      fn_total_ventas, fn_total_videojuegos
                 y estado de cada juego               fn_unidades_vendidas, fn_ingresos_producto
                                                      pr_generar_resumen_ventas (masivo)
                                                      pkg_tienda.generar_reporte
 9  Decision     El sistema sugiere cuanto comprar    pkg_inventario.sugerir_reposicion
                 de cada juego                        fn_cantidad_sugerida
                                                      pkg_inventario.cierre_inventario

 Ciclo: catalogo -> venta -> alerta -> sugerencia -> reposicion -> venta ...
        con control y auditoria en todo momento, y anulacion si hay errores.


======================================================================
 3. OBJETOS POR INDICADOR DE LA RUBRICA
======================================================================

PROCEDIMIENTOS (IE2.1.1 / IE2.1.2)
  Sin parametros : pr_generar_resumen_ventas, pr_reporte_clientes,
                   pkg_inventario.sugerir_reposicion / cierre_inventario
  Con parametros : pr_actualizar_stock_minimo (IN, IN, OUT),
                   pr_registrar_venta, pkg_ventas.vender / agregar_producto /
                   anular_venta, pkg_inventario.reponer_stock,
                   pkg_catalogo.agregar_videojuego / actualizar_precio /
                   registrar_cliente

FUNCIONES (IE2.1.3 / IE2.1.4)
  Sin parametros : fn_total_videojuegos, fn_total_ventas, fn_alertas_pendientes
  Con parametros : fn_unidades_vendidas, fn_ingresos_producto,
                   fn_precio_videojuego, fn_total_compras_cliente,
                   fn_cantidad_sugerida
  En SQL         : SELECT ... FROM videojuego / cliente / dual
  En PL/SQL      : dentro de procedimientos, packages y bloques

PACKAGES (IE2.2.1 / IE2.2.2)  publicos / privados
  pkg_tienda     : ingresos_producto, registrar_venta, generar_reporte
                   / validar_periodo
  pkg_catalogo   : agregar_videojuego, actualizar_precio, registrar_cliente
                   / validar_texto, validar_precio
  pkg_ventas     : vender, agregar_producto, anular_venta, total_venta,
                   anulacion_autorizada
                   / g_anulando (variable), validar_cantidad, descontar_stock
  pkg_inventario : estado_producto, reponer_stock, sugerir_reposicion,
                   mostrar_resumen, cierre_inventario
                   / c_linea (constante), imprimir, porcentaje_ventas

TRIGGERS (IE2.3.1 / IE2.3.2)
  Sentencia AFTER : trg_venta_sentencia
  Sentencia BEFORE: trg_venta_bloquear_borrado
  Fila BEFORE     : trg_venta_validar_fecha
  Fila AFTER      : trg_auditoria_stock, trg_alerta_reposicion,
                    trg_historial_precio


======================================================================
 3b. NORMALIZACION DEL MODELO (1FN, 2FN, 3FN)
======================================================================

Las 14 tablas cumplen 1FN, 2FN y 3FN:
  1FN: todos los valores son atomicos, no hay grupos repetidos y cada
       tabla tiene clave primaria. (El VARRAY de la Parte 1 se usa solo
       en PL/SQL; no se guarda en ninguna columna.)
  2FN: las tablas con clave compuesta (DETALLE_VENTA y
       DETALLE_VENTA_ANULADA) solo tienen atributos que dependen de la
       clave completa: cantidad y precio_unitario de ESE juego en ESA venta.
  3FN: ningun atributo depende de otro atributo que no sea la clave.

Cambios hechos para llegar a 3FN:
  ALERTA_REPOSICION      se quitaron "tipo" (dependia de stock_detectado)
                         y "estado" (dependia de fecha_atencion).
                         Pendiente = fecha_atencion IS NULL.
  VENTA_ANULADA          se quito "total" (se calcula desde su detalle)
                         y se agrego DETALLE_VENTA_ANULADA, igual que
                         VENTA / DETALLE_VENTA. id_cliente ahora es FK.
  RESUMEN_VENTA_PRODUCTO se quitaron "nombre" (esta en VIDEOJUEGO) y
                         "estado" (se calcula con estado_producto);
                         se guarda stock_minimo para poder calcularlo.

Datos que se calculan al consultar (no se guardan):
  tipo de alerta   CASE WHEN stock_detectado = 0 THEN 'AGOTADO' ELSE 'STOCK BAJO'
  estado de alerta CASE WHEN fecha_atencion IS NULL THEN 'PENDIENTE' ELSE 'ATENDIDA'
  total de venta   SUM(cantidad * precio_unitario) del detalle
  estado de stock  pkg_inventario.estado_producto(stock, stock_minimo)


======================================================================
 4. SCRIPT 06_objetos_eval2.sql
    (copiar desde aqui hasta "FIN SCRIPT 06")
======================================================================

-- BDY1103 - Evaluacion Parcial 2
-- Ciclo completo del negocio: catalogo, clientes, venta, control,
-- correccion (anulacion), alerta, reposicion, reportes y sugerencia de compra.
-- Requisito: haber ejecutado antes 00_instalar_proyecto.sql.
-- Ejecutar UNA sola vez con F5. No borra tablas ni datos existentes.
SET SERVEROUTPUT ON;

-- ===============================================================
-- a) TABLAS Y SECUENCIAS NUEVAS
-- ===============================================================
*/
-- Precio de lista de cada videojuego (catalogo).
CREATE TABLE precio_videojuego (
 id_videojuego NUMBER PRIMARY KEY REFERENCES videojuego,
 precio NUMBER(12,2) NOT NULL CHECK (precio > 0),
 fecha_actualizacion DATE NOT NULL
);

-- Historial de cambios de precio (lo llena trg_historial_precio).
CREATE SEQUENCE seq_historial_precio START WITH 1 INCREMENT BY 1;
CREATE TABLE historial_precio (
 id_historial NUMBER PRIMARY KEY,
 id_videojuego NUMBER NOT NULL REFERENCES videojuego,
 precio_anterior NUMBER(12,2) NOT NULL,
 precio_nuevo NUMBER(12,2) NOT NULL,
 usuario VARCHAR2(128) NOT NULL,
 fecha DATE NOT NULL
);

-- Identificadores para nuevos videojuegos y clientes.
CREATE SEQUENCE seq_videojuego START WITH 100 INCREMENT BY 1;
CREATE SEQUENCE seq_cliente START WITH 100 INCREMENT BY 1;

-- Alertas de reposicion (las crea y cierra trg_alerta_reposicion).
-- 3FN: no se guardan "tipo" ni "estado" porque se deducen de otras columnas:
--   tipo   = AGOTADO si stock_detectado = 0, si no STOCK BAJO
--   estado = PENDIENTE mientras fecha_atencion sea NULL, si no ATENDIDA
CREATE SEQUENCE seq_alerta START WITH 1 INCREMENT BY 1;
CREATE TABLE alerta_reposicion (
 id_alerta NUMBER PRIMARY KEY,
 id_videojuego NUMBER NOT NULL REFERENCES videojuego,
 stock_detectado NUMBER NOT NULL CHECK (stock_detectado >= 0),
 fecha_alerta DATE NOT NULL,
 fecha_atencion DATE
);

-- Ingresos de mercaderia (los registra pkg_inventario.reponer_stock).
CREATE SEQUENCE seq_reposicion START WITH 1 INCREMENT BY 1;
CREATE TABLE reposicion (
 id_reposicion NUMBER PRIMARY KEY,
 id_videojuego NUMBER NOT NULL REFERENCES videojuego,
 cantidad NUMBER NOT NULL CHECK (cantidad > 0),
 usuario VARCHAR2(128) NOT NULL,
 fecha DATE NOT NULL
);

-- Ventas anuladas (las registra pkg_ventas.anular_venta).
-- 3FN: igual que VENTA / DETALLE_VENTA, la cabecera no guarda el total;
-- se calcula desde DETALLE_VENTA_ANULADA.
CREATE TABLE venta_anulada (
 id_venta NUMBER PRIMARY KEY,
 id_cliente NUMBER NOT NULL REFERENCES cliente,
 fecha_venta DATE NOT NULL,
 motivo VARCHAR2(200) NOT NULL,
 usuario VARCHAR2(128) NOT NULL,
 fecha_anulacion DATE NOT NULL
);
CREATE TABLE detalle_venta_anulada (
 id_venta NUMBER REFERENCES venta_anulada,
 id_videojuego NUMBER REFERENCES videojuego,
 cantidad NUMBER NOT NULL CHECK (cantidad > 0),
 precio_unitario NUMBER(12,2) NOT NULL CHECK (precio_unitario > 0),
 PRIMARY KEY (id_venta, id_videojuego)
);

-- Resultado del proceso masivo (lo llena pr_generar_resumen_ventas).
-- Foto del cierre. 3FN: el nombre se obtiene con JOIN a VIDEOJUEGO y el
-- estado se calcula con pkg_inventario.estado_producto(stock, stock_minimo).
CREATE TABLE resumen_venta_producto (
 id_videojuego NUMBER PRIMARY KEY REFERENCES videojuego,
 unidades_vendidas NUMBER NOT NULL,
 ingresos NUMBER NOT NULL,
 stock NUMBER NOT NULL,
 stock_minimo NUMBER NOT NULL,
 fecha_proceso DATE NOT NULL
);

-- Auditoria del trigger a nivel de sentencia sobre VENTA.
CREATE SEQUENCE seq_auditoria_venta START WITH 1 INCREMENT BY 1;
CREATE TABLE auditoria_venta (
 id_auditoria NUMBER PRIMARY KEY,
 operacion VARCHAR2(10) NOT NULL,
 usuario VARCHAR2(128) NOT NULL,
 fecha DATE NOT NULL
);

-- ===============================================================
-- b) DATOS INICIALES DE LAS TABLAS NUEVAS
-- ===============================================================

-- Precios de lista de los videojuegos existentes.
INSERT INTO precio_videojuego VALUES (1, 30000, SYSDATE);
INSERT INTO precio_videojuego VALUES (2, 25000, SYSDATE);
INSERT INTO precio_videojuego VALUES (3, 45000, SYSDATE);
INSERT INTO precio_videojuego VALUES (4, 35000, SYSDATE);

-- Alertas iniciales: productos que YA estan bajo el minimo.
INSERT INTO alerta_reposicion
 (id_alerta, id_videojuego, stock_detectado, fecha_alerta)
SELECT seq_alerta.NEXTVAL, id_videojuego, stock, SYSDATE
FROM videojuego
WHERE stock < stock_minimo;

COMMIT;

-- ===============================================================
-- c) FUNCIONES ALMACENADAS
-- ===============================================================

-- AGREGADO: identificadores de venta compatibles con la Parte 2.
DECLARE
 v_inicio NUMBER;
 v_existe NUMBER;
BEGIN
 SELECT COUNT(*) INTO v_existe FROM user_sequences
 WHERE sequence_name = 'SEQ_VENTA';
 IF v_existe = 0 THEN
   SELECT GREATEST(NVL(MAX(id_venta), 0) + 1, 1) INTO v_inicio
   FROM (SELECT id_venta FROM venta
         UNION ALL SELECT id_venta FROM venta_anulada);
   EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_venta START WITH ' ||
     TO_CHAR(v_inicio, 'TM9') || ' INCREMENT BY 1';
 END IF;
END;
/

-- AGREGADO: ingresos por producto; incluye inicio y excluye fin del periodo.
CREATE OR REPLACE FUNCTION fn_ingresos_producto (
 p_id_videojuego IN NUMBER, p_fecha_inicio IN DATE, p_fecha_fin IN DATE
) RETURN NUMBER IS
 v_total NUMBER;
BEGIN
 IF p_fecha_inicio IS NULL OR p_fecha_fin IS NULL
    OR p_fecha_fin <= p_fecha_inicio THEN
   RAISE_APPLICATION_ERROR(-20040, 'Periodo invalido');
 END IF;
 SELECT NVL(SUM(d.cantidad * d.precio_unitario), 0) INTO v_total
 FROM venta v JOIN detalle_venta d ON d.id_venta = v.id_venta
 WHERE d.id_videojuego = p_id_videojuego
   AND v.fecha >= p_fecha_inicio AND v.fecha < p_fecha_fin;
 RETURN v_total;
END fn_ingresos_producto;
/
SHOW ERRORS FUNCTION fn_ingresos_producto;

-- SIN parametros: total de videojuegos del catalogo.
CREATE OR REPLACE FUNCTION fn_total_videojuegos RETURN NUMBER IS
 v_total NUMBER;
BEGIN
 SELECT COUNT(*) INTO v_total FROM videojuego;
 RETURN v_total;
END fn_total_videojuegos;
/
SHOW ERRORS FUNCTION fn_total_videojuegos;

-- SIN parametros: total vendido en CLP.
CREATE OR REPLACE FUNCTION fn_total_ventas RETURN NUMBER IS
 v_total NUMBER;
BEGIN
 SELECT NVL(SUM(cantidad * precio_unitario), 0)
 INTO v_total
 FROM detalle_venta;
 RETURN v_total;
END fn_total_ventas;
/
SHOW ERRORS FUNCTION fn_total_ventas;

-- SIN parametros: cantidad de alertas de reposicion pendientes
-- (pendiente = todavia no tiene fecha de atencion).
CREATE OR REPLACE FUNCTION fn_alertas_pendientes RETURN NUMBER IS
 v_total NUMBER;
BEGIN
 SELECT COUNT(*) INTO v_total
 FROM alerta_reposicion
 WHERE fecha_atencion IS NULL;
 RETURN v_total;
END fn_alertas_pendientes;
/
SHOW ERRORS FUNCTION fn_alertas_pendientes;

-- CON parametros: unidades vendidas de un videojuego.
CREATE OR REPLACE FUNCTION fn_unidades_vendidas(
 p_id_videojuego IN NUMBER
) RETURN NUMBER IS
 v_unidades NUMBER;
BEGIN
 SELECT NVL(SUM(cantidad), 0)
 INTO v_unidades
 FROM detalle_venta
 WHERE id_videojuego = p_id_videojuego;
 RETURN v_unidades;
END fn_unidades_vendidas;
/
SHOW ERRORS FUNCTION fn_unidades_vendidas;

-- CON parametros: precio de lista vigente de un videojuego.
CREATE OR REPLACE FUNCTION fn_precio_videojuego(
 p_id_videojuego IN NUMBER
) RETURN NUMBER IS
 v_precio NUMBER;
BEGIN
 SELECT precio INTO v_precio
 FROM precio_videojuego
 WHERE id_videojuego = p_id_videojuego;
 RETURN v_precio;
EXCEPTION
 WHEN NO_DATA_FOUND THEN
   RAISE_APPLICATION_ERROR(-20030, 'Videojuego sin precio de lista');
END fn_precio_videojuego;
/
SHOW ERRORS FUNCTION fn_precio_videojuego;

-- CON parametros: total comprado por un cliente (CLP).
CREATE OR REPLACE FUNCTION fn_total_compras_cliente(
 p_id_cliente IN NUMBER
) RETURN NUMBER IS
 v_total NUMBER;
BEGIN
 SELECT NVL(SUM(d.cantidad * d.precio_unitario), 0)
 INTO v_total
 FROM venta v JOIN detalle_venta d ON d.id_venta = v.id_venta
 WHERE v.id_cliente = p_id_cliente;
 RETURN v_total;
END fn_total_compras_cliente;
/
SHOW ERRORS FUNCTION fn_total_compras_cliente;

-- CON parametros: unidades sugeridas para reponer un videojuego.
-- Regla del negocio: reponer hasta el doble del stock minimo.
CREATE OR REPLACE FUNCTION fn_cantidad_sugerida(
 p_id_videojuego IN NUMBER
) RETURN NUMBER IS
 v_stock videojuego.stock%TYPE;
 v_minimo videojuego.stock_minimo%TYPE;
BEGIN
 SELECT stock, stock_minimo INTO v_stock, v_minimo
 FROM videojuego
 WHERE id_videojuego = p_id_videojuego;
 RETURN GREATEST(v_minimo * 2 - v_stock, 0);
EXCEPTION
 WHEN NO_DATA_FOUND THEN
   RETURN 0;
END fn_cantidad_sugerida;
/
SHOW ERRORS FUNCTION fn_cantidad_sugerida;

-- ===============================================================
-- d) ESPECIFICACIONES DE LOS PACKAGES (parte PUBLICA)
-- ===============================================================

-- Catalogo: videojuegos, precios y clientes.
CREATE OR REPLACE PACKAGE pkg_catalogo IS
 PROCEDURE agregar_videojuego(p_id_categoria IN NUMBER,
   p_nombre IN VARCHAR2, p_stock_minimo IN NUMBER,
   p_precio IN NUMBER, p_id_videojuego OUT NUMBER);
 PROCEDURE actualizar_precio(p_id_videojuego IN NUMBER,
   p_nuevo_precio IN NUMBER);
 PROCEDURE registrar_cliente(p_nombre IN VARCHAR2,
   p_id_cliente OUT NUMBER);
END pkg_catalogo;
/
SHOW ERRORS PACKAGE pkg_catalogo;

-- Ventas: venta con precio de lista, varios productos y anulacion.
CREATE OR REPLACE PACKAGE pkg_ventas IS
 PROCEDURE vender(p_id_cliente IN NUMBER, p_id_videojuego IN NUMBER,
   p_cantidad IN NUMBER, p_id_venta OUT NUMBER);
 PROCEDURE agregar_producto(p_id_venta IN NUMBER,
   p_id_videojuego IN NUMBER, p_cantidad IN NUMBER);
 PROCEDURE anular_venta(p_id_venta IN NUMBER, p_motivo IN VARCHAR2);
 FUNCTION total_venta(p_id_venta IN NUMBER) RETURN NUMBER;
 -- Lo consulta el trigger que bloquea borrados directos.
 FUNCTION anulacion_autorizada RETURN BOOLEAN;
END pkg_ventas;
/
SHOW ERRORS PACKAGE pkg_ventas;

-- Inventario: estado, reposicion, sugerencia de compra y cierre.
CREATE OR REPLACE PACKAGE pkg_inventario IS
 FUNCTION estado_producto(p_stock IN NUMBER, p_minimo IN NUMBER)
   RETURN VARCHAR2;
 PROCEDURE reponer_stock(p_id_videojuego IN NUMBER, p_cantidad IN NUMBER);
 PROCEDURE sugerir_reposicion;
 PROCEDURE mostrar_resumen;
 PROCEDURE cierre_inventario;
END pkg_inventario;
/
SHOW ERRORS PACKAGE pkg_inventario;

-- ===============================================================
-- e) PROCEDIMIENTOS ALMACENADOS
-- ===============================================================

-- AGREGADO: interfaz requerida por pkg_ventas; conserva la transaccion
-- del llamador y descuenta stock una sola vez. No llama a SP_REGISTRAR_VENTA.
CREATE OR REPLACE PROCEDURE pr_registrar_venta (
 p_id_cliente IN NUMBER, p_id_videojuego IN NUMBER,
 p_cantidad IN NUMBER, p_precio IN NUMBER,
 p_fecha IN DATE, p_id_venta OUT NUMBER
) IS
 v_stock videojuego.stock%TYPE;
 v_existe NUMBER;
BEGIN
 SAVEPOINT sp_registrar_venta;
 p_id_venta := NULL;
 IF p_cantidad IS NULL OR p_cantidad <= 0
    OR p_cantidad <> TRUNC(p_cantidad) THEN
   RAISE_APPLICATION_ERROR(-20003, 'Cantidad invalida');
 END IF;
 IF p_precio IS NULL OR p_precio <= 0
    OR p_precio <> ROUND(p_precio, 2) THEN
   RAISE_APPLICATION_ERROR(-20022, 'Precio invalido');
 END IF;
 IF p_fecha IS NULL OR p_fecha > SYSDATE THEN
   RAISE_APPLICATION_ERROR(-20010, 'Fecha obligatoria y no futura');
 END IF;
 SELECT COUNT(*) INTO v_existe FROM cliente WHERE id_cliente = p_id_cliente;
 IF v_existe = 0 THEN
   RAISE_APPLICATION_ERROR(-20004, 'Cliente inexistente');
 END IF;
 BEGIN
   SELECT stock INTO v_stock FROM videojuego
   WHERE id_videojuego = p_id_videojuego FOR UPDATE WAIT 5;
 EXCEPTION WHEN NO_DATA_FOUND THEN
   RAISE_APPLICATION_ERROR(-20002, 'Videojuego inexistente');
 END;
 IF v_stock < p_cantidad THEN
   RAISE_APPLICATION_ERROR(-20007, 'Stock insuficiente');
 END IF;
 p_id_venta := seq_venta.NEXTVAL;
 INSERT INTO venta (id_venta, id_cliente, fecha)
 VALUES (p_id_venta, p_id_cliente, p_fecha);
 INSERT INTO detalle_venta (id_venta, id_videojuego, cantidad, precio_unitario)
 VALUES (p_id_venta, p_id_videojuego, p_cantidad, p_precio);
 UPDATE videojuego SET stock = stock - p_cantidad
 WHERE id_videojuego = p_id_videojuego;
EXCEPTION WHEN OTHERS THEN
 ROLLBACK TO sp_registrar_venta;
 p_id_venta := NULL;
 RAISE;
END pr_registrar_venta;
/
SHOW ERRORS PROCEDURE pr_registrar_venta;

-- SIN parametros - PROCESO MASIVO: resumen de todo el catalogo.
CREATE OR REPLACE PROCEDURE pr_generar_resumen_ventas IS
 v_filas NUMBER := 0;
BEGIN
 DELETE FROM resumen_venta_producto;
 FOR r IN (SELECT j.id_videojuego, j.stock, j.stock_minimo,
                  NVL((SELECT SUM(d.cantidad * d.precio_unitario)
                       FROM detalle_venta d
                       WHERE d.id_videojuego = j.id_videojuego), 0) ingresos
           FROM videojuego j
           ORDER BY j.id_videojuego) LOOP
   INSERT INTO resumen_venta_producto
     (id_videojuego, unidades_vendidas, ingresos,
      stock, stock_minimo, fecha_proceso)
   VALUES
     (r.id_videojuego, fn_unidades_vendidas(r.id_videojuego),
      r.ingresos, r.stock, r.stock_minimo, SYSDATE);
   v_filas := v_filas + 1;
 END LOOP;
 DBMS_OUTPUT.PUT_LINE('Resumen generado: ' || v_filas
   || ' videojuegos procesados.');
END pr_generar_resumen_ventas;
/
SHOW ERRORS PROCEDURE pr_generar_resumen_ventas;

-- SIN parametros - PROCESO MASIVO: reporte de compras por cliente.
CREATE OR REPLACE PROCEDURE pr_reporte_clientes IS
 v_clientes NUMBER := 0;
BEGIN
 DBMS_OUTPUT.PUT_LINE('COMPRAS POR CLIENTE');
 FOR r IN (SELECT id_cliente, nombre FROM cliente
           ORDER BY fn_total_compras_cliente(id_cliente) DESC,
                    id_cliente) LOOP
   DBMS_OUTPUT.PUT_LINE(r.nombre || ' | Total comprado CLP: '
     || fn_total_compras_cliente(r.id_cliente));
   v_clientes := v_clientes + 1;
 END LOOP;
 DBMS_OUTPUT.PUT_LINE('Clientes procesados: ' || v_clientes);
END pr_reporte_clientes;
/
SHOW ERRORS PROCEDURE pr_reporte_clientes;

-- CON parametros (IN e OUT): actualizacion masiva del stock minimo.
CREATE OR REPLACE PROCEDURE pr_actualizar_stock_minimo(
 p_id_categoria IN NUMBER,
 p_nuevo_minimo IN NUMBER,
 p_filas OUT NUMBER
) IS
BEGIN
 IF p_nuevo_minimo IS NULL OR p_nuevo_minimo < 0
    OR p_nuevo_minimo <> TRUNC(p_nuevo_minimo) THEN
   RAISE_APPLICATION_ERROR(-20011, 'Stock minimo invalido');
 END IF;
 UPDATE videojuego
 SET stock_minimo = p_nuevo_minimo
 WHERE id_categoria = p_id_categoria;
 p_filas := SQL%ROWCOUNT;
 IF p_filas = 0 THEN
   DBMS_OUTPUT.PUT_LINE('No hay videojuegos en la categoria '
     || p_id_categoria);
 ELSE
   DBMS_OUTPUT.PUT_LINE('Stock minimo actualizado en ' || p_filas
     || ' videojuegos de la categoria ' || p_id_categoria);
 END IF;
END pr_actualizar_stock_minimo;
/
SHOW ERRORS PROCEDURE pr_actualizar_stock_minimo;

-- ===============================================================
-- f) CUERPOS DE LOS PACKAGES (implementacion + parte PRIVADA)
-- ===============================================================

CREATE OR REPLACE PACKAGE BODY pkg_catalogo IS

 -- PRIVADO: valida textos obligatorios.
 PROCEDURE validar_texto(p_texto IN VARCHAR2, p_campo IN VARCHAR2) IS
 BEGIN
   IF p_texto IS NULL OR LENGTH(TRIM(p_texto)) = 0 THEN
     RAISE_APPLICATION_ERROR(-20021, p_campo || ' es obligatorio');
   END IF;
 END validar_texto;

 -- PRIVADO: valida precios.
 PROCEDURE validar_precio(p_precio IN NUMBER) IS
 BEGIN
   IF p_precio IS NULL OR p_precio <= 0
      OR p_precio <> ROUND(p_precio, 2) THEN
     RAISE_APPLICATION_ERROR(-20022, 'Precio invalido');
   END IF;
 END validar_precio;

 -- PUBLICO: incorpora un videojuego nuevo (sin stock) con su precio.
 PROCEDURE agregar_videojuego(p_id_categoria IN NUMBER,
   p_nombre IN VARCHAR2, p_stock_minimo IN NUMBER,
   p_precio IN NUMBER, p_id_videojuego OUT NUMBER) IS
   v_existe NUMBER;
 BEGIN
   validar_texto(p_nombre, 'Nombre del videojuego');
   validar_precio(p_precio);
   IF p_stock_minimo IS NULL OR p_stock_minimo < 0
      OR p_stock_minimo <> TRUNC(p_stock_minimo) THEN
     RAISE_APPLICATION_ERROR(-20011, 'Stock minimo invalido');
   END IF;
   SELECT COUNT(*) INTO v_existe FROM categoria
   WHERE id_categoria = p_id_categoria;
   IF v_existe = 0 THEN
     RAISE_APPLICATION_ERROR(-20023, 'Categoria inexistente');
   END IF;
   p_id_videojuego := seq_videojuego.NEXTVAL;
   INSERT INTO videojuego
     (id_videojuego, id_categoria, nombre, stock, stock_minimo)
   VALUES (p_id_videojuego, p_id_categoria, TRIM(p_nombre), 0,
     p_stock_minimo);
   INSERT INTO precio_videojuego (id_videojuego, precio, fecha_actualizacion)
   VALUES (p_id_videojuego, p_precio, SYSDATE);
   DBMS_OUTPUT.PUT_LINE('Videojuego agregado: ' || TRIM(p_nombre)
     || ' (ID ' || p_id_videojuego || ')');
 END agregar_videojuego;

 -- PUBLICO: cambia el precio de lista (trg_historial_precio lo registra).
 PROCEDURE actualizar_precio(p_id_videojuego IN NUMBER,
   p_nuevo_precio IN NUMBER) IS
 BEGIN
   validar_precio(p_nuevo_precio);
   UPDATE precio_videojuego
   SET precio = p_nuevo_precio, fecha_actualizacion = SYSDATE
   WHERE id_videojuego = p_id_videojuego;
   IF SQL%ROWCOUNT = 0 THEN
     RAISE_APPLICATION_ERROR(-20030, 'Videojuego sin precio de lista');
   END IF;
   DBMS_OUTPUT.PUT_LINE('Precio actualizado para el videojuego '
     || p_id_videojuego || ': ' || p_nuevo_precio);
 END actualizar_precio;

 -- PUBLICO: registra un cliente nuevo.
 PROCEDURE registrar_cliente(p_nombre IN VARCHAR2,
   p_id_cliente OUT NUMBER) IS
 BEGIN
   validar_texto(p_nombre, 'Nombre del cliente');
   p_id_cliente := seq_cliente.NEXTVAL;
   INSERT INTO cliente (id_cliente, nombre)
   VALUES (p_id_cliente, TRIM(p_nombre));
   DBMS_OUTPUT.PUT_LINE('Cliente registrado: ' || TRIM(p_nombre)
     || ' (ID ' || p_id_cliente || ')');
 END registrar_cliente;

END pkg_catalogo;
/
SHOW ERRORS PACKAGE BODY pkg_catalogo;

CREATE OR REPLACE PACKAGE BODY pkg_ventas IS

 -- PRIVADO: variable de estado. Solo anular_venta la pone en TRUE.
 g_anulando BOOLEAN := FALSE;

 -- PRIVADO: valida cantidades.
 PROCEDURE validar_cantidad(p_cantidad IN NUMBER) IS
 BEGIN
   IF p_cantidad IS NULL OR p_cantidad <= 0
      OR p_cantidad <> TRUNC(p_cantidad) THEN
     RAISE_APPLICATION_ERROR(-20003, 'Cantidad invalida');
   END IF;
 END validar_cantidad;

 -- PRIVADO: descuenta stock bloqueando la fila del videojuego.
 PROCEDURE descontar_stock(p_id_videojuego IN NUMBER,
   p_cantidad IN NUMBER) IS
   v_stock videojuego.stock%TYPE;
 BEGIN
   BEGIN
     SELECT stock INTO v_stock FROM videojuego
     WHERE id_videojuego = p_id_videojuego FOR UPDATE WAIT 5;
   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       RAISE_APPLICATION_ERROR(-20002, 'Videojuego inexistente');
   END;
   UPDATE videojuego SET stock = stock - p_cantidad
   WHERE id_videojuego = p_id_videojuego AND stock >= p_cantidad;
   IF SQL%ROWCOUNT = 0 THEN
     RAISE_APPLICATION_ERROR(-20007, 'Stock insuficiente');
   END IF;
 END descontar_stock;

 -- PUBLICO: total de una venta.
 FUNCTION total_venta(p_id_venta IN NUMBER) RETURN NUMBER IS
   v_total NUMBER;
 BEGIN
   SELECT NVL(SUM(cantidad * precio_unitario), 0) INTO v_total
   FROM detalle_venta WHERE id_venta = p_id_venta;
   RETURN v_total;
 END total_venta;

 -- PUBLICO: informa al trigger si el borrado viene de anular_venta.
 FUNCTION anulacion_autorizada RETURN BOOLEAN IS
 BEGIN
   RETURN g_anulando;
 END anulacion_autorizada;

 -- PUBLICO: venta con PRECIO DE LISTA y fecha actual.
 -- Reutiliza pr_registrar_venta (validaciones, bloqueo y savepoint).
 PROCEDURE vender(p_id_cliente IN NUMBER, p_id_videojuego IN NUMBER,
   p_cantidad IN NUMBER, p_id_venta OUT NUMBER) IS
   v_precio NUMBER;
 BEGIN
   v_precio := fn_precio_videojuego(p_id_videojuego);
   pr_registrar_venta(p_id_cliente, p_id_videojuego, p_cantidad,
     v_precio, SYSDATE, p_id_venta);
   DBMS_OUTPUT.PUT_LINE('Venta ' || p_id_venta || ' registrada a precio de lista: '
     || v_precio);
 END vender;

 -- PUBLICO: agrega otro videojuego a una venta existente.
 PROCEDURE agregar_producto(p_id_venta IN NUMBER,
   p_id_videojuego IN NUMBER, p_cantidad IN NUMBER) IS
   v_existe NUMBER;
   v_precio NUMBER;
 BEGIN
   SAVEPOINT sp_pkg_ventas_agregar;
   validar_cantidad(p_cantidad);
   SELECT COUNT(*) INTO v_existe FROM venta WHERE id_venta = p_id_venta;
   IF v_existe = 0 THEN
     RAISE_APPLICATION_ERROR(-20031, 'Venta inexistente');
   END IF;
   v_precio := fn_precio_videojuego(p_id_videojuego);
   descontar_stock(p_id_videojuego, p_cantidad);
   INSERT INTO detalle_venta
     (id_venta, id_videojuego, cantidad, precio_unitario)
   VALUES (p_id_venta, p_id_videojuego, p_cantidad, v_precio);
   DBMS_OUTPUT.PUT_LINE('Producto ' || p_id_videojuego
     || ' agregado a la venta ' || p_id_venta);
 EXCEPTION
   WHEN DUP_VAL_ON_INDEX THEN
     ROLLBACK TO sp_pkg_ventas_agregar;
     RAISE_APPLICATION_ERROR(-20032,
       'El videojuego ya esta en la venta; modifique la cantidad');
   WHEN OTHERS THEN
     ROLLBACK TO sp_pkg_ventas_agregar;
     RAISE;
 END agregar_producto;

 -- PUBLICO: anula una venta, devuelve el stock y deja registro.
 PROCEDURE anular_venta(p_id_venta IN NUMBER, p_motivo IN VARCHAR2) IS
   v_cliente venta.id_cliente%TYPE;
   v_fecha venta.fecha%TYPE;
   v_total NUMBER;
 BEGIN
   SAVEPOINT sp_pkg_ventas_anular;
   IF p_motivo IS NULL OR LENGTH(TRIM(p_motivo)) = 0 THEN
     RAISE_APPLICATION_ERROR(-20034, 'Debe indicar el motivo');
   END IF;
   BEGIN
     SELECT id_cliente, fecha INTO v_cliente, v_fecha
     FROM venta WHERE id_venta = p_id_venta FOR UPDATE;
   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       RAISE_APPLICATION_ERROR(-20031, 'Venta inexistente');
   END;
   v_total := total_venta(p_id_venta);
   -- Devuelve cada producto al stock (dispara la auditoria de stock).
   FOR d IN (SELECT id_videojuego, cantidad FROM detalle_venta
             WHERE id_venta = p_id_venta) LOOP
     UPDATE videojuego SET stock = stock + d.cantidad
     WHERE id_videojuego = d.id_videojuego;
   END LOOP;
   -- Respaldo: cabecera y detalle (el total se calcula, no se guarda).
   INSERT INTO venta_anulada
     (id_venta, id_cliente, fecha_venta, motivo, usuario, fecha_anulacion)
   VALUES (p_id_venta, v_cliente, v_fecha, TRIM(p_motivo),
     SYS_CONTEXT('USERENV', 'SESSION_USER'), SYSDATE);
   INSERT INTO detalle_venta_anulada
     (id_venta, id_videojuego, cantidad, precio_unitario)
   SELECT id_venta, id_videojuego, cantidad, precio_unitario
   FROM detalle_venta WHERE id_venta = p_id_venta;
   DELETE FROM detalle_venta WHERE id_venta = p_id_venta;
   g_anulando := TRUE;
   DELETE FROM venta WHERE id_venta = p_id_venta;
   g_anulando := FALSE;
   DBMS_OUTPUT.PUT_LINE('Venta ' || p_id_venta || ' anulada. Monto devuelto CLP: '
     || v_total);
 EXCEPTION
   WHEN OTHERS THEN
     g_anulando := FALSE;
     ROLLBACK TO sp_pkg_ventas_anular;
     RAISE;
 END anular_venta;

END pkg_ventas;
/
SHOW ERRORS PACKAGE BODY pkg_ventas;

CREATE OR REPLACE PACKAGE BODY pkg_inventario IS

 -- PRIVADO: constante para el formato de salida.
 c_linea CONSTANT VARCHAR2(60) := RPAD('-', 60, '-');

 -- PRIVADO: imprime una linea.
 PROCEDURE imprimir(p_texto IN VARCHAR2) IS
 BEGIN
   DBMS_OUTPUT.PUT_LINE(p_texto);
 END imprimir;

 -- PRIVADO: porcentaje de un monto sobre el total vendido.
 FUNCTION porcentaje_ventas(p_ingresos IN NUMBER) RETURN NUMBER IS
   v_total NUMBER;
 BEGIN
   v_total := fn_total_ventas;
   IF v_total = 0 THEN
     RETURN 0;
   END IF;
   RETURN ROUND(p_ingresos * 100 / v_total, 1);
 END porcentaje_ventas;

 -- PUBLICO: clasifica un producto segun su stock.
 FUNCTION estado_producto(p_stock IN NUMBER, p_minimo IN NUMBER)
   RETURN VARCHAR2 IS
 BEGIN
   IF p_stock = 0 THEN
     RETURN 'AGOTADO';
   ELSIF p_stock < p_minimo THEN
     RETURN 'STOCK BAJO';
   ELSE
     RETURN 'NORMAL';
   END IF;
 END estado_producto;

 -- PUBLICO: ingreso de mercaderia. Sube el stock y lo registra.
 -- trg_auditoria_stock guarda el cambio y trg_alerta_reposicion
 -- cierra la alerta si el stock vuelve a superar el minimo.
 PROCEDURE reponer_stock(p_id_videojuego IN NUMBER, p_cantidad IN NUMBER) IS
 BEGIN
   IF p_cantidad IS NULL OR p_cantidad <= 0
      OR p_cantidad <> TRUNC(p_cantidad) THEN
     RAISE_APPLICATION_ERROR(-20003, 'Cantidad invalida');
   END IF;
   UPDATE videojuego SET stock = stock + p_cantidad
   WHERE id_videojuego = p_id_videojuego;
   IF SQL%ROWCOUNT = 0 THEN
     RAISE_APPLICATION_ERROR(-20002, 'Videojuego inexistente');
   END IF;
   INSERT INTO reposicion (id_reposicion, id_videojuego, cantidad, usuario, fecha)
   VALUES (seq_reposicion.NEXTVAL, p_id_videojuego, p_cantidad,
     SYS_CONTEXT('USERENV', 'SESSION_USER'), SYSDATE);
   imprimir('Reposicion registrada: videojuego ' || p_id_videojuego
     || ' + ' || p_cantidad || ' unidades');
 END reponer_stock;

 -- PUBLICO: lista de compra sugerida a partir de las alertas pendientes.
 PROCEDURE sugerir_reposicion IS
 BEGIN
   imprimir(c_linea);
   imprimir('SUGERENCIA DE REPOSICION (' || fn_alertas_pendientes
     || ' alertas pendientes)');
   imprimir(c_linea);
   FOR r IN (SELECT j.id_videojuego, j.nombre, j.stock, j.stock_minimo
             FROM alerta_reposicion a
             JOIN videojuego j ON j.id_videojuego = a.id_videojuego
             WHERE a.fecha_atencion IS NULL
             ORDER BY fn_unidades_vendidas(j.id_videojuego) DESC,
                      j.id_videojuego) LOOP
     imprimir(r.nombre || ' | ' || estado_producto(r.stock, r.stock_minimo)
       || ' | Stock: ' || r.stock
       || ' / minimo ' || r.stock_minimo
       || ' | Vendidas: ' || fn_unidades_vendidas(r.id_videojuego)
       || ' | Comprar: ' || fn_cantidad_sugerida(r.id_videojuego));
   END LOOP;
   imprimir(c_linea);
 END sugerir_reposicion;

 -- PUBLICO: imprime el resumen ya generado.
 PROCEDURE mostrar_resumen IS
   v_filas NUMBER := 0;
 BEGIN
   imprimir(c_linea);
   imprimir('RESUMEN DE INVENTARIO Y VENTAS');
   imprimir(c_linea);
   FOR r IN (SELECT j.nombre, s.unidades_vendidas, s.ingresos,
                    s.stock, s.stock_minimo
             FROM resumen_venta_producto s
             JOIN videojuego j ON j.id_videojuego = s.id_videojuego
             ORDER BY s.ingresos DESC, s.id_videojuego) LOOP
     imprimir(r.nombre || ' | Unidades: ' || r.unidades_vendidas
       || ' | Ingresos CLP: ' || r.ingresos
       || ' | ' || porcentaje_ventas(r.ingresos) || '% del total'
       || ' | Stock: ' || r.stock || ' | '
       || estado_producto(r.stock, r.stock_minimo));
     v_filas := v_filas + 1;
   END LOOP;
   IF v_filas = 0 THEN
     imprimir('Sin datos. Ejecute antes pr_generar_resumen_ventas.');
   END IF;
   imprimir(c_linea);
   imprimir('Videojuegos en catalogo: ' || fn_total_videojuegos);
   imprimir('Total vendido CLP: ' || fn_total_ventas);
   imprimir('Alertas de reposicion pendientes: ' || fn_alertas_pendientes);
   imprimir(c_linea);
 END mostrar_resumen;

 -- PUBLICO: cierre completo (resumen + sugerencia de compra).
 PROCEDURE cierre_inventario IS
 BEGIN
   pr_generar_resumen_ventas;
   mostrar_resumen;
   sugerir_reposicion;
 END cierre_inventario;

END pkg_inventario;
/
SHOW ERRORS PACKAGE BODY pkg_inventario;

-- ===============================================================
-- g) TRIGGERS
-- ===============================================================

-- SENTENCIA - AFTER: una fila de auditoria por cada operacion sobre VENTA.
CREATE OR REPLACE TRIGGER trg_venta_sentencia
 AFTER INSERT OR UPDATE OR DELETE ON venta
DECLARE
 v_operacion VARCHAR2(10);
BEGIN
 IF INSERTING THEN
   v_operacion := 'INSERT';
 ELSIF UPDATING THEN
   v_operacion := 'UPDATE';
 ELSIF DELETING THEN
   v_operacion := 'DELETE';
 END IF;
 INSERT INTO auditoria_venta (id_auditoria, operacion, usuario, fecha)
 VALUES (seq_auditoria_venta.NEXTVAL, v_operacion,
         SYS_CONTEXT('USERENV', 'SESSION_USER'), SYSDATE);
END;
/
SHOW ERRORS TRIGGER trg_venta_sentencia;

-- SENTENCIA - BEFORE: las ventas no se borran directamente;
-- solo pkg_ventas.anular_venta puede hacerlo (deja respaldo y devuelve stock).
CREATE OR REPLACE TRIGGER trg_venta_bloquear_borrado
 BEFORE DELETE ON venta
BEGIN
 IF NOT pkg_ventas.anulacion_autorizada THEN
   RAISE_APPLICATION_ERROR(-20020,
     'Las ventas no se eliminan: use pkg_ventas.anular_venta');
 END IF;
END;
/
SHOW ERRORS TRIGGER trg_venta_bloquear_borrado;

-- FILA - BEFORE: no se aceptan ventas con fecha futura.
CREATE OR REPLACE TRIGGER trg_venta_validar_fecha
 BEFORE INSERT OR UPDATE OF fecha ON venta
 FOR EACH ROW
BEGIN
 IF :NEW.fecha > SYSDATE THEN
   RAISE_APPLICATION_ERROR(-20010,
     'La fecha de la venta no puede ser futura');
 END IF;
END;
/
SHOW ERRORS TRIGGER trg_venta_validar_fecha;

-- FILA - AFTER: abre una alerta cuando el stock cae bajo el minimo
-- y la cierra (fecha_atencion) cuando el stock vuelve a alcanzarlo.
CREATE OR REPLACE TRIGGER trg_alerta_reposicion
 AFTER INSERT OR UPDATE OF stock, stock_minimo ON videojuego
 FOR EACH ROW
BEGIN
 IF :NEW.stock < :NEW.stock_minimo
    AND (INSERTING OR NOT (:OLD.stock < :OLD.stock_minimo)) THEN
   INSERT INTO alerta_reposicion
     (id_alerta, id_videojuego, stock_detectado, fecha_alerta)
   VALUES (seq_alerta.NEXTVAL, :NEW.id_videojuego, :NEW.stock, SYSDATE);
 ELSIF UPDATING AND :NEW.stock >= :NEW.stock_minimo
       AND :OLD.stock < :OLD.stock_minimo THEN
   UPDATE alerta_reposicion
   SET fecha_atencion = SYSDATE
   WHERE id_videojuego = :NEW.id_videojuego AND fecha_atencion IS NULL;
 END IF;
END;
/
SHOW ERRORS TRIGGER trg_alerta_reposicion;

-- FILA - AFTER: historial de cambios de precio de lista.
CREATE OR REPLACE TRIGGER trg_historial_precio
 AFTER UPDATE OF precio ON precio_videojuego
 FOR EACH ROW
BEGIN
 IF :OLD.precio <> :NEW.precio THEN
   INSERT INTO historial_precio
     (id_historial, id_videojuego, precio_anterior, precio_nuevo,
      usuario, fecha)
   VALUES (seq_historial_precio.NEXTVAL, :NEW.id_videojuego,
     :OLD.precio, :NEW.precio,
     SYS_CONTEXT('USERENV', 'SESSION_USER'), SYSDATE);
 END IF;
END;
/
SHOW ERRORS TRIGGER trg_historial_precio;

-- (trg_auditoria_stock, FILA - AFTER sobre el stock, viene de la Parte 1)

-- ===============================================================
-- CONTROL: todos deben salir VALID y USER_ERRORS sin filas.
-- ===============================================================
SELECT object_name, object_type, status
FROM user_objects
WHERE object_type IN ('FUNCTION', 'PROCEDURE', 'PACKAGE',
                      'PACKAGE BODY', 'TRIGGER')
ORDER BY object_type, object_name;

SELECT name, type, line, position, text
FROM user_errors
ORDER BY name, sequence;

-- FIN SCRIPT 06


--======================================================================
-- 5. SCRIPT 07_demostracion_eval2.sql
--    (copiar desde aqui hasta "FIN SCRIPT 07")
--======================================================================

-- BDY1103 - Evaluacion Parcial 2 - Demostracion del ciclo del negocio.
-- Ejecutar con F5 en una sesion SIN cambios pendientes.
-- Al final hace ROLLBACK: los datos vuelven a como estaban.
SET SERVEROUTPUT ON;

-- =====================================================================
-- ETAPA 1. CATALOGO Y CLIENTES (pkg_catalogo)
-- =====================================================================
DECLARE
 v_juego NUMBER;
 v_cliente NUMBER;
BEGIN
 -- Nuevo videojuego: entra sin stock, por eso el trigger abre una alerta.
 pkg_catalogo.agregar_videojuego(2, 'Velocidad Extrema', 3, 40000, v_juego);
 -- Cambio de precio: trg_historial_precio guarda el valor anterior.
 pkg_catalogo.actualizar_precio(1, 32000);
 -- Cliente nuevo.
 pkg_catalogo.registrar_cliente('Ana Torres', v_cliente);
 -- Error controlado: precio invalido.
 BEGIN
   pkg_catalogo.actualizar_precio(2, -100);
 EXCEPTION
   WHEN OTHERS THEN
     DBMS_OUTPUT.PUT_LINE('Error esperado: ' || SQLERRM);
 END;
END;
/
-- Precio de lista de todo el catalogo (funcion con parametros en SQL).
SELECT id_videojuego, nombre, fn_precio_videojuego(id_videojuego) AS precio_lista
FROM videojuego ORDER BY id_videojuego;
SELECT id_videojuego, precio_anterior, precio_nuevo, usuario
FROM historial_precio ORDER BY id_historial;

-- =====================================================================
-- ETAPA 2. VENTA CON PRECIO DE LISTA Y VARIOS PRODUCTOS (pkg_ventas)
-- =====================================================================
SET SERVEROUTPUT ON;

DECLARE
 v_cliente NUMBER;
 v_venta NUMBER;
BEGIN
 SELECT MAX(id_cliente) INTO v_cliente
 FROM cliente WHERE nombre = 'Ana Torres';

 -- Preparacion: si no se ejecuto la etapa 1, crear el cliente necesario.
 IF v_cliente IS NULL THEN
   pkg_catalogo.registrar_cliente('Ana Torres', v_cliente);
 END IF;

 pkg_ventas.vender(v_cliente, 2, 1, v_venta);          -- Mundo Lunar
 pkg_ventas.agregar_producto(v_venta, 4, 1);           -- Carrera Urbana

 DBMS_OUTPUT.PUT_LINE('Total de la venta ' || v_venta || ': '
   || pkg_ventas.total_venta(v_venta));

 -- Errores controlados.
-- BEGIN
--   pkg_ventas.agregar_producto(v_venta, 4, 1);
-- EXCEPTION
--   WHEN OTHERS THEN
--     DBMS_OUTPUT.PUT_LINE('Error esperado: ' || SQLERRM);
-- END;

-- BEGIN
  -- pkg_ventas.vender(v_cliente, 3, 5, v_venta);        -- Futbol Total: stock 1
-- EXCEPTION
--   WHEN OTHERS THEN
--     DBMS_OUTPUT.PUT_LINE('Error esperado: ' || SQLERRM);
-- END;
END;
/

-- Compras por cliente (funcion con parametros en SQL + procedimiento masivo).
SELECT id_cliente, nombre,
       fn_total_compras_cliente(id_cliente) AS total_comprado
FROM cliente
ORDER BY id_cliente;

BEGIN
 pr_reporte_clientes;
END;
/

-- =====================================================================
-- ETAPA 3. CORRECCION: ANULAR LA VENTA (pkg_ventas + trigger de sentencia)
-- =====================================================================
DECLARE
 v_venta NUMBER;
BEGIN
 SELECT MAX(v.id_venta) INTO v_venta
 FROM venta v JOIN cliente c ON c.id_cliente = v.id_cliente
 WHERE c.nombre = 'Ana Torres';
 pkg_ventas.anular_venta(v_venta, 'Error de digitacion');
 -- Un DELETE directo es bloqueado por trg_venta_bloquear_borrado.
 BEGIN
   DELETE FROM venta WHERE id_venta = 1;
 EXCEPTION
   WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Bloqueado: ' || SQLERRM);
 END;
END;
/
-- El total de la venta anulada se calcula desde su detalle (3FN).
SELECT a.id_venta, a.motivo, a.usuario,
       SUM(d.cantidad * d.precio_unitario) AS total_anulado
FROM venta_anulada a JOIN detalle_venta_anulada d ON d.id_venta = a.id_venta
GROUP BY a.id_venta, a.motivo, a.usuario;
SELECT id_videojuego, nombre, stock FROM videojuego
WHERE id_videojuego IN (2, 4) ORDER BY id_videojuego;

-- =====================================================================
-- ETAPA 4. ALERTAS Y SUGERENCIA DE COMPRA (trigger + pkg_inventario)
-- =====================================================================
-- Tipo y estado se calculan al consultar (no se guardan: 3FN).
SELECT a.id_alerta, j.nombre, a.stock_detectado,
       CASE WHEN a.stock_detectado = 0 THEN 'AGOTADO' ELSE 'STOCK BAJO' END AS tipo,
       CASE WHEN a.fecha_atencion IS NULL THEN 'PENDIENTE' ELSE 'ATENDIDA' END AS estado
FROM alerta_reposicion a JOIN videojuego j ON j.id_videojuego = a.id_videojuego
ORDER BY a.id_alerta;
SELECT fn_alertas_pendientes AS alertas_pendientes FROM dual;
BEGIN
 pkg_inventario.sugerir_reposicion;
END;
/

-- =====================================================================
-- ETAPA 5. REPOSICION: LLEGA MERCADERIA (pkg_inventario + triggers)
-- =====================================================================

SET SERVEROUTPUT ON;

DECLARE
 v_cantidad NUMBER;
BEGIN
 DBMS_OUTPUT.PUT_LINE(
   'Alertas pendientes antes: ' || fn_alertas_pendientes
 );

 -- Isla Perdida: reponer solo si la cantidad sugerida es positiva.
 v_cantidad := fn_cantidad_sugerida(1);

 IF v_cantidad > 0 THEN
   pkg_inventario.reponer_stock(1, v_cantidad);
 ELSE
   DBMS_OUTPUT.PUT_LINE('Isla Perdida ya tiene stock suficiente.');
 END IF;

 DBMS_OUTPUT.PUT_LINE(
   'Alertas pendientes despues: ' || fn_alertas_pendientes
 );
END;
/

-- Mostrar las alertas y su estado despues de la reposicion.
SELECT a.id_alerta, j.nombre,
       CASE
         WHEN a.fecha_atencion IS NULL THEN 'PENDIENTE'
         ELSE 'ATENDIDA'
       END AS estado,
       a.fecha_atencion
FROM alerta_reposicion a
JOIN videojuego j ON j.id_videojuego = a.id_videojuego
ORDER BY a.id_alerta;

-- Mostrar los ingresos de mercaderia registrados.
SELECT r.id_reposicion, j.nombre, r.cantidad
FROM reposicion r
JOIN videojuego j ON j.id_videojuego = r.id_videojuego
ORDER BY r.id_reposicion;

-- Comprobar el stock final de Isla Perdida.
SELECT id_videojuego, nombre, stock, stock_minimo
FROM videojuego
WHERE id_videojuego = 1;

-- =====================================================================
-- ETAPA 6. REPORTES Y DECISION (funciones, procedimientos y cierre)
-- =====================================================================
SELECT fn_total_videojuegos AS total_videojuegos,
       fn_total_ventas      AS total_ventas_clp
FROM dual;

SELECT id_videojuego,
       nombre,
       stock,
       fn_unidades_vendidas(id_videojuego) AS unidades,
       fn_ingresos_producto(id_videojuego, DATE '2026-09-01',
                            DATE '2026-10-01') AS ingresos_sep_2026,
       pkg_inventario.estado_producto(stock, stock_minimo) AS estado
FROM videojuego
ORDER BY id_videojuego;

DECLARE
 v_filas NUMBER;
BEGIN
 pr_actualizar_stock_minimo(2, 2, v_filas);
 DBMS_OUTPUT.PUT_LINE('Filas devueltas por el parametro OUT: ' || v_filas);
 BEGIN
   pr_actualizar_stock_minimo(2, -5, v_filas);
 EXCEPTION
   WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Error esperado: ' || SQLERRM);
 END;
END;
/

-- Cierre: resumen masivo + sugerencia de compra.
BEGIN
 pkg_inventario.cierre_inventario;
END;
/
-- Esto NO funciona porque "imprimir" es PRIVADO (no esta en la especificacion).
-- Descomentar en la presentacion para mostrar el error PLS-00302:
-- BEGIN pkg_inventario.imprimir('hola'); END;
-- /

-- =====================================================================
-- ETAPA 7. TRIGGERS: SENTENCIA vs FILA
-- =====================================================================
DECLARE
 v_antes NUMBER;
 v_despues NUMBER;
 v_filas NUMBER;
BEGIN
 -- Sentencia: 2 ventas modificadas -> 1 registro de auditoria.
 SELECT COUNT(*) INTO v_antes FROM auditoria_venta;
 UPDATE venta SET fecha = fecha WHERE id_cliente = 1;
 v_filas := SQL%ROWCOUNT;
 SELECT COUNT(*) INTO v_despues FROM auditoria_venta;
 DBMS_OUTPUT.PUT_LINE('SENTENCIA: filas modificadas ' || v_filas
   || ' | registros en AUDITORIA_VENTA ' || (v_despues - v_antes));
 -- Fila: 2 videojuegos modificados -> 2 registros de auditoria.
 SELECT COUNT(*) INTO v_antes FROM auditoria_stock;
 UPDATE videojuego SET stock = stock - 1 WHERE id_categoria = 1;
 v_filas := SQL%ROWCOUNT;
 SELECT COUNT(*) INTO v_despues FROM auditoria_stock;
 DBMS_OUTPUT.PUT_LINE('FILA: filas modificadas ' || v_filas
   || ' | registros en AUDITORIA_STOCK ' || (v_despues - v_antes));
 -- Fila BEFORE: venta con fecha futura.
 BEGIN
   INSERT INTO venta (id_venta, id_cliente, fecha)
   VALUES (seq_venta.NEXTVAL, 1, SYSDATE + 30);
 EXCEPTION
   WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Rechazada: ' || SQLERRM);
 END;
END;
/

-- Deja todo como estaba.
ROLLBACK;

-- FIN SCRIPT 07

/*
======================================================================
 6. RESULTADOS ESPERADOS DE LA DEMOSTRACION
    (datos base de la Parte 1. Los ID nuevos salen 100 la primera vez;
     si repites la demo pueden ser mayores, porque las secuencias avanzan)
======================================================================

ETAPA 1 - Catalogo y clientes
  "Videojuego agregado: Velocidad Extrema (ID 100)"
  "Precio actualizado para el videojuego 1: 32000"
  "Cliente registrado: Ana Torres (ID 100)"
  "Error esperado: ORA-20022: Precio invalido"
  Precios: Isla Perdida 32000 | Mundo Lunar 25000 | Futbol Total 45000 |
           Carrera Urbana 35000 | Velocidad Extrema 40000
  Historial de precio: videojuego 1, 30000 -> 32000

ETAPA 2 - Venta
  "Venta <n> registrada a precio de lista: 25000"
  "Producto 4 agregado a la venta <n>"
  "Total de la venta <n>: 60000"
  "Error esperado: ORA-20032: El videojuego ya esta en la venta..."
  "Error esperado: ORA-20007: Stock insuficiente"
  Compras por cliente: Cliente de prueba 185000 | Ana Torres 60000

ETAPA 3 - Correccion
  "Venta <n> anulada. Monto devuelto CLP: 60000"
  "Bloqueado: ORA-20020: Las ventas no se eliminan: use pkg_ventas.anular_venta"
  VENTA_ANULADA: 1 fila con motivo "Error de digitacion"
  DETALLE_VENTA_ANULADA: 2 filas (Mundo Lunar y Carrera Urbana);
  total_anulado calculado = 60000
  Stock devuelto: Mundo Lunar 8 | Carrera Urbana 10

ETAPA 4 - Alertas y sugerencia
  Alertas (tipo y estado calculados en el SELECT):
  Isla Perdida (2, STOCK BAJO, PENDIENTE), Futbol Total (1, STOCK BAJO,
  PENDIENTE), Velocidad Extrema (0, AGOTADO, PENDIENTE)  -> alertas_pendientes = 3
  Sugerencia (ordenada por unidades vendidas):
    Isla Perdida      | Stock 2 / minimo 5 | Vendidas 3 | Comprar 8
    Futbol Total      | Stock 1 / minimo 4 | Vendidas 1 | Comprar 7
    Velocidad Extrema | Stock 0 / minimo 3 | Vendidas 0 | Comprar 6

ETAPA 5 - Reposicion
  "Reposicion registrada: videojuego 1 + 8 unidades"
  "Reposicion registrada: videojuego 100 + 6 unidades"
  "Error esperado: ORA-20003: Cantidad invalida"
  "Alertas pendientes despues de reponer: 1"
  Isla Perdida y Velocidad Extrema quedan ATENDIDA (fecha_atencion con fecha);
  Futbol Total sigue PENDIENTE.

ETAPA 6 - Reportes y decision
  total_videojuegos = 5 | total_ventas_clp = 185000 (la venta anulada no cuenta)
  ID  NOMBRE             STOCK UNIDADES INGRESOS_SEP ESTADO
  1   Isla Perdida         10      3       90000     NORMAL
  2   Mundo Lunar           8      2       50000     NORMAL
  3   Futbol Total          1      1       45000     STOCK BAJO
  4   Carrera Urbana       10      0           0     NORMAL
  100 Velocidad Extrema     6      0           0     NORMAL
  "Stock minimo actualizado en 3 videojuegos de la categoria 2"
  "Filas devueltas por el parametro OUT: 3"
  "Error esperado: ORA-20011: Stock minimo invalido"
  Cierre: "Resumen generado: 5 videojuegos procesados."
    Isla Perdida 90000 (48,6%) NORMAL | Mundo Lunar 50000 (27%) NORMAL |
    Futbol Total 45000 (24,3%) STOCK BAJO | Carrera Urbana 0 | Velocidad Extrema 0
    Videojuegos 5 | Total vendido 185000 | Alertas pendientes 1
    Sugerencia: Futbol Total | Stock 1 / minimo 2 | Vendidas 1 | Comprar 3

ETAPA 7 - Sentencia vs fila
  "SENTENCIA: filas modificadas 2 | registros en AUDITORIA_VENTA 1"
  "FILA: filas modificadas 2 | registros en AUDITORIA_STOCK 2"
  "Rechazada: ORA-20010: La fecha de la venta no puede ser futura"

Despues del ROLLBACK final no queda nada de la demo
(las secuencias si avanzan; es normal en Oracle).

(El separador decimal puede salir con coma o punto segun tu Oracle.)


======================================================================
 7. (OPCIONAL) BORRAR LOS OBJETOS DE LA PARTE 2
    Usar si el 06 fallo a medias o si ejecutaste la version anterior.
    NO borra nada de la Parte 1. Si alguno dice "no existe", ignoralo.
======================================================================
*/
/*
DROP TRIGGER trg_historial_precio;
DROP TRIGGER trg_alerta_reposicion;
DROP TRIGGER trg_venta_validar_fecha;
DROP TRIGGER trg_venta_bloquear_borrado;
DROP TRIGGER trg_venta_sentencia;
DROP PACKAGE pkg_inventario;
DROP PACKAGE pkg_ventas;
DROP PACKAGE pkg_catalogo;
DROP PROCEDURE pr_actualizar_stock_minimo;
DROP PROCEDURE pr_reporte_clientes;
DROP PROCEDURE pr_generar_resumen_ventas;
DROP FUNCTION fn_cantidad_sugerida;
DROP FUNCTION fn_total_compras_cliente;
DROP FUNCTION fn_precio_videojuego;
DROP FUNCTION fn_unidades_vendidas;
DROP FUNCTION fn_alertas_pendientes;
DROP FUNCTION fn_total_ventas;
DROP FUNCTION fn_total_videojuegos;
DROP TABLE auditoria_venta;
DROP TABLE resumen_venta_producto;
DROP TABLE detalle_venta_anulada;
DROP TABLE venta_anulada;
DROP TABLE reposicion;
DROP TABLE alerta_reposicion;
DROP TABLE historial_precio;
DROP TABLE precio_videojuego;
DROP SEQUENCE seq_auditoria_venta;
DROP SEQUENCE seq_reposicion;
DROP SEQUENCE seq_alerta;
DROP SEQUENCE seq_cliente;
DROP SEQUENCE seq_videojuego;
DROP SEQUENCE seq_historial_precio;
-- Si agregaste videojuegos o clientes con pkg_catalogo y los confirmaste
-- con COMMIT, quedan en las tablas de la Parte 1 (no se borran aqui).
*/
USE leaseoper
GO

IF OBJECT_ID('dbo.pa_lo_interfaz_M_31agri01LI') IS NOT NULL
	DROP PROCEDURE dbo.pa_lo_interfaz_M_31agri01LI
GO

CREATE PROCEDURE [dbo].[pa_lo_interfaz_M_31agri01LI] @fecha_proceso SMALLDATETIME
	,@salida TINYINT OUT
AS
/*
Nombre             : pa_lo_interfaz_M_31agri01LI

Descripción        : 
Parametros entrada : @num_proceso : Número de Proceso de Envío.

Parametros salida  : N/E

Tablas entrada     : 

Tablas salida      : 

Fecha              : 30-JUL-2014.

Modificaciones     :

Procedimientos que Llama :

Observaciones      : 

Autor              : Miguel Cornejo J

   EXEC pa_lo_interfaz_M_31agri01LI '16/12/2014',0

*/
DECLARE @sumatoria CHAR(16)
	,@num_reg INT
	,@saldo_insoluto FLOAT

SET NOCOUNT ON

SELECT @sumatoria = convert(CHAR(16), str(sum(convert(FLOAT, a.valor)), 16, 0))
FROM t_bienes_detalle a
	,t_contratos b
WHERE a.operacion = b.rut_cliente
	AND b.fecha_ingreso_cont <= @fecha_proceso

SELECT @num_reg = count(b.operacion)
FROM leasecom..v_clientes a
	,t_contratos b
	,Leaseoper..t_bienes_detalle c
	,leasecom..t_clientes d
WHERE a.rut = b.rut_cliente
	AND b.rut_cliente = d.rut_cliente
	AND b.fecha_ingreso_cont <= @fecha_proceso

SELECT convert(CHAR(8), @fecha_proceso, 112) + --fecha_proc 
	'BANCODECHILE LEASINGANDINO' +
	--[Detalle]-- 
	convert(CHAR(3), b.cod_oficina_real) + --ofici_agri
	isnull((
			SELECT convert(CHAR(5), id_cliente)
			FROM t_datos_cliente_banco cb
			WHERE cb.lberut = a.rut
			), REPLICATE('', 6)) + --clien_agri
	convert(CHAR(9), b.operacion) + --contr_agri
	convert(CHAR(9), c.cod_material) + --mater_agri
	convert(CHAR(40), a.nombre) + --rsoci_agri
	SUBSTRING(REPLICATE('0', 9 - DATALENGTH(RTRIM(CONVERT(CHAR(9), a.rut)))) + RTRIM(CONVERT(CHAR(9), a.rut)), 1, 9) + --a.rut
	a.dv + --dveri_agri
	convert(CHAR(4), (d.cod_rubro * 100) + d.cod_rubro_especifico) + --crubr_agri       
	convert(CHAR(40), a.direccion) + (
		SELECT convert(CHAR(15), loc.descripcion)
		FROM t_clientes_direccion cdir
			,leasecom..p_localidad loc
		WHERE cdir.rut = a.rut
			AND cdir.cod_comuna = loc.cod_comuna_cia
		) + --comun_agri	
	(
		SELECT convert(CHAR(15), pciu.cod_ciudad)
		FROM t_clientes_direccion cdir
			,leasecom..p_localidad loc
			,leasecom..p_ciudad pciu
		WHERE cdir.rut = a.rut
			AND cdir.cod_comuna = loc.cod_comuna_cia
			AND loc.cod_ciudad = pciu.cod_ciudad
		) + --ciuda_agri
	(
		SELECT convert(CHAR(2), preg.cod_region)
		FROM t_clientes_direccion cdir
			,leasecom..p_localidad loc
			,leasecom..p_regiones preg
		WHERE cdir.rut = a.rut
			AND cdir.cod_comuna = loc.cod_comuna_cia
			AND loc.cod_region = preg.cod_region
		) + --regio_agri
	convert(CHAR(50), c.descripcion) + --miden_agri
	convert(CHAR(38), a.nombre) + --descr_cont
	convert(CHAR(3), e.cantidad) + --nunid_cont
	CASE c.fecha_acta_recepcion
		WHEN NULL
			THEN isnull((
						SELECT convert(CHAR(9), (pvp.valor * c.valor))
						FROM t_contratos cb
						LEFT OUTER JOIN leasecom..p_valor_paridades pvp ON cb.fecha_ing_carta_recep = pvp.fecha
							AND pvp.cod_moneda = cb.cod_moneda_contrato
						WHERE cb.operacion = c.operacion
						), c.valor)
		ELSE (
				isnull((
						SELECT convert(CHAR(9), (pvp.valor * c.valor))
						FROM t_contratos cb
						LEFT OUTER JOIN leasecom..p_valor_paridades pvp ON cb.fecha_ing_carta_recep = pvp.fecha
							AND pvp.cod_moneda = cb.cod_moneda_contrato
						WHERE cb.operacion = c.operacion
						), c.valor)
				)
		END + --vcmat_cont
	CASE c.fecha_acta_recepcion
		WHEN NULL
			THEN b.fecha_ing_carta_recep
		ELSE c.fecha_acta_recepcion
		END + --vcori_cont
	(
		SELECT convert(CHAR(8), tvh.marca)
		FROM t_vehiculos_detalle tvh
		WHERE tvh.operacion = b.operacion
		) + --facti_cont
	(
		SELECT convert(CHAR(8), tvh.modelo)
		FROM t_vehiculos_detalle tvh
		WHERE tvh.operacion = b.operacion
		) + --fevig_cont   
	(
		SELECT convert(CHAR(8), tvh.tipo_vehiculo)
		FROM t_vehiculos_detalle tvh
		WHERE tvh.operacion = b.operacion
		) + --fterm_con    
	'' +
	--cober_cont
	--blanc_cont
	convert(CHAR(9),@num_reg) + 
	@sumatoria
FROM leasecom..v_clientes a
	,t_contratos b
	,Leaseoper..t_bienes_detalle c
	,t_contratos_anexo d
	,t_bienes e
	,t_seguro_cliente f
	,p_ramos g
WHERE a.rut = b.rut_cliente
	AND b.operacion = c.operacion
	AND b.operacion = d.operacion
	AND b.operacion = e.operacion
	AND f.cod_ramo = 44 --equipo agricolas
	AND f.operacion = b.operacion
	AND b.fecha_ingreso_cont <= @fecha_proceso

RETURN 0

GRANT EXECUTE
	ON dbo.pa_lo_interfaz_M_31agri01LI
	TO Usuarios
GO



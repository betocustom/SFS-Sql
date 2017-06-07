USE leaseoper
GO

IF OBJECT_ID ('dbo.pa_lo_interfaz_M_31_comp01PE_096683120') IS NOT NULL
	DROP PROCEDURE dbo.pa_lo_interfaz_M_31_comp01PE_096683120
GO

CREATE PROCEDURE [dbo].[pa_lo_interfaz_M_31_comp01PE_096683120]
    @fecha_proceso  SMALLDATETIME ,
    @salida	        TINYINT OUT
AS
/*
Nombre             : pa_lo_interfaz_M_31_comp01PE_096683120

Descripci�n        : 
Parametros entrada : @num_proceso : N�mero de Proceso de Env�o.

Parametros salida  : N/E

Tablas entrada     : 

Tablas salida      : 

Fecha              : 30-JUL-2014.

Modificaciones     :

Procedimientos que Llama :

Observaciones      : 

Autor              : Miguel Cornejo J

   EXEC pa_lo_interfaz_M_31_comp01PE_096683120 '16/12/2014',0

*/
DECLARE @sumatoria CHAR(16),
        @num_reg  INT,
        @saldo_insoluto FLOAT 
        
SET NOCOUNT ON






 SELECT  @sumatoria= convert(CHAR(16),str(sum(convert(float,a.valor)),16,0))
   FROM  t_bienes_detalle a,
	     t_contratos b
   WHERE a.operacion = b.rut_cliente
    AND b.fecha_ingreso_cont <= @fecha_proceso


SELECT @num_reg  = count(b.operacion)		      		      
   FROM leasecom..v_clientes a,
        t_contratos b,
        Leaseoper..t_bienes_detalle c,
        leasecom..t_clientes d        
   WHERE a.rut = b.rut_cliente  
    AND b.rut_cliente = d.rut_cliente
    AND b.fecha_ingreso_cont <= @fecha_proceso




SELECT convert(CHAR(8), @fecha_proceso, 112) + --fecha_proc 
	'BANCODECHILE LEASINGANDINO' +
	--[Detalle]-- 
	convert(CHAR(3), b.cod_oficina_real) + --ofici_casc
	isnull((
			SELECT convert(CHAR(5), id_cliente)
			FROM t_datos_cliente_banco cb
			WHERE cb.lberut = a.rut
			), REPLICATE('', 5)) + --clien_casc
	convert(CHAR(4), (d.cod_rubro * 100) + d.cod_rubro_especifico) + --contr_casc
	convert(CHAR(9), c.cod_material) + --mater_casc
	convert(CHAR(40), a.nombre) + --rsoci_casc
       SUBSTRING(REPLICATE('0',9 -DATALENGTH(RTRIM(CONVERT(CHAR(9),a.rut))))+ RTRIM(CONVERT(CHAR(9),a.rut)),1,9)+--a.rut
       a.dv + --dveri_agri
       convert(CHAR(4), (d.cod_rubro * 100) + d.cod_rubro_especifico)+ --crubr_agri       
       	convert(CHAR(40), a.direccion) + 
       (
		SELECT convert(CHAR(15), loc.descripcion)
		FROM t_clientes_direccion cdir
			,leasecom..p_localidad loc
		WHERE cdir.rut = a.rut
			AND cdir.cod_comuna = loc.cod_comuna_cia
		) + --comun_casc	
	(
		SELECT convert(CHAR(15), pciu.cod_ciudad)
		FROM t_clientes_direccion cdir
			,leasecom..p_localidad loc
			,leasecom..p_ciudad pciu
		WHERE cdir.rut = a.rut
			AND cdir.cod_comuna = loc.cod_comuna_cia
			AND loc.cod_ciudad = pciu.cod_ciudad
		) + --ciuda_casc
	(
		SELECT convert(CHAR(2), preg.cod_region)
		FROM t_clientes_direccion cdir
			,leasecom..p_localidad loc
			,leasecom..p_regiones preg
		WHERE cdir.rut = a.rut
			AND cdir.cod_comuna = loc.cod_comuna_cia
			AND loc.cod_region = preg.cod_region
		) + --regio_comp
	convert(CHAR(50), c.descripcion) + --miden_casc
	convert(CHAR(38), a.nombre) +      --descr_cont
	convert(CHAR(3), e.cantidad) +     --nunid_cont
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
		END +--vcmat_comp
       CASE c.fecha_acta_recepcion 
        WHEN NULL THEN convert(CHAR(8),b.fecha_ing_carta_recep,112)
        ELSE convert(CHAR(8),c.fecha_acta_recepcion,112)
       END+  --fevig_comp
       convert(CHAR(8), b.fecha_termino,112)+  --fterm_comp
        convert(CHAR(40), a.direccion) + 
       (
		SELECT convert(CHAR(15), loc.descripcion)
		FROM t_clientes_direccion cdir
			,leasecom..p_localidad loc
		WHERE cdir.rut = a.rut
			AND cdir.cod_comuna = loc.cod_comuna_cia
		) + --comun_casc	
	(
		SELECT convert(CHAR(15), pciu.cod_ciudad)
		FROM t_clientes_direccion cdir
			,leasecom..p_localidad loc
			,leasecom..p_ciudad pciu
		WHERE cdir.rut = a.rut
			AND cdir.cod_comuna = loc.cod_comuna_cia
			AND loc.cod_ciudad = pciu.cod_ciudad
		) + --ciuda_casc
	(
		SELECT convert(CHAR(2), preg.cod_region)
		FROM t_clientes_direccion cdir
			,leasecom..p_localidad loc
			,leasecom..p_regiones preg
		WHERE cdir.rut = a.rut
			AND cdir.cod_comuna = loc.cod_comuna_cia
			AND loc.cod_region = preg.cod_region
		) + --regio_casc
       ' '+ --derec_comp
       --cober_cont
       REPLICATE('0',254)+--filler
       convert(CHAR(9),@num_reg)+
       @sumatoria
   FROM leasecom..v_clientes a,
        t_contratos b,
        Leaseoper..t_bienes_detalle c,
        t_contratos_anexo d,
        t_bienes e,
        t_seguro_cliente f,
        p_ramos g       
   WHERE a.rut = b.rut_cliente
    AND b.operacion = c.operacion
    AND b.operacion = d.operacion
    AND b.operacion = e.operacion
    AND f.cod_ramo  = 44
    AND f.operacion = b.operacion
    AND b.fecha_ingreso_cont <= @fecha_proceso






RETURN 0


GRANT EXECUTE ON dbo.pa_lo_interfaz_M_31_comp01PE_096683120 TO Usuarios
GO


USE [leaseoper]
GO
/****** Object:  StoredProcedure [dbo].[pa_lo_interfaz_rez001]    Script Date: 06/03/2014 16:20:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




/****** Objeto:  procedimiento almacenado dbo.pa_lo_interfaz_rez001    fecha de la secuencia de comandos: 09-07-2007 9:25:28 ******/
ALTER PROCEDURE [dbo].[pa_lo_interfaz_rez001]
@fecha_proceso    SMALLDATETIME,
@salida            INT OUTPUT
AS
/*
Nombre            :  pa_lo_interfaz_rez001

Descripción       : 

Parametros entrada: @fecha_proceso:

Parametros salida :  Ninguno.

Tablas entrada    :  t_contratos - t_cuotas

Tablas salida     :  Archivo plano.

Fecha             :  Enero 2014.

Modificaciones    :

Procedimientos que Llama :

Observaciones      :  

Autor              : Verónica Inzunza.

Ejecucion          :  

EXEC leaseoper..pa_lo_interfaz_rez001 '19/03/2014',0
EXEC leaseoper..pa_lo_interfaz_rez001 '24/03/2014',0

*/
set nocount on
--

DECLARE
  @operacion            INT,
  @rut_cliente          INT,
  @cod_moneda           TINYINT,
  @estado_operacion     TINYINT,
  @fecha_ing_cont       SMALLDATETIME,
  @ejecutivo_contrato	NUMERIC(4),
  @monto_cto_orig       FLOAT,
  @tasa_var				FLOAT,
  @tasa_spre			FLOAT,
  @monto_pie			FLOAT,
  @cla_cartera			INT,
  @num_contrato			INT,
  @cod_oficina			INT,
  @id_cliente			INT,
  @fec_suscripcion		SMALLDATETIME,
  @tipo_periodo_arr		FLOAT, 
  @fec_vencimiento      SMALLDATETIME,
  @num_cuota			INT,
  @capital_cuo			float,
  @interes_cuo			float,
  @iva_cuo				FLOAT,
  @total_reg			INT,
  @total_rut			BIGINT,
  @cuota_abono			FLOAT,
  @capital_abono		FLOAT,
  @dv					CHAR(1),
  @rut					INT,
  @oficina				char(2),
  @cliente				char(5),
  @contrato				char(3),
  @reneg				INT,
  @tasa_anual			FLOAT,
  @fec_ultima_factur	CHAR(8),
  --@ultimo_pag_minimo	dec(11),
  @ultimo_pag_minimo	FLOAT,
  @codigo_bloqueo		CHAR(2),
  @marca_cuotas			CHAR(1)

--
IF @fecha_proceso IS NULL OR @fecha_proceso = '01/01/1900'
BEGIN
   SELECT @salida = 0
   --RAISERROR 20000 'Debe Ingresar Periodo a Procesar'
   RETURN 1
END
--

DECLARE
	@cto_negocio		CHAR(3),
	@tprod				CHAR(3),
	@rut_dv				CHAR(10),
	@ofope				CHAR(3),
	@tipo_oper			CHAR(05),
	@num_oper			CHAR(17),
	@subop				CHAR(3),
	@filler_1			CHAR(6),
	@ofi_cli			CHAR(03),	
	@ejecutivo			CHAR(03),	
	@moneda				CHAR(03), 
	--@monto			DEC(13,4),	
	@monto				FLOAT,
	@fec_suscrip		CHAR(08),	
	--@paridad			DEC(6,4),
	@paridad			FLOAT,	 
	@fec_termino		CHAR(08),	   
	--@saldo_cap		DEC(13,4),	
	--@saldo_insoluto	DEC(13,4),
	@saldo_cap			FLOAT,
	@saldo_insoluto		FLOAT,
	@num_cuotas 		CHAR(03),
	@estado_credito		CHAR(02),
	@fec_estado			CHAR(08),
	@renegociado		CHAR(01),
	@fec_prim_impaga	CHAR(08),
	@num_cuotas_impag	CHAR(03),
	@fec_ultimo_pago	CHAR(08),
	--@tasa_ptmo		DEC(8,5),
	@tasa_ptmo			FLOAT,
	--@rebaja_cuota		DEC(13,4),
	--@valor_prox_cuota	DEC(13,4),
	@rebaja_cuota		FLOAT,
	@valor_prox_cuota	FLOAT,
	@fec_prox_cuota		CHAR(08),
	@frec_pago			CHAR(01),
	@peridiocidad_pago	CHAR(03),
	@cupo_nacional		CHAR(11),
	--@cupo_internac    	DEC(13,2),
	@cupo_internac		FLOAT,
	@tot_factura_nac  	DEC(11),
	--@tot_factura_inter	DEC(13,2),
	@tot_factura_inter	FLOAT,
	--@ult_pag_minimo 	DEC(11),
	@ult_pag_minimo		FLOAT,
	@cod_bloqueo   		CHAR(02),
	@convenio_pago    	CHAR(01),
	@fec_prox_factura 	CHAR(08),
	@tramo_factura    	CHAR(01),
	@solicitud			CHAR(01),
	@fec_infor			CHAR(08),
	@conve_cartera		CHAR(05),
	@sistema			CHAR(03),
	@fec_vcto			CHAR(08),
	@numero_cuota		CHAR(05),
	@tc_cto				CHAR(09),
	--@capital			DEC(13,4),
	--@interes			DEC(13,4),
	--@comision			DEC(13,4),
	--@seguro_deg		DEC(13,4),
	--@seguro_inic		DEC(13,4),
	@capital			FLOAT,
	@interes			FLOAT,
	@comision			FLOAT,
	@seguro_deg			FLOAT,
	@seguro_inic		FLOAT,
	--@montos				DEC(13,4),
	@montos				FLOAT,
	@estado  			CHAR(02),
	@marca_cuota		CHAR(01),
	@filler_2			CHAR(40)


CREATE TABLE #det_rezago (
	cto_negocio			CHAR(03)	NULL,
	tprod				CHAR(03)	NULL,
	rut					BIGINT		NULL,
	rut_dv				CHAR(10)	NULL,
	ofope				CHAR(03)	NULL,
	tipo_oper			CHAR(05)	NULL,
	num_oper			CHAR(17)	NULL, --oficina leasing, cliente leasing y contrato
	subop				CHAR(03)	NULL,
	filler_1			CHAR(06)	NULL,
	ofi_cli				CHAR(03)    NULL,	
	ejecutivo			CHAR(03)	NULL,	
	moneda				CHAR(03)	NULL, --moneda sbif 1-$-999, 2-uf-998, 4-us-13
	--monto				DEC(13,4)	NULL,
	monto				FLOAT		NULL,
	fec_suscrip			CHAR(08)	NULL,	
	--paridad			DEC(6,4)	NULL,
	paridad				FLOAT		NULL, 
	fec_termino			CHAR(08)	NULL,	   
	--saldo_cap			DEC(13,4)	NULL,	
	--saldo_insoluto	DEC(13,4)	NULL,
	saldo_cap			FLOAT		NULL,	
	saldo_insoluto		FLOAT		NULL,
	num_cuotas 			CHAR(03)	NULL,
	estado_credito		CHAR(02)	NULL,
	fec_estado			CHAR(08)	NULL,
	renegociado			CHAR(01)	NULL,
	fec_prim_impaga		CHAR(08)	NULL,
	num_cuotas_impag	CHAR(03)	NULL,
	fec_ultimo_pago		CHAR(08)	NULL,
	--tasa_ptmo			DEC(8,5)	NULL,
	--rebaja_cuota		DEC(13,4)	NULL,
	--valor_prox_cuota	DEC(13,4)	NULL,
	tasa_ptmo			FLOAT		NULL,
	rebaja_cuota		FLOAT		NULL,
	valor_prox_cuota	FLOAT		NULL,
	fec_prox_cuota		CHAR(08)	NULL,
	frec_pago			CHAR(01)	NULL,
	peridiocidad_pago	CHAR(03)	NULL,
	cupo_nacional		CHAR(11)	NULL,
	--cupo_internac    	DEC(13,2)	NULL,
	--tot_factura_nac  	DEC(11)		NULL,
	--tot_factura_inter	DEC(13,2)	NULL,
	cupo_internac    	FLOAT		NULL,
	tot_factura_nac  	FLOAT		NULL,
	tot_factura_inter	FLOAT		NULL,
	fec_ultima_factur 	CHAR(08)	NULL,
	--ult_pag_minimo 	DEC(11)		NULL,
	ult_pag_minimo 		FLOAT		NULL,
	cod_bloqueo   		CHAR(02)	NULL,
	convenio_pago    	CHAR(01)	NULL,
	fec_prox_factura 	CHAR(08)	NULL,
	tramo_factura    	CHAR(01)	NULL,
	solicitud			CHAR(01)	NULL,
	fec_infor			CHAR(08)	NULL,
	conve_cartera		CHAR(05)	NULL,
	sistema				CHAR(03)	NULL,
	fec_vcto			CHAR(08)	NULL,
	numero_cuota		CHAR(05)	NULL,
	tc_cto				CHAR(09)	NULL,
	--capital				DEC(13,4)	NULL,
	--interes				DEC(13,4)	NULL,
	--comision				DEC(13,4)	NULL,
	--seguro_deg			DEC(13,4)	NULL,
	--seguro_inic			DEC(13,4)	NULL,
	--montos				DEC(13,4)	NULL,
	capital				FLOAT		NULL,
	interes				FLOAT		NULL,
	comision			FLOAT		NULL,
	seguro_deg			FLOAT		NULL,
	seguro_inic			FLOAT		NULL,
	montos				FLOAT		NULL,
	estado  			CHAR(02)	NULL,
	marca_cuota			CHAR(01)	NULL,
	filler_2			CHAR(40)	NULL)

--486
CREATE TABLE #cabecera(
salida CHAR(486) NULL,
indice int null)

CREATE TABLE #detalle(
salida CHAR(486) NULL,
indice INT null)

CREATE TABLE #trailer(
salida CHAR(486) NULL,
indice INT null)

CREATE TABLE #salida(
salida CHAR(486) NULL,
indice INT null)

SET @cto_negocio = '012'
SET @tprod		 = '090'
SET @ofope		 = '130'
SET @subop		 = '000'
SET @filler_1	 = REPLICATE(' ',6)

-- Curso que recorre todos los contratos Vigentes 
DECLARE c_cto CURSOR LOCAL FOR
SELECT a.operacion, a.rut_cliente, a.cod_moneda_contrato, a.estado_operacion, a.fecha_ingreso_cont, a.ejecutivo_contrato,
      (ISNULL(provision_material,0)+ISNULL(provision_gasto_legal,0)+ISNULL(provision_seguros,0)+ISNULL(provision_importacion,0)+ISNULL(provision_otros,0)) monto_cto,
      a.tasa_variable,a.tasa_spread,a.clasificacion_cartera,a.num_contrato,a.cod_oficina_real,a.monto_pie,a.fecha_suscripcion,
      a.cod_tipo_periodo_arr,c.fecha_vencimiento,c.num_cuota,c.capital,c.interes,c.iva
FROM   leaseoper..t_contratos a, leaseoper..t_contratos_anexo b, leaseoper..t_cuotas c
WHERE  a.operacion = b.operacion
  AND  a.operacion = c.operacion
  AND  a.estado_operacion = 2
  AND  c.fecha_vencimiento < @fecha_proceso --cuotas morosas
  
OPEN c_cto
FETCH  c_cto INTO @operacion, @rut_cliente, @cod_moneda, @estado_operacion, @fecha_ing_cont, @ejecutivo_contrato, 
@monto_cto_orig,@tasa_var,@tasa_spre,@cla_cartera,@num_contrato,@cod_oficina,@monto_pie,@fec_suscripcion,@tipo_periodo_arr,
@fec_vencimiento,@num_cuota,@capital_cuo,@interes_cuo,@iva_cuo
WHILE (@@FETCH_STATUS = 0)
BEGIN
   -- Inicializa Variables.
    SELECT	@monto     = 0,
			@paridad   = 0,
			@saldo_cap = 0,
			@saldo_insoluto = 0,
			@tasa_ptmo = 0,
			@rebaja_cuota = 0,
			@valor_prox_cuota = 0,
			@cupo_internac = 0,
			@tot_factura_nac = 0,
			@tot_factura_inter	= 0,
			@ult_pag_minimo = 0,
			@capital = 0,
			@interes = 0,
			@comision	= 0,
			@seguro_deg		= 0,
			@seguro_inic	= 0,
			@montos		= 0
			
       --  =======================================================================================
       --rut , dv
       
       SELECT @dv = ISNULL(dv,' ')
		FROM leasecom..v_clientes
		WHERE rut = @rut_cliente
		
		SET @rut	= @rut_cliente 
		SET @rut_dv = @rut_cliente + @dv
		
        -- =======================================================================================
        --tipo oper
        
        IF @cla_cartera = 1 --comercial
        BEGIN
			IF @cod_moneda = 1 --pesos
				SET @tipo_oper = '35520'
			IF @cod_moneda = 2 --uf
				SET @tipo_oper = '35500'
			IF @cod_moneda = 4 --us
				SET @tipo_oper = '35510' 
		END
		
		IF @cla_cartera = 2 --consumo
        BEGIN
			IF @cod_moneda = 1 --pesos
				SET @tipo_oper = '36020'
			IF @cod_moneda = 2 --uf
				SET @tipo_oper = '36000'
			IF @cod_moneda = 4 --us
				SET @tipo_oper = '36610'
		END
		
		IF @cla_cartera = 3 --vivienda
        BEGIN
			IF @cod_moneda = 1 --pesos
				SET @tipo_oper = '37020'
			IF @cod_moneda = 2 --uf
				SET @tipo_oper = '37000'
			IF @cod_moneda = 4 --us
				SET @tipo_oper = '37610'
		END
	--
	--identificacion
	
	SELECT @id_cliente = ISNULL(id_cliente,0)
	FROM dbo.t_datos_cliente_banco
	WHERE lberut = @rut_cliente
	
	SET @oficina = REPLICATE('0', 2 - LEN(RTRIM(CONVERT(char(2),@cod_oficina)))) + RTRIM(CONVERT(char(2),@cod_oficina)) 
	SET @cliente = REPLICATE('0', 5 - LEN(RTRIM(convert(char(5),@id_cliente )))) + RTRIM(convert(char(5),@id_cliente )) 
	SET @contrato = REPLICATE('0', 3 - LEN(RTRIM(convert(char(3),@num_contrato)))) + RTRIM(convert(char(3),@num_contrato)) 
	
	SET @num_oper = @oficina + @cliente + @contrato

	
	--oficina
	SET @ofi_cli = CONVERT(CHAR(3),@cod_oficina)
	
	--ejecutivo
	SET @ejecutivo =CONVERT(CHAR(3),@ejecutivo_contrato)
	
	--moneda sbif
	IF @cod_moneda = 1
		SET @moneda = 999
	ELSE
	BEGIN
		IF @cod_moneda = 2
			SET @moneda = 998
		ELSE
		BEGIN
			IF @cod_moneda = 4
				SET @moneda = 13
			ELSE
				SET @moneda = 0
		END
	END
	
	--monto contrato
	SET @monto = (@monto_cto_orig - @monto_pie) --* 10000

	--fecha suscripción
	SET @fec_suscrip	= CONVERT(CHAR(08),@fec_suscripcion,112) 
	
	--paridad
	SELECT @paridad = ISNULL(valor,0)
	FROM leasecom..p_valor_paridades
	WHERE cod_moneda = @cod_moneda
	AND   fecha = @fecha_proceso
	
	--fecha termino
	SELECT @fec_termino = CONVERT(CHAR(08),MAX(fecha_vencimiento),112)
	FROM dbo.t_cuotas
	WHERE operacion = @operacion
	AND cod_tipo_cuota = 2
	
	--saldo capital
	SELECT @saldo_cap = SUM(capital) --* 10000
	FROM dbo.t_cuotas
	WHERE operacion = @operacion
	AND estado IN (1,3)
	AND fecha_vencimiento > @fecha_proceso
	
	--saldo insoluto
    SELECT @saldo_insoluto = SUM(capital) 
    FROM   leaseoper..t_cuotas
    WHERE  operacion = @operacion
    AND  estado in (1,3)
    
    
     --Ver si tiene cuotas con abono, para rebajar lo pagado.
    IF EXISTS( SELECT estado FROM leaseoper..t_cuotas WHERE operacion = @operacion AND estado = 3)
    BEGIN
       SELECT @cuota_abono   = SUM(b.valor_cuota_total),
              @capital_abono = SUM(b.capital)
       FROM  leaseoper..t_cuotas a, leaseoper..t_cuotas_mov b
       WHERE  a.operacion = @operacion
         AND  a.estado = 3
         AND  a.operacion = b.operacion
         AND  a.cod_tipo_cuota = b.cod_tipo_cuota
         AND a.num_cuota = b.num_cuota


       SELECT @saldo_insoluto = (@saldo_insoluto - ISNULL(@capital_abono,0)) --* 10000
       --SELECT @monto_mora_mo = @monto_mora_mo - ISNULL(@cuota_abono,0)
    END
    
     
    --cuotas impagas
    SELECT @num_cuotas = count(1) 
    FROM   leaseoper..t_cuotas
    WHERE  operacion = @operacion
    AND  estado in (1,3)
    
    --estado credito
    IF EXISTS(	SELECT operacion
				FROM dbo.t_contratos_castigados
				WHERE operacion = @operacion)
		SET @estado_credito = 4
	ELSE
	BEGIN
	    IF EXISTS(	SELECT operacion
					FROM t_cuotas_venc_detalle
					WHERE operacion = @operacion)
			SET @estado_credito = 2
		ELSE
			SET @estado_credito = 1
	END
		
    --fecha estado 
	/*1 Fecha de primera cuota sin pagar, t_cuotas
	2 t_cuotas_venc_detalle fecha_car_venc
	4 t_contratos_castigados campo fecha_castigo*/

	IF @estado_credito = 1
		SELECT @fec_estado = CONVERT(CHAR(8),MIN(fecha_vencimiento),112)
		FROM dbo.t_cuotas
		where operacion = @operacion
		AND fecha_pago IS NULL
	IF @estado_credito = 2
		SELECT @fec_estado = CONVERT(CHAR(8),MIN(fecha_cart_venc),112)
		FROM t_cuotas_venc_detalle
		where operacion = @operacion
	IF @estado_credito = 4
		SELECT @fec_estado = CONVERT(CHAR(8),fecha_castigo,112)
		FROM t_contratos_castigados
		where operacion = @operacion

    
    --contratos renegociados
    
    SET @reneg = (SELECT COUNT(1)
					FROM dbo.t_control_modificaciones
					WHERE operacion_antigua = @operacion)
    
    IF @reneg > 0 
		SET @renegociado = 'S'
	ELSE
		SET @renegociado = 'N'
		
	--fecha cuota impaga
	SELECT @fec_prim_impaga = CONVERT(CHAR(08),MIN(fecha_vencimiento),112) 
	FROM dbo.t_cuotas
	WHERE operacion = @operacion
	AND fecha_vencimiento < @fecha_proceso
	
	--cuotas arriendo
	SELECT @num_cuotas_impag = CONVERT(CHAR(3),num_cuotas_arriendo)
	FROM dbo.t_contratos
	WHERE operacion = @operacion
	
	--fecha último pago
	SELECT @fec_ultimo_pago = CONVERT(CHAR(08),MAX(fecha_pago),112)
	FROM dbo.t_cuotas_mov
	WHERE operacion = @operacion
	
	--tasa compuesta
	/*	1   	Mensual                                                                                             
		2   	Bimensual                                                                                           
		3   	Trimestral                                                                                          
		4   	Semestral                                                                                           
		5   	Anual */
		
	IF @tipo_periodo_arr = 1
		SELECT @tipo_periodo_arr = 1
	IF @tipo_periodo_arr = 2
		SELECT @tipo_periodo_arr = 2
	IF @tipo_periodo_arr = 3
		SELECT @tipo_periodo_arr = 3
	IF @tipo_periodo_arr = 4
		SELECT @tipo_periodo_arr = 6
	IF @tipo_periodo_arr = 5
		SELECT @tipo_periodo_arr = 12
	
	SET @tasa_anual = ISNULL(@tasa_var,0) + ISNULL(@tasa_spre,0)
	
	SET @tasa_ptmo = (POWER( ((@tasa_anual/100.00)+1.00), (1.00 / (@tipo_periodo_arr/12))) - 1.00) --* 100000  
	
	--SET @tasa_ptmo = POWER( ((@tasa_anual/100)+1), (1 / (@tipo_periodo_arr/12))) - 1  

	--rebaja cuota
	SET @rebaja_cuota	= REPLICATE('0',17)
	
	--valor próxima cuota
	SELECT @valor_prox_cuota = valor_cuota_total --* 10000
	FROM dbo.t_cuotas
	WHERE operacion = @operacion
	AND estado IN (1,3)
	AND fecha_vencimiento > @fecha_proceso
	
	--fecha próxima cuota
	SELECT @fec_prox_cuota = CONVERT(CHAR(08),fecha_vencimiento,112)
	FROM dbo.t_cuotas
	WHERE operacion = @operacion
	AND estado IN (1,3)
	AND fecha_vencimiento > @fecha_proceso

	--pago
	SET @frec_pago = 'M'
	
	--periocidad pago
	SET @peridiocidad_pago = CONVERT(CHAR(3),@tipo_periodo_arr)
	
	--varios
	SET @cupo_nacional		= replicate('0',11) 
	SET @cupo_internac    	= replicate('0',13) 
	SET @tot_factura_nac  	= replicate('0',11) 
	SET @tot_factura_inter	= replicate('0',13) 
	SET @fec_ultima_factur 	= replicate('0',8) 
	SET @ultimo_pag_minimo 	= replicate('0',11) 
	SET @codigo_bloqueo   	= replicate('0',2) 
	SET @convenio_pago    	= replicate(' ',1) 
	SET @fec_prox_factura 	= replicate('0',8) 
	SET @tramo_factura    	= replicate('0',1) 
	
	--solicitud 
	
	DECLARE @dia int

	SET  @dia = DATEPART(dw, @fecha_proceso)

	IF @dia = 5
		SET @solicitud = 'C' --proceso masivo
	ELSE
		SET @solicitud = ' '
	
	--fecha informada
	SET @fec_infor = CONVERT(CHAR(8),@fecha_proceso,112)
	
	SET @conve_cartera = REPLICATE('0',5)
	
	SET @sistema = 'LSA'
	
	--vencimiento de la cuota
	SET @fec_vcto		= CONVERT(CHAR(8),@fec_vencimiento,112)
	
	--num cuota
	set @numero_cuota	= CONVERT(CHAR(5),@num_cuota)
	
	--paridad al vencimiento
	--SELECT @tc_cto = CONVERT(CHAR(9),ISNULL(valor,0) * 10000)
	SELECT @tc_cto = CONVERT(CHAR(9),ISNULL(valor,0))
	FROM leasecom..p_valor_paridades
	WHERE cod_moneda = @cod_moneda
	AND   fecha = @fec_vencimiento
	
	--capital cuota
	SET @capital	= (ISNULL(@capital_cuo,0) + ISNULL(@iva_cuo,0)) --* 10000
	
	--interes cuota
	SET @interes	= ISNULL(@interes_cuo,0)

	--varios
	set @comision	= replicate('0',17) 
	set @seguro_deg	= replicate('0',17) 
	set @seguro_inic= replicate('0',17) 
	set @montos		= replicate('0',17) 
	
	--estado credito / alguna relación con las carteras??? campo repetido
    SET @estado = CONVERT(CHAR(2),@estado_operacion)
    
    --varios
    SET @marca_cuotas = REPLICATE(' ',1)
    SET @filler_2	  = REPLICATE(' ',40)

     
   -- Insertar registro.  
		INSERT INTO #det_rezago
		VALUES(
		ISNULL(@cto_negocio,' '),
		ISNULL(@tprod,' '),
		ISNULL(@rut,0),
		ISNULL(@rut_dv,' '),
		ISNULL(@ofope,' '),
		ISNULL(@tipo_oper,' '),
		ISNULL(@num_oper,' '),
		ISNULL(@subop,' '),
		ISNULL(@filler_1,' '),
		ISNULL(@ofi_cli,' '),
		ISNULL(@ejecutivo,' '),
		ISNULL(@moneda,' '),
		ISNULL(@monto,0),
		ISNULL(@fec_suscrip,'19000101'),
		ISNULL(@paridad,0),
		ISNULL(@fec_termino,'19000101'),
		ISNULL(@saldo_cap,0),
		ISNULL(@saldo_insoluto,0),
		ISNULL(@num_cuotas,' '),
		ISNULL(@estado_credito,' '),
		ISNULL(@fec_estado,'19000101'),
		ISNULL(@renegociado,' '),
		ISNULL(@fec_prim_impaga,'19000101'),
		ISNULL(@num_cuotas_impag,' '),
		ISNULL(@fec_ultimo_pago,'19000101'),
		ISNULL(@tasa_ptmo,0),
		ISNULL(@rebaja_cuota,0),
		ISNULL(@valor_prox_cuota,0),
		ISNULL(@fec_prox_cuota,'19000101'),
		ISNULL(@frec_pago,' '),
		ISNULL(@peridiocidad_pago,' '),
		ISNULL(@cupo_nacional,' '),
		ISNULL(@cupo_internac,0),
		ISNULL(@tot_factura_nac,0),
		ISNULL(@tot_factura_inter,0),
		ISNULL(@fec_ultima_factur,'00000000'),
		ISNULL(@ult_pag_minimo,0),
		ISNULL(@codigo_bloqueo,' '),
		ISNULL(@convenio_pago,' '),
		ISNULL(@fec_prox_factura,'00000000'),
		ISNULL(@tramo_factura,' '),
		ISNULL(@solicitud,' '),
		ISNULL(@fec_infor,'19000101'),
		ISNULL(@conve_cartera,' '),
		ISNULL(@sistema,' '),
		ISNULL(@fec_vcto,'19000101'),
		ISNULL(@numero_cuota,' '),
		ISNULL(@tc_cto,' '),
		ISNULL(@capital,0),
		ISNULL(@interes,0),
		ISNULL(@comision,0),
		ISNULL(@seguro_deg,0),
		ISNULL(@seguro_inic,0),
		ISNULL(@montos,0),
		ISNULL(@estado,' '),
		ISNULL(@marca_cuota,' '),
		ISNULL(@filler_2,' '))

--    IF @@error <> 0
--    BEGIN
--      RAISERROR 20022 'Error al inserta registro'
--      RETURN
--    END

--
FETCH  c_cto INTO @operacion, @rut_cliente, @cod_moneda, @estado_operacion, @fecha_ing_cont, @ejecutivo_contrato, 
@monto_cto_orig,@tasa_var,@tasa_spre,@cla_cartera,@num_contrato,@cod_oficina,@monto_pie,@fec_suscripcion,@tipo_periodo_arr,
@fec_vencimiento,@num_cuota,@capital_cuo,@interes_cuo,@iva_cuo

END
CLOSE c_cto
DEALLOCATE c_cto

SET @total_reg = (SELECT COUNT(*) FROM #det_rezago)
SET @total_rut = (SELECT SUM(rut) FROM #det_rezago)

insert into #cabecera
SELECT  REPLICATE(' ',6) +
		'LSA' +
		CONVERT(CHAR(8),@fecha_proceso,112),1


INSERT INTO #detalle
SELECT 
	LTRIM(RTRIM(cto_negocio))	+
	LTRIM(RTRIM(tprod))	+
	REPLICATE('0',10 - LEN(RTRIM(rut_dv))) +  RTRIM(rut_dv) +
	LTRIM(RTRIM(ofope))	+
	LTRIM(RTRIM(tipo_oper))	+
	REPLICATE('0',17 - LEN(RTRIM(num_oper))) +  RTRIM(num_oper) +
	LTRIM(RTRIM(subop))		+
	filler_1	+
	REPLICATE('0', 3 - LEN(RTRIM(ofi_cli))) + RTRIM(ofi_cli) +
	REPLICATE('0', 3 - LEN(RTRIM(ejecutivo))) + RTRIM(ejecutivo) +
	REPLICATE('0', 3 - LEN(RTRIM(moneda))) + RTRIM(moneda) +
	REPLICATE('0', 17 - LEN(RTRIM(CONVERT(CHAR(17),monto)))) + RTRIM(convert(CHAR(17),monto)) +
	LTRIM(RTRIM(fec_suscrip))	+
	REPLICATE('0', 10 - LEN(RTRIM(CONVERT(CHAR(10),paridad)))) + RTRIM(convert(CHAR(10),paridad)) +
	LTRIM(RTRIM(fec_termino))	+
	REPLICATE('0', 17 - LEN(RTRIM(CONVERT(CHAR(17),saldo_cap)))) + RTRIM(convert(CHAR(17),saldo_cap)) +
	REPLICATE('0', 17 - LEN(RTRIM(CONVERT(CHAR(17),saldo_insoluto)))) + RTRIM(convert(CHAR(17),saldo_insoluto)) +
	REPLICATE('0', 3 - LEN(RTRIM(num_cuotas))) + RTRIM(num_cuotas) +
	REPLICATE('0', 2 - LEN(RTRIM(estado_credito))) + RTRIM(estado_credito) +
	LTRIM(RTRIM(fec_estado))		+
	LTRIM(RTRIM(renegociado))		+
	LTRIM(RTRIM(fec_prim_impaga))	+
	REPLICATE('0', 3 - LEN(RTRIM(num_cuotas_impag))) + RTRIM(num_cuotas_impag) +
	LTRIM(RTRIM(fec_ultimo_pago))	 +
	REPLICATE('0', 8 - LEN(RTRIM(CONVERT(CHAR(8),tasa_ptmo)))) + RTRIM(convert(CHAR(8),tasa_ptmo)) +
	REPLICATE('0', 17 - LEN(RTRIM(CONVERT(CHAR(17),rebaja_cuota)))) + RTRIM(convert(CHAR(17),rebaja_cuota)) +
	REPLICATE('0', 17 - LEN(RTRIM(CONVERT(CHAR(17),valor_prox_cuota)))) + RTRIM(convert(CHAR(17),valor_prox_cuota)) +
	LTRIM(RTRIM(fec_prox_cuota))		+
	LTRIM(RTRIM(frec_pago))			+
	REPLICATE('0',3 - LEN(RTRIM(peridiocidad_pago))) + rtrim(peridiocidad_pago) +
	LTRIM(RTRIM(cupo_nacional))		+
	REPLICATE('0', 13 - LEN(RTRIM(CONVERT(CHAR(13),cupo_internac)))) + RTRIM(convert(CHAR(13),cupo_internac)) +
	REPLICATE('0', 11 - LEN(RTRIM(CONVERT(CHAR(11),tot_factura_nac)))) + RTRIM(convert(CHAR(11),tot_factura_nac)) +
	REPLICATE('0', 13 - LEN(RTRIM(CONVERT(CHAR(13),tot_factura_inter)))) + RTRIM(convert(CHAR(13),tot_factura_inter)) +
	LTRIM(RTRIM(fec_ultima_factur)) 	+
	REPLICATE('0', 11 - LEN(RTRIM(CONVERT(CHAR(11),ult_pag_minimo)))) + RTRIM(convert(CHAR(11),ult_pag_minimo)) +
	LTRIM(RTRIM(cod_bloqueo))   	+
	convenio_pago    	+
	LTRIM(RTRIM(fec_prox_factura)) 	+
	LTRIM(RTRIM(tramo_factura))    	+
	solicitud			+
	LTRIM(RTRIM(fec_infor))			+
	LTRIM(RTRIM(conve_cartera))		+
	LTRIM(RTRIM(sistema))			+
	LTRIM(RTRIM(fec_vcto))			+
	REPLICATE('0',5 - LEN(RTRIM(numero_cuota))) + rtrim(numero_cuota) +
	REPLICATE('0',9 - LEN(RTRIM(tc_cto))) + rtrim(tc_cto) +
	REPLICATE('0', 17 - LEN(RTRIM(CONVERT(CHAR(17),capital)))) + RTRIM(convert(CHAR(17),capital)) +
	REPLICATE('0', 17 - LEN(RTRIM(CONVERT(CHAR(17),interes)))) + RTRIM(convert(CHAR(17),interes)) +
	REPLICATE('0', 17 - LEN(RTRIM(CONVERT(CHAR(17),comision)))) + RTRIM(convert(CHAR(17),comision)) +
	REPLICATE('0', 17 - LEN(RTRIM(CONVERT(CHAR(17),seguro_deg)))) + RTRIM(convert(CHAR(17),seguro_deg)) +
	REPLICATE('0', 17 - LEN(RTRIM(CONVERT(CHAR(17),seguro_inic)))) + RTRIM(convert(CHAR(17),seguro_inic)) +
	REPLICATE('0', 17 - LEN(RTRIM(CONVERT(CHAR(17),montos)))) + RTRIM(convert(CHAR(17),montos)) +
	REPLICATE('0',2 - LEN(RTRIM(estado))) + rtrim(estado) +
	marca_cuota			+
	filler_2,
	2			
FROM #det_rezago

insert into #trailer
SELECT REPLICATE(' ',6) +
		replicate('0' , 6 - LEN(CONVERT(VARCHAR(6),@total_reg)))  + CONVERT(VARCHAR(6),@total_reg) +
		replicate('0' , 15 - LEN(CONVERT(VARCHAR(15),@total_rut)))  + CONVERT(VARCHAR(15),@total_rut) +
		REPLICATE(' ', 459),3 

	
INSERT INTO #salida
	SELECT salida ,indice
	FROM #cabecera
	union
	SELECT salida ,indice
	FROM #detalle
	union
	SELECT salida ,indice
	FROM #trailer
	ORDER BY indice
	
SELECT salida
FROM #salida

RETURN 0

GRANT EXEC ON pa_lo_interfaz_rez001 TO Usuarios











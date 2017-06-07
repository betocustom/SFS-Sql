USE [leaseoper]
GO
/****** Object:  StoredProcedure [dbo].[pa_lo_interfaz_isa_deven]    Script Date: 06/03/2014 16:20:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




/****** Objeto:  procedimiento almacenado dbo.pa_lo_interfaz_isa_deven    fecha de la secuencia de comandos: 09-07-2007 9:25:28 ******/
ALTER PROCEDURE [dbo].[pa_lo_interfaz_isa_deven]
@fecha_proceso    SMALLDATETIME,
@salida            INT OUTPUT
AS
/*
Nombre            :  pa_lo_interfaz_isa_deven

Descripción       : 

Parametros entrada: @fecha_proceso:

Parametros salida :  Ninguno.

Tablas entrada    :  t_contratos - t_cuotas

Tablas salida     :  Archivo plano.

Fecha             :  Julio 2014.

Modificaciones    :

Procedimientos que Llama :

Observaciones      :  

Autor              : Verónica Inzunza.

Ejecucion          :  

EXEC leaseoper..pa_lo_interfaz_isa_deven '19/03/2014',0
EXEC leaseoper..pa_lo_interfaz_isa_deven '24/03/2014',0

*/
set nocount on
--

DECLARE
  @operacion							INT,
  @rut_cliente							INT,
  @cod_moneda							TINYINT,
  @cod_oficina							TINYINT, 
  @cla_cartera							TINYINT,
  @dv									CHAR(01),
  @tipo_oper							CHAR(05),
  @int_dv_cuotas_vig					FLOAT,
  @int_dv_cuotas_vig_moro_29			FLOAT,
  @int_dv_cuotas_vig_moro_59			FLOAT,
  @int_dv_cuotas_vig_moro_89			FLOAT,
  @int_dv_cuotas_vig_moro_90			FLOAT,
  @int_dv_cuotas_vig_$					FLOAT,
  @int_dv_cuotas_vig_moro_29_$			FLOAT,
  @int_dv_cuotas_vig_moro_59_$			FLOAT,
  @int_dv_cuotas_vig_moro_89_$			FLOAT,
  @int_dv_cuotas_vig_moro_90_$			FLOAT,
  @paridad								FLOAT,
  @int_nor_$_dv_cuotas_vig				FLOAT,
  @int_nor_$_dv_cuotas_moro_29			FLOAT,
  @int_nor_$_dv_cuotas_moro_59			FLOAT,
  @int_nor_$_dv_cuotas_moro_89			FLOAT,
  @int_nor_$_dv_cuotas_moro_90			FLOAT,
  @int_mora_$_dv_cuotas_vig_cdn			FLOAT,
  @int_mora_$_dv_cuotas_moro_29_cdn		FLOAT,
  @int_mora_$_dv_cuotas_moro_59_cdn		FLOAT,
  @int_mora_$_dv_cuotas_moro_89_cdn		FLOAT,
  @int_mora_$_dv_cuotas_moro_90_cdn		FLOAT,
  @int_mora_$_dv_cuotas_moro_29_c		FLOAT,
  @int_mora_$_dv_cuotas_moro_59_c		FLOAT,
  @int_mora_$_dv_cuotas_moro_89_c		FLOAT,
  @int_mora_$_dv_cuotas_moro_90_c		FLOAT,
  @rea_k_cdn_cuotas_vig_$				FLOAT,
  @rea_k_cdn_cuotas_moro_29_$			FLOAT,
  @rea_k_cdn_cuotas_moro_59_$			FLOAT,
  @rea_k_cdn_cuotas_moro_89_$			FLOAT,
  @rea_k_cdn_cuotas_moro_90_$			FLOAT


IF @fecha_proceso IS NULL OR @fecha_proceso = '01/01/1900'
BEGIN
   SELECT @salida = 0
   --RAISERROR 20000 'Debe Ingresar Periodo a Procesar'
   RETURN 1
END
--

DECLARE
	@tipo_reg						CHAR(1),
	@ppp_emb						CHAR(2),
	@cero1							CHAR(30),
	@cero2							CHAR(15),
	@dev_int_dif_pcio_mc_u       	CHAR(15),
	@dev_is_cr_vig_mo_u          	CHAR(15),
	@dev_is_cr_mora_h20_mo_u     	CHAR(15),
	@dev_is_cr_mora_m30_h59_mo_u 	CHAR(15),
	@dev_is_cr_mora_m60_h89_mo_u 	CHAR(15),
	@dev_is_cr_mora_m90_mo_u     	CHAR(15),
	@cero3                       	CHAR(15),
	@dev_is_cr_vig_mc_u          	CHAR(15),
	@dev_is_cr_mora_h20_mc_u     	CHAR(15),
	@dev_is_cr_mora_m30_h59_mc_u 	CHAR(15),
	@dev_is_cr_mora_m60_h89_mc_u 	CHAR(15),
	@dev_is_cr_mora_m90_mc_u   		CHAR(15),
	@cero4                       	CHAR(15),
	@cero5                       	CHAR(15),
	@cero6                       	CHAR(15),
	@cero7                       	CHAR(45),
	@pdev_reaj_vig_mn            	CHAR(13),
	@pdev_reaj_01_h29_mn         	CHAR(13),
	@pdev_reaj_30_h59_mn         	CHAR(13),
	@pdev_reaj_60_h89_mn         	CHAR(13),
	@pdev_reaj_90_mas_mn         	CHAR(13),
	@cero8                       	CHAR(26),
	@cero9                       	CHAR(13),
	@dev_rs_cm_mora_m01_h29_mo_u 	CHAR(13),
	@dev_rs_cm_mora_m30_h59_mo_u 	CHAR(13),
	@dev_rs_cm_mora_m60_h89_mo_u 	CHAR(13),
	@dev_rs_cm_mora_m90_mas_mo_u 	CHAR(13),
	@dev_rs_cm_int_con_venc_u    	CHAR(13),
	@dev_rs_cm_pre_judic_mo_u    	CHAR(13),
	@dev_rs_cm_en_ejec_mo_u 		CHAR(13),
	@dev_ppp_contab_cre     		CHAR(1),
	@mda_conta						CHAR(3),
	@dev_pzo_tas_var				CHAR(16),
	@total_reg						INT,
	@num_docto						INT


CREATE TABLE #det_devengo (
	tipo_reg                    	CHAR(001) NULL,
	rut                         	CHAR(009) NULL,
	dv                          	CHAR(001) NULL,
	oficina                     	CHAR(003) NULL,
	cartera                         CHAR(005) NULL,
	ppp_emb                     	CHAR(002) NULL,
	num_docto                   	CHAR(009) NULL,
	devmon                      	CHAR(015) NULL,
	dev01_29                    	CHAR(015) NULL,
	dev30_59                    	CHAR(015) NULL,
	dev60_89                    	CHAR(015) NULL,
	dev90_mas                   	CHAR(015) NULL,
	cero1                       	CHAR(030) NULL,
	pdevmon                     	CHAR(015) NULL,
	pdev01_29                   	CHAR(015) NULL,
	pdev30_59                   	CHAR(015) NULL,
	pdev60_89                   	CHAR(015) NULL,
	pdev90_mas                  	CHAR(015) NULL,
	cero2                       	CHAR(015) NULL,
	dev_int_dif_pcio_mc_u       	CHAR(015) NULL,
	dev_is_cr_vig_mo_u          	CHAR(015) NULL,
	dev_is_cr_mora_h20_mo_u     	CHAR(015) NULL,
	dev_is_cr_mora_m30_h59_mo_u 	CHAR(015) NULL,
	dev_is_cr_mora_m60_h89_mo_u 	CHAR(015) NULL,
	dev_is_cr_mora_m90_mo_u     	CHAR(015) NULL,
	cero3                       	CHAR(015) NULL,
	dev_is_cr_vig_mc_u          	CHAR(015) NULL,
	dev_is_cr_mora_h20_mc_u     	CHAR(015) NULL,
	dev_is_cr_mora_m30_h59_mc_u 	CHAR(015) NULL,
	dev_is_cr_mora_m60_h89_mc_u 	CHAR(015) NULL,
	dev_is_cr_mora_m90_mc_u			CHAR(015) NULL,
	cero4                       	CHAR(015) NULL,
	pdev_isn_c_det_vig_mc       	CHAR(015) NULL,
	pdev_isn_c_det_01_h29_mc    	CHAR(015) NULL,
	pdev_isn_c_det_30_h59_mc    	CHAR(015) NULL,
	pdev_isn_c_det_60_h89_mc    	CHAR(015) NULL,
	pdev_isn_c_det_90_mas_mc    	CHAR(015) NULL,
	cero5                       	CHAR(015) NULL,
	pdev_isp_c_det_vig_mc       	CHAR(015) NULL,
	pdev_isp_c_det_01_h29_mc    	CHAR(015) NULL,
	pdev_isp_c_det_30_h59_mc    	CHAR(015) NULL,
	pdev_isp_c_det_60_h89_mc    	CHAR(015) NULL,
	pdev_isp_c_det_90_mas_mc    	CHAR(015) NULL,
	cero6                       	CHAR(015) NULL,
	pdev_ip_c_01_h29_mc         	CHAR(015) NULL,
	pdev_ip_c_30_h59_mc         	CHAR(015) NULL,
	pdev_ip_c_60_h89_mc         	CHAR(015) NULL, 
	pdev_ip_c_90_mas_mc         	CHAR(015) NULL,
	cero7                       	CHAR(045) NULL,
	pdev_reaj_vig_mn            	CHAR(013) NULL,
	pdev_reaj_01_h29_mn         	CHAR(013) NULL,
	pdev_reaj_30_h59_mn         	CHAR(013) NULL,
	pdev_reaj_60_h89_mn         	CHAR(013) NULL,
	pdev_reaj_90_mas_mn         	CHAR(013) NULL,
	cero8                       	CHAR(026) NULL,
	pdev_reaj_det_vig_mn        	CHAR(013) NULL,
	pdev_reaj_det_m01_h29_mn    	CHAR(013) NULL,
	pdev_reaj_det_m30_h59_mn    	CHAR(013) NULL,
	pdev_reaj_det_m60_h89_mn    	CHAR(013) NULL,
	pdev_reaj_det_m90_mas_mn    	CHAR(013) NULL,
	cero9                       	CHAR(013) NULL,
	dev_rs_cm_mora_m01_h29_mo_u 	CHAR(013) NULL, 
	dev_rs_cm_mora_m30_h59_mo_u 	CHAR(013) NULL,
	dev_rs_cm_mora_m60_h89_mo_u 	CHAR(013) NULL,
	dev_rs_cm_mora_m90_mas_mo_u 	CHAR(013) NULL,
	dev_rs_cm_int_con_venc_u    	CHAR(013) NULL,
	dev_rs_cm_pre_judic_mo_u    	CHAR(013) NULL,
	dev_rs_cm_en_ejec_mo_u			CHAR(013) NULL,
	dev_ppp_contab_cre				CHAR(001) NULL,
	mda_conta						CHAR(003) NULL,
	dev_pzo_tas_var					CHAR(016) NULL)  

--985
CREATE TABLE #cabecera(
salida CHAR(985) NULL,
indice int null)

CREATE TABLE #detalle(
salida CHAR(985) NULL,
indice INT null)

CREATE TABLE #trailer(
salida CHAR(985) NULL,
indice INT null)

CREATE TABLE #salida(
salida CHAR(985) NULL,
indice INT null)

SET @tipo_reg						= '1'
SET @ppp_emb						= '00'
SET @cero1                       	= REPLICATE('0',30)
SET @cero2                       	= REPLICATE('0',15)
SET @dev_int_dif_pcio_mc_u       	= REPLICATE('0',15)
SET @dev_is_cr_vig_mo_u          	= REPLICATE('0',15)
SET @dev_is_cr_mora_h20_mo_u     	= REPLICATE('0',15)
SET @dev_is_cr_mora_m30_h59_mo_u 	= REPLICATE('0',15)
SET @dev_is_cr_mora_m60_h89_mo_u 	= REPLICATE('0',15)
SET @dev_is_cr_mora_m90_mo_u     	= REPLICATE('0',15)
SET @cero3                       	= REPLICATE('0',15)
SET @dev_is_cr_vig_mc_u          	= REPLICATE('0',15)
SET @dev_is_cr_mora_h20_mc_u     	= REPLICATE('0',15)
SET @dev_is_cr_mora_m30_h59_mc_u 	= REPLICATE('0',15)
SET @dev_is_cr_mora_m60_h89_mc_u 	= REPLICATE('0',15)
SET @dev_is_cr_mora_m90_mc_u   		= REPLICATE('0',15)
SET @cero4                       	= REPLICATE('0',15)
SET @cero5                       	= REPLICATE('0',15)
SET @cero6                       	= REPLICATE('0',15)
SET @cero7                       	= REPLICATE('0',45)
SET @pdev_reaj_vig_mn            	= REPLICATE('0',13)
SET @pdev_reaj_01_h29_mn         	= REPLICATE('0',13)
SET @pdev_reaj_30_h59_mn         	= REPLICATE('0',13)
SET @pdev_reaj_60_h89_mn         	= REPLICATE('0',13)
SET @pdev_reaj_90_mas_mn         	= REPLICATE('0',13)
SET @cero8                       	= REPLICATE('0',26)
SET @cero9                       	= REPLICATE('0',13)
SET @dev_rs_cm_mora_m01_h29_mo_u 	= REPLICATE('0',13)
SET @dev_rs_cm_mora_m30_h59_mo_u 	= REPLICATE('0',13)
SET @dev_rs_cm_mora_m60_h89_mo_u 	= REPLICATE('0',13)
SET @dev_rs_cm_mora_m90_mas_mo_u 	= REPLICATE('0',13)
SET @dev_rs_cm_int_con_venc_u    	= REPLICATE('0',13)
SET @dev_rs_cm_pre_judic_mo_u    	= REPLICATE('0',13)
SET @dev_rs_cm_en_ejec_mo_u 		= REPLICATE('0',13)
SET @dev_ppp_contab_cre     		= REPLICATE('0',1)
SET @mda_conta						= '999'
SET @dev_pzo_tas_var				= REPLICATE(' ',16)

-- Curso que recorre todos los contratos Vigentes 
DECLARE c_cto CURSOR LOCAL FOR
SELECT operacion,
	rut_cliente,
	cod_oficina_real,
	clasificacion_cartera,
	cod_moneda_contrato
FROM t_contratos
WHERE estado_operacion = 2 --contrato vigente
AND fecha_ing_carta_recep < = @fecha_proceso
OPEN c_cto
FETCH  c_cto INTO @operacion, @rut_cliente, @cod_oficina, @cla_cartera, @cod_moneda
WHILE (@@FETCH_STATUS = 0)
BEGIN
			
       --rut , dv
       
       SELECT @dv = ISNULL(dv,' ')
		FROM leasecom..v_clientes
		WHERE rut = @rut_cliente
		
       --cartera
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
	--numero documento
	SET @num_docto = @operacion
	
	--intereses devengados cuotas vigentes sin mora, moneda contrato
	SELECT @int_dv_cuotas_vig = SUM(interes)
	FROM dbo.t_cuotas
	WHERE operacion = @operacion
	AND estado = 1
	AND fecha_vencimiento > @fecha_proceso
	
	--intereses devengados cuotas vigentes morosas 1-29, moneda contrato
	SELECT @int_dv_cuotas_vig_moro_29 = SUM(interes)
	FROM dbo.t_cuotas
	WHERE operacion = @operacion
	AND estado = 1
	AND fecha_vencimiento < @fecha_proceso
	AND DATEDIFF(dd,fecha_vencimiento,@fecha_proceso) BETWEEN 1 AND 29
	
	--intereses devengados cuotas vigentes morosas 30-59, moneda contrato
	SELECT @int_dv_cuotas_vig_moro_59 = SUM(interes)
	FROM dbo.t_cuotas
	WHERE operacion = @operacion
	AND estado = 1
	AND fecha_vencimiento < @fecha_proceso
	AND DATEDIFF(dd,fecha_vencimiento,@fecha_proceso) BETWEEN 30 AND 59
	
	--intereses devengados cuotas vigentes morosas 60-89, moneda contrato
	SELECT @int_dv_cuotas_vig_moro_89 = SUM(interes)
	FROM dbo.t_cuotas
	WHERE operacion = @operacion
	AND estado = 1
	AND fecha_vencimiento < @fecha_proceso
	AND DATEDIFF(dd,fecha_vencimiento,@fecha_proceso) BETWEEN 60 AND 89


	--intereses devengados cuotas vigentes morosas > 90, moneda contrato
	SELECT @int_dv_cuotas_vig_moro_90 = SUM(interes)
	FROM dbo.t_cuotas
	WHERE operacion = @operacion
	AND estado = 1
	AND fecha_vencimiento < @fecha_proceso
	AND DATEDIFF(dd,fecha_vencimiento,@fecha_proceso) > 90
	
	IF @cod_moneda = 1
	BEGIN
		--intereses devengados cuotas vigentes y morosas en $
		SET @int_dv_cuotas_vig_$			= @int_dv_cuotas_vig
		set @int_dv_cuotas_vig_moro_29_$	= @int_dv_cuotas_vig_moro_29   
		set @int_dv_cuotas_vig_moro_59_$	= @int_dv_cuotas_vig_moro_59 
		set @int_dv_cuotas_vig_moro_89_$	= @int_dv_cuotas_vig_moro_89
		set @int_dv_cuotas_vig_moro_90_$	= @int_dv_cuotas_vig_moro_90 
	END	
	ELSE 
	BEGIN
	
		--paridad
		SELECT @paridad = ISNULL(valor,0)
		FROM leasecom..p_valor_paridades
		WHERE cod_moneda = @cod_moneda
		AND   fecha = @fecha_proceso
		
		--intereses devengados cuotas vigentes y morosas en UF o US
		SET @int_dv_cuotas_vig_$			= @int_dv_cuotas_vig * @paridad
		set @int_dv_cuotas_vig_moro_29_$	= @int_dv_cuotas_vig_moro_29 * @paridad   
		set @int_dv_cuotas_vig_moro_59_$	= @int_dv_cuotas_vig_moro_59 * @paridad 
		set @int_dv_cuotas_vig_moro_89_$	= @int_dv_cuotas_vig_moro_89 * @paridad 
		set @int_dv_cuotas_vig_moro_90_$	= @int_dv_cuotas_vig_moro_90 * @paridad 
	END
	
	--intereses normales en $, cuotas vigentes contratos vigentes
	SELECT @int_nor_$_dv_cuotas_vig = SUM(interes)
	FROM dbo.t_cuotas
	WHERE operacion = @operacion
	AND estado = 1 --vigente
	AND fecha_vencimiento > @fecha_proceso
	
	IF @cod_moneda <> 1
		SET @int_nor_$_dv_cuotas_vig	= @int_nor_$_dv_cuotas_vig * @paridad

	--Intereses normales en $, cuotas morosas entre 1 y 29 días, Contratos deteriorado negativo
	SELECT @int_nor_$_dv_cuotas_moro_29 = SUM(interes)
	FROM dbo.t_cuotas a,t_contratos_ifrs b
	WHERE a.operacion = b.operacion
	AND a.operacion = @operacion
	AND a.fecha_vencimiento < @fecha_proceso
	AND DATEDIFF(dd,a.fecha_vencimiento,@fecha_proceso) BETWEEN 1 AND 29
	AND b.deterioro_operacion = 'D'
	AND b.marca_suspension = 'S'
	AND b.fecha_suspension < @fecha_proceso
	
	IF @cod_moneda <> 1
		SET @int_nor_$_dv_cuotas_moro_29	= @int_nor_$_dv_cuotas_moro_29 * @paridad


	--Intereses normales en $, cuotas morosas entre 30 y 59 días, Contratos deteriorado negativo
	SELECT @int_nor_$_dv_cuotas_moro_59 = SUM(interes)
	FROM dbo.t_cuotas a,t_contratos_ifrs b
	WHERE a.operacion = b.operacion
	AND a.operacion = @operacion
	AND a.fecha_vencimiento < @fecha_proceso
	AND DATEDIFF(dd,a.fecha_vencimiento,@fecha_proceso) BETWEEN 30 AND 59
	AND b.deterioro_operacion = 'D'
	AND b.marca_suspension = 'S'
	AND b.fecha_suspension < @fecha_proceso
	
	IF @cod_moneda <> 1
		SET @int_nor_$_dv_cuotas_moro_59	= @int_nor_$_dv_cuotas_moro_59 * @paridad


	--Intereses normales en $, cuotas morosas entre 60 y 89 días, Contratos deteriorado negativo
	SELECT @int_nor_$_dv_cuotas_moro_89 = SUM(interes)
	FROM dbo.t_cuotas a,t_contratos_ifrs b
	WHERE a.operacion = b.operacion
	AND a.operacion = @operacion
	AND a.fecha_vencimiento < @fecha_proceso
	AND DATEDIFF(dd,a.fecha_vencimiento,@fecha_proceso) BETWEEN 60 AND 89
	AND b.deterioro_operacion = 'D'
	AND b.marca_suspension = 'S'
	AND b.fecha_suspension < @fecha_proceso
	
	IF @cod_moneda <> 1
		SET @int_nor_$_dv_cuotas_moro_89	= @int_nor_$_dv_cuotas_moro_89 * @paridad


	--Intereses normales en $, cuotas morosas 90 y más, Contratos deteriorado negativo
	SELECT @int_nor_$_dv_cuotas_moro_90 = SUM(interes)
	FROM dbo.t_cuotas a,t_contratos_ifrs b
	WHERE a.operacion = b.operacion
	AND a.operacion = @operacion
	AND a.fecha_vencimiento < @fecha_proceso
	AND DATEDIFF(dd,a.fecha_vencimiento,@fecha_proceso) > 90
	AND b.deterioro_operacion = 'D'
	AND b.marca_suspension = 'S'
	AND b.fecha_suspension < @fecha_proceso
	
	IF @cod_moneda <> 1
		SET @int_nor_$_dv_cuotas_moro_90	= @int_nor_$_dv_cuotas_moro_90 * @paridad
		
	--Intereses  mora devengados  de cuotas vigentes, Contratos deteriorado negativo ????
	SELECT @int_mora_$_dv_cuotas_vig_cdn = SUM(a.interes)
	FROM dbo.t_cuotas a,t_contratos_ifrs b
	WHERE a.operacion = @operacion
	AND a.estado IN (1,3) --vigente
	AND a.fecha_vencimiento < @fecha_proceso
	AND b.deterioro_operacion = 'D'
	AND b.marca_suspension = 'S'
	AND b.fecha_suspension < @fecha_proceso

	
	IF @cod_moneda <> 1
		SET @int_mora_$_dv_cuotas_vig_cdn	= @int_mora_$_dv_cuotas_vig_cdn * @paridad

	--Intereses  mora devengados  de cuotas morosas entre 1 y 29 días, Contratos deteriorado negativo ????
	SELECT @int_mora_$_dv_cuotas_moro_29_cdn = SUM(interes)
	FROM dbo.t_cuotas a,t_contratos_ifrs b
	WHERE a.operacion = b.operacion
	AND a.operacion = @operacion
	AND a.fecha_vencimiento < @fecha_proceso
	AND DATEDIFF(dd,a.fecha_vencimiento,@fecha_proceso) BETWEEN 1 AND 29
	AND b.deterioro_operacion = 'D'
	AND b.marca_suspension = 'S'
	AND b.fecha_suspension < @fecha_proceso
	
	IF @cod_moneda <> 1
		SET @int_mora_$_dv_cuotas_moro_29_cdn	= @int_mora_$_dv_cuotas_moro_29_cdn * @paridad
		
	--Intereses  mora devengados  de cuotas morosas entre 30 y 59 días, Contratos deteriorado negativo ????
	SET @int_mora_$_dv_cuotas_moro_59_cdn = 0
	
	--Intereses  mora devengados  de cuotas morosas entre 60 y 89 días, Contratos deteriorado negativo ????
	set @int_mora_$_dv_cuotas_moro_89_cdn = 0
	
	--Intereses  mora devengados  de cuotas morosas mayor 90 días, Contratos deteriorado negativo ????
	set @int_mora_$_dv_cuotas_moro_90_cdn = 0
	
	--Intereses  mora en pesos devengados  de cuotas morosas entre 1 y 29 dias, no castigadas de contrato ????
	set @int_mora_$_dv_cuotas_moro_29_c = 0

	--Intereses  mora en pesos devengados  de cuotas morosas entre 30 y 59 dias, no castigadas de contrato ????
	set @int_mora_$_dv_cuotas_moro_59_c = 0

	--Intereses  mora en pesos devengados  de cuotas morosas entre 60 y 89 dias, no castigadas de contrato ????
	set @int_mora_$_dv_cuotas_moro_89_c = 0

	--Intereses  mora en pesos devengados  de cuotas morosas mayor 90 dias, no castigadas de contrato ????
	set @int_mora_$_dv_cuotas_moro_90_c = 0
	
	--reajustes de capital contrato deteriorado negativo, cuotas vigentes en pesos
	set @rea_k_cdn_cuotas_vig_$ = 0
	
	--reajustes de capital contrato deteriorado negativo, cuotas morosas de 1 a 29 dias en pesos
	set @rea_k_cdn_cuotas_moro_29_$ = 0
	
	--reajustes de capital contrato deteriorado negativo, cuotas morosas de 30 a 59 dias en pesos
	set @rea_k_cdn_cuotas_moro_59_$ = 0
	
	--reajustes de capital contrato deteriorado negativo, cuotas morosas de 60 a 89 dias en pesos
	set @rea_k_cdn_cuotas_moro_89_$ = 0
	
	--reajustes de capital contrato deteriorado negativo, cuotas morosas mas de 90 dias en pesos
	set @rea_k_cdn_cuotas_moro_90_$ = 0


	----------------------------------------------------------------
   -- Insertar registro.  
		INSERT INTO #det_devengo
		VALUES(
		ISNULL(@tipo_reg,' '),
		ISNULL(@rut_cliente,' '),
		ISNULL(@dv,' '),
		ISNULL(@cod_oficina,'0'),
		ISNULL(@tipo_oper,' '),
		ISNULL(@ppp_emb,'0'),
		ISNULL(@num_docto,0),
		ISNULL(@int_dv_cuotas_vig,0),
		ISNULL(@int_dv_cuotas_vig_moro_29,0),
		ISNULL(@int_dv_cuotas_vig_moro_59,0),
		ISNULL(@int_dv_cuotas_vig_moro_89,0),          	
		ISNULL(@int_dv_cuotas_vig_moro_90,0),     
		ISNULL(@cero1,'0'),
		ISNULL(@int_dv_cuotas_vig_$,0),
		ISNULL(@int_dv_cuotas_vig_moro_29_$,0),
		ISNULL(@int_dv_cuotas_vig_moro_59_$,0),
		ISNULL(@int_dv_cuotas_vig_moro_89_$,0),
		ISNULL(@int_dv_cuotas_vig_moro_90_$,0),
		ISNULL(@cero2,'0'),
		ISNULL(@dev_int_dif_pcio_mc_u,'0'),
		ISNULL(@dev_is_cr_vig_mo_u,'0'),
		ISNULL(@dev_is_cr_mora_h20_mo_u,'0'),
		ISNULL(@dev_is_cr_mora_m30_h59_mo_u,'0'),
		ISNULL(@dev_is_cr_mora_m60_h89_mo_u,'0'),
		ISNULL(@dev_is_cr_mora_m90_mo_u,'0'),
		ISNULL(@cero3,'0'),
		ISNULL(@dev_is_cr_vig_mc_u,'0'),
		ISNULL(@dev_is_cr_mora_h20_mc_u,'0'),
		ISNULL(@dev_is_cr_mora_m30_h59_mc_u,'0'),
		ISNULL(@dev_is_cr_mora_m60_h89_mc_u,'0'),
		ISNULL(@dev_is_cr_mora_m90_mc_u,'0'),
		ISNULL(@cero4,'0'),
		ISNULL(@int_nor_$_dv_cuotas_vig,0),       	
		ISNULL(@int_nor_$_dv_cuotas_moro_29,0),    
		ISNULL(@int_nor_$_dv_cuotas_moro_59,0),    
		ISNULL(@int_nor_$_dv_cuotas_moro_89,0),    
		ISNULL(@int_nor_$_dv_cuotas_moro_90,0),    
		ISNULL(@cero5,'0'),   
		ISNULL(@int_mora_$_dv_cuotas_vig_cdn,0),       	
		ISNULL(@int_mora_$_dv_cuotas_moro_29_cdn,0),
		ISNULL(@int_mora_$_dv_cuotas_moro_59_cdn,0),
		ISNULL(@int_mora_$_dv_cuotas_moro_89_cdn,0),
		ISNULL(@int_mora_$_dv_cuotas_moro_90_cdn,0),
		ISNULL(@cero6,'0'),
		ISNULL(@int_mora_$_dv_cuotas_moro_29_c,0),
		ISNULL(@int_mora_$_dv_cuotas_moro_59_c,0),
		ISNULL(@int_mora_$_dv_cuotas_moro_89_c,0),
		ISNULL(@int_mora_$_dv_cuotas_moro_90_c,0),	
		ISNULL(@cero7,'0'),
		ISNULL(@pdev_reaj_vig_mn,'0'),
		ISNULL(@pdev_reaj_01_h29_mn,'0'),
		ISNULL(@pdev_reaj_30_h59_mn,'0'),
		ISNULL(@pdev_reaj_60_h89_mn,'0'),
		ISNULL(@pdev_reaj_90_mas_mn,'0'),
		ISNULL(@cero8,'0'),
		ISNULL(@rea_k_cdn_cuotas_vig_$,0), 
		ISNULL(@rea_k_cdn_cuotas_moro_29_$,0),
		ISNULL(@rea_k_cdn_cuotas_moro_59_$,0),
		ISNULL(@rea_k_cdn_cuotas_moro_89_$,0),
		ISNULL(@rea_k_cdn_cuotas_moro_90_$,0),
		ISNULL(@cero9,'0'),
		ISNULL(@dev_rs_cm_mora_m01_h29_mo_u,'0'),
		ISNULL(@dev_rs_cm_mora_m30_h59_mo_u,'0'),
		ISNULL(@dev_rs_cm_mora_m60_h89_mo_u,'0'),
		ISNULL(@dev_rs_cm_mora_m90_mas_mo_u,'0'),
		ISNULL(@dev_rs_cm_int_con_venc_u,'0'),
		ISNULL(@dev_rs_cm_pre_judic_mo_u,'0'),
		ISNULL(@dev_rs_cm_en_ejec_mo_u,'0'),
		ISNULL(@dev_ppp_contab_cre,'0'),
		ISNULL(@mda_conta,'999'),
		ISNULL(@dev_pzo_tas_var,' '))


--    IF @@error <> 0
--    BEGIN
--      RAISERROR 20022 'Error al inserta registro'
--      RETURN
--    END

--
FETCH  c_cto INTO @operacion, @rut_cliente, @cod_oficina, @cla_cartera, @cod_moneda

END
CLOSE c_cto
DEALLOCATE c_cto

SET @total_reg = (SELECT COUNT(*) FROM #det_devengo)

insert into #cabecera
SELECT  '0' +
		'LSA' +
		'DEVENGAMIENTO' +
		CONVERT(CHAR(8),@fecha_proceso,112) + 
		REPLICATE(' ',960), 1

INSERT INTO #detalle
SELECT 
	tipo_reg +
	REPLICATE('0',9 - LEN(RTRIM(rut))) +  RTRIM(rut) +
	dv +
	REPLICATE('0',3 - LEN(RTRIM(oficina))) +  RTRIM(oficina) +
	REPLICATE('0',5 - LEN(RTRIM(cartera))) +  RTRIM(cartera) +
	ppp_emb +
	REPLICATE('0',9 - LEN(RTRIM(num_docto))) +  RTRIM(num_docto) +
	REPLICATE('0',15 - LEN(RTRIM(devmon))) +  RTRIM(devmon) +
	REPLICATE('0',15 - LEN(RTRIM(dev01_29))) +  RTRIM(dev01_29) +
	REPLICATE('0',15 - LEN(RTRIM(dev30_59))) +  RTRIM(dev30_59) +
	REPLICATE('0',15 - LEN(RTRIM(dev60_89))) +  RTRIM(dev60_89) +
	REPLICATE('0',15 - LEN(RTRIM(dev90_mas))) +  RTRIM(dev90_mas) +
	cero1 +
	REPLICATE('0',15 - LEN(RTRIM(pdevmon))) +  RTRIM(pdevmon) +
	REPLICATE('0',15 - LEN(RTRIM(pdev01_29))) +  RTRIM(pdev01_29) +
	REPLICATE('0',15 - LEN(RTRIM(pdev30_59))) +  RTRIM(pdev30_59) +
	REPLICATE('0',15 - LEN(RTRIM(pdev60_89))) +  RTRIM(pdev60_89) +
	REPLICATE('0',15 - LEN(RTRIM(pdev90_mas))) +  RTRIM(pdev90_mas) +
	cero2 +
	dev_int_dif_pcio_mc_u  +
	dev_is_cr_vig_mo_u  +
	dev_is_cr_mora_h20_mo_u +
	dev_is_cr_mora_m30_h59_mo_u +
	dev_is_cr_mora_m60_h89_mo_u +
	dev_is_cr_mora_m90_mo_u +
	cero3   +
	dev_is_cr_vig_mc_u +
	dev_is_cr_mora_h20_mc_u +
	dev_is_cr_mora_m30_h59_mc_u +
	dev_is_cr_mora_m60_h89_mc_u +
	dev_is_cr_mora_m90_mc_u	+
	cero4  +
	REPLICATE('0',15 - LEN(RTRIM(pdev_isn_c_det_vig_mc))) +  RTRIM(pdev_isn_c_det_vig_mc) +
	REPLICATE('0',15 - LEN(RTRIM(pdev_isn_c_det_01_h29_mc))) +  RTRIM(pdev_isn_c_det_01_h29_mc) +
	REPLICATE('0',15 - LEN(RTRIM(pdev_isn_c_det_30_h59_mc))) +  RTRIM(pdev_isn_c_det_30_h59_mc) +
	REPLICATE('0',15 - LEN(RTRIM(pdev_isn_c_det_60_h89_mc))) +  RTRIM(pdev_isn_c_det_60_h89_mc) +
	REPLICATE('0',15 - LEN(RTRIM(pdev_isn_c_det_90_mas_mc))) +  RTRIM(pdev_isn_c_det_90_mas_mc) +
	cero5  +
	REPLICATE('0',15 - LEN(RTRIM(pdev_isp_c_det_vig_mc))) +  RTRIM(pdev_isp_c_det_vig_mc) +
	REPLICATE('0',15 - LEN(RTRIM(pdev_isp_c_det_01_h29_mc))) +  RTRIM(pdev_isp_c_det_01_h29_mc) +
	REPLICATE('0',15 - LEN(RTRIM(pdev_isp_c_det_30_h59_mc))) +  RTRIM(pdev_isp_c_det_30_h59_mc) +
	REPLICATE('0',15 - LEN(RTRIM(pdev_isp_c_det_60_h89_mc))) +  RTRIM(pdev_isp_c_det_60_h89_mc) +
	REPLICATE('0',15 - LEN(RTRIM(pdev_isp_c_det_90_mas_mc))) +  RTRIM(pdev_isp_c_det_90_mas_mc) +
	cero6 +
	REPLICATE('0',15 - LEN(RTRIM(pdev_ip_c_01_h29_mc))) +  RTRIM(pdev_ip_c_01_h29_mc) +
	REPLICATE('0',15 - LEN(RTRIM(pdev_ip_c_30_h59_mc))) +  RTRIM(pdev_ip_c_30_h59_mc) +
	REPLICATE('0',15 - LEN(RTRIM(pdev_ip_c_60_h89_mc))) +  RTRIM(pdev_ip_c_60_h89_mc) +
	REPLICATE('0',15 - LEN(RTRIM(pdev_ip_c_90_mas_mc))) +  RTRIM(pdev_ip_c_90_mas_mc) +
	cero7 +
	pdev_reaj_vig_mn +
	pdev_reaj_01_h29_mn +
	pdev_reaj_30_h59_mn +
	pdev_reaj_60_h89_mn +
	pdev_reaj_90_mas_mn +
	cero8 +
	REPLICATE('0',13 - LEN(RTRIM(pdev_reaj_det_vig_mn))) +  RTRIM(pdev_reaj_det_vig_mn) +
	REPLICATE('0',13 - LEN(RTRIM(pdev_reaj_det_m01_h29_mn))) +  RTRIM(pdev_reaj_det_m01_h29_mn) +
	REPLICATE('0',13 - LEN(RTRIM(pdev_reaj_det_m30_h59_mn))) +  RTRIM(pdev_reaj_det_m30_h59_mn) +
	REPLICATE('0',13 - LEN(RTRIM(pdev_reaj_det_m60_h89_mn))) +  RTRIM(pdev_reaj_det_m60_h89_mn) +
	REPLICATE('0',13 - LEN(RTRIM(pdev_reaj_det_m90_mas_mn))) +  RTRIM(pdev_reaj_det_m90_mas_mn) +
	cero9 +
	dev_rs_cm_mora_m01_h29_mo_u +
	dev_rs_cm_mora_m30_h59_mo_u +
	dev_rs_cm_mora_m60_h89_mo_u +
	dev_rs_cm_mora_m90_mas_mo_u +
	dev_rs_cm_int_con_venc_u +
	dev_rs_cm_pre_judic_mo_u +
	dev_rs_cm_en_ejec_mo_u	+
	dev_ppp_contab_cre	+
	mda_conta +
	dev_pzo_tas_var,
	2
FROM #det_devengo

insert into #trailer
SELECT '2' +
		replicate('0' , 6 - LEN(CONVERT(VARCHAR(6),@total_reg)))  + CONVERT(VARCHAR(6),@total_reg) +
		REPLICATE('0', 15) + --Sumatoria de  intereses devengados normales, en pesos de contratos vigentes
		REPLICATE('0', 15) + --Sumatoria de  intereses devengados normales, en moneda del contrato,  de contratos vigentes
		REPLICATE(' ', 948),3 
	
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

GRANT EXEC ON pa_lo_interfaz_isa_deven TO Usuarios











USE [leaseoper]
GO
/****** Object:  StoredProcedure [dbo].[pa_lo_interfaz_m31_fore01li_099001000]    Script Date: 06/03/2014 16:20:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/****** Objeto:  procedimiento almacenado dbo.pa_lo_interfaz_m31_fore01li_099001000    fecha de la secuencia de comandos: 09-07-2007 9:25:28 ******/
ALTER PROCEDURE [dbo].[pa_lo_interfaz_m31_fore01li_099001000]
@fecha_proceso    SMALLDATETIME,
@salida           INT OUTPUT
AS
/*
Nombre            :  pa_lo_interfaz_m31_fore01li_099001000

Descripción       : Esta Interfaz es enviada a la compañia de seguros

Parametros entrada: @fecha_proceso:

Parametros salida :  Ninguno.

Tablas entrada    :  

Tablas salida     :  Archivo plano.

Fecha             :  Julio 2014.

Modificaciones    :

Procedimientos que Llama :

Observaciones      :  

Autor              : Verónica Inzunza.

Ejecucion          :  

EXEC leaseoper..pa_lo_interfaz_m31_fore01li_099001000 '19/03/2014',0
EXEC leaseoper..pa_lo_interfaz_m31_fore01li_099001000 '24/03/2014',0

*/
set nocount on
--

DECLARE
@operacion			INT,
@oficina			SMALLINT,
@rut_cliente		INT,
@cod_material		CHAR(03),
@des_material		CHAR(50),
@id_cliente			INT,
@contrato			CHAR(03),
@razon_social		CHAR(50),		
@dv					CHAR(01),
@cod_rubro			SMALLINT,
@cod_rubro_esp		SMALLINT,
@rubro				CHAR(04),
@num_unidades		CHAR(03),
@fec_vig			CHAR(08),
@fec_ter			CHAR(08),
@fec_act			CHAR(08),
@cod_marca			CHAR(04),	
@derec_for			CHAR(01),	
@cober_for			CHAR(02),
@blanc_for			CHAR(02),
@total_valor_bien	FLOAT,
@total_reg			INT,
@num_material		INT,
@num_material_grupo INT,
@direccion			CHAR(40),
@region				CHAR(02),
@cod_comuna			INT,
@cod_ciudad			INT,
@cod_region			INT,
@comuna				CHAR(15),
@ciudad				CHAR(15),
@fecha_acta_recepcion  SMALLDATETIME,
@fecha_termino		   SMALLDATETIME,
@valor				FLOAT,
@valor_bien			FLOAT,
@paridad_uf			FLOAT,
@paridad_us			FLOAT,
@cod_moneda			INT,
@fecha_ing_carta_recep SMALLDATETIME,
@fecha_paridad		   SMALLDATETIME
 

--
IF @fecha_proceso IS NULL OR @fecha_proceso = '01/01/1900'
BEGIN
   SELECT @salida = 0
   --RAISERROR 20000 'Debe Ingresar Periodo a Procesar'
   RETURN 1
END
--
CREATE TABLE #forestal(
	ofici_for	CHAR(02) NULL,
	clien_for	CHAR(05) NULL,
	contr_for	CHAR(03) NULL,
	mater_for	CHAR(03) NULL,
	--rsoci_for	CHAR(40) NULL,
	rsoci_for	CHAR(50) NULL,
	rutri_for	CHAR(08) NULL,
	dveri_for	CHAR(01) NULL,
	crubr_for	CHAR(04) NULL,
	domic_for	CHAR(40) NULL,
	comun_for	CHAR(15) NULL,
	ciuda_for	CHAR(15) NULL,
	regio_for	CHAR(02) NULL,
	miden_for	CHAR(50) NULL, 
	--descr_for	CHAR(38) NULL,
	descr_for	CHAR(50) NULL,
	nunid_for	CHAR(03) NULL, 
	vcmat_for	FLOAT	 NULL,
	vcori_for	FLOAT	 NULL,
	facti_for	CHAR(08) NULL,
	fevig_for	CHAR(08) NULL,
	fterm_for	CHAR(08) NULL,
	derec_for	CHAR(01) NULL,
	cober_for	CHAR(02) NULL,
	blanc_for	CHAR(02)NULL)
	
--276
CREATE TABLE #cabecera(
salida CHAR(280) NULL,
indice int null)

CREATE TABLE #detalle(
salida CHAR(280) NULL,
indice INT null)

CREATE TABLE #trailer(
salida CHAR(280) NULL,
indice INT null)

CREATE TABLE #salida(
salida CHAR(280) NULL,
indice INT null)

-- Cursor que recorre todos los contratos Vigentes 

DECLARE c_cto CURSOR LOCAL FOR
select a.operacion,
	a.rut_cliente,
	a.cod_oficina_real,
	a.fecha_ing_carta_recep,
	a.fecha_termino,
	b.num_material,
	b.num_material_grupo,
	b.cod_material,
	b.descripcion,
	b.cod_rubro,
	b.cod_rubro_especifico,
	b.fecha_acta_recepcion,
	b.valor,
	b.cod_moneda
FROM t_contratos a,t_bienes_detalle b
WHERE a.operacion = b.operacion
AND a.estado_operacion = 2
AND a.fecha_ingreso_cont <= @fecha_proceso
ORDER BY a.operacion
OPEN c_cto
FETCH  c_cto INTO @operacion, @rut_cliente,@oficina, @fecha_ing_carta_recep,@fecha_termino,@num_material,@num_material_grupo,@cod_material, @des_material, @cod_rubro, @cod_rubro_esp,
@fecha_acta_recepcion,@valor,@cod_moneda
WHILE (@@FETCH_STATUS = 0)
BEGIN
		
	--cliente
	SELECT @id_cliente = ISNULL(id_cliente,0)
	FROM dbo.t_datos_cliente_banco
	WHERE lberut = @rut_cliente
	
	--contrato y cod material estan def como char(3), pero en nuestras bases tienes 6 digitos.
	SET @contrato = '000'
	SET @cod_material = '000'
	--SET @tipo_vehiculo = '00' --char(2) pero es una descripción
	
	--cliente
	SELECT @razon_social = nombre,
		   @dv = dv,
		   @direccion = direccion,
		   @cod_comuna = cod_comuna
	FROM leasecom..v_clientes
	WHERE rut = @rut_cliente
	
	SELECT @comuna = descripcion,
		   @cod_region = cod_region,
		   @cod_ciudad = cod_ciudad
	FROM leasecom..p_localidad --cod comuna
	WHERE cod_comuna = @cod_comuna
	
	SELECT @ciudad = descripcion
	FROM leasecom..p_ciudad ----cod region, cod_ciudad
	WHERE cod_region = @cod_region
	AND cod_ciudad = @cod_ciudad
	
	--valor compra
	SET @fecha_paridad = ISNULL(@fecha_acta_recepcion,@fecha_ing_carta_recep)
	
	SET @fecha_paridad = ISNULL(@fecha_paridad,@fecha_proceso)
	
	--paridad en UF
	select @paridad_uf  = valor 
	from leasecom..p_valor_paridades 
	where cod_moneda = 2
	and fecha = @fecha_paridad
	
	if @cod_moneda = 1
		SET @valor_bien = (@valor / @paridad_uf)
		
	IF @cod_moneda = 4
	BEGIN
		--paridad US
		select @paridad_us  = valor 
		from leasecom..p_valor_paridades 
		where cod_moneda = 4
		and fecha = @fecha_paridad

		SET @valor_bien = (@valor * @paridad_us) / @paridad_uf
	END

	--rubro
	SET @rubro = CONVERT(CHAR(2),@cod_rubro) + CONVERT(CHAR(2),@cod_rubro_esp)
	
	--unidades
	SELECT @num_unidades = CONVERT(CHAR(3), ISNULL(COUNT(1),0))
	FROM t_bienes_detalle
	WHERE operacion = @operacion
	AND num_material_grupo = @num_material_grupo
	
	--fecha vigencia,fecha termino,fecha activación
	SET @fec_vig	= '00000000'
	SET @fec_ter	= CONVERT(CHAR(8),@fecha_termino,112)
	SET @fec_act    = CONVERT(CHAR(8),@fecha_ing_carta_recep,112)
	
	--campo sin uso
	SET @derec_for	= ' '	
	
	--Cobertura de Seguro
	SET @cober_for = '00' --definición banco de chile, para accesorios = 8
	
	--Señala Seguro por Mera tenencia hasta 60 días.
	SET @blanc_for	= '00'
    
    -- Insertar registro. 
    INSERT INTO #forestal
    VALUES( ISNULL(@oficina,' '),
			ISNULL(@id_cliente,' '),
			ISNULL(@contrato,' '),
			ISNULL(@cod_material ,' '),
			ISNULL(@razon_social,' '),
			ISNULL(@rut_cliente,' '),
			ISNULL(@dv,' '),
			ISNULL(@rubro,' '),
			ISNULL(@direccion,' '),
			ISNULL(@comuna,' '),
			ISNULL(@ciudad,' '),
			ISNULL(@cod_region,'0'),
			ISNULL(@des_material,' '),
			ISNULL(@razon_social,' '),
			ISNULL(@num_unidades,'0'),
			ISNULL(@valor_bien,0),
			ISNULL(@valor_bien,0),
			ISNULL(@fec_act,'00000000'),
			ISNULL(@fec_vig,'00000000'),
			ISNULL(@fec_ter,'00000000'),
			ISNULL(@derec_for,' '),
			ISNULL(@cober_for,' '),
			ISNULL(@blanc_for,' '))
FETCH  c_cto INTO @operacion, @rut_cliente,@oficina, @fecha_ing_carta_recep,@fecha_termino,@num_material,@num_material_grupo,@cod_material, @des_material, @cod_rubro, @cod_rubro_esp,
@fecha_acta_recepcion,@valor,@cod_moneda
END
CLOSE c_cto
DEALLOCATE c_cto

--SELECT *
--FROM #forestal

SET @total_reg = (SELECT COUNT(*) FROM #forestal) + 2
SET @total_valor_bien = (SELECT SUM(vcmat_for) FROM #forestal)

insert into #cabecera
SELECT CONVERT(CHAR(08),@fecha_proceso,112) +
       'BANCODECHILE LEASINGANDINO',1

INSERT INTO #detalle
SELECT 
	REPLICATE('0', 2 - LEN(LTRIM(RTRIM(ofici_for)))) + LTRIM(RTRIM(ofici_for)) + 
	REPLICATE('0', 5 - LEN(LTRIM(RTRIM(clien_for)))) + LTRIM(RTRIM(clien_for)) +
	REPLICATE('0', 3 - LEN(LTRIM(RTRIM(contr_for)))) + LTRIM(RTRIM(contr_for)) +
	REPLICATE('0', 3 - LEN(LTRIM(RTRIM(mater_for)))) + LTRIM(RTRIM(mater_for)) +
	LTRIM(RTRIM(rsoci_for)) + REPLICATE(' ', 40 - LEN(rsoci_for)) +
	REPLICATE('0', 8 - LEN(LTRIM(RTRIM(rutri_for)))) + LTRIM(RTRIM(rutri_for)) +
	REPLICATE('0', 1 - LEN(dveri_for)) + dveri_for +
	REPLICATE('0', 4 - LEN(crubr_for)) + crubr_for +
	LTRIM(RTRIM(domic_for)) + REPLICATE(' ', 40 - LEN(LTRIM(RTRIM(domic_for)))) + 
	LTRIM(RTRIM(comun_for)) + REPLICATE(' ', 15 - LEN(LTRIM(RTRIM(comun_for)))) + 
	LTRIM(RTRIM(ciuda_for)) + REPLICATE(' ', 15 - LEN(LTRIM(RTRIM(ciuda_for)))) + 
	REPLICATE('0', 2  - LEN(LTRIM(RTRIM(regio_for)))) + LTRIM(RTRIM(regio_for)) + 
	LTRIM(RTRIM(miden_for)) + REPLICATE(' ', 50 - LEN(LTRIM(RTRIM(miden_for)))) +
	LTRIM(RTRIM(descr_for)) + REPLICATE(' ', 38 - LEN(LTRIM(RTRIM(descr_for)))) +
	REPLICATE('0', 3 - LEN(LTRIM(RTRIM(nunid_for)))) + LTRIM(RTRIM(nunid_for)) +
	REPLICATE('0', 9 - LEN(LTRIM(STR(vcmat_for,7,2)))) + LTRIM(STR(vcmat_for,7,2)) +
	REPLICATE('0', 9 - LEN(LTRIM(STR(vcori_for,7,2)))) + LTRIM(STR(vcori_for,7,2)) +
	REPLICATE('0', 8 - LEN(LTRIM(RTRIM(facti_for)))) + LTRIM(RTRIM(facti_for)) +
	REPLICATE('0', 8 - LEN(LTRIM(RTRIM(fevig_for)))) + LTRIM(RTRIM(fevig_for)) +
	REPLICATE('0', 8 - LEN(LTRIM(RTRIM(fterm_for)))) + LTRIM(RTRIM(fterm_for)) +
	derec_for +
	REPLICATE('0', 2 - LEN(LTRIM(RTRIM(cober_for)))) + LTRIM(RTRIM(cober_for)) +
	REPLICATE('0', 2 - LEN(LTRIM(RTRIM(blanc_for)))) + LTRIM(RTRIM(blanc_for)),
	2
FROM #forestal

insert into #trailer
SELECT replicate('0' , 9 - LEN(CONVERT(VARCHAR(9),@total_reg)))  + CONVERT(VARCHAR(9),@total_reg) +
	   replicate('0' , 16 - LEN(CONVERT(VARCHAR(16),@total_valor_bien)))  + CONVERT(VARCHAR(16),@total_valor_bien),3 
	
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

GRANT EXEC ON pa_lo_interfaz_m31_fore01li_099001000 TO Usuarios











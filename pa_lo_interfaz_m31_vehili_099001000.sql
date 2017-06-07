USE [leaseoper]
GO
/****** Object:  StoredProcedure [dbo].[pa_lo_interfaz_m31_vehili_099001000]    Script Date: 06/03/2014 16:20:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/****** Objeto:  procedimiento almacenado dbo.pa_lo_interfaz_m31_vehili_099001000    fecha de la secuencia de comandos: 09-07-2007 9:25:28 ******/
ALTER PROCEDURE [dbo].[pa_lo_interfaz_m31_vehili_099001000]
@fecha_proceso    SMALLDATETIME,
@salida           INT OUTPUT
AS
/*
Nombre            :  pa_lo_interfaz_m31_vehili_099001000

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

EXEC leaseoper..pa_lo_interfaz_m31_vehili_099001000 '19/03/2014',0
EXEC leaseoper..pa_lo_interfaz_m31_vehili_099001000 '24/03/2014',0

*/
set nocount on
--

DECLARE
@operacion			INT,
@oficina			SMALLINT,
@rut_cliente		INT,
@cod_material		INT,
@des_material		CHAR(50),
@marca				CHAR(30),
@modelo				CHAR(40),
@tipo_vehiculo		CHAR(50),
@ano				SMALLINT,
@color				CHAR(40),
@placa_letras		CHAR(06),
@num_motor			CHAR(30),
@num_chasis			CHAR(30),
@id_cliente			INT,
@contrato			CHAR(03),
@razon_social		CHAR(40),		
@dv					CHAR(01),
@cod_rubro			SMALLINT,
@cod_rubro_esp		SMALLINT,
@rubro				CHAR(04),
@num_unidades		CHAR(03),
@tasacion			FLOAT,
@filler_1			CHAR(01),
@fec_vig			CHAR(08),
@fec_ter			CHAR(08),
@filler_2			CHAR(08),
@cod_marca			CHAR(04),	
@derec_veh			CHAR(01),	
@cober_veh			CHAR(02),
@blanc_veh			CHAR(02),
@total_tasacion		FLOAT,
@total_reg			INT,
@deducible			CHAR(04),
@num_material		INT,
@num_material_grupo INT,
@fecha_termino		SMALLDATETIME
 

--
IF @fecha_proceso IS NULL OR @fecha_proceso = '01/01/1900'
BEGIN
   SELECT @salida = 0
   --RAISERROR 20000 'Debe Ingresar Periodo a Procesar'
   RETURN 1
END
--
CREATE TABLE #vehiculos(
	ofici_veh	CHAR(02) NULL,
	clien_veh	CHAR(05) NULL,
	contr_veh	CHAR(03) NULL,
	mater_veh	CHAR(03) NULL,
	rsoci_veh	CHAR(40) NULL,
	rutri_veh	CHAR(08) NULL,
	dveri_veh	CHAR(01) NULL,
	miden_veh	CHAR(50) NULL,
	crubr_veh	CHAR(04) NULL,
	nunid_veh	CHAR(03) NULL,
	vtasa_veh	FLOAT    NULL,
	vdedu_veh	CHAR(04) NULL,
	filler_01	CHAR(01) NULL,
	comar_veh	CHAR(04) NULL,
	filler_02	CHAR(08) NULL,
	fevig_veh	CHAR(08) NULL,
	fterm_veh	CHAR(08) NULL,
	marca_veh	CHAR(25) NULL,
	model_veh	CHAR(25) NULL,
	tipov_veh	CHAR(02) NULL,
	anofa_veh	CHAR(04) NULL,
	color_veh	CHAR(25) NULL,
	npise_veh	CHAR(12) NULL,
	nmarh_veh	CHAR(25) NULL,
	chass_veh	CHAR(25) NULL,
	derec_veh	CHAR(01) NULL,
	cober_veh	CHAR(02) NULL,
	blanc_veh	CHAR(02)NULL)
	
--309
CREATE TABLE #cabecera(
salida CHAR(350) NULL,
indice int null)

CREATE TABLE #detalle(
salida CHAR(350) NULL,
indice INT null)

CREATE TABLE #trailer(
salida CHAR(350) NULL,
indice INT null)

CREATE TABLE #salida(
salida CHAR(350) NULL,
indice INT null)

-- Cursor que recorre todos los contratos Vigentes 

DECLARE c_cto CURSOR LOCAL FOR
select a.operacion,
	a.cod_oficina_real,
	b.num_material,
	b.num_material_grupo,
	b.cod_material,
	b.descripcion,
	b.cod_rubro,
	b.cod_rubro_especifico,
	b.valor_tasacion,
	a.fecha_termino,
	a.rut_cliente,
	c.marca,
	c.modelo,
	c.tipo_vehiculo,
	c.ano,
	c.color,
	c.placa_letras,
	c.num_motor,
	c.num_chasis
FROM t_contratos a,t_bienes_detalle b,dbo.t_vehiculos_detalle c 
WHERE a.operacion = b.operacion
AND b.cod_material = c.cod_material
AND b.operacion = c.operacion
AND a.estado_operacion = 2
AND a.fecha_ingreso_cont <= @fecha_proceso
ORDER BY a.operacion
OPEN c_cto
FETCH  c_cto INTO @operacion, @oficina, @num_material,@num_material_grupo,@cod_material, @des_material, @cod_rubro, @cod_rubro_esp,@tasacion,
@fecha_termino,@rut_cliente,@marca, @modelo, @tipo_vehiculo, @ano,@color,@placa_letras,@num_motor,@num_chasis
WHILE (@@FETCH_STATUS = 0)
BEGIN
		
	--cliente
	SELECT @id_cliente = ISNULL(id_cliente,0)
	FROM dbo.t_datos_cliente_banco
	WHERE lberut = @rut_cliente
	
	--contrato y cod material estan def como char(3), pero en nuestras bases tienes 6 digitos.
	SET @contrato = '000'
	SET @cod_material = '000'
	SET @tipo_vehiculo = '00' --char(2) pero es una descripción
	
	--cliente
	SELECT @razon_social = nombre,
		   @dv = dv
	FROM leasecom..v_clientes
	WHERE rut = @rut_cliente
	
	--rubro
	SET @rubro = @cod_rubro + @cod_rubro_esp
	
	--unidades
	SELECT @num_unidades = CONVERT(CHAR(3), ISNULL(COUNT(1),0))
	FROM t_bienes_detalle
	WHERE operacion = @operacion
	AND num_material_grupo = @num_material_grupo
	
	--deducible
	SELECT @deducible = CONVERT(CHAR(4),ISNULL(deducible,0))
	FROM dbo.t_seguro
	WHERE operacion = @operacion
	AND num_material = @num_material
	AND cod_material = @cod_material
	
	SET @filler_1 = ' '
	SET @filler_2 = '00000000'
	
	--cod marca
	SELECT @cod_marca = CONVERT(CHAR(4),ISNULL(cod_marca,0))
	FROM leasecom..p_marcas_vehiculos
	WHERE descripcion = LTRIM(RTRIM(@marca))
	
	--fecha vigencia,fecha termino
	SET @fec_vig	= '00000000'
	SET @fec_ter	= CONVERT(CHAR(8),@fecha_termino,112)
	
	
	--campo sin uso
	SET @derec_veh	= ' '	
	
	--Cobertura de Seguro
	SET @cober_veh = '07' -- definición banco de chile vehículos = 7
	
	--Señala Seguro por Mera tenencia hasta 60 días.
	SET @blanc_veh	= '00'
    
    -- Insertar registro. 
    INSERT INTO #vehiculos
    VALUES( ISNULL(@oficina,' '),
			ISNULL(@id_cliente,' '),
			ISNULL(@contrato,' '),
			ISNULL(@cod_material ,' '),
			ISNULL(@razon_social,' '),
			ISNULL(@rut_cliente,' '),
			ISNULL(@dv,' '),
			ISNULL(@des_material,' '),
			ISNULL(@rubro,' '),
			ISNULL(@num_unidades,'0'),
			ISNULL(@tasacion ,0),
			ISNULL(@deducible,'0'),
			ISNULL(@filler_1,' '),
			ISNULL(@cod_marca,'0'),
			ISNULL(@filler_2,' '),
			ISNULL(@fec_vig,'00000000'),
			ISNULL(@fec_ter,'00000000'),
			ISNULL(@marca,' '),
			ISNULL(@modelo,' '),
			ISNULL(@tipo_vehiculo,' '),
			ISNULL(@ano,' '),
			ISNULL(@color,' '),
			ISNULL(@placa_letras,' '),
			ISNULL(@num_motor,' '),
			ISNULL(@num_chasis,' '),
			ISNULL(@derec_veh,' '),
			ISNULL(@cober_veh,' '),
			ISNULL(@blanc_veh,' '))
FETCH  c_cto INTO @operacion, @oficina, @num_material,@num_material_grupo,@cod_material, @des_material, @cod_rubro, @cod_rubro_esp,@tasacion,
@fecha_termino,@rut_cliente,@marca, @modelo, @tipo_vehiculo, @ano,@color,@placa_letras,@num_motor,@num_chasis
END
CLOSE c_cto
DEALLOCATE c_cto

SET @total_reg = (SELECT COUNT(*) FROM #vehiculos) + 2
SET @total_tasacion = (SELECT SUM(vtasa_veh) FROM #vehiculos)

insert into #cabecera
SELECT CONVERT(CHAR(08),@fecha_proceso,112) +
       'BANCODECHILE LEASINGANDINO', 1

insert into #detalle
SELECT 
	REPLICATE('0', 2 - LEN(LTRIM(RTRIM(ofici_veh)))) + LTRIM(RTRIM(ofici_veh)) + 
	REPLICATE('0', 5 - LEN(LTRIM(RTRIM(clien_veh)))) + LTRIM(RTRIM(clien_veh)) +
	REPLICATE('0', 3 - LEN(LTRIM(RTRIM(contr_veh)))) + LTRIM(RTRIM(contr_veh)) +
	REPLICATE('0', 3 - LEN(LTRIM(RTRIM(mater_veh)))) + LTRIM(RTRIM(mater_veh)) +
	LTRIM(RTRIM(rsoci_veh)) + REPLICATE(' ', 40 - LEN(rsoci_veh)) +
	REPLICATE('0', 8 - LEN(LTRIM(RTRIM(rutri_veh)))) + LTRIM(RTRIM(rutri_veh)) +
	REPLICATE('0', 1 - LEN(dveri_veh)) + dveri_veh +
	LTRIM(RTRIM(miden_veh)) + REPLICATE(' ', 50 - LEN(LTRIM(RTRIM(miden_veh)))) +
	REPLICATE('0', 4 - LEN(crubr_veh)) + RTRIM(crubr_veh) +
	REPLICATE('0', 3 - LEN(nunid_veh)) + RTRIM(nunid_veh) +
	REPLICATE('0', 9 - LEN(LTRIM(STR(vtasa_veh,7,2)))) + LTRIM(STR(vtasa_veh,7,2)) +
	REPLICATE('0', 4 - LEN(vdedu_veh)) + LTRIM(RTRIM(vdedu_veh)) +
	filler_01 + 
	REPLICATE('0', 4 - LEN(LTRIM(RTRIM(comar_veh)))) + LTRIM(RTRIM(comar_veh)) + 
	REPLICATE('0', 8 - LEN(LTRIM(RTRIM(filler_02)))) + LTRIM(RTRIM(filler_02)) +
	REPLICATE('0', 8 - LEN(LTRIM(RTRIM(fevig_veh)))) + LTRIM(RTRIM(fevig_veh)) +
	REPLICATE('0', 8 - LEN(LTRIM(RTRIM(fterm_veh)))) + LTRIM(RTRIM(fterm_veh)) +
	LTRIM(RTRIM(marca_veh)) + REPLICATE(' ', 25 - LEN(marca_veh)) +
	LTRIM(RTRIM(model_veh)) + REPLICATE(' ', 25 - LEN(model_veh)) +
	REPLICATE('0', 2 - LEN(LTRIM(RTRIM(tipov_veh)))) + LTRIM(RTRIM(tipov_veh)) +
	REPLICATE('0', 4 - LEN(LTRIM(RTRIM(anofa_veh)))) + LTRIM(RTRIM(anofa_veh)) +
	LTRIM(RTRIM(color_veh)) + REPLICATE(' ', 25 - LEN(color_veh)) +
	LTRIM(RTRIM(npise_veh)) + REPLICATE(' ', 12 - LEN(npise_veh)) +
	LTRIM(RTRIM(nmarh_veh)) + REPLICATE(' ', 25 - LEN(nmarh_veh)) +
	LTRIM(RTRIM(chass_veh)) + REPLICATE(' ', 25 - LEN(chass_veh)) +
	derec_veh +
	REPLICATE('0', 2 - LEN(LTRIM(RTRIM(cober_veh)))) + LTRIM(RTRIM(cober_veh)) +
	REPLICATE('0', 2 - LEN(LTRIM(RTRIM(blanc_veh)))) + LTRIM(RTRIM(blanc_veh)),
	2
FROM #vehiculos

insert into #trailer
SELECT replicate('0' , 9 - LEN(CONVERT(VARCHAR(9),@total_reg)))  + CONVERT(VARCHAR(9),@total_reg) +
	   replicate('0' , 16 - LEN(CONVERT(VARCHAR(16),@total_tasacion)))  + CONVERT(VARCHAR(16),@total_tasacion),
	   3 

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

GRANT EXEC ON pa_lo_interfaz_m31_vehili_099001000 TO Usuarios











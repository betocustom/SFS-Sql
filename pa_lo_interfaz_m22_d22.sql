USE [leaseoper]
GO
/****** Object:  StoredProcedure [dbo].[pa_lo_interfaz_m22_d22]    Script Date: 06/03/2014 16:20:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/****** Objeto:  procedimiento almacenado dbo.pa_lo_interfaz_m22_d22    fecha de la secuencia de comandos: 09-07-2007 9:25:28 ******/
ALTER PROCEDURE [dbo].[pa_lo_interfaz_m22_d22]
@fecha_proceso    SMALLDATETIME,
@salida            INT OUTPUT
AS
/*
Nombre            :  pa_lo_interfaz_m22_d22

Descripción       : 

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

EXEC leaseoper..pa_lo_interfaz_m22_d22 '31/05/2014',0

*/
set nocount on
--

DECLARE
	@operacion				INT,
	@valor_bien				FLOAT,
	@cod_rubro				SMALLINT,
	@cod_rubro_especifico	SMALLINT,
	@pais_origen			SMALLINT,
	@fecha_tasacion			SMALLDATETIME,
	@monto_tasacion			FLOAT,
	@cod_rubro_super		SMALLINT,
	@oficina				INT,
	@id_cliente				INT,
	@filler_1				CHAR(10),
	@filler_2				CHAR(01)				


IF @fecha_proceso IS NULL OR @fecha_proceso = '01/01/1900'
BEGIN
   SELECT @salida = 0
   --RAISERROR 20000 'Debe Ingresar Periodo a Procesar'
   RETURN 1
END
--

CREATE TABLE #det_d22 (
	filler_1	CHAR(10) NULL,
	ofi_lea		CHAR(02) NULL,	
	cli_lea		CHAR(05) NULL,--	Cliente Leasing
	num_cont	CHAR(03) NULL,--	Número de Contrato Leasing
	valor_comp	CHAR(12) NULL,--	Valor compra del Bien actualizado
	rubro_super CHAR(04) NULL,--    rubro nuestro super t_rubros_especificos
	porig	    CHAR(03) NULL,--	pais origen	
	ftasa	    CHAr(08) NULL,--	fecha tasacion	
	valor_tasa	CHAR(12) NULL,--	Valor Tasacion
	filler_2	CHAR(01) NULL)

SET @filler_1 = REPLICATE('0',10)
SET @filler_2 = REPLICATE(' ',1)

-- Curso que recorre la tabla t_d22
DECLARE d22 CURSOR LOCAL FOR
	SELECT a.operacion,
		a.valor_bien,
		a.cod_rubro,
		a.cod_rubro_especifico,
		a.pais_origen,
		a.fecha_tasacion,
		a.monto_tasacion,
		b.cod_rubro_super
	FROM t_d22 a, leasecom..p_rubros_especificos b
	WHERE a.cod_rubro = b.cod_rubro
	AND a.cod_rubro_especifico = b.cod_rubro_especifico
	AND a.fecha_proceso = @fecha_proceso
 
OPEN d22
FETCH  d22 INTO @operacion,
	@valor_bien,
	@cod_rubro,
	@cod_rubro_especifico,
	@pais_origen,
	@fecha_tasacion,
	@monto_tasacion,
	@cod_rubro_super
WHILE (@@FETCH_STATUS = 0)
BEGIN
   -- Inicializa Variables.
    SELECT	@oficina     = 0,
			@id_cliente  = 0
	
	--oficina leasing
	SELECT @oficina = ISNULL(cod_oficina_real,0)
	FROM  t_contratos
	WHERE operacion = @operacion
	
	--cliente leasing
	SELECT @id_cliente = ISNULL(id_cliente,0)
	FROM dbo.t_datos_cliente_banco
	WHERE lberut = (select rut_cliente
					FROM dbo.t_contratos
					WHERE operacion = @operacion)

   -- Insertar registro.  
	INSERT INTO #det_d22
	VALUES(
   	ISNULL(@filler_1,' '),
	ISNULL(@oficina,' '),
	ISNULL(@id_cliente	,' '),
	ISNULL(@operacion,' '),
	ISNULL(convert(CHAR(12),CAST(@valor_bien AS DECIMAL(12))),0),
	ISNULL(@cod_rubro_super,' '),
	ISNULL(@pais_origen,' '),
	ISNULL(CONVERT(CHAR(8),@fecha_tasacion,112),'99999999'),
	ISNULL(convert(CHAR(8),CAST(@monto_tasacion AS DECIMAL(12))),0),
	ISNULL(@filler_2,' '))

--
FETCH  d22 INTO @operacion,
	@valor_bien,
	@cod_rubro,
	@cod_rubro_especifico,
	@pais_origen,
	@fecha_tasacion,
	@monto_tasacion,
	@cod_rubro_super
END
CLOSE d22
DEALLOCATE d22

SELECT 
	filler_1 +
	REPLICATE('0', 2 - len(rtrim(ofi_lea))) + RTRIM(ofi_lea) +
	replicate('0', 5 - LEN(RTRIM(cli_lea))) + RTRIM(cli_lea) +
	replicate('0', 3 - LEN(RTRIM(num_cont))) + RTRIM(num_cont) +
	replicate('0', 12 - LEN(RTRIM(valor_comp))) + RTRIM(valor_comp) +
	REPLICATE('0', 4 - len(rtrim(rubro_super))) + RTRIM(rubro_super) +
	REPLICATE('0', 3 - len(rtrim(porig))) + RTRIM(porig) +
	ftasa +
	replicate('0', 12 - LEN(RTRIM(valor_tasa))) + RTRIM(valor_tasa) +
	filler_2 as reg
INTO #final
FROM #det_d22

insert into #final
SELECT  '001' +
		'D22' +
		REPLICATE('0', 4 - len(rtrim(YEAR(@fecha_proceso)))) + RTRIM(YEAR(@fecha_proceso)) +
		REPLICATE('0', 2 - len(rtrim(MONTH(@fecha_proceso)))) + RTRIM(MONTH(@fecha_proceso)) +
		REPLICATE(' ',48)

SELECT reg
FROM #final

RETURN 0

GRANT EXEC ON pa_lo_interfaz_m22_d22 TO Usuarios











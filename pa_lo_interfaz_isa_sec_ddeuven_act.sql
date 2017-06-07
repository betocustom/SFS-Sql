USE [leaseoper]
GO
/****** Object:  StoredProcedure [dbo].[pa_lo_interfaz_isa_sec_ddeuven_act]    Script Date: 06/03/2014 16:20:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/****** Objeto:  procedimiento almacenado dbo.pa_lo_interfaz_isa_sec_ddeuven_act    fecha de la secuencia de comandos: 09-07-2007 9:25:28 ******/
ALTER PROCEDURE [dbo].[pa_lo_interfaz_isa_sec_ddeuven_act]
@fecha_proceso    SMALLDATETIME,
@salida            INT OUTPUT
AS
/*
Nombre            :  pa_lo_interfaz_isa_sec_ddeuven_act

Descripción       : Interfaz cuotas clientes leasing

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

EXEC leaseoper..pa_lo_interfaz_isa_sec_ddeuven_act '19/03/2014',0
EXEC leaseoper..pa_lo_interfaz_isa_sec_ddeuven_act '24/03/2014',0

05/03/2007 15:33
*/
set nocount on
--

DECLARE
  @operacion            INT,
  @rut_cliente          INT,
  @cod_moneda           TINYINT,
  @cod_oficina			SMALLINT,
  @num_contrato			INT, 
  @fecha_venc			SMALLDATETIME, 
  @capital				FLOAT, 
  @interes				FLOAT,
  @capital_s			CHAR(15), 
  @interes_s			CHAR(15),
  @ident_oper			CHAR(22),
  @tipo_proceso			CHAR(1),
  @total_reg			INT,
  @dv					CHAR(1),
  @id_cliente			INT,
  @oficina				CHAR(2),
  @cliente				CHAR(5),
  @contrato				CHAR(3)

--
--
IF @fecha_proceso IS NULL OR @fecha_proceso = '01/01/1900'
BEGIN
   SELECT @salida = 0
   --RAISERROR 20000 'Debe Ingresar Periodo a Procesar'
   RETURN 1
END
--
--
CREATE TABLE #cuotas(
tipo_proce	CHAR(01)	NULL,
rut_cli		CHAR(09)	NULL,
dv_cli		CHAR(01)	NULL,
ident_oper	CHAR(22)	NULL,
fecha_venc	CHAR(08)	NULL,
capital		CHAR(15)	NULL,
interes		CHAR(15)	NULL)

CREATE TABLE #trailer(
salida CHAR(71) NULL)

SET @tipo_proceso = 'D'

-- Cursor que recorre todos los contratos Vigentes y sus cuotas sin mora

DECLARE c_cto CURSOR LOCAL FOR
SELECT a.operacion,
	a.rut_cliente,
	a.cod_moneda_contrato,
	a.cod_oficina_real, 
	a.num_contrato,
	b.fecha_vencimiento,
	b.capital,
	b.interes
FROM   leaseoper..t_contratos a, leaseoper..t_cuotas b
WHERE  a.operacion = b.operacion
  AND  a.estado_operacion = 2 --contrato vigente
  AND  b.cod_tipo_cuota in (0,2)--es cuota u opción de compra
  AND  b.estado in (1,3) -- estado cuota vigente y p.parcial
  AND  b.fecha_vencimiento >= @fecha_proceso
OPEN c_cto
FETCH  c_cto INTO @operacion, @rut_cliente, @cod_moneda, @cod_oficina, @num_contrato, @fecha_venc, @capital, @interes
WHILE (@@FETCH_STATUS = 0)
BEGIN
		
	--dv

	SELECT @dv = ISNULL(dv,' ')
	FROM leasecom..v_clientes
	WHERE rut = @rut_cliente
	
	--identificacion de la operación 
	
	SELECT @id_cliente = ISNULL(id_cliente,0)
	FROM dbo.t_datos_cliente_banco
	WHERE lberut = @rut_cliente
	
	SET @oficina = REPLICATE('0', 2 - LEN(RTRIM(CONVERT(char(2),@cod_oficina)))) + RTRIM(CONVERT(char(2),@cod_oficina)) 
	SET @cliente = REPLICATE('0', 5 - LEN(RTRIM(convert(char(5),@id_cliente )))) + RTRIM(convert(char(5),@id_cliente )) 
	SET @contrato = REPLICATE('0', 3 - LEN(RTRIM(convert(char(3),@num_contrato)))) + RTRIM(convert(char(3),@num_contrato)) 

	SET @ident_oper = @oficina + @cliente + @contrato
	
	--IF @cod_moneda <> 1 --solo para los distintos a pesos
	--BEGIN
	--	SET @capital_s = STR(@capital,15,4)
	--	SET @interes_s = STR(@interes,15,4)
	--END
	--ELSE
	--BEGIN
	--	SET @capital_s = STR(@capital,15)
	--	SET @interes_s = STR(@interes,15)
	--END
	
	SET @capital_s = STR(@capital,15,4)
	SET @interes_s = STR(@interes,15,4)


   -- Insertar registro.  
    INSERT INTO #cuotas
    VALUES( ISNULL(@tipo_proceso,' '),
			ISNULL(@rut_cliente,' '),
			ISNULL(@dv,' '),
			ISNULL(@ident_oper ,' '),
			ISNULL(@fecha_venc,'19000101'),
			ISNULL(@capital_s,' '),
			ISNULL(@interes_s,' '))


FETCH c_cto INTO @operacion, @rut_cliente, @cod_moneda, @cod_oficina, @num_contrato, @fecha_venc, @capital, @interes

END
CLOSE c_cto
DEALLOCATE c_cto

SET @total_reg = (SELECT COUNT(*) FROM #cuotas)

SELECT 
	tipo_proce +
	REPLICATE('0', 9 - LEN(RTRIM(rut_cli))) + RTRIM(rut_cli) +
	rtrim(dv_cli) +
	RTRIM(ident_oper) + REPLICATE('0', 22 - LEN(RTRIM(ident_oper))) +
	CONVERT(CHAR(08),@fecha_venc,112) +  
	REPLICATE('0', 15 - LEN(LTRIM(RTRIM(capital)))) + LTRIM(RTRIM(capital)) +
	REPLICATE('0', 15 - LEN(LTRIM(RTRIM(interes)))) + LTRIM(RTRIM(interes)) AS reg
INTO #final
FROM #cuotas

insert into #final
SELECT 'C' + 
		'LSA' + 
		CONVERT(CHAR(08),@fecha_proceso,112) + 
		REPLICATE(' ', 10) +
		REPLICATE(' ', 10) +
		REPLICATE(' ', 10) +
		REPLICATE(' ', 29)

insert into #trailer
SELECT 'T' + 
		replicate('0' , 7 - LEN(CONVERT(VARCHAR(7),@total_reg)))  + CONVERT(VARCHAR(7),@total_reg) +
		REPLICATE(' ', 10) +
		REPLICATE(' ', 10) +
		REPLICATE(' ', 10) +
		REPLICATE(' ', 10) +
		REPLICATE(' ', 23)

	
SELECT reg
FROM #final
union
SELECT salida
FROM #trailer

RETURN 0

GRANT EXEC ON pa_lo_interfaz_isa_sec_ddeuven_act TO Usuarios











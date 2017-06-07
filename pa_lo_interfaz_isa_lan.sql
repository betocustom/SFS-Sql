USE [leaseoper]
GO
/****** Object:  StoredProcedure [dbo].[pa_lo_interfaz_isa_lan]    Script Date: 06/03/2014 16:20:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/****** Objeto:  procedimiento almacenado dbo.pa_lo_interfaz_isa_lan    fecha de la secuencia de comandos: 09-07-2007 9:25:28 ******/
ALTER PROCEDURE [dbo].[pa_lo_interfaz_isa_lan]
@fecha_proceso    SMALLDATETIME,
@salida            INT OUTPUT
AS
/*
Nombre            :  pa_lo_interfaz_isa_lan

Descripción       : Interfaz contratos en cuentas de orden

Parametros entrada: @fecha_proceso:

Parametros salida :  Ninguno.

Tablas entrada    :  t_contratos 

Tablas salida     :  Archivo plano.

Fecha             :  Julio 2014.

Modificaciones    :

Procedimientos que Llama :

Observaciones      :  

Autor              : Verónica Inzunza.

Ejecucion          :  

EXEC leaseoper..pa_lo_interfaz_isa_lan '19/03/2014',0
EXEC leaseoper..pa_lo_interfaz_isa_lan '24/03/2014',0

05/03/2007 15:33
*/
set nocount on
--

DECLARE
  @operacion            INT,
  @rut_cliente          INT,
  @cod_ejecutivo        INT,
  @monto				FLOAT, 
  @dv					CHAR(1),
  @indmo_dat			CHAR(1),
  @monto_s				CHAR(12),
  @nom_ejecutivo		CHAR(30),
  @razon_social			CHAR(40)

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
CREATE TABLE #orden(
rutri_dat		CHAR(08)	NULL,
dveri_dat		CHAR(01)	NULL,
rsoci_dat		CHAR(40)	NULL,
indmo_dat		CHAR(01)	NULL,
mccor_dat		CHAR(12)	NULL,
ejres_dat		CHAR(06)	NULL,
nombr_dat		CHAR(30)	NULL)


-- Cursor que recorre todos los contratos en cuentas de orden

SET @indmo_dat = 'N'

DECLARE c_cto CURSOR LOCAL FOR
SELECT operacion,
	rut_cliente,
	ejecutivo_contrato,
	(provision_material + provision_gasto_legal + provision_seguros + provision_importacion + provision_otros) AS monto
FROM t_contratos
WHERE estado_operacion = 1 --c-18
--AND fecha_ing_carta_recep < = @fecha_proceso
OPEN c_cto
FETCH  c_cto INTO @operacion, @rut_cliente, @cod_ejecutivo, @monto
WHILE (@@FETCH_STATUS = 0)
BEGIN
		
	--dv, razon social

	SELECT  @dv = ISNULL(dv,' '),
			@razon_social = ISNULL(nombre,' ')
	FROM leasecom..v_clientes
	WHERE rut = @rut_cliente
	
	--monto	
	SET @monto_s = STR(@monto,12)
	
	--nombre ejecutivo leasecom..t_personal???
	SELECT @nom_ejecutivo = ISNULL(nombre,' ')
	FROM leasecom..t_oficiales_banco
	WHERE cod_ejecutivo = @cod_ejecutivo

   -- Insertar registro.  
    INSERT INTO #orden
    VALUES( ISNULL(@rut_cliente,' '),
			ISNULL(@dv,' '),
			ISNULL(@razon_social ,' '),
			ISNULL(@indmo_dat,' '),
			ISNULL(@monto_s,' '),
			ISNULL(@cod_ejecutivo,' '),
			ISNULL(@nom_ejecutivo,' '))

FETCH c_cto INTO @operacion, @rut_cliente, @cod_ejecutivo, @monto

END
CLOSE c_cto
DEALLOCATE c_cto

SELECT 
	REPLICATE('0', 8 - LEN(RTRIM(rutri_dat))) + RTRIM(rutri_dat) +
	rtrim(dveri_dat) +
	rtrim(rsoci_dat) + REPLICATE(' ', 40 - LEN(RTRIM(rsoci_dat))) +
	indmo_dat +
	REPLICATE('0', 12 - LEN(mccor_dat)) + mccor_dat +
	REPLICATE('0', 6 - LEN(RTRIM(ejres_dat))) + RTRIM(ejres_dat) +
	rtrim(nombr_dat) + REPLICATE(' ', 30 - LEN(RTRIM(nombr_dat))) 
FROM #orden

RETURN 0

GRANT EXEC ON pa_lo_interfaz_isa_lan TO Usuarios











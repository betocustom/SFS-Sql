USE leaseoper
GO

IF OBJECT_ID ('dbo.pa_lo_M13CSIM268') IS NOT NULL
	DROP PROCEDURE dbo.pa_lo_M13CSIM268
GO

CREATE PROCEDURE [dbo].[pa_lo_M13CSIM268]
    @fecha_proceso  SMALLDATETIME ,
    @salida	    TINYINT OUT
AS
/*
Nombre             : pa_lo_M13CSIM268

Descripción        : Este proceso genera archivo plano con las facturas a imprimir por el BANCO.

Parametros entrada : @num_proceso : Número de Proceso de Envío.

Parametros salida  : N/E

Tablas entrada     : 

Tablas salida      : 

Fecha              : 14-Diciembre2012.

Modificaciones     : M1.agrego Replace para cambiar TAB por punto.

Procedimientos que Llama :

Observaciones      : 

Autor              : Carlos Beltran Galaz

   EXEC pa_lo_M13CSIM268 '16/12/2014',0

*/
SET NOCOUNT ON

SELECT 'INFORMACION'+
        convert(CHAR(8),@fecha_proceso,112)   


RETURN 0


GRANT EXECUTE ON dbo.pa_lo_M13CSIM268 TO Usuarios
GO


USE leaseoper
GO

IF OBJECT_ID ('dbo.pa_lo_interfaz_M_13CSIM268_UNIX') IS NOT NULL
	DROP PROCEDURE dbo.pa_lo_interfaz_M_13CSIM268_UNIX
GO

CREATE PROCEDURE [dbo].[pa_lo_interfaz_M_13CSIM268_UNIX]
    @fecha_proceso  SMALLDATETIME ,
    @salida	        TINYINT OUT
AS
/*
Nombre             : pa_lo_interfaz_M_13CSIM268_UNIX

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

   EXEC pa_lo_interfaz_M_13CSIM268_UNIX '16/06/2014',0

*/

        


SELECT convert(CHAR(17),'INFORMACION AL :')+
      convert(CHAR(8),@fecha_proceso,112)





RETURN 0


GRANT EXECUTE ON dbo.pa_lo_interfaz_M_13CSIM268_UNIX TO Usuarios
GO


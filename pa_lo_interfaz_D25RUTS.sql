USE leaseoper
GO

IF OBJECT_ID ('dbo.pa_lo_interfaz_D25') IS NOT NULL
	DROP PROCEDURE dbo.pa_lo_interfaz_D25
GO

CREATE PROCEDURE [dbo].[pa_lo_interfaz_D25]
    @fecha_proceso  SMALLDATETIME ,
    @salida	    TINYINT OUT
AS
/*
Nombre             : pa_lo_interfaz_D25

Descripción        : Este proceso genera archivo plano con los rut en estado C-18

Parametros entrada : @num_proceso : Número de Proceso de Envío.

Parametros salida  : N/E

Tablas entrada     : 

Tablas salida      : 

Fecha              : 30-Junio-2014.

Modificaciones     : 

Procedimientos que Llama :

Observaciones      : 

Autor              : Miguel Cornejo J 

   EXEC pa_lo_interfaz_D25 '16/12/2014',0

*/
SET NOCOUNT ON

SELECT SUBSTRING(REPLICATE('0',9 -DATALENGTH(RTRIM(CONVERT(CHAR(9),b.rut))))+ RTRIM(CONVERT(CHAR(9),b.rut)),1,9)+ --a.rut,,       
       b.dv
 FROM t_contratos a,
      leasecom..v_clientes  b
WHERE a.estado_operacion = 1 
AND a.fecha_ingreso_cont <= @fecha_proceso
AND a.rut_cliente = b.rut 


RETURN 0


GRANT EXECUTE ON dbo.pa_lo_interfaz_D25 TO Usuarios
GO

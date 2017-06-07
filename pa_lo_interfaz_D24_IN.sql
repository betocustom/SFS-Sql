USE leaseoper
GO

IF OBJECT_ID ('dbo.pa_lo_interfaz_D24_IN') IS NOT NULL
	DROP PROCEDURE dbo.pa_lo_interfaz_D24_IN
GO

CREATE PROCEDURE [dbo].[pa_lo_interfaz_D24_IN]
    @fecha_proceso  SMALLDATETIME ,
    @salida	    TINYINT OUT
AS
/*
Nombre             : pa_lo_interfaz_D24_IN

Descripción        : 
Parametros entrada : @num_proceso : Número de Proceso de Envío.

Parametros salida  : N/E

Tablas entrada     : 

Tablas salida      : 

Fecha              : 30-JUL-2014.

Modificaciones     :

Procedimientos que Llama :
	
Observaciones      : 

Autor              : Carlos Beltran Galaz

   EXEC pa_lo_interfaz_D24_IN '16/12/2014',0

*/
DECLARE @sumatoria CHAR(16),
		@num_reg  INT
        
        
SET NOCOUNT ON


      SELECT  @sumatoria= convert(CHAR(16),str(sum(convert(float,b.rut_cliente)),16,0))
 	   FROM leasecom..v_clientes a,
	        t_contratos b,
	        Leaseoper..t_bienes_detalle c
	   WHERE a.rut = b.rut_cliente
	    AND b.operacion = c.operacion
	    AND b.fecha_ingreso_cont <= @fecha_proceso



SELECT @num_reg  = count(c.operacion)		      		      
   FROM t_contratos_IFRS a,
        leasecom..v_clientes b,
        t_contratos c
   WHERE a.Rut_Cliente = b.rut
    AND a.operacion = c.operacion
    AND c.fecha_ingreso_cont <= @fecha_proceso
    


SELECT  'HEADER'+
        convert(CHAR(8), @fecha_proceso, 112)+
        'LSA'+
        SUBSTRING(REPLICATE('0',9 -DATALENGTH(LTRIM(CONVERT(CHAR(9),c.rut_Cliente))))+ LTRIM(CONVERT(CHAR(9),c.rut_Cliente)),1,9)+
        b.dv+
        isnull(convert(CHAR(8),a.fecha_deterioro, 112),REPLICATE('',8) )+
        'TRAILER'+
        convert(CHAR(9),@num_reg)+--leidos,
        SUBSTRING(REPLICATE('0',16 -DATALENGTH(LTRIM(CONVERT(CHAR(16),@sumatoria))))+ LTRIM(CONVERT(CHAR(16),@sumatoria)),1,16)+ --sumatoria,
     	CONVERT(CHAR(33), '')
   FROM t_contratos_IFRS a,
        leasecom..v_clientes b,
        t_contratos c
   WHERE a.Rut_Cliente = b.rut
    AND a.operacion = c.operacion
    AND c.fecha_ingreso_cont <= @fecha_proceso



RETURN 0



GRANT EXECUTE ON dbo.pa_lo_interfaz_D24_IN TO Usuarios
GO


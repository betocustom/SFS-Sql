USE leaseoper
GO

IF OBJECT_ID ('dbo.pa_lo_interfaz_D07_CLT015_LSA_otros_nombres') IS NOT NULL
	DROP PROCEDURE dbo.pa_lo_interfaz_D07_CLT015_LSA_otros_nombres
GO

CREATE PROCEDURE [dbo].[pa_lo_interfaz_D07_CLT015_LSA_otros_nombres]
    @fecha_proceso  SMALLDATETIME ,
    @salida	        TINYINT OUT
AS
/*
Nombre             : pa_lo_interfaz_D07_CLT015_LSA_otros_nombres

Descripción        : 
Parametros entrada : @num_proceso : Número de Proceso de Envío.

Parametros salida  : N/E

Tablas entrada     : 

Tablas salida      : 

Fecha              : Agosto 2014.

Modificaciones     :

Procedimientos que Llama :

Observaciones      : 

Autor              : Verónica Inzunza

   EXEC pa_lo_interfaz_D07_CLT015_LSA_otros_nombres '16/12/2014',0

*/
DECLARE @sumatoria CHAR(16),
        @num_reg  INT,
        @saldo_insoluto FLOAT 
        
SET NOCOUNT ON


SELECT  SUBSTRING(REPLICATE('0',9 -DATALENGTH(RTRIM(CONVERT(CHAR(9),a.rut))))+ RTRIM(CONVERT(CHAR(9),a.rut)),1,9)+ --a.rut
       'DRICOM'+       
       SUBSTRING(REPLICATE('0',9 -DATALENGTH(RTRIM(CONVERT(CHAR(9),a.rut))))+ RTRIM(CONVERT(CHAR(9),a.rut)),1,9)+ --a.rut
       REPLICATE('0',2)+ --filler_01
       CASE WHEN a.rut > 50000000 THEN '02'       
       ELSE '04'
       END+  --fecha --tipo
       convert(CHAR(80),a.nombre)+       
       REPLICATE('0',8)+ --filler_01
       '1'+
       REPLICATE('0',8)+ --filler_01
       REPLICATE(' ',225)--filler_01
   FROM leasecom..v_clientes a,
        t_contratos b,
        Leaseoper..t_bienes_detalle c,
        t_contratos_anexo d
   WHERE a.rut = b.rut_cliente
    AND b.operacion = c.operacion
    AND b.operacion = d.operacion
    AND b.fecha_ingreso_cont <= @fecha_proceso


RETURN 0


GRANT EXECUTE ON dbo.pa_lo_interfaz_D07_CLT015_LSA_otros_nombres TO Usuarios
GO


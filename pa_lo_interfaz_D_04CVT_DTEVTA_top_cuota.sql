USE leaseoper
GO

IF OBJECT_ID ('dbo.pa_lo_interfaz_D_04CVT_DTEVTA_topcuota') IS NOT NULL
	DROP PROCEDURE dbo.pa_lo_interfaz_D_04CVT_DTEVTA_topcuota
GO

CREATE PROCEDURE [dbo].[pa_lo_interfaz_D_04CVT_DTEVTA_topcuota]
    @fecha_proceso  SMALLDATETIME ,
    @salida	        TINYINT OUT
AS
/*
Nombre             : pa_lo_interfaz_D_04CVT_DTEVTA_topcuota

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

   EXEC pa_lo_interfaz_D_04CVT_DTEVTA_topcuota '16/06/2014',0

*/
DECLARE @sumatoria CHAR(16),
        @num_reg  INT,
        @saldo_insoluto FLOAT 
        
        


SELECT convert(CHAR(8),@fecha_proceso,112)+ --fecha_proc
       convert(CHAR(8),fac.fecha_emision,112)+ 
       CASE fac.tipo 
        WHEN 1 THEN '033'
        WHEN 2 THEN '034'
       END +--tdocu
       SUBSTRING(REPLICATE('0',10 -DATALENGTH(LTRIM(str(fac.num_factura,10,0))))+ LTRIM(str(fac.num_factura,10,0)),1,10)+ 
       SUBSTRING(REPLICATE('0',10 -DATALENGTH(LTRIM(str(fac.num_factura,10,0))))+ LTRIM(str(fac.num_factura,10,0)),1,10)+ 
       SUBSTRING(REPLICATE('0',10 -DATALENGTH(LTRIM(str(fac.neto+fac.iva,10,0))))+ LTRIM(str(fac.neto+fac.iva,10,0)),1,10)   
   FROM leasecom..v_clientes a, 
        t_facturas fac,
        t_contratos b,
        leasecom..t_clientes d         
   WHERE a.rut = b.rut_cliente
    AND b.rut_cliente = d.rut_cliente
    AND b.fecha_ingreso_cont <= @fecha_proceso





RETURN 0


GRANT EXECUTE ON dbo.pa_lo_interfaz_D_04CVT_DTEVTA_topcuota TO Usuarios
GO


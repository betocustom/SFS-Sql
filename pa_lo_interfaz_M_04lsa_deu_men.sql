USE leaseoper
GO

IF OBJECT_ID ('dbo.pa_lo_interfaz_M_04lsa_deu_men') IS NOT NULL
	DROP PROCEDURE dbo.pa_lo_interfaz_M_04lsa_deu_men
GO

CREATE PROCEDURE [dbo].[pa_lo_interfaz_M_04lsa_deu_men]
    @fecha_proceso  SMALLDATETIME ,
    @salida	        TINYINT OUT
AS
/*
Nombre             : pa_lo_interfaz_M_04lsa_deu_men

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

   EXEC pa_lo_interfaz_M_04lsa_deu_men '16/12/2014',0

*/
DECLARE @sumatoria CHAR(16),
        @num_reg  INT,
        @saldo_insoluto FLOAT 
        
SET NOCOUNT ON




SELECT @num_reg  = count(b.operacion)		      		      
		    FROM leasecom..v_clientes a,
		         t_contratos b,
		         leasecom..t_clientes d
		   WHERE a.rut = b.rut_cliente    
		    AND b.rut_cliente = d.rut_cliente
		    AND b.fecha_ingreso_cont <= @fecha_proceso



SELECT '0'+
       'LSA'+
       'DEUDORES'+
       convert(CHAR(8),@fecha_proceso,112)+--fecha_proc  
       REPLICATE('0',85)+     
       --[Detalle]--        
       '1'+       
       SUBSTRING(REPLICATE('0',9 -DATALENGTH(RTRIM(CONVERT(CHAR(9),a.rut))))+ RTRIM(CONVERT(CHAR(9),a.rut)),1,9)+--a.rut,
       a.dv+--dv
       '130'+
       dbo.Fn_TO(b.operacion,1)+ --to
	   '00'+
	   SUBSTRING(REPLICATE('0',9 -DATALENGTH(RTRIM(CONVERT(CHAR(9),b.operacion))))+ RTRIM(CONVERT(CHAR(9),b.operacion)),1,9)+--a.num_doctok,
	   SUBSTRING(REPLICATE('0',9 -DATALENGTH(RTRIM(CONVERT(CHAR(9),a.rut))))+ RTRIM(CONVERT(CHAR(9),a.rut)),1,9)+--rut2,
       a.dv+--dv2
	   '0'+
	   '001'+
	   '000'+
	   'LSA'+
	   convert(CHAR(9),b.rut_cliente)+'LSA'+convert(CHAR(3),b.cod_oficina_real)+convert(CHAR(6),b.operacion)+ --deu_llave
	   REPLICATE('0',23)+ 
       REPLICATE('0',15)+ 
       ---Trailer---
       '2'+
       convert(CHAR(6),@num_reg)+--NUMLINEAS
       convert(CHAR(6),@num_reg)+--numero
       REPLICATE('0',6)+ 
       REPLICATE('0',91)	      
   FROM leasecom..v_clientes a,
        t_contratos b,
        leasecom..t_clientes d
   WHERE a.rut = b.rut_cliente    
    AND b.rut_cliente = d.rut_cliente
    AND b.fecha_ingreso_cont <= @fecha_proceso





RETURN 0

GRANT EXECUTE ON dbo.pa_lo_interfaz_M_04lsa_deu_men TO usuarios
GO


GRANT EXECUTE ON dbo.pa_lo_interfaz_M_04lsa_deu_men TO Usuarios
GO


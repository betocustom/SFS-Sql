USE leaseoper
GO

IF OBJECT_ID ('dbo.pa_lo_interfaz_D_21_LSARELPDTO') IS NOT NULL
	DROP PROCEDURE dbo.pa_lo_interfaz_D_21_LSARELPDTO
GO

CREATE PROCEDURE [dbo].[pa_lo_interfaz_D_21_LSARELPDTO]
    @fecha_proceso  SMALLDATETIME ,
    @salida	        TINYINT OUT
AS
/*
Nombre             : pa_lo_interfaz_D_21_LSARELPDTO

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

   EXEC pa_lo_interfaz_D_21_LSARELPDTO '16/06/2014',0

*/
DECLARE @sumatoria CHAR(16),
        @num_reg  INT,
        @saldo_insoluto FLOAT 
        
        

DECLARE @dias_max INT,
        @dias int,
        @operacion INT,
        @fecha_vencimiento SMALLDATETIME,
        @fecha_pago SMALLDATETIME    
                
        
SET NOCOUNT ON


--sumatoria
      SELECT  @sumatoria= convert(CHAR(16),str(sum(convert(float,b.rut_cliente)),16,0))
 	   FROM leasecom..v_clientes a,
	        t_contratos b
	   WHERE a.rut = b.rut_cliente
	    AND b.fecha_ingreso_cont <= @fecha_proceso
	    
	    
SELECT @num_reg = count(*)
 FROM leasecom..v_clientes a,
        t_contratos b,        
        leasecom..t_clientes d      
   WHERE a.rut = b.rut_cliente
    AND b.rut_cliente = d.rut_cliente
    AND b.fecha_ingreso_cont <= @fecha_proceso


SELECT 'C'+
	   convert(CHAR(8),@fecha_proceso,112)+ --fecha_proc
       convert(CHAR(8),@fecha_proceso,112)+ 
       REPLICATE('0',68)+ --contenido
       --[Detalle]--    
       'D'+    
       'LSA'+
       convert(CHAR(6),b.operacion)+convert(CHAR(3),b.cod_oficina_real)+ltrim(convert(CHAR(9),a.rut))+--numero_operacion
       'CTD'+
        isnull(cte.cta_cte, REPLICATE('0',25))+
       '01'+
       'CUENTA DE CARGO'+
       'T'+       
       convert(CHAR(9),@num_reg) + --numreg
       @sumatoria+ --rutri 
      REPLICATE('',60)--filler_03                  
   FROM leasecom..v_clientes a 
        LEFT OUTER JOIN leasecom..t_clientes_cta_cte cte ON a.rut = cte.rut,       
        t_contratos b,
        leasecom..t_clientes d         
   WHERE a.rut = b.rut_cliente
    AND b.rut_cliente = d.rut_cliente
    AND b.fecha_ingreso_cont <= @fecha_proceso





RETURN 0


GRANT EXECUTE ON dbo.pa_lo_interfaz_D_21_LSARELPDTO TO Usuarios
GO


USE leaseoper
GO

IF OBJECT_ID ('dbo.pa_lo_interfaz_D_09lsa_sec_ddeuven_act') IS NOT NULL
	DROP PROCEDURE dbo.pa_lo_interfaz_D_09lsa_sec_ddeuven_act
GO

CREATE PROCEDURE [dbo].[pa_lo_interfaz_D_09lsa_sec_ddeuven_act]
    @fecha_proceso  SMALLDATETIME ,
    @salida	        TINYINT OUT
AS
/*
Nombre             : pa_lo_interfaz_D_09lsa_sec_ddeuven_act

Descripción        : 
Parametros entrada : @num_proceso : Número de Proceso de Envío.

Parametros salida  : N/E

Fecha              : 30-JUL-2014.

Modificaciones     :

Procedimientos que Llama :

Observaciones      : 

Autor              : Miguel Cornejo J

   EXEC pa_lo_interfaz_D_09lsa_sec_ddeuven_act '16/12/2014',0

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




SELECT 'C'+
       'LSA'+    
       convert(CHAR(8),@fecha_proceso,112)+
       REPLICATE(' ',59)+
     --[Detalle]-- 
       'D'+
       SUBSTRING(REPLICATE('0',9 -DATALENGTH(RTRIM(CONVERT(CHAR(9),a.rut))))+ RTRIM(CONVERT(CHAR(9),a.rut)),1,9)+
       a.dv+
       convert(CHAR(6),b.operacion)+rtrim(ltrim(convert(CHAR(3), b.cod_oficina_real)))+(SELECT rtrim(ltrim(convert(CHAR(6), count(1))))       
												       FROM t_cuotas c           
															WHERE c.estado = 1
															  AND c.operacion  NOT IN ( SELECT d.operacion 
															                             FROM  t_castigos d 
															                           WHERE c.operacion = d.operacion )
																  AND c.fecha_vencimiento <=  '20140715'   
																  AND c.operacion = b.operacion
																GROUP BY c.operacion )+
       convert(CHAR(8),cuo.fecha_vencimiento,112)+ 
       str(cuo.valor_cuota_total,12,3)+
       str(cuo.interes,12,3)+       
--Trailer---
       'T'+--filler
       convert(char(7),@num_reg)+--numreg       
       REPLICATE('',63)--filler_03
   FROM leasecom..v_clientes a,
        t_contratos b,
        t_cuotas cuo,        
        leasecom..t_clientes d
   WHERE a.rut = b.rut_cliente
  --  AND b.operacion = c.operacion
    AND b.rut_cliente = d.rut_cliente
    AND cuo.operacion = b.operacion
    AND b.fecha_ingreso_cont <= @fecha_proceso



RETURN 0


GRANT EXECUTE ON dbo.pa_lo_interfaz_D_09lsa_sec_ddeuven_act TO Usuarios
GO


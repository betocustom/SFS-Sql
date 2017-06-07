USE leaseoper
GO

IF OBJECT_ID ('dbo.pa_lo_interfaz_D11lsa_car') IS NOT NULL
	DROP PROCEDURE dbo.pa_lo_interfaz_D11lsa_car
GO

CREATE PROCEDURE [dbo].[pa_lo_interfaz_D11lsa_car]
    @fecha_proceso  SMALLDATETIME ,
    @salida	    TINYINT OUT
AS
/*
Nombre             : pa_lo_interfaz_D11lsa_car

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

   EXEC pa_lo_interfaz_D11lsa_car '16/12/2014',0

*/
DECLARE @sumatoria CHAR(16),
        @num_reg int
        
        
SET NOCOUNT ON


SELECT @num_reg = count(*)
   FROM leasecom..v_clientes a,
        t_contratos b
   WHERE a.rut = b.rut_cliente
    AND b.fecha_ingreso_cont <= @fecha_proceso



SELECT '0'+
       'LSA'+   
       'DEUDORES'+
       convert(CHAR(8),@fecha_proceso,112)+--fecha_proc
       REPLICATE('0',85)+
       '2'+
       SUBSTRING(REPLICATE('0',9 -DATALENGTH(LTRIM(CONVERT(CHAR(9),a.rut))))+ LTRIM(CONVERT(CHAR(9),a.rut)),1,9)+ --a.rut,       
       a.dv+
       '130'+ --oficina
       dbo.Fn_TO(b.operacion,1)+ 			          --to,
       REPLICATE('0',2)+ --ppp_emb
       convert(CHAR(9),b.operacion) + --num_docto
       SUBSTRING(REPLICATE('0',9 -DATALENGTH(LTRIM(CONVERT(CHAR(9),a.rut))))+ LTRIM(CONVERT(CHAR(9),a.rut)),1,9)+ --rut2
       a.dv+
       '0'+ --td,
       '001'+--tfijo,
       '000'+--ndeud
       'LSA'+--sistema
       convert(CHAR(8),a.rut)+'LSA130'+convert(CHAR,b.operacion)+ --deu_llave  
       REPLICATE('',77)+ --filler_01
       REPLICATE('0',6)+
       REPLICATE('0',15)+
       REPLICATE('0',15)+ --filler_04
       '2'+--tipo_reg
       SUBSTRING(REPLICATE('0',6 -DATALENGTH(LTRIM(CONVERT(CHAR(6),@num_reg))))+ LTRIM(CONVERT(CHAR(6),@num_reg)),1,6)+ --@num_reg, --num_lineas
       REPLICATE('0',6)+
       REPLICATE('0',6)+
       REPLICATE('0',91)--filler_04       
   FROM leasecom..v_clientes a,
        t_contratos b
   WHERE a.rut = b.rut_cliente
    AND b.fecha_ingreso_cont <= @fecha_proceso



RETURN 0

GO
GRANT EXECUTE ON dbo.pa_lo_interfaz_D11lsa_car TO Usuarios
GO


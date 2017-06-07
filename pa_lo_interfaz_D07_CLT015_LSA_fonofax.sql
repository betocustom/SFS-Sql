USE leaseoper
GO

IF OBJECT_ID ('dbo.pa_lo_interfaz_D07_CLT015_LSA_fonofax') IS NOT NULL
	DROP PROCEDURE dbo.pa_lo_interfaz_D07_CLT015_LSA_fonofax
GO

CREATE PROCEDURE [dbo].[pa_lo_interfaz_D07_CLT015_LSA_fonofax]
    @fecha_proceso  SMALLDATETIME ,
    @salida	        TINYINT OUT
AS
/*
Nombre             : pa_lo_interfaz_D07_CLT015_LSA_fonofax

Descripci�n        : 
Parametros entrada : @num_proceso : N�mero de Proceso de Env�o.

Parametros salida  : N/E  

Tablas entrada     : 

Tablas salida      : 

Fecha              : Agosto 2014.

Modificaciones     :

Procedimientos que Llama :

Observaciones      : 

Autor              : Ver�nica Inzunza

   EXEC pa_lo_interfaz_D07_CLT015_LSA_fonofax '16/12/2014',0

*/
DECLARE @sumatoria CHAR(16),
        @num_reg  INT,
        @saldo_insoluto FLOAT 
        
SET NOCOUNT ON

SELECT SUBSTRING(REPLICATE('0',9 -DATALENGTH(RTRIM(CONVERT(CHAR(9),a.rut))))+ RTRIM(CONVERT(CHAR(9),a.rut)),1,9)+ --a.rut
       'FFACOM'+       
       SUBSTRING(REPLICATE('0',9 -DATALENGTH(RTRIM(CONVERT(CHAR(9),a.rut))))+ RTRIM(CONVERT(CHAR(9),a.rut)),1,9)+ --a.rut
       REPLICATE('0',3)+ --filler_01
       'FO'+  --fecha --tipo
       'P'+ --tmedio  MCJ Telefono por defefcto
       REPLICATE('0',2)+ --filler_01
       '1'+ --tmedio    
       REPLICATE('0',12 - LEN(d.telefono)) + d.telefono  +
       REPLICATE('0',1)+ --filler_01
       REPLICATE('0',8)+ --filler_01
       REPLICATE(' ',297)--filler_01
   FROM leasecom..v_clientes a,
        t_contratos b,
        Leaseoper..t_bienes_detalle c,
        t_clientes_direccion d
   WHERE a.rut = b.rut_cliente
    AND b.operacion = c.operacion
    AND b.rut_cliente = d.rut
    AND b.fecha_ingreso_cont <= @fecha_proceso


RETURN 0


GRANT EXECUTE ON dbo.pa_lo_interfaz_D07_CLT015_LSA_fonofax TO Usuarios
GO


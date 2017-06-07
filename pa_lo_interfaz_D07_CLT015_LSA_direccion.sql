USE leaseoper
GO

IF OBJECT_ID ('dbo.pa_lo_interfaz_D07_CLT015_LSA_direccion') IS NOT NULL
	DROP PROCEDURE dbo.pa_lo_interfaz_D07_CLT015_LSA_direccion
GO

CREATE PROCEDURE [dbo].[pa_lo_interfaz_D07_CLT015_LSA_direccion]
    @fecha_proceso  SMALLDATETIME ,
    @salida	        TINYINT OUT
AS
/*
Nombre             : pa_lo_interfaz_D07_CLT015_LSA_direccion

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

   EXEC pa_lo_interfaz_D07_CLT015_LSA_direccion '16/12/2014',0

*/
DECLARE @sumatoria CHAR(16),
        @num_reg  INT,
        @saldo_insoluto FLOAT 
        
SET NOCOUNT ON

SELECT  SUBSTRING(REPLICATE('0',9 -DATALENGTH(RTRIM(CONVERT(CHAR(9),a.rut))))+ RTRIM(CONVERT(CHAR(9),a.rut)),1,9)+ --a.rut
       'DRICOM'+       
       SUBSTRING(REPLICATE('0',9 -DATALENGTH(RTRIM(CONVERT(CHAR(9),a.rut))))+ RTRIM(CONVERT(CHAR(9),a.rut)),1,9)+ --a.rut
       REPLICATE('0',3)+ --filler_01
       convert(CHAR(45),a.direccion)+--direccion
       REPLICATE('0',1)+--filler_01
       REPLICATE('0',5)+--filler_01
       REPLICATE('0',2)+--filler_01
       REPLICATE('0',7)+--filler_01
       'B'+
       '130'+ 
       REPLICATE('0',8)+--filler_01
       REPLICATE(' ',1)+--filler_01
       REPLICATE(' ',92)+--filler_01
     isnull((SELECT loc.descripcion 
         FROM t_clientes_direccion   cdir,
               leasecom..p_localidad loc
         WHERE cdir.rut = a.rut
           AND cdir.cod_comuna = loc.cod_comuna_cia  ),REPLICATE(' ',30))+--comun_agri	
       REPLICATE('0',5)+--filler_01
       REPLICATE(' ',123)--filler_01                  
   FROM leasecom..v_clientes a,
        t_contratos b,
        Leaseoper..t_bienes_detalle c,
        t_contratos_anexo d
   WHERE a.rut = b.rut_cliente
    AND b.operacion = c.operacion
    AND b.operacion = d.operacion
    AND b.fecha_ingreso_cont <= @fecha_proceso






RETURN 0


GRANT EXECUTE ON dbo.pa_lo_interfaz_D07_CLT015_LSA_direccion TO Usuarios
GO


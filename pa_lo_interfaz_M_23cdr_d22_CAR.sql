USE leaseoper
GO

IF OBJECT_ID ('dbo.pa_lo_interfaz_M_23cdr_d22_CAR') IS NOT NULL
	DROP PROCEDURE dbo.pa_lo_interfaz_M_23cdr_d22_CAR
GO

CREATE PROCEDURE [dbo].[pa_lo_interfaz_M_23cdr_d22_CAR]
    @fecha_proceso  SMALLDATETIME,
    @salida	        TINYINT OUT
AS
/*
Nombre             : pa_lo_interfaz_M_23cdr_d22_CAR

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

   EXEC pa_lo_interfaz_M_23cdr_d22_CAR '16/06/2014',0

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


SELECT @num_reg = count(*)+2
 FROM t_d22 a
   WHERE a.fecha_proceso <= @fecha_proceso


SELECT 'AREA BANCHILE LEASING'+
	   '001'+ --filler_02
	   convert(CHAR(55),'BANCO DE CHILE')+
	   '001'+
	   'D22'+
	   isnull((SELECT distinct str(count(operacion),15,4)
	   FROM t_d22 ),REPLICATE('0',19))+--nbienes
	   isnull((SELECT str(sum(valor_bien),15,4)
	    FROM t_d22
	    WHERE fecha_proceso <= @fecha_proceso
	    ),REPLICATE('0',19))+--valdia
	   isnull((SELECT str(sum(monto_tasacion),15,4)
	    FROM t_d22
	    WHERE fecha_proceso <= @fecha_proceso
	    ),REPLICATE('0',19))+--valdia
	    str(@num_reg,15,4)
	   
	   
	   

RETURN 0


GRANT EXECUTE ON dbo.pa_lo_interfaz_M_23cdr_d22_CAR TO Usuarios
GO


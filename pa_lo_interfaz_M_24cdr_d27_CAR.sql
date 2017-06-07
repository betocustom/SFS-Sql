USE leaseoper
GO

IF OBJECT_ID ('dbo.pa_lo_interfaz_M_24cdr_d27_CAR') IS NOT NULL
	DROP PROCEDURE dbo.pa_lo_interfaz_M_24cdr_d27_CAR
GO

CREATE PROCEDURE [dbo].[pa_lo_interfaz_M_24cdr_d27_CAR]
    @fecha_proceso  SMALLDATETIME,
    @salida	        TINYINT OUT
AS
/*
Nombre             : pa_lo_interfaz_M_24cdr_d27_CAR

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

   EXEC pa_lo_interfaz_M_24cdr_d27_CAR '16/06/2014',0

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
 FROM t_d27 a
   WHERE a.fecha_reg <= @fecha_proceso


SELECT 'MODELO'+
	   REPLICATE('0',126)+ --filler_02
	   convert(CHAR(55),'BANCO DE CHILE')+
	   '001'+
	   REPLICATE('0',63)+
	  'Informacion correspondiente al mes de'+
	   convert(CHAR(2),datepart(mm,@fecha_proceso))+
	   convert(CHAR(2),datepart(yy,@fecha_proceso))+
	   REPLICATE('0',33)+ --filler_02
	   convert(CHAR(75),'Archivo : D27')+
	   REPLICATE('0',8)+'+'+REPLICATE('-',65)+'+'+
	   REPLICATE('0',7)+
	   '|  Nro. de Registros Informados'+
	   '|'+ 
	   isnull(str(@num_reg,19,0),REPLICATE('0',19))+
	   '|'+ 
	   REPLICATE('0',70)+
	   REPLICATE('0',7)+
	   '|  Total montos al dia'+
	   '|'+
	   isnull((SELECT str(sum(monto),15,4)
	    FROM t_d27
	    WHERE fecha_reg <= @fecha_proceso
	      AND morosidad = 0
	    ),REPLICATE('0',19))+--valdia
	   '|'+
	   REPLICATE('0',70)+--filler5
	   REPLICATE('0',7)+
	   '|  Total montos morosos'+
	   '|'+
	   isnull((SELECT str(sum(monto),15,4)
	    FROM t_d27
	    WHERE fecha_reg <= @fecha_proceso
	      AND morosidad >= 1
	    ),REPLICATE('0',19))+--valdia
	   '|'+
	   REPLICATE('0',70)--filler5
	   





RETURN 0


GRANT EXECUTE ON dbo.pa_lo_interfaz_M_24cdr_d27_CAR TO Usuarios
GO


USE leaseoper
GO

IF OBJECT_ID ('dbo.pa_lo_interfaz_D14') IS NOT NULL
	DROP PROCEDURE dbo.pa_lo_interfaz_D14
GO

CREATE PROCEDURE [dbo].[pa_lo_interfaz_D14]
    @fecha_proceso  SMALLDATETIME ,
    @salida	    TINYINT OUT
AS
/*
Nombre             : pa_lo_interfaz_D14

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

   EXEC pa_lo_interfaz_D14 '16/12/2014',0

*/
DECLARE @sumatoria CHAR(16)
        
        
SET NOCOUNT ON



SELECT  REPLICATE('0',15),
       @fecha_proceso,
       'DEVENGAMIENTO',   
        REPLICATE('0',51),
       --suma_cargos,
       --suma_abonos,
       --cuenta_reg,
       '00',
       'LSA',
       130, --codduc
       --codcta,
       0,
       130,
       --fecon
       '',
       'MOVIMIENTO DEL DIA LEASING ANDINO',
       --cargo,
       --abono,
       '01',--nuglo,
       0,
       'LSA'
   FROM t_contratos_IFRS a,
        v_clientes b,
        t_contratos c
   WHERE a.Rut_Cliente = b.cli_rut
    AND a.operacion = c.operacion
    AND c.fecha_ingreso_cont <= @fecha_proceso


RETURN 0



GRANT EXECUTE ON dbo.pa_lo_interfaz_D14 TO Usuarios
GO


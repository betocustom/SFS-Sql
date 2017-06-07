USE leaseoper
GO

IF OBJECT_ID ('dbo.pa_lo_interfaz_S_01CLTLSA_LSA') IS NOT NULL
	DROP PROCEDURE dbo.pa_lo_interfaz_S_01CLTLSA_LSA
GO

CREATE PROCEDURE [dbo].[pa_lo_interfaz_S_01CLTLSA_LSA]
    @fecha_proceso  SMALLDATETIME ,
    @salida	        TINYINT OUT
AS
/*
Nombre             : pa_lo_interfaz_S_01CLTLSA_LSA

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

   EXEC pa_lo_interfaz_S_01CLTLSA_LSA '16/12/2014',0

*/
DECLARE @sumatoria CHAR(16),
        @num_reg  INT
        
        
SET NOCOUNT ON


SELECT @num_reg = count(*)
  FROM  leasecom..v_clientes a,
        t_contratos b,
        Leaseoper..t_bienes_detalle c
   WHERE a.rut = b.rut_cliente
    AND b.operacion = c.operacion
    AND b.fecha_ingreso_cont <= @fecha_proceso




SELECT '000000000LSA0000000000000000000000HEA*** FECHA PROCESO: '+ --filler
       convert(CHAR(8),@fecha_proceso,112)+ --fproceso  
       REPLICATE('',196)+
       SUBSTRING(REPLICATE('0',9 -DATALENGTH(RTRIM(CONVERT(CHAR(9),a.rut))))+ RTRIM(CONVERT(CHAR(9),a.rut)),1,9)+--a.rut,               
       'LSA'+
       convert(CHAR(2),b.cod_oficina_real)+
       isnull(convert(CHAR(6),d.id_cliente_banco),REPLICATE('',6) )+ --clien_ini
       isnull((SELECT convert(char(5),id_cliente)
              FROM t_datos_cliente_banco cb 
          WHERE cb.lberut = a.rut), REPLICATE('',6) )+ --contr_ini
       'PRO'+ --tfijo,
       'AGR'+ --ndeud
      SUBSTRING(REPLICATE('0',9 -DATALENGTH(RTRIM(CONVERT(CHAR(9),a.rut))))+ RTRIM(CONVERT(CHAR(9),a.rut)),1,9)+--a.rut,
       'LSA'+ --tipro
       convert(char(3),b.cod_oficina_real)+ --ofici
       isnull((SELECT convert(char(5),id_cliente) 
              FROM t_datos_cliente_banco cb 
          WHERE cb.lberut = a.rut),REPLICATE('',6) ) +	--clien /* es un campo nuevo a agregar, aun no se realiza el alter*/
       convert(char(5),b.num_contrato)+--con           
         CASE  WHEN a.rut > 50000000
           THEN   convert(CHAR(12),(SELECT razon_social
                    FROM leasecom..t_clientes_empresas
                   WHERE rut = a.rut))
         ELSE 
              isnull((SELECT  CONVERT(CHAR(10),RTRIM(nombres )+SPACE(1)+RTRIM(apellido_p)+SPACE(1)+RTRIM(apellido_m))
                FROM leasecom..t_clientes_personas
              WHERE rut = a.rut),REPLICATE('',12)) 
         END + --filler_01          
         CASE  b.estado_operacion 
           WHEN 1 THEN  '2'
           WHEN 2 THEN  '1'
           ELSE ''
         END  + --tiporela 
             CASE  b.estado_operacion 
           WHEN 1 THEN  '22'
           WHEN 2 THEN  '20'
           ELSE ''
         END  + --cod_rela	       
       '130'+
       REPLICATE('0',4)+ --filler_03
       REPLICATE('0',1)+--filler_04
       REPLICATE('0',9)+--filler_05
       convert(char(3),b.cod_oficina_real) + --OfiEjeCli
       convert(char(3),cot.ejecutivo_generador)+ --CodEjeCli
       convert(char(8),b.fecha_ingreso_cont,112)+ --fecha
         CASE  b.estado_operacion 
           WHEN 1 THEN  '3'
           ELSE '0'
         END +--tiperela 
       convert(char(8),b.fecha_ingreso_cont,112)+--fechaesta
        CASE  WHEN a.rut > 50000000
           THEN   '  0'
         ELSE 
             isnull((SELECT   CONVERT(CHAR(3),RTRIM(cod_est_civil))
                FROM leasecom..t_clientes_personas
              WHERE rut = a.rut),REPLICATE('0',3)) 
         END+  --filler_06    
       '2'+           
       '0'+
       REPLICATE('0',8)+
       REPLICATE('0',3)+
       REPLICATE('0',2)+
       REPLICATE('0',8)+ --filler_12
       'N'+
       REPLICATE('0',4)+
       REPLICATE('0',124)+ --filler_15       
       '000000000LSA0000000000000000000000TOT*** TOTAL NOVEDADES :'+
       SUBSTRING(REPLICATE('0',7 -DATALENGTH(RTRIM(CONVERT(CHAR(7),@num_reg))))+ RTRIM(CONVERT(CHAR(7),@num_reg)),1,7)--numreg               
    FROM leasecom..v_clientes a,
         t_contratos b,
         Leaseoper..t_bienes_detalle c,
        leasecom..t_clientes d,
        leasecom..t_cotizacion cot 
   WHERE a.rut = b.rut_cliente
    AND b.operacion = c.operacion
    AND b.rut_cliente = d.rut_cliente
    AND b.cod_cotizacion = cot.cod_cotizacion
    AND b.fecha_ingreso_cont <= @fecha_proceso







RETURN 0

GRANT EXECUTE ON dbo.pa_lo_interfaz_S_01CLTLSA_LSA TO usuarios
GO


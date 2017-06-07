USE leaseoper
GO

IF OBJECT_ID ('dbo.pa_lo_interfaz_S_02_CLT015_LSA_SEM_basico') IS NOT NULL
	DROP PROCEDURE dbo.pa_lo_interfaz_S_02_CLT015_LSA_SEM_basico
GO

CREATE PROCEDURE [dbo].[pa_lo_interfaz_S_02_CLT015_LSA_SEM_basico]
    @fecha_proceso  SMALLDATETIME ,
    @salida	        TINYINT OUT
AS
/*
Nombre             : pa_lo_interfaz_S_02_CLT015_LSA_SEM_basico

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

   EXEC pa_lo_interfaz_S_02_CLT015_LSA_SEM_basico '16/12/2014',0

*/
DECLARE @sumatoria CHAR(16),
        @num_reg  INT,
        @saldo_insoluto FLOAT 
        
SET NOCOUNT ON






 SELECT  @sumatoria= convert(CHAR(16),str(sum(convert(float,a.valor)),16,0))
   FROM  t_bienes_detalle a,
	     t_contratos b
   WHERE a.operacion = b.rut_cliente
    AND b.fecha_ingreso_cont <= @fecha_proceso


SELECT @num_reg  = count(b.operacion)		      		      
   FROM leasecom..v_clientes a,
        t_contratos b,
        Leaseoper..t_bienes_detalle c,
        leasecom..t_clientes d      
   WHERE a.rut = b.rut_cliente  
    AND b.rut_cliente = d.rut_cliente    
    AND b.fecha_ingreso_cont <= @fecha_proceso




SELECT  '000000000LSA0000000000000000000000HEA*** FECHA PROCESO:'+ --filler 
        convert(CHAR(8),@fecha_proceso,112)+  
       isnull((SELECT convert(CHAR(8),max(fecha_contab),112)
          FROM leaseoper..t_contratos_contab cont
         WHERE cont.operacion = b.operacion 
         AND cont.tipo      > 1),REPLICATE('',9) ) +                       
       --[Detalle]--        
       SUBSTRING(REPLICATE('0',9 -DATALENGTH(LTRIM(CONVERT(CHAR(9),a.rut))))+ LTRIM(CONVERT(CHAR(9),a.rut)),1,9)+ --a.rut
       'BAS'+
       SUBSTRING(REPLICATE('0',9 -DATALENGTH(LTRIM(CONVERT(CHAR(9),a.rut))))+ LTRIM(CONVERT(CHAR(9),a.rut)),1,9)+ --a.rut
       a.dv+
       '2'+
       convert(CHAR(50),a.nombre)+ --rsoci
       convert(CHAR(3),b.cod_oficina_real)+ --sucur
       convert(CHAR(3),b.ejecutivo_contrato)+  --ejecu
       REPLICATE('0',3)+ --filler_01
       REPLICATE('0',3)+--filler_02       
       CASE WHEN a.rut > 50000000 THEN '3'
       ELSE '0'
       END+  --categoria 
       REPLICATE('0',3)+ --filler_03
       REPLICATE('0',3)+ --filler_04
       REPLICATE('0',3)+ --filler_05
       -----------------
       CASE WHEN a.rut > 50000000 THEN isnull((SELECT convert(CHAR(8),clip.fecha_creacion )
                                         FROM leasecom..t_clientes_empresas clip
                                       WHERE clip.rut = a.rut),REPLICATE('0',3))
       
       ELSE isnull((SELECT convert(CHAR(8),clip.fecha_nacimiento) 
              FROM leasecom..t_clientes_personas clip
              WHERE clip.rut = a.rut),REPLICATE('0',3))
       END+  --fecha 
       REPLICATE('0',8)+ --filler_06
       CASE WHEN a.rut > 50000000 THEN '0'       
       ELSE isnull((SELECT convert(CHAR(1),clip.sexo) 
              FROM leasecom..t_clientes_personas clip
              WHERE clip.rut = a.rut),REPLICATE('0',1))
       END+  --sexo        
       CASE WHEN a.rut > 50000000 THEN '0'       
       ELSE isnull((SELECT convert(CHAR(1),clip.cod_est_civil)
              FROM leasecom..t_clientes_personas clip
              WHERE clip.rut = a.rut),REPLICATE('0',1))
       END+  --ecivil        
       --nacion
       REPLICATE('0',3)+ --filler_07
       CASE WHEN a.rut > 50000000 THEN isnull((SELECT convert(CHAR(3),clip.cod_act_eco) 
                                         FROM leasecom..t_clientes_empresas clip
                                        WHERE clip.rut = a.rut),REPLICATE('0',3))
       
       ELSE isnull((SELECT convert(CHAR(3),clip.cod_act_eco) 
              FROM leasecom..t_clientes_personas clip
              WHERE clip.rut = a.rut),REPLICATE('0',3))
       END+  --activ
       REPLICATE('0',3)+ --filler_08
       REPLICATE('0',3)+ --filler_09 
       (SELECT convert(CHAR(3),cli.tipo_cliente) 
         FROM leasecom..t_clientes cli
         WHERE cli.rut_cliente = a.rut )+ --compos 
       (SELECT convert(CHAR(8),tif.fecha_proceso,112)
         FROM t_contratos_IFRS tif
        WHERE tif.operacion = b.operacion)+--fclasi
       (SELECT  convert(CHAR(2),cs.descripcion)
        FROM p_codigo_clasif_super cs,
             t_contratos_IFRS tif
        WHERE cs.cod_clasif_super = tif.codigo_clasif_super
          AND tif.operacion = b.operacion )+--clasi
         --fclasi1
         --clasi_ant
        REPLICATE('0',8)+
        REPLICATE('0',8)+
        'N'+
        REPLICATE('0',8)+
        'N'+
        'N'+
        'N'+ 
        REPLICATE('0',6)+
        'N'+
        'N'+
        'N'+ 
        REPLICATE('0',2)+
        REPLICATE('0',8)+
        'N'+
        'N'+
        --ifunci
         isnull((SELECT convert(CHAR(8),max(cont.fecha_ingreso),112) 
            FROM t_contratos_contab cont
           WHERE cont.operacion = b.operacion 
             AND cont.tipo      > 1),REPLICATE('',8))+--fecre        
        REPLICATE('0',8)+
        'B'+
        REPLICATE('',131)                   
   FROM leasecom..v_clientes a,
        t_contratos b,
        Leaseoper..t_bienes_detalle c,
        t_contratos_anexo d
   WHERE a.rut = b.rut_cliente
    AND b.operacion = c.operacion
    AND b.operacion = d.operacion
    AND b.fecha_ingreso_cont <= @fecha_proceso






RETURN 0


GRANT EXECUTE ON dbo.pa_lo_interfaz_S_02_CLT015_LSA_SEM_basico TO Usuarios
GO


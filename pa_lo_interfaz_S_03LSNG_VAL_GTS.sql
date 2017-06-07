USE leaseoper
GO

IF OBJECT_ID ('dbo.pa_lo_interfaz_M_29LSNG_VAL_GTS_OMD') IS NOT NULL
	DROP PROCEDURE dbo.pa_lo_interfaz_M_29LSNG_VAL_GTS_OMD
GO

CREATE PROCEDURE [dbo].[pa_lo_interfaz_M_29LSNG_VAL_GTS_OMD]
    @fecha_proceso  SMALLDATETIME ,
    @salida	        TINYINT OUT
AS
/*
Nombre             : pa_lo_interfaz_M_29LSNG_VAL_GTS_OMD

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

   EXEC pa_lo_interfaz_M_29LSNG_VAL_GTS_OMD '16/12/2014',0

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



SELECT '0'+
       'LSA'+   
       'GARANTIAS'+
       convert(CHAR(8),@fecha_proceso,112)+ --fecha_proc
        REPLICATE('0',264)+
       --[Detalle]--        
       SUBSTRING(REPLICATE('0',9 -DATALENGTH(LTRIM(CONVERT(CHAR(9),a.rut))))+ LTRIM(CONVERT(CHAR(9),a.rut)),1,9)+ --a.rut,
       a.dv+
       convert(CHAR(9),b.cod_oficina_real)+ --ofi_ini
       isnull(convert(CHAR(4),d.id_cliente_banco),REPLICATE('0',4)) + --clien_ini,
       isnull((SELECT convert(CHAR(9),id_cliente) 
	     FROM t_datos_cliente_banco dc
	    WHERE dc.lberut = b.rut_cliente ),REPLICATE('0',2))+ --contr_ini /* es un campo nuevo a agregar, aun no se realiza el alter*/	   
       convert(CHAR(3),c.cod_material) +  --mater
       convert(CHAR(3),c.cod_rubro)+ --cbien,
       str((c.valor_libro_inicial_mat*100),12,3)+ --vcomer
        str((c.valor_libro_inicial_mat*0.8)*100,12,3)+--vgaran    
       isnull(convert(CHAR(8),c.fecha_tasacion,112), REPLICATE('0',8))+
       '999'+
       isnull((SELECT convert(CHAR(2),preg.cod_region) 
          FROM t_clientes_direccion   cdir,
               leasecom..p_localidad  loc,
               leasecom..p_regiones   preg
         WHERE cdir.rut = a.rut
           AND cdir.cod_comuna = loc.cod_comuna_cia                   
           AND loc.cod_region  = preg.cod_region  ),REPLICATE('0',2))+--region,
       'EMPRESAS'+
        isnull((SELECT convert(CHAR(5),loc.descripcion) 
         FROM t_clientes_direccion   cdir,
               leasecom..p_localidad loc
         WHERE cdir.rut = a.rut
           AND cdir.cod_comuna = loc.cod_comuna_cia  ),REPLICATE('0',2))+--comuna,
       '130'+
       dbo.Fn_TO(b.operacion,1)+ --cartera
       '00'+ --filler4
       convert(CHAR(9),b.cod_oficina_real)+--ofici,
	   isnull((SELECT convert(CHAR(9),id_cliente) 
	     FROM t_datos_cliente_banco dc
	    WHERE dc.lberut = b.rut_cliente ),REPLICATE('0',2))+ --clien /* es un campo nuevo a agregar, aun no se realiza el alter*/
	   convert(CHAR(12),b.num_contrato)+--contr
	   convert(CHAR(9),b.operacion)+	--folio
       REPLICATE('0',150)+ --filler_05
       '2'+ --filler
       'LSA'+ --filler_01
       convert(CHAR(12),@num_reg)+ --numreg
       isnull((SELECT str(sum(gar.monto)*100,14,4) 
         FROM t_garantias gar,
              t_garantias_operacion  gop
         WHERE gar.num_garantia = gop.num_garantia
           AND gop.operacion    = b.operacion  ),REPLICATE('0',2))+ --totval
       REPLICATE('',252)--filler_03       
   FROM leasecom..v_clientes a,
        t_contratos b,
        Leaseoper..t_bienes_detalle c,
        leasecom..t_clientes d
   WHERE a.rut = b.rut_cliente
    AND b.operacion = c.operacion
    AND b.rut_cliente = d.rut_cliente
    AND b.fecha_ingreso_cont <= @fecha_proceso






RETURN 0


GRANT EXECUTE ON dbo.pa_lo_interfaz_M_29LSNG_VAL_GTS_OMD TO Usuarios
GO


USE leaseoper
GO

IF OBJECT_ID ('dbo.pa_lo_interfaz_D_15rez001_lsa') IS NOT NULL
	DROP PROCEDURE dbo.pa_lo_interfaz_D_15rez001_lsa
GO

CREATE PROCEDURE [dbo].[pa_lo_interfaz_D_15rez001_lsa]
    @fecha_proceso  SMALLDATETIME ,
    @salida	        TINYINT OUT
AS
/*
Nombre             : pa_lo_interfaz_D_15rez001_lsa

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

   EXEC pa_lo_interfaz_D_15rez001_lsa '16/12/2014',0

*/
DECLARE @sumatoria CHAR(16),
        @num_reg  INT,
        @saldo_insoluto FLOAT 
        
SET NOCOUNT ON



---Saldo insoluto
    SELECT  SUM(capital) AS saldo_insoluto,
            b.operacion,
            convert(FLOAT,0) AS cuota_abono,                  
      CASE b.cod_tipo_periodo_arr  
       When  4 THEN  6
       When  5 THEN  12 
       ELSE b.cod_tipo_periodo_arr
      END  AS cod_tipo_periodo_arr,
      convert(FLOAT,0) AS tasa_ptmo,
      ISNULL(b.tasa_spread,0) AS tasa_spread,
      ISNULL(b.tasa_variable,0) AS tasa_variable,
      0 AS num_cuota_min,
      convert(FLOAT,0) AS cuota_min     
    INTO   #universo  
    FROM   leaseoper..t_cuotas a,
           t_contratos b 
    WHERE a.operacion = b.operacion
      AND a.estado in (1,3)
      AND b.fecha_ingreso_cont <= @fecha_proceso
    GROUP BY b.operacion,b.cod_tipo_periodo_arr,b.tasa_spread,b.tasa_variable



 UPDATE #universo
   SET  saldo_insoluto = (saldo_insoluto - ISNULL(abonos.capital_abono,0)) * 10000,
        tasa_ptmo      = POWER( (((tasa_variable+tasa_spread)/100.00)+1.00), (1.00 / (convert(FLOAT,cod_tipo_periodo_arr)/12))) - 1.00       
  FROM ( SELECT SUM(b.capital) AS capital_abono,
	            c.operacion                       
	      FROM  leaseoper..t_cuotas a, 
	            leaseoper..t_cuotas_mov b,
	            #universo c
	       WHERE  a.operacion = c.operacion
	         AND  a.estado = 3
	         AND  a.operacion = b.operacion
	         AND  a.cod_tipo_cuota = b.cod_tipo_cuota
	         AND a.num_cuota = b.num_cuota
	        GROUP BY c.operacion ) AS abonos
   WHERE #universo.operacion = abonos.operacion         

---Saldo insoluto



--min cuota
 UPDATE #universo
   SET  cuota_min     =  cuota.valor_cuota_total,   
        num_cuota_min =  cuota.num_cuota
  FROM ( SELECT cuo.valor_cuota_total,
		       b.operacion,
		       cuo.num_cuota
		   FROM t_cuotas cuo,
		        t_contratos b		        
		WHERE cuo.operacion = b.operacion
		  AND cuo.estado = 1
		  AND cuo.num_cuota IN ( SELECT min(cu.num_cuota) 
								   FROM t_cuotas cu
								WHERE cuo.operacion = b.operacion
								  AND cu.operacion  = cuo.operacion
								  --AND cu.num_cuota = cuo.num_cuota
								  AND cu.cod_tipo_cuota =0
								  AND cu.estado = 1								 
								  AND cu.fecha_vencimiento >=  @fecha_proceso)  ) AS cuota  							  										    
   WHERE #universo.operacion = cuota.operacion   
--min cuota


      SELECT  @sumatoria= convert(CHAR(16),str(sum(convert(float,b.rut_cliente)),16,0))
 	   FROM  leasecom..v_clientes a,
		     t_contratos b
	   WHERE a.rut = b.rut_cliente
	    AND b.fecha_ingreso_cont <= @fecha_proceso


SELECT @num_reg  = count(b.operacion)		      		      
 FROM leasecom..v_clientes a,
        t_contratos b,       
        leasecom..t_clientes d,
        #universo e
   WHERE a.rut = b.rut_cliente
  --  AND b.operacion = c.operacion
    AND b.rut_cliente = d.rut_cliente
    AND b.operacion   = e.operacion
    AND b.fecha_ingreso_cont <= @fecha_proceso





SELECT REPLICATE('0',6)+
       'LSA'+    
        convert(CHAR(8),@fecha_proceso,112)+
     --[Detalle]-- 
       '012'+
       '090'+
        SUBSTRING(REPLICATE('0',9 -DATALENGTH(LTRIM(CONVERT(CHAR(9),a.rut))))+ LTRIM(CONVERT(CHAR(9),a.rut)),1,9)+
       '130'+--ofope
	   dbo.Fn_TO(b.operacion,1)+ --tiope
       convert(CHAR(3),b.cod_oficina_real)+convert(CHAR(8),b.operacion)+--nucre
       REPLICATE('0',3)+--subop
       REPLICATE('',6)+
       isnull(convert(CHAR(3),b.cod_oficina_real)   ,REPLICATE('0',3)) +
       isnull(convert(CHAR(3),b.cod_oficina_real)   ,REPLICATE('0',3))+
       isnull(convert(CHAR(3),b.ejecutivo_contrato) ,REPLICATE('0',3))+ 
       isnull(convert(CHAR(3),b.cod_moneda_contrato),REPLICATE('0',3))+
       str(((b.provision_material+ b.provision_gasto_legal+b.provision_seguros)-b.monto_pie)*10000,13,4)+
       convert(CHAR(8),b.fecha_ing_carta_recep,112)+
       CASE b.cod_moneda_contrato WHEN 1 THEN  '1' 
         ELSE (SELECT convert(CHAR(10),p.valor)
				 FROM  leasecom..p_valor_paridades p,
				      t_contratos con
				WHERE con.operacion = b.operacion			        
				AND  con.cod_moneda_contrato = p.cod_moneda
				AND  con.fecha_ing_carta_recep = p.fecha )
        END+ --tc_origen
       convert(CHAR(8),b.fecha_termino,112)+ 
       (SELECT str(sum((cuo.capital)),13,4) 
		  FROM t_cuotas cuo
		 WHERE cuo.operacion = b.operacion
		   AND cuo.estado = 1 )+ --saldo_cap 
       str(e.saldo_insoluto,13,4)+
	  (SELECT  convert(CHAR(3),count(*))
		  FROM t_cuotas cuo
		 WHERE cuo.operacion = b.operacion
		   AND cuo.estado in (1,3) )+ --num_cuotas
	 CASE WHEN exists (select 1 from leaseoper..t_contratos
                   where operacion not in (select operacion from t_contratos_castigados)
                     AND operacion not in (select operacion from t_contratos_venc)
                     AND operacion = b.operacion) THEN '01'
        --"Cartera Vencida --> 
        WHEN exists (select 1 from leaseoper..t_contratos
                  where operacion not in (select operacion from t_contratos_castigados)
            AND  operacion  in (select operacion from t_contratos_venc)
            AND operacion = b.operacion) THEN '02'
        --"Cartera Castigada --> 
        WHEN exists (select 1 from leaseoper..t_contratos
                  WHERE operacion  in (select operacion from t_contratos_castigados)            
                    AND operacion = b.operacion) THEN '04'           
       END+ --estado_credito 
       CASE WHEN exists (select 1 from leaseoper..t_contratos
                   where operacion not in (select operacion from t_contratos_castigados)
                     AND operacion not in (select operacion from t_contratos_venc)
                     AND operacion = b.operacion) 
                     THEN (SELECT convert(CHAR(08),min(cuo.fecha_vencimiento),112) 
								   FROM t_cuotas cuo
								WHERE cuo.operacion = b.operacion
								  AND cuo.estado = 1
								  AND cuo.fecha_vencimiento >= @fecha_proceso )  
        --"Cartera Vencida --> 
        WHEN exists (select 1 from leaseoper..t_contratos
                  where operacion not in (select operacion from t_contratos_castigados)
            AND  operacion  in (select operacion from t_contratos_venc)
            AND operacion = b.operacion) THEN (select convert(CHAR(08),ven.fecha_ing_cart_venc) 
                                                   from t_contratos_venc ven
                                                   WHERE ven.operacion = b.operacion)
        --"Cartera Castigada --> 
        WHEN exists (select 1 from leaseoper..t_contratos
                  WHERE operacion  in (select operacion from t_contratos_castigados)            
                    AND operacion = b.operacion) THEN (select convert(CHAR(08),cas.fecha_castigo) 
                                                   from t_contratos_castigados cas
                                                   WHERE cas.operacion = b.operacion)           
       END+ --fecha_estado	 
       CASE WHEN EXISTS (SELECT 1 operacion_nueva 
                          from t_control_modificaciones com
                        WHERE  b.operacion = com.operacion_nueva) THEN 'S'
        ELSE 'N'
       END+ --renegociado 
       (SELECT convert(CHAR(8),min(cuo.fecha_vencimiento),112) 
	     FROM t_cuotas cuo
		WHERE cuo.operacion = b.operacion
		  AND cuo.estado = 1
		  AND cuo.fecha_vencimiento < @fecha_proceso)+ --fec_prim_impaga
        (SELECT convert(CHAR(3),count(1)) 
	     FROM t_cuotas cuo
		WHERE cuo.operacion = b.operacion
		  AND cuo.estado = 1
		  AND cuo.fecha_vencimiento < @fecha_proceso)+ --num_cuotas_impag                                                              
        (SELECT convert(CHAR(8),max(cuo.fecha_pago)) 
	       FROM t_cuotas cuo
		WHERE cuo.operacion = b.operacion
		  AND cuo.estado = 2
		  AND cuo.fecha_vencimiento < @fecha_proceso)+ --fecha_ultmo_pago             
       str((b.tasa_spread+b.tasa_variable)/12,8,5)+ --tasa_ptmo
       REPLICATE('0',17)+ --rebaja_cuota 
       str(e.cuota_min,13,4)+ --valor_prox_cuota        
       (SELECT convert(CHAR(8),cuo.fecha_vencimiento,112) 
           FROM t_cuotas cuo 
         WHERE cuo.operacion = e.operacion
           AND cuo.operacion = b.operacion
           AND cuo.cod_tipo_cuota = 0
           AND cuo.num_cuota = e.num_cuota_min )+ --fec_prox_cuota
       'M'+
       CONVERT(CHAR(3),b.cod_tipo_periodo_arr)+ --peridiocidad_pago               
        REPLICATE('0',11)+ --cupo_nacional
		REPLICATE('0',13)+ --cupo_internac    
		REPLICATE('0',11)+ --tot_factura_nac  
		REPLICATE('0',13)+ --tot_factura_inter
		REPLICATE('0',8)+ --fec_ultma_factur 
		REPLICATE('0',11)+ --ultmo_pag_minimo 
		REPLICATE('0',2)+ --codigo_bloqueo   
		REPLICATE('0',1)+ --convenio_pago    
		REPLICATE('0',8)+ --fec_prox_factura 
		REPLICATE('0',1)+ --tramo_factura    
		CASE (select datepart(dw,@fecha_proceso))
		 WHEN 5 THEN 'C'
		 ELSE ''
		END+ --solicitud 
		convert(CHAR(8),@fecha_proceso,112)+--fecha_infor       
        REPLICATE('0',5)+ --convecartera
        'LSA'+  --sistema      
        (SELECT convert(CHAR(8),cuo.fecha_vencimiento,112) 
           FROM t_cuotas cuo 
         WHERE cuo.operacion = e.operacion
           AND cuo.operacion = b.operacion
           AND cuo.cod_tipo_cuota = 0
           AND cuo.num_cuota = e.num_cuota_min )+ --fec_vcto
        convert(CHAR(5),e.num_cuota_min) + --numero_cuota
        CASE b.cod_moneda_contrato WHEN 1 THEN  convert(CHAR(9),(1*10000)) 
         ELSE (SELECT  str(( p.valor)*10000,9,0)
				 FROM t_cuotas cuo,
				      leasecom..p_valor_paridades p				     
				WHERE cuo.operacion = b.operacion
				 AND  cuo.num_cuota = e.num_cuota_min
				 AND cuo.cod_tipo_cuota = 0 				  
				 AND  cuo.fecha_vencimiento = p.fecha           
				 AND  b.cod_moneda_contrato = p.cod_moneda)
        END+ --tc_cto
        (SELECT str(cuo.capital,13,4) 
           FROM t_cuotas cuo 
         WHERE cuo.operacion = e.operacion
           AND cuo.cod_tipo_cuota = 0
           AND cuo.num_cuota = e.num_cuota_min)+ --capital
        (SELECT str(cuo.interes,13,4) 
           FROM t_cuotas cuo 
         WHERE cuo.operacion = e.operacion
           AND cuo.num_cuota = e.num_cuota_min
           AND cuo.cod_tipo_cuota = 0)+ --intereses               
		REPLICATE('0',17)+ --comision
		REPLICATE('0',17)+ --seguro_deg
		REPLICATE('0',17)+ --seguro_inic
		REPLICATE('0',17)+ --o.montos
             --"Cartera Vigente --> 
       CASE WHEN exists (select 1 from leaseoper..t_contratos
                   where operacion not in (select operacion from t_contratos_castigados)
                     AND operacion not in (select operacion from t_contratos_venc)
                     AND operacion = b.operacion) 
                     THEN '01' 
        --"Cartera Vencida --> 
        WHEN exists (select 1 from leaseoper..t_contratos
                  where operacion not in (select operacion from t_contratos_castigados)
            AND  operacion  in (select operacion from t_contratos_venc)
            AND operacion = b.operacion) THEN '02'
        --"Cartera Castigada --> 
        WHEN exists (select 1 from leaseoper..t_contratos
                  WHERE operacion  in (select operacion from t_contratos_castigados)            
                    AND operacion = b.operacion) THEN '04'          
       END+ --estado
	   ' '+--marca_cuota
       REPLICATE('',40)+ --filler
--Trailer
       REPLICATE('',06)+ --filler
       convert(CHAR(6),@num_reg)+ --numreg
       @sumatoria+ --rutri
       REPLICATE('',459)--filler_03
   FROM leasecom..v_clientes a,
        t_contratos b,
        -- Leaseoper..t_bienes_detalle c,
        leasecom..t_clientes d,
        #universo e
   WHERE a.rut = b.rut_cliente
  --  AND b.operacion = c.operacion
    AND b.rut_cliente = d.rut_cliente
    AND b.operacion   = e.operacion
    AND b.fecha_ingreso_cont <= @fecha_proceso



RETURN 0


GRANT EXECUTE ON dbo.pa_lo_interfaz_D_15rez001_lsa TO Usuarios
GO


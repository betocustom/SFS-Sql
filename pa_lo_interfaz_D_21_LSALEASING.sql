USE leaseoper
GO

IF OBJECT_ID ('dbo.pa_lo_interfaz_D_21_LSALEASING') IS NOT NULL
	DROP PROCEDURE dbo.pa_lo_interfaz_D_21_LSALEASING
GO

CREATE PROCEDURE [dbo].[pa_lo_interfaz_D_21_LSALEASING]
    @fecha_proceso  SMALLDATETIME ,
    @salida	        TINYINT OUT
AS
/*
Nombre             : pa_lo_interfaz_D_21_LSALEASING

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

   EXEC pa_lo_interfaz_D_21_LSALEASING '16/06/2014',0

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


SELECT str(sum((c.capital*c.interes)),16,4) AS sumaKxA,
       convert(CHAR(15),'') AS sumaKxA_pend,
       (SELECT str(sum((toc.capital*toc.interes)),16,4) 
          FROM t_cuotas toc
         WHERE toc.operacion = c.operacion
           AND toc.estado IN (1,3)
           AND toc.fecha_vencimiento <= dateadd(dd,-90,@fecha_proceso)  ) AS sumaKxA_venc, 
       c.operacion       
       INTO #sumKxA
       FROM t_cuotas c           
WHERE c.estado IN (1,3)
  AND c.operacion  NOT IN ( SELECT d.operacion 
                             FROM  t_castigos d 
                           WHERE c.operacion = d.operacion
                          )
  AND c.fecha_vencimiento <=  @fecha_proceso    
GROUP BY c.operacion


SELECT str(sum((c.capital*c.interes)),12,3) AS sumaKxA_pend,
       c.operacion     
       INTO #sumKxA_b  
       FROM t_cuotas c,
            #sumKxA  d          
WHERE c.operacion = d.operacion
  AND c.fecha_vencimiento >  @fecha_proceso
GROUP BY c.operacion

UPDATE #sumKxA
 SET sumaKxA_pend = fb.sumaKxA_pend
FROM #sumKxA_b fb,
     #sumKxA   sk
WHERE fb.operacion = sk.operacion      
   

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
      convert(FLOAT,0) AS cuota_min, 
      0 AS atraso_maximo_dias    
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



--ultima cuota pagada
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
									  AND cu.estado IN (2,5) ) ) AS cuota  							  										    
   WHERE #universo.operacion = cuota.operacion   

--sumatoria
      SELECT  @sumatoria= convert(CHAR(16),str(sum(convert(float,b.rut_cliente)),16,0))
 	   FROM leasecom..v_clientes a,
	        t_contratos b
	   WHERE a.rut = b.rut_cliente
	    AND b.fecha_ingreso_cont <= @fecha_proceso
	    
	    
	    
--Atraso maximo dias

DECLARE c_cuotas CURSOR FOR
	    SELECT cu.operacion,
	           cu.fecha_vencimiento,
	           cu.fecha_pago
        	FROM t_cuotas cu
	        WHERE cu.operacion >= 100000 AND
			  cu.cod_tipo_cuota = 0	  
				  

OPEN c_cuotas

FETCH c_cuotas INTO @operacion,@fecha_vencimiento,@fecha_pago

--SELECT @desc_fijo = 0, @desc_var = 0
SELECT @dias_max = 0

WHILE @@FETCH_STATUS = 0 
 BEGIN
 
  IF  @fecha_pago > @fecha_vencimiento 
  BEGIN
	  SELECT @dias =datediff(dd,@fecha_vencimiento,@fecha_pago)
	  IF @dias > @dias_max 
	   BEGIN 
	    SELECT @dias_max= @dias
	   END 
   
	   UPDATE #universo
	    SET atraso_maximo_dias = @dias_max
	    WHERE operacion = @operacion
   END
   
   FETCH c_cuotas INTO @operacion,@fecha_vencimiento,@fecha_pago
 END 
DEALLOCATE c_cuotas



SELECT @num_reg = count(*)
 FROM leasecom..v_clientes a,
        t_contratos b,
        #sumKxA ska,
        leasecom..t_clientes d,
        #universo e
   WHERE a.rut = b.rut_cliente
    AND ska.operacion = b.operacion
    AND b.rut_cliente = d.rut_cliente
    AND b.fecha_ingreso_cont <= @fecha_proceso


SELECT 'C'+
	   convert(CHAR(8),@fecha_proceso,112)+ --fecha_proc
       convert(CHAR(8),@fecha_proceso,112)+ 
       'LSA'+   
       REPLICATE('0',419)+ --contenido
       --[Detalle]--    
       'D'+    
       'LSA'+
       convert(CHAR(6),b.operacion)+convert(CHAR(3),b.cod_oficina_real)+ltrim(convert(CHAR(9),a.rut))+--numero_operacion
       convert(CHAR(22),b.operacion)+--folio_oper_leasing
       SUBSTRING(REPLICATE('0',9 -DATALENGTH(LTRIM(CONVERT(CHAR(9),a.rut))))+ LTRIM(CONVERT(CHAR(9),a.rut)),1,9)+             
       a.dv+
       isnull(convert(CHAR(8),b.fecha_ing_carta_recep,112),REPLICATE('',8))+--fecha_otorga
       convert(CHAR(8),b.fecha_ingreso_cont,112)+
       (SELECT  convert(CHAR(8),max(cuo.fecha_vencimiento),112) 
		   FROM t_cuotas cuo
		WHERE cuo.operacion = b.operacion)+ --fecha_vcto
		str(((b.provision_material+ b.provision_gasto_legal+b.provision_seguros)-b.monto_pie),13,4)+
	    CASE b.cod_moneda_contrato
	        WHEN 1 THEN  '001'
	        WHEN 2 THEN  '098'
	        WHEN 4 THEN  '011' 
	    END+ 	
	    CASE b.cod_moneda_contrato
	        WHEN 1 THEN  'CLP'
	        WHEN 2 THEN  'CLF'
	        WHEN 4 THEN  'USD' 
	    END+ 	
 CASE clasificacion_cartera
							WHEN 1 THEN 
						       CASE cod_moneda_contrato
						        WHEN 1 THEN  'Comercial contrato en Pesos'
						        WHEN 2 THEN  'Comercial contrato en UF'
						        WHEN 3 THEN  'Comercial contrato en $US' 
						       END 	
							WHEN 2 THEN 
							   CASE cod_moneda_contrato
						        WHEN 1 THEN  'Consumo contrato en Pesos'
						        WHEN 2 THEN  'Consumo contrato en UF' 
						        WHEN 3 THEN  'Consumo contrato en $US'   
						       END 
							WHEN 3 THEN 
							   CASE cod_moneda_contrato
						        WHEN 1 THEN  'Vivienda contrato en Pesos'
						        WHEN 2 THEN  'Vivienda contrato en UF'
						        WHEN 3 THEN  'Vivienda contrato en $US' 
						       END 
				 END+ 		
 --"Cartera Vigente --> 
   CASE WHEN exists (select 1 
                       from leaseoper..t_contratos
                      where operacion not in (select operacion from t_contratos_castigados)
                 		AND operacion not in (select operacion from t_contratos_venc)
                 		AND operacion = b.operacion) 
                 THEN CASE b.estado_operacion
                             WHEN 2 THEN 'VIGENTE'
                             WHEN 3 THEN 'TERMINO NORMAL'
                                       
                       END
    --"Cartera Vencida --> 
    WHEN exists (select 1 from leaseoper..t_contratos
              where operacion not in (select operacion from t_contratos_castigados)
        AND  operacion  in (select operacion from t_contratos_venc)
        AND operacion = b.operacion) THEN  CASE b.estado_operacion
                                                 WHEN 2 THEN 'EN MORA'
                                                 WHEN 3 THEN 'VENCIDO'         
                                           END 
    --"Cartera Castigada --> 
    WHEN exists (select 1 from leaseoper..t_contratos
              WHERE operacion  in (select operacion from t_contratos_castigados)            
                AND operacion = b.operacion) THEN 
                                               CASE b.estado_operacion
                                                 WHEN 2 THEN 'CASTIGADO TOTAL'
                                                 WHEN 3 THEN 'TERMINADO POR CASTIGO'         
                                               END 
   END+ 
       str(b.tasa_spread,6,0)+ --tasa_base      
       str(POWER( (((b.tasa_variable+b.tasa_spread)/100.00)+1.00), (1.00 / (convert(FLOAT,b.cod_tipo_periodo_arr)/12))) - 1.00,6,0)+       
       str(b.tasa_variable,6,0)+--tasa_base
       (SELECT tt.descripcion FROM leasecom..p_tipo_tasa tt
         WHERE tt.cod_tipo_tasa = b.cod_tipo_tasa )+--glosa_tasa_base esto se saca de b.cod_tipo_tasa
       'ANUAL'+
       isnull((SELECT convert(char(8),max(cu.fecha_pago),112)
			   FROM t_cuotas cu
			WHERE cu.operacion = b.operacion			  			 			  
		  AND cu.estado IN (2,5)) ,REPLICATE('',8))+ --fecha_ultimo_pago  	  
	   str(e.cuota_min,12,3) + --monto_ultimo_pago
	   (SELECT convert(char(8),count(*)) 
		   FROM t_cuotas cu
		  WHERE cu.operacion = b.operacion		  
		    AND cu.estado IN (2,5) )+--num_cuo_pagadas       
		(SELECT convert(char(8),count(*)) 
			FROM t_cuotas cu
		   WHERE cu.operacion = b.operacion   		  
		     AND cu.estado IN (1,3) )+	-- num_cuo_vigentes
	   (SELECT str(count(1),3,0) 
		 FROM t_cuotas tc
		WHERE tc.operacion = b.operacion
		  AND tc.estado = 1
          AND tc.fecha_vencimiento <= dateadd(dd,-90,@fecha_proceso))+ --num_cuotas_vencidas
	   isnull((SELECT str(cas.num_cuotas_morosas,3,0)
	    FROM t_contratos_castigados cas
	    WHERE cas.operacion = b.operacion ),'  ')+--num_cuotas_castigadas
	    convert(CHAR(3),b.num_cuotas_arriendo)+ --num_cuo_pactadas		   
	   CASE b.seguro
	    WHEN '1' THEN 'Responsabilidad Cliente'
	    WHEN '2' THEN 'Responsabilidad Banco'
	   END + --codigo_seguro
	   CASE 
	    WHEN EXISTS(SELECT 1 
                         FROM t_garantias_operacion tgo
                        WHERE tgo.operacion = b.operacion
                          /* AND tgo.cobertura = 1*/)   THEN 'CON GARANTIA'
          ELSE CASE  WHEN EXISTS(SELECT 1 
                         FROM t_garantias_cliente tgc
                        WHERE tgc.rut_cliente = b.rut_cliente
                          AND tgc.cobertura = 1)   THEN 'CON GARANTIA'  
               ELSE 'SIN GARANTIA'             
               END                   
       END+ --garantias
	   ska.sumaKxA+ --saldo_capital_vigente
	   ska.sumaKxA_pend+ --saldo_capital_razago
       ska.sumaKxA_venc+--saldo_capital_vencido	   
	   (SELECT isnull(str(sum(cd.capital_castigo*cd.interes_castigo),12,3),replicate('',15)) 
	       FROM t_castigos_detalle cd
	       WHERE cd.operacion = b.operacion)+--saldo_capital_castigo
	   (SELECT isnull(convert(CHAR(8),min(cuo.fecha_vencimiento),112) ,replicate('',8)) 
           FROM t_cuotas cuo 
         WHERE cuo.operacion = e.operacion
           AND cuo.operacion = b.operacion
           AND cuo.cod_tipo_cuota = 0
           AND cuo.estado IN (1,3)
           AND cuo.fecha_vencimiento >= @fecha_proceso )+ --fec_prox_cuota		  
        CASE WHEN (SELECT isnull(str(datediff(dd,cu.fecha_vencimiento,@fecha_proceso),6,0),replicate('0',6)) 
                     FROM t_cuotas cu
                   WHERE cu.operacion = b.operacion
                     AND cu.num_cuota= e.num_cuota_min) > 0 
              THEN (SELECT isnull(str(datediff(dd,cu.fecha_vencimiento,@fecha_proceso),6,0),replicate('0',6)) 
                     FROM t_cuotas cu
                   WHERE cu.operacion = b.operacion
                     AND cu.num_cuota= e.num_cuota_min)  --atraso_actual
              ELSE REPLICATE('0',6)
        END +            
     str(@dias_max,6,0)+--atraso_maximo_dias
       (SELECT isnull(convert(CHAR(8),cif.fecha_deterioro,112),replicate('0',8)) 
           FROM t_contratos_IFRS cif
         WHERE cif.operacion = b.operacion )+ --fecha_deterioro
      --Trailer
      'T' +
       convert(CHAR(9),@num_reg) + --numreg
       @sumatoria+ --rutri 
      REPLICATE('',414)--filler_03                  
   FROM leasecom..v_clientes a,
        t_contratos b,
        #sumKxA ska,
        leasecom..t_clientes d,
        #universo e
   WHERE a.rut = b.rut_cliente
    AND ska.operacion = b.operacion
    AND b.rut_cliente = d.rut_cliente
    AND b.estado_operacion IN (2,3)
    AND b.operacion   = e.operacion
    AND b.fecha_ingreso_cont <= @fecha_proceso





RETURN 0


GRANT EXECUTE ON dbo.pa_lo_interfaz_D_21_LSALEASING TO Usuarios
GO


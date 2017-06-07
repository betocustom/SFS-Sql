USE leaseoper
GO

IF OBJECT_ID ('dbo.pa_lo_interfaz_M_10lsacast_unix') IS NOT NULL
	DROP PROCEDURE dbo.pa_lo_interfaz_M_10lsacast_unix
GO

CREATE PROCEDURE [dbo].[pa_lo_interfaz_M_10lsacast_unix]
    @fecha_proceso  SMALLDATETIME ,
    @salida	        TINYINT OUT
AS
/*
Nombre             : pa_lo_interfaz_M_10lsacast_unix

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

   EXEC pa_lo_interfaz_M_10lsacast_unix '20140601',0

*/
DECLARE @sumatoria         CHAR(16),
        @num_reg           INT,
        @saldo_insoluto    FLOAT,
        @operacion         INT,
        @num_cuota         INT,
        @fecha_pago        SMALLDATETIME,
        @fecha_cart_venc   SMALLDATETIME,
        @fecha_vencimiento SMALLDATETIME,
        @ultimo_dia        DATETIME, --Ultimo día del mes         
        @cod_moneda        TINYINT,
        @reajuste          FLOAT 
        

SELECT @num_reg = COUNT(*)
  FROM leasecom..v_clientes a, 
        t_facturas fac,
        t_contratos b,
        leasecom..t_clientes d,
        t_castigos e         
   WHERE a.rut = b.rut_cliente
    AND b.rut_cliente = d.rut_cliente
    AND b.operacion   = e.operacion
    AND b.fecha_ingreso_cont <= @fecha_proceso
        




---- Cambiar el cursor para el campo @vreaj

SELECT @ultimo_dia = DATEADD(dd,-(DAY(@fecha_proceso)),@fecha_proceso)

CREATE TABLE #universo
	(
	operacion         INT,
	num_cuota         SMALLINT,
	fecha_pago        SMALLDATETIME,
--	fecha_cart_venc   SMALLDATETIME,
--	fecha_vencimiento SMALLDATETIME,
	reajuste          FLOAT 
	)



DECLARE c_cuotas CURSOR FOR
       
   SELECT tcd.operacion,
          f.cod_moneda_contrato,
          tcd.num_cuota,
          tc.fecha_pago,
          tcv.fecha_cart_venc,
          tc.fecha_vencimiento           
       FROM t_castigos_detalle tcd,
        t_cuotas_venc_detalle tcv,
        t_cuotas    tc,        
        t_contratos f         
   WHERE tcd.operacion = tc.operacion
    AND tcd.num_cuota = tc.num_cuota
    AND tcd.operacion = f.operacion
    AND f.cod_moneda_contrato <> 1
    AND tcd.operacion = tcv.operacion
    AND tcd.num_cuota = tcv.num_cuota
    AND isnull(tc.fecha_pago,'19000101') <> '19000101' 
    AND f.fecha_ingreso_cont <= @fecha_proceso
				  
OPEN c_cuotas

FETCH c_cuotas INTO @operacion, @cod_moneda,@num_cuota,@fecha_pago,@fecha_cart_venc,@fecha_vencimiento                                                            

WHILE @@FETCH_STATUS = 0 
 BEGIN
 

  SELECT @reajuste = valor
	      FROM leasecom..p_valor_paridades pp
	    WHERE pp.cod_moneda = @cod_moneda
	      AND pp.fecha      = @fecha_pago
    
  IF  @fecha_cart_venc > @fecha_vencimiento 
  BEGIN
	 IF  @fecha_vencimiento < @ultimo_dia
	  BEGIN 
	  	  
	   SELECT @reajuste = @reajuste-valor 
	      FROM leasecom..p_valor_paridades pp
	    WHERE pp.cod_moneda = @cod_moneda
	      AND pp.fecha = @fecha_vencimiento	    
	             
	  END 
	 ELSE 
	   BEGIN
	    SELECT @reajuste = @reajuste-valor 
	      FROM leasecom..p_valor_paridades pp
	    WHERE pp.cod_moneda = @cod_moneda
	      AND pp.fecha = @ultimo_dia	   
	    END  	     
   END
  ELSE 
   BEGIN 
      SELECT @reajuste = @reajuste-valor 
	      FROM leasecom..p_valor_paridades pp
	    WHERE pp.cod_moneda = @cod_moneda
	      AND pp.fecha = @fecha_cart_venc	   
   END   
   
   
    SELECT @reajuste =  @reajuste * tc.capital       
      FROM t_cuotas tc
    WHERE operacion = @operacion
      AND num_cuota  = @num_cuota  
   
   INSERT INTO #universo 
    SELECT 	@operacion,         
           	@num_cuota,         
           	@fecha_pago,        
            @reajuste
   
   FETCH c_cuotas INTO @operacion, @cod_moneda,@num_cuota,@fecha_pago,@fecha_cart_venc,@fecha_vencimiento                                                            

 END 
DEALLOCATE c_cuotas
-----


SELECT 'H'+
       'LSA'+       
       convert(CHAR(8),@fecha_proceso,112)+ --fecha_proc
       'castigos leasing'+
       replicate(' ',369)+--filler
       'F'+
       --DETALLE
      SUBSTRING(REPLICATE('0',9 -DATALENGTH(LTRIM(CONVERT(CHAR(9),b.rut_cliente))))+ LTRIM(CONVERT(CHAR(9),b.rut_cliente)),1,9)+--fald_nro_cli       	   
       a.dv+
       '130'+        
       dbo.Fn_TO(b.operacion,1)+ --tipo_oper
       replicate('0',3)+
       convert(CHAR(9),b.operacion)+
       '130'+
 	   dbo.Fn_TO(b.operacion,1)+
       convert(CHAR(9),b.operacion)+ --folio_cas
       SUBSTRING(REPLICATE('0',9 -DATALENGTH(LTRIM(CONVERT(CHAR(9),b.rut_cliente))))+ LTRIM(CONVERT(CHAR(9),b.rut_cliente)),1,9)+--rutri_cas       	   
       a.dv+--dveri_cas
       '0'+--tipo_deu
       str((tcd.monto_castigo*100),11,4)+
       convert(CHAR(8),tcd.fecha_castigo,112)+ 
       CASE b.cod_moneda_contrato
	        WHEN 1 THEN  '001'
	        WHEN 2 THEN  '098'
	        WHEN 4 THEN  '011' 
	   END+ 	
       convert(CHAR(8),b.fecha_ing_carta_recep,112)+ --fechax01
       (SELECT isnull(str(sum(cd.capital_castigo*cd.interes_castigo),14,3),replicate('',15)) 
	       FROM t_castigos_detalle cd
	       WHERE cd.operacion = b.operacion)+--saldo_capital_castigo
       str(tcd.cuota_castigo ,10,3)+            
       CASE b.cod_moneda_contrato WHEN 1 THEN  '1' 
         ELSE (SELECT convert(CHAR(10),p.valor)
				 FROM  leasecom..p_valor_paridades p,
				      t_contratos con
				WHERE con.operacion = b.operacion			        
				AND  con.cod_moneda_contrato = p.cod_moneda
				AND  con.fecha_ing_carta_recep = p.fecha )
        END+    
       '2'+
       REPLICATE('',11)+
       REPLICATE('0',16)+
       REPLICATE('0',16)+
       ' '+
       (SELECT  CASE WHEN tcd.fecha_castigo < tc.fecha_vencimiento 
               THEN str(tc.valor_cuota_total*100,11,4)  
               ELSE REPLICATE('0',8)
               END
          FROM t_cuotas tc
         WHERE tcd.operacion = tc.operacion 
           AND tcd.num_cuota = tc.num_cuota 
           AND tcd.periodo   = (SELECT max(periodo)
                                  FROM t_castigos_detalle tcb
                                 WHERE tcb.operacion = tcd.operacion
                                   AND tcb.num_cuota = tcd.num_cuota ) 
            )+  --casaanticipado
       (SELECT isnull(str(sum(cd.capital_castigo*cd.interes_castigo),12,3),replicate('',15)) 
	       FROM t_castigos_detalle cd
	       WHERE cd.operacion = b.operacion)+--montori
       (SELECT convert(CHAR(4),count(*)) FROM
            t_cuotas tc
          WHERE tc.operacion = b.operacion  )+ --total_cuotas
       (SELECT convert(CHAR(4),count(*)) 
          FROM t_castigos_detalle cd
          WHERE cd.operacion = b.operacion)+ --total_cuocas
	   (SELECT convert(CHAR(4),count(*)) FROM
            t_cuotas tc
          WHERE tc.operacion = b.operacion
            AND tc.estado IN (2,5)  )+ --totcuopag
	   (SELECT str(sum((tc.capital*tc.interes)),16,4) 
	      FROM t_cuotas tc
	     WHERE tc.operacion = b.operacion
	       AND tc.estado IN (2,5) )  +  --KxApagado
	   str(tcd.capital_castigo,10,4)+ --vamorpes
	   (SELECT  str(sum((tc.interes)),10,4) 
	      FROM t_cuotas tc
	     WHERE tc.operacion = b.operacion
	       AND tc.num_cuota = tcd.num_cuota
	       AND tcd.fecha_proceso   = (SELECT max(tcb.fecha_proceso)
                                 		FROM t_castigos_detalle tcb
                                       WHERE tcb.operacion = tcd.operacion
                                         AND tcb.num_cuota = tcd.num_cuota ) ) + --vintepes
       isnull((SELECT str(u.reajuste,10,4) 
          FROM #universo u,
               t_cuotas tc 
         WHERE u.operacion = b.operacion
           AND u.num_cuota = tc.num_cuota            
            ),convert(CHAR(10),''))+--vreaj
	   REPLICATE('0',14)+--vopro00
	   REPLICATE('0',14)+--vopro01
	   REPLICATE('0',14)+--vopro02
	   isnull((SELECT convert(CHAR(8),tc.fecha_pago,112)
	       FROM t_cuotas tc
	       WHERE tc.operacion = tcd.operacion
	         AND tc.num_cuota = tcd.operacion ),'00000000')+--fpago
	   'LSA'+--sistema
	   '8981548'+--ctacon
	   REPLICATE('',10)+--filler06   
	   (SELECT CASE  WHEN tc.fecha_vencimiento < @fecha_proceso 
	                 THEN convert(CHAR(8),tc.fecha_vencimiento,112)
	                 ELSE REPLICATE('0',8)
	           END 
	       FROM t_cuotas tc
	       WHERE tc.operacion = tcd.operacion
	         AND tc.num_cuota = tcd.num_cuota 
	         AND tcd.fecha_proceso   = (SELECT max(tcb.fecha_proceso)
                                 		FROM t_castigos_detalle tcb
                                       WHERE tcb.operacion = tcd.operacion
                                         AND tcb.num_cuota = tcd.num_cuota ))+ --fvenc
	   REPLICATE('',10)+--filler07	   
	   'F'+--filler08     
       --TRAILER
       'T'+
       'LSA'+ 
       convert(CHAR(8),@fecha_proceso,112)+
       'CASTIGOS LEASING'+
       convert(CHAR(7),@num_reg)+
        (SELECT str(sum((tc.valor_cuota_total)),16,4) 
	      FROM t_cuotas tc
	     WHERE tc.operacion = b.operacion
	       AND tc.estado IN (1,3) ) +
       REPLICATE('',343)+
       'F'       
       FROM leasecom..v_clientes a, 
        t_castigos_detalle tcd,
        t_contratos b,
        leasecom..t_clientes d,
        t_castigos e         
   WHERE a.rut = b.rut_cliente
    AND tcd.operacion = b.operacion 
    AND b.rut_cliente = d.rut_cliente
    AND b.operacion   = e.operacion
    AND b.fecha_ingreso_cont <= @fecha_proceso





RETURN 0


GRANT EXECUTE ON dbo.pa_lo_interfaz_M_10lsacast_unix TO Usuarios
GO


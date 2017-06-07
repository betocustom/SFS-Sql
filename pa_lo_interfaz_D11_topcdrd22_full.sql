USE leaseoper
GO

IF OBJECT_ID ('dbo.pa_lo_interfaz_D11_topcdrd22') IS NOT NULL
	DROP PROCEDURE dbo.pa_lo_interfaz_D11_topcdrd22
GO

CREATE PROCEDURE [dbo].[pa_lo_interfaz_D11_topcdrd22]
    @fecha_proceso  SMALLDATETIME ,
    @salida	    TINYINT OUT
AS
/*
Nombre             : pa_lo_interfaz_D11_topcdrd22

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

   EXEC pa_lo_interfaz_D11_topcdrd22 '16/12/2014',0

*/
--DECLARE @sumaKxA CHAR(16)
        
        
SET NOCOUNT ON


SELECT str(sum((c.capital*c.interes)),16,4) AS sumaKxA,
       convert(CHAR(15),'') AS sumaKxA_pend,
       c.operacion       
       INTO #sumKxA
       FROM t_cuotas c           
WHERE c.estado = 1
  AND c.operacion  NOT IN ( SELECT d.operacion 
                             FROM  t_castigos d 
                           WHERE c.operacion = d.operacion
                          )
  AND c.fecha_vencimiento <=  @fecha_proceso    
GROUP BY c.operacion


SELECT str(sum((c.capital*c.interes)),16,4) AS sumaKxA_pend,
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
   


SELECT   @fecha_proceso,
       a.rut,
       a.dv,
       @fecha_proceso,
       CASE b.clasificacion_cartera
							WHEN 1 THEN 
						       CASE b.cod_moneda_contrato
						        WHEN 1 THEN  '35520'
						        WHEN 2 THEN  '35500'
						        WHEN 3 THEN  '35510' 
						       END 	
							WHEN 2 THEN 
							   CASE b.cod_moneda_contrato
						        WHEN 1 THEN  '36020'
						        WHEN 2 THEN  '36000'
						        WHEN 3 THEN  '36610' 
						       END 
							WHEN 3 THEN 
							   CASE b.cod_moneda_contrato
						        WHEN 1 THEN  '37020'
						        WHEN 2 THEN  '37000'
						        WHEN 3 THEN  '37610'
						       END 
	   END, 			          --to,
	   (b.provision_material+ b.provision_gasto_legal+b.provision_seguros)-b.monto_pie, --total1
        SUBSTRING(REPLICATE('0',16 -DATALENGTH(RTRIM(CONVERT(CHAR(16),c.sumaKxA))))+ RTRIM(CONVERT(CHAR(16),c.sumaKxA)),1,16) AS total2,--total2,
       --reg_datos,
       '2',
       a.rut,
       a.dv,
       '130',--oficina,
       CASE b.clasificacion_cartera
							WHEN 1 THEN 
						       CASE b.cod_moneda_contrato
						        WHEN 1 THEN  '35520'
						        WHEN 2 THEN  '35500'
						        WHEN 3 THEN  '35510' 
						       END 	
							WHEN 2 THEN 
							   CASE b.cod_moneda_contrato
						        WHEN 1 THEN  '36020'
						        WHEN 2 THEN  '36000'
						        WHEN 3 THEN  '36610' 
						       END 
							WHEN 3 THEN 
							   CASE b.cod_moneda_contrato
						        WHEN 1 THEN  '37020'
						        WHEN 2 THEN  '37000'
						        WHEN 3 THEN  '37610'
						       END 
	   END, 			          --to,
       '00',--ppp_emb
       b.operacion, --num_docto
       --situa_cred
       SUBSTRING(REPLICATE('0',5 -DATALENGTH(RTRIM(CONVERT(CHAR(16),a.cod_act_eco))))+ RTRIM(CONVERT(CHAR(5),a.cod_act_eco)),1,5) AS activ_econ,--activ_econ,
       ( SELECT tgar.cod_tipo_garan
          FROM t_garantias_operacion tgaro,
               t_garantias tgar
         WHERE tgaro.num_garantia = tgar.num_garantia
           AND tgaro.operacion = b.operacion ),   --tipo_garant     
       d.clasif_riesgo_comercial,   --		clas_rgo_cred   
--		oper_ren        
	   b.fecha_ingreso_cont,	--fec_otor_cre    
	   REPLICATE('0',8),--fec_aprob_lin   
       REPLICATE('0',8),--fec_extin_lin   
       REPLICATE('0',8),--fec_resus_pag
      --fec_ult_renov  
       REPLICATE('0',8),--fec_paso_venc   
       REPLICATE('0',8),--fec_paso_ejec
      --fec_paso_cast
      (SELECT min(cuo.fecha_vencimiento) 
		   FROM t_cuotas cuo
		WHERE cuo.operacion = b.operacion
		  AND cuo.estado = 1
		  AND cuo.fecha_vencimiento >= @fecha_proceso ),   --fec_prox_venc
      (SELECT max(cuo.fecha_pago)
		   FROM t_cuotas cuo
		WHERE cuo.operacion = b.operacion
		  AND cuo.estado = 2),--fec_ult_pag_cap 
	  --fec_ult_pag_int 
      (SELECT min(cuo.fecha_vencimiento) 
		   FROM t_cuotas cuo
		WHERE cuo.operacion = b.operacion
		  AND cuo.estado = 1
		  AND cuo.fecha_vencimiento < @fecha_proceso),--fec_rez_mas_ant 
	  REPLICATE('0',8),--fec_imp_mas_ant 
	  --fec_ult_tasa   
	  --fec_penul_tasa  
	  --moneda_sbif  
	  b.cod_moneda_contrato, --moneda_cont     
	  --moneda_int      
	  (b.provision_material+ b.provision_gasto_legal+b.provision_seguros)-b.monto_pie,--mto_orig_mon    
	  --mto_ren_mon     
	  (SELECT min(cuo.capital) 
		   FROM t_cuotas cuo
		WHERE cuo.operacion = b.operacion
		  AND cuo.estado = 1
		  AND cuo.fecha_vencimiento >= @fecha_proceso ), --cap_prox_ven_mo 
	  (SELECT min(cuo.interes) 
		   FROM t_cuotas cuo
		WHERE cuo.operacion = b.operacion
		  AND cuo.estado = 1
		  AND cuo.fecha_vencimiento >= @fecha_proceso ), --int_prox_ven_mo 
	 REPLICATE('0',15),--seg_des_prx_ven 
	 REPLICATE('0',15),--seg_inc_prx_ven 
     REPLICATE('0',15),--comis_mhe_prx_v 
	 REPLICATE('0',15),--div_pror_prx_ve 
	--vig_mon         
	--mora_h29_mo     
	--mora_m30_h59_mo 
	--mora_m60_h89_mo 
	--mora_d90_mo     
	REPLICATE('0',15),--ixc_venc_mo     
	REPLICATE('0',15),--pre_jud_mo      
	REPLICATE('0',15),--ejec_mo         
	--vig_mn 
	REPLICATE('0',11),--ixc_venc_mn     
	REPLICATE('0',11),--pre_jud_mn      
	REPLICATE('0',11),--ejec_mn         
	REPLICATE('0',15),--vig_me          
	REPLICATE('0',15),--int_venc_me     
	REPLICATE('0',15),--pre_jud_me      
	REPLICATE('0',15),--ejec_me         
	REPLICATE('0',15),--in_vig_mo       
	REPLICATE('0',15),--in_mora_h29_mo  
	REPLICATE('0',15),--in_mora_m30_h59 
	REPLICATE('0',15),--in_mora_m60_h89 
	REPLICATE('0',15),--in_mora_d90_mo  
	REPLICATE('0',15),--ip_mora_h29_mo  
	REPLICATE('0',15),--ip_mora_m30_h59 
	REPLICATE('0',15),--ip_mora_m60_h89 
	REPLICATE('0',15),--ip_mora_d90_mo  
	REPLICATE('0',15),--ip_ixc_venc_mo  
	REPLICATE('0',15),--ip_pre_judic_mo 
	REPLICATE('0',15),--ip_ejec_mo      
	REPLICATE('0',15),--is_nok_ixc_vemo 
	REPLICATE('0',15),--is_nok_pre_jumo 
	REPLICATE('0',15),--is_nok_ejec_mo  
	REPLICATE('0',15),--is_nok_ixc_vemn 
	REPLICATE('0',15),--is_nok_pre_jumn 
	REPLICATE('0',15),--is_nok_ejec_mc  
	REPLICATE('0',11),--rs_nok_ixc_venc 
	REPLICATE('0',11),--rs_nok_pre_jud  
	--rs_nok_ejec_mc  
	--ppp_orig        
	--ppp_rdual       
	--cuot_cap_x_venc 
	REPLICATE('0',15),--cuot_int_x_venc 
	--cuot_atra
	REPLICATE('0',15),--cuot_venc       
	REPLICATE('0',15),--cuot_ejec       
	--cuot_pac        
	--prox_cuot       
	--tip_int         
	1, --mtdo_calc_int   	        
	--expre_tasa      
	--tip_base        
	--pto_sob_base    
	--tasa_real_aplic 
	--tasa_equi_aa    
	--cod_vari_tasa 	  
	REPLICATE('0',1),--tip_doc_sust    
	REPLICATE('0',5),--to_doc_sust     
	--num_doc_sust
	'130',--ofi_rea_cont    	
	'999',--ofi_pag         
	'130',--ofi_orig_otor   
	'1350',--tipo_cre        
	--est_cre         
	--causa_extincion 
	REPLICATE('0',1),--pzo_contab      
	REPLICATE('0',1),--ind_div_prorr   
	--parid_capit 
	REPLICATE('0',8),--fech_cpra_cart  
	REPLICATE('0',7),--tasa_dcto_cpra  
	--dif_pcio_cpra_c 
	--mto_ven_pag_mm  
	REPLICATE('0',15),--mto_ven_ren_mm  
	--ult_mto_pag_cap 
	--utl_mto_pag_int 
	REPLICATE('0',15),--mto_activ_x_ren 
	--prom_cap_vig_mo 
	--prom_cap_mor_mo 
	REPLICATE('0',15),--prom_cap_ven_mo 
	REPLICATE('0',15),--prom_int_morven 
	--intnor_reci_mes 
	--intpen_reci_mes 
	--rea_recib_mes   
	REPLICATE('0',11),--comision_mhe    
	REPLICATE('0',05),--trans_manuales  
	REPLICATE('0',05),--trans_automatic 
	'N',--ind_uso_cta_cte 
	REPLICATE('0',11),--numero_cta_cte  
	REPLICATE('0',01),--frec_pago       
	--seg_imp_mora_mo 
	--seg_imp_venc_mo 
	REPLICATE('0',13),--seg_imp_mora_mn 
	REPLICATE('0',13),--seg_imp_venc_mn 
	REPLICATE('0',5),--filler          
	REPLICATE('0',13)--llave_mhe
   FROM leasecom..v_clientes a,
        t_contratos b,
        #sumKxA c,
        leasecom..t_clientes d 
   WHERE a.rut = b.rut_cliente
    AND b.operacion = c.operacion
    AND b.rut_cliente = d.rut_cliente
    AND b.fecha_ingreso_cont <= @fecha_proceso





RETURN 0

GRANT EXECUTE ON dbo.pa_lo_interfaz_D11_topcdrd22 TO usuarios
GO



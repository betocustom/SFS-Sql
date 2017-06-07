USE leaseoper
GO

IF OBJECT_ID ('dbo.pa_lo_interfaz_M_32_LSA_LIBCOM_CVT') IS NOT NULL
	DROP PROCEDURE dbo.pa_lo_interfaz_M_32_LSA_LIBCOM_CVT
GO

CREATE PROCEDURE [dbo].[pa_lo_interfaz_M_32_LSA_LIBCOM_CVT]
    @fecha_proceso  SMALLDATETIME ,
    @salida	        TINYINT OUT
--    @mes    CHAR(2),
--    @ano    CHAR(4),
AS
/*
    Nombre             :    pa_lo_interfaz_M_32_LSA_LIBCOM_CVT

    Descripción        :    El objetivo es listar el libro de compras para el periodo señalado.

    Parámetros ent.    :    @mes, @ano

    Parámetros sal.    :    No tiene.

    Tablas entrada     :    leasecom..t_clientes_empresas,
                            leasecom..t_clientes_personas,
                            leasecom..t_operacion,
                            leasecom..t_proveedores, 
                            t_doc_prov,
                            t_nota_credito_debito

    Tablas salida      : 

    Fecha              :       

    Modificaciones     :    M1(Daniel Huenchumil) : 
                            Se incorpora actualización para el campo operación de la tabla temporal, 
                            además se comenta actualización anterior que estaba errónea. 
                            Se omiten cartas de crédito ( tipo_docum = 10 )
                            MCJ 2014-09-08 Se adapata para interfaz M-32 de libro de compras 
    Procedimientos que Llama :    

    Observaciones          :

    Autor           :           

    Ejecucion           :

    exec pa_lo_interfaz_M_32_LSA_LIBCOM_CVT '20140131',0

*/
SET NOCOUNT ON


DECLARE @c_interno      INT,    @c_afecto       FLOAT,  @c_iva          FLOAT,  @c_marca        CHAR(3), 
        @factor         FLOAT,  @s_r            FLOAT,  @n_r            FLOAT,  @c_num_docum    INT,
        @c_rut_p        INT,    @num_factura    INT,    @existe_adm     INT,
        @num_reg        INT,    @mes            CHAR(2),@ano            CHAR(4), @rut_contri  CHAR(9)
        

SELECT @mes = substring(convert(CHAR(6),@fecha_proceso,112),5,2)
SELECT @ano = convert(CHAR(4),@fecha_proceso,112)
        
        
 
CREATE TABLE #infinal (
    numero_interno  INT,
    rut_proveedor   INT,
    dig_proveedor   CHAR(1),
    num_docum       INT,
    fecha_emision   SMALLDATETIME,
    nombre          CHAR(100),
    afecto_exento   FLOAT,
    iva             FLOAT,
    neto            FLOAT,
    total           FLOAT,
    estado          TINYINT,
    operacion       NUMERIC(20,0), 
    reconocido      TINYINT,
    tipo_docum      TINYINT,
    marca           CHAR(3), 
    recuperable     FLOAT,   
    no_recuperable  FLOAT,   
    porcentaje      FLOAT,
    id_documento 	INT,
    tipo_doc_desc 	CHAR(25),
    es_electronico  CHAR(2),
    cod_rubro		SMALLINT )   
    
CREATE INDEX m ON #infinal(numero_interno)

INSERT  #infinal
SELECT	t_doc_prov.numero_interno,
        t_doc_prov.rut_proveedor,
        digito=SPACE(1),
        ISNULL(t_doc_prov.num_docum, 0),
        t_doc_prov.fecha_emision,
        razon_social=SPACE(40),
        ISNULL(t_doc_prov.exento, 0),
        ISNULL(t_doc_prov.iva, 0),
        ISNULL(t_doc_prov.neto,0),
        ISNULL(t_doc_prov.iva + t_doc_prov.neto,0),
        t_doc_prov.estado,
        t_doc_prov_operacion.operacion,
        0,
        0,
        marca='NEG', 
        recuperable=0,   
        no_recuperable=0, 
        porcentaje=0,
        t_doc_prov.id_documento,
		desc_valor,
		CASE  es_electronico
			WHEN 0 THEN 'NO'
			ELSE 'SI'
		END,
		NULL
  FROM	t_doc_prov, t_doc_prov_operacion,leasecom..t_columnas_detalle cd
  WHERE	t_doc_prov.tipo_docum in (3,6,9 /*,10*/)      --M1
  AND   SUBSTRING(CONVERT(CHAR(10),t_doc_prov.numero_interno),1,6) = @ano*100+@mes 
  AND   t_doc_prov.id_documento = t_doc_prov_operacion.id_documento 
  AND	cd.id_columna = 2848 AND tipo_docum = cd.valor
--    solo facturas ingresadas en LS	
  AND	t_doc_prov.fecha_ingreso > (SELECT fecha_inicio FROM leaseoper..p_parametros WHERE cod_param = 350)	

UNION

SELECT  ISNULL(numero_interno,1),
        rut_proveedor,
        digito = SPACE(1),
        ISNULL(num_docum,0),
        fecha_emision,
        razon_social = SPACE(40),
        (ISNULL(exento,0)*-1),
        (iva*-1),(neto*-1),
        (ISNULL(exento,0)+iva+neto)*-1,
        t_nota_credito_debito.estado,
        NULL,   --1,
        0,
        tipo_docum,
        marca = 'NCR', 
        recuperable = 0,   
        no_recuperable = 0, 
        porcentaje = 0,
        0,
		desc_valor,
		'NO',
		NULL
  FROM	t_nota_credito_debito,leasecom..t_columnas_detalle cd
  WHERE	tipo_docum = 1    -- nota credito
  AND	SUBSTRING(CONVERT(CHAR(10),t_nota_credito_debito.numero_interno),1,6)=@ano*100+@mes 
  AND	cd.id_columna=2848 AND tipo_docum = cd.valor
--    solo facturas ingresadas en LS	
  AND	t_nota_credito_debito.fecha_ingreso > (SELECT fecha_inicio from leaseoper..p_parametros where cod_param = 350)	

UNION

SELECT	ISNULL(numero_interno,1),
        rut_proveedor,
        digito = SPACE(1),
        ISNULL(num_docum,0),
        fecha_emision,
        razon_social = SPACE(40) ,
        ISNULL(exento,0),
        iva,neto,
        ISNULL(exento,0)+iva+neto,
        t_nota_credito_debito.estado,
        NULL,           --1,
        0,
        tipo_docum,
        marca = 'NCR', 
        recuperable = 0,   
        no_recuperable = 0, 
        porcentaje = 0,
        0,
		desc_valor,
		'NO',
		NULL
  FROM	t_nota_credito_debito,leasecom..t_columnas_detalle cd
  WHERE	tipo_docum in (2, 3 ,9)		 -- nota debito
  AND	SUBSTRING(CONVERT(CHAR(10),t_nota_credito_debito.numero_interno),1,6) = @ano*100+@mes 
  AND	cd.id_columna=2848 AND tipo_docum = cd.valor
--    solo facturas ingresadas en LS	
  AND	t_nota_credito_debito.fecha_ingreso > (SELECT fecha_inicio from leaseoper..p_parametros where cod_param = 350)	
 		
/* Inicio M1 Daniel Huenchumil */

/*
UPDATE           #infinal
    SET    #infinal.operacion = t_doc_prov_operacion.operacion
    FROM   t_doc_prov_operacion
    WHERE       #infinal.operacion          = 1                        AND
                #infinal.id_documento            = t_doc_prov_operacion.id_documento
*/
UPDATE	#infinal
  SET	operacion = dpo.operacion
  FROM	leaseoper..t_nota_credito_debito ndc, leaseoper..t_doc_prov dp,
		leaseoper..t_doc_prov_operacion dpo, #infinal tmp
  WHERE	ndc.num_factura = dp.num_docum 
  AND	ndc.rut_proveedor = dp.rut_proveedor 
  AND	dp.id_documento = dpo.id_documento
  AND	ndc.num_docum = tmp.num_docum
/* Fin M1 Daniel Huenchumil */

/* Actualiza Rubro */
SELECT	a.rut_proveedor, a.num_factura, a.cod_rubro, Sum(a.valor_libro_inicial_mat) AS VALOR
  INTO	#Rubros
  FROM	leaseoper..t_bienes_detalle a, #infinal b
  WHERE a.rut_proveedor = b.rut_proveedor
  AND   a.num_factura = b.num_docum		  --operacion = 5040083009000002232
GROUP BY a.rut_proveedor, a.num_factura, a.cod_rubro

SELECT	a.rut_proveedor, a.num_factura, a.cod_rubro
  INTO	#Rubros_Final
  FROM	#Rubros a
  WHERE a.valor = (SELECT MAX(valor) FROM #Rubros b WHERE a.rut_proveedor = b.rut_proveedor AND a.num_factura = b.num_factura )

UPDATE	#infinal
  SET	cod_rubro = b.cod_rubro
  FROM	#infinal a, #Rubros_Final b
  WHERE	a.rut_proveedor = b.rut_proveedor
  AND	a.num_docum = b.num_factura
/* Fin de actualiza rubro */
--********************************************************************************************************************************************
IF (SELECT COUNT(*) FROM #infinal WHERE reconocido = 0) > 0
BEGIN
    IF EXISTS(SELECT * FROM #infinal a, leasecom..t_proveedores b WHERE a.rut_proveedor = b.rut)

		UPDATE  #infinal
          SET	dig_proveedor = digito,
                nombre        = UPPER(leasecom..t_proveedores.razon_social),
                reconocido    = 1
          FROM	leasecom..t_proveedores
          WHERE	reconocido    = 0 
          AND	rut_proveedor <> 1 
          AND	rut_proveedor = leasecom..t_proveedores.rut
 
	IF EXISTS(SELECT * FROM #infinal a, leasecom..p_brokers b WHERE a.rut_proveedor = b.rut)
 
		UPDATE  #infinal
          SET	dig_proveedor = digito,
                nombre        = UPPER(leasecom..p_brokers.nombre),
                reconocido    = 1
		  FROM	leasecom..p_brokers
          WHERE	reconocido    = 0 
          AND	rut_proveedor <> 1 
          AND	rut_proveedor = leasecom..p_brokers.rut
 
	IF EXISTS(SELECT * FROM #infinal a, leasecom..p_tasadores b WHERE a.rut_proveedor = b.rut)
 
		UPDATE  #infinal
          SET	dig_proveedor = digito,
                nombre        = UPPER(leasecom..p_tasadores.nombre),
                reconocido    = 1
		  FROM	leasecom..p_tasadores
		  WHERE reconocido     = 0 
		  AND	rut_proveedor <> 1 
		  AND	rut_proveedor = leasecom..p_tasadores.rut

END
 
IF (SELECT COUNT(*) FROM #infinal WHERE reconocido = 0) > 0
BEGIN
	UPDATE	#infinal
	  SET	rut_proveedor = rut_cliente
	  FROM	leasecom..t_operacion
	  WHERE	#infinal.rut_proveedor = 1 
	  AND	#infinal.operacion     = leasecom..t_operacion.operacion
 
	IF (SELECT COUNT(*) FROM #infinal WHERE reconocido = 0) > 0
 
		UPDATE  #infinal
          SET	dig_proveedor = digito,
                nombre        = UPPER(RTRIM(nombres)+' '+RTRIM(apellido_p)+' '+RTRIM(apellido_m)),
                reconocido    = 1
          FROM	leasecom..t_clientes_personas
          WHERE reconocido = 0 
          AND	rut        = rut_proveedor
 
	IF (SELECT COUNT(*) FROM #infinal WHERE reconocido = 0) > 0
 
		UPDATE	#infinal
          SET	dig_proveedor   = digito,
                nombre                 = UPPER(RTRIM(razon_social)),
                reconocido                = 1
          FROM	leasecom..t_clientes_empresas
          WHERE	reconocido = 0 
          AND	rut        = rut_proveedor
 
END
 
UPDATE  #infinal
  SET	afecto_exento = neto,
        neto = 0
  WHERE	iva IN (NULL,0)   
  AND	neto <> 0   
  AND	afecto_exento = 0 
  AND	tipo_docum    = 0
 
UPDATE  #infinal
  SET	nombre        = 'ANULADA',
        afecto_exento = 0,
        neto          = 0,
        iva           = 0,
        total         = 0
  WHERE	estado = 9
 
SELECT	@factor = porcentaje
  FROM	leaseoper..t_cierre_mensual
  WHERE tipo_libro = 1  
  AND	periodo    = CONVERT(INT, @ano*100+@mes)
 
IF @@rowcount=0
   SELECT @factor = 100.00
 
IF @factor = 0
   SELECT @factor = 100.00
 
UPDATE #infinal
   SET porcentaje = @factor
 
DELETE #infinal where numero_interno <= 200304
 
DECLARE c_recup CURSOR FOR
SELECT	numero_interno,
		afecto_exento,
		iva,
		marca,
		num_docum,
		rut_proveedor
  FROM	#infinal
 
OPEN c_recup
 
FETCH c_recup INTO @c_interno,@c_afecto,@c_iva, @c_marca,@c_num_docum,@c_rut_p
 
WHILE @@FETCH_STATUS = 0
BEGIN
	IF @c_marca = 'NCR'
	BEGIN
		SELECT @num_factura = 0
 
		SELECT	@num_factura = num_factura
          FROM	leaseoper..t_nota_credito_debito
          WHERE num_docum     = @c_num_docum 
          AND	rut_proveedor = @c_rut_p
 
		SELECT @c_marca = 'NEG'
 
		UPDATE	#infinal
          SET	marca  = @c_marca
          WHERE numero_interno = @c_interno
 
	END
	
	IF @c_marca = 'NEG'
	BEGIN
		IF ABS(@c_iva) > 0
		BEGIN
			UPDATE	#infinal
              SET	recuperable    = @c_iva,
                    no_recuperable = 0
			  WHERE numero_interno = @c_interno
		END
	END

	ELSE

	BEGIN
		SELECT @s_r = 0
		SELECT @n_r = 0
		
		SELECT @s_r = (@c_iva * @factor)/100
		SELECT @n_r = @c_iva - @s_r
		
		UPDATE	#infinal
          SET	recuperable    = @s_r,
                no_recuperable = @n_r
          WHERE numero_interno = @c_interno
 
	END
 
	FETCH c_recup INTO @c_interno,@c_afecto,@c_iva, @c_marca,@c_num_docum,@c_rut_p
END
 
CLOSE c_recup
DEALLOCATE c_recup
 
SELECT  numero_interno,
		RTRIM(CONVERT(CHAR(10),rut_proveedor))+'-'+dig_proveedor rut,
		num_docum,
		fecha_emision,
		nombre,
		afecto_exento,
		iva,
		neto,
		afecto_exento+iva+neto total,
		periodo = @mes+'/'+@ano,
		recuperable,
		no_recuperable,
		marca,
		porcentaje,
		tipo_doc_desc,
		es_electronico ,
		operacion,
		cod_rubro,
		nom_rubro = CONVERT(CHAR(40), '')
  INTO	#presalida
  FROM	#infinal
ORDER BY fecha_emision

UPDATE	#presalida
  SET	nom_rubro = b.descripcion
  FROM	#presalida a, leasecom..p_rubros b
  WHERE	a.cod_rubro = b.cod_rubro

--SELECT  numero_interno,
--        MAX(rut),
--        MAX(num_docum),
--        MAX(fecha_emision),
--        MAX(nombre),
--        MAX(afecto_exento),
--        MAX(iva),
--        MAX(neto),
--        MAX(total),
--        MAX(periodo),
--        MAX(recuperable),
--        MAX(no_recuperable),
--        MAX(marca),
--        MAX(porcentaje),
--		MAX(tipo_doc_desc),
--	 	MAX(es_electronico),
--        MAX(operacion),
--        MAX(cod_rubro),
--        MAX(nom_rubro)
--  FROM	#presalida
-- GROUP BY numero_interno
--ORDER BY MAX(fecha_emision)


SELECT @num_reg = count(*)
FROM	#presalida


SELECT @rut_contri = SUBSTRING(REPLICATE('0',9 -DATALENGTH(LTRIM(CONVERT(CHAR(9),p.monto))))+ LTRIM(CONVERT(CHAR(9),p.monto)),1,9)
  FROM p_parametros p
 WHERE cod_param = 200


SELECT '1'+
       @rut_contri +   
       dbo.f_retorna_dv(@rut_contri)+
       @rut_contri +  
       dbo.f_retorna_dv(@rut_contri)+
       convert(CHAR(6),@fecha_proceso,112)+--fecha_proc        
       '20041231'+
       '123456'+
       'COMPRA'+
       'MENSUAL'+
       'TOTAL'+
       REPLICATE('0',3)+
       REPLICATE('0',10)+
       REPLICATE('0',385)+
       --[Detalle]--  
       '2'+       
       CASE dp.tipo_docum WHEN 3 THEN '030' --ps.tipo_doc_desc       
       WHEN 1 THEN '060'
       WHEN 2 THEN '055'
       WHEN 4 THEN '032'
       END+ --fald_tipo_doc
       convert(CHAR(10),ps.num_docum)+--fald_folio
       '1'+
       ISNULL(str(porc_impuesto,3,2),'0')+ --fald_tasa_imp
	   convert(CHAR(8),ps.fecha_emision,112)+	--fald_fecha_doc     
	   SUBSTRING(REPLICATE('0',9 -DATALENGTH(LTRIM(CONVERT(CHAR(9),dp.rut_proveedor))))+ LTRIM(CONVERT(CHAR(9),dp.rut_proveedor)),1,9)+--fald_nro_cli       	   
	    '-'+--fald_gio_cli       	   
		leasecom.dbo.fn_obtiene_digito_rut(dp.rut_proveedor)+--fald_dig_cli       
		CASE  WHEN a.rut_cliente > 50000000
           THEN   convert(CHAR(12),(SELECT razon_social
                    FROM leasecom..t_clientes_empresas
                   WHERE rut = a.rut_cliente))
         ELSE 
              isnull((SELECT  CONVERT(CHAR(10),RTRIM(nombres )+SPACE(1)+RTRIM(apellido_p)+SPACE(1)+RTRIM(apellido_m))
                FROM leasecom..t_clientes_personas
              WHERE rut = a.rut_cliente),REPLICATE('',12)) 
         END + --fald_nom_razon    
		str(ps.afecto_exento,18,0)+--fald_mto_exen  mto_exen      
		str(ps.neto,18,0)+--fald_mto_neto           
		str(ps.iva,18,0)+ --fald_mto_iva           
		str(ps.neto,18,0)+--fald_mto_neto_af   
		str(ps.iva,18,0)+ --fald_mto_iva_af    
		'0'+ --fald_cod_nrec1     
		REPLICATE('0',18)+--fald_mto_iva_nrec1 
		REPLICATE('0',18)+--fald_mto_iva_uscom 
		str(ps.total,18,0)+--fald_mto_total     
		REPLICATE('0',224)+--fald_filler        
		--Trailler        
		'4'+
		CASE dp.tipo_docum WHEN 3 THEN '030'
	       WHEN 1 THEN '060'
	       WHEN 2 THEN '055'
	       WHEN 4 THEN '032'
	    END+ --fald_tipo_doc
	    isnull(convert(CHAR(01),dp.tipo_impuesto),'1')+--falt_tipo_imp
	    convert(CHAR(10),(SELECT count(*)
	       FROM #presalida
	      WHERE ps.afecto_exento > 0 ))+ --falt_ope_exe
	    isnull((SELECT str(sum(pe.afecto_exento),18,0)
	       FROM #presalida pe
	      WHERE pe.afecto_exento > 0 ),	REPLICATE('0',18))+
       (SELECT str(sum(pe.neto),18,0)
	       FROM #presalida pe )+
        str(@num_reg,10,0)+ --falt_can_doc
        (SELECT str(sum(pe.iva),18,0)
	       FROM #presalida pe )+
       (SELECT convert(CHAR(10),count(*))
	       FROM #presalida pe
	      WHERE pe.afecto_exento = 0 )+       
	  (SELECT str(sum(pe.total),18,0)
	       FROM #presalida pe 
	         WHERE pe.afecto_exento = 0)+
      (SELECT str(sum(pe.iva),18,0)
	       FROM #presalida pe 
	         WHERE pe.afecto_exento = 0)+ 
	  REPLICATE('0',145)+
	  REPLICATE('0',10)+
	  REPLICATE('0',18)+
	  REPLICATE('0',6)+
	  REPLICATE('0',18)+       
      (SELECT str(sum(pe.total),18,0)
	       FROM #presalida pe )+
	  REPLICATE('0',102)      	          
FROM   #presalida ps,
       t_doc_prov dp,
       t_contratos a
WHERE ps.num_docum = dp.num_docum       
  AND ps.operacion = a.operacion
   





RETURN 0

GRANT EXECUTE ON dbo.pa_lo_interfaz_M_32_LSA_LIBCOM_CVT TO Usuarios
GO


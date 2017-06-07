USE leaseoper
GO

IF OBJECT_ID ('dbo.pa_lo_genera_td27') IS NOT NULL
	DROP PROCEDURE dbo.pa_lo_genera_td27
GO

CREATE PROCEDURE [dbo].[pa_lo_genera_td27]
@periodo_pcs     INT,
@salida          INT OUT
AS 
/*
Nombre            : pa_lo_genera_td27

Descripción       : Generación de archivo D27, morosidad de clientes.

Parametros entrada: @fecha_proceso:

Parametros salida : Ninguno.

Tablas entrada    : 

Tablas salida     : 

Fecha             : Enero 2009.

Modificaciones    : 

Procedimientos que Llama : 

Observaciones     :    

Autor             : D. Huenchumil 

Ejecucion         :  


EXEC pa_lo_genera_td27 201407, 0 

SELECT * FROM leaseoper..t_d27 where periodo=201307 order by rut, morosidad

SELECT * FROM leaseoper..t_d27 where periodo=201307 and tipo_arrendatario=9
SELECT sum(monto) FROM leaseoper..t_d27 where periodo=201307 ;

*/
SET NOCOUNT ON 
--
DECLARE 
    @fecha_cierre_mes SMALLDATETIME,
    @valor_us         FLOAT,
    @valor_uf         FLOAT

-- ----------------------------------------------------------------------------------------
SELECT @fecha_cierre_mes = CONVERT(SMALLDATETIME, '01-' + SUBSTRING(CONVERT(VARCHAR(6), @periodo_pcs), 5, 2) + '-' + SUBSTRING(CONVERT(VARCHAR(6), @periodo_pcs), 1, 4), 103)
SELECT @fecha_cierre_mes = DATEADD(DAY, -1, DATEADD(MONTH, 1, @fecha_cierre_mes))
SELECT @fecha_cierre_mes = CONVERT(SMALLDATETIME, CONVERT(VARCHAR(10), @fecha_cierre_mes, 103), 103)
-- ----------------------------------------------------------------------------------------

CREATE TABLE #tmp_cod_mora
(cod_mora    TINYINT     NOT NULL,
 mora_ini    SMALLINT    NOT NULL,
 mora_fin    INT        NULL,
 descripcion VARCHAR(50) NOT NULL)

CREATE INDEX #idx_cmora_01 ON #tmp_cod_mora (cod_mora)
--
CREATE TABLE #tmp_d27
(
 operacion    NUMERIC(20) NOT NULL, 
 cod_moneda   SMALLINT    NOT NULL,
 rut          INT         NOT NULL, 
 dv           CHAR(1)     NOT NULL, 
 cliente      CHAR(50)    NOT NULL, 
 tipo_arr     TINYINT     NOT NULL,
 interes_dev  FLOAT           NULL
 )
CREATE INDEX #idx_d27_01 ON #tmp_d27 (operacion)

--
CREATE TABLE #tmp_cuo_d27
(operacion          NUMERIC(20)   NOT NULL, 
 cod_tipo_cuota     TINYINT       NOT NULL,
 num_cuota          SMALLINT      NOT NULL,
 valor_cuota_total  FLOAT         NOT NULL,
 capital            FLOAT         NOT NULL,
 interes            FLOAT         NOT NULL,
 iva                FLOAT         NOT NULL,
 fecha_vencimiento  SMALLDATETIME NOT NULL,
 d_mora             SMALLINT      NOT NULL,
 t_mora             TINYINT       NOT NULL,
 monto_$            FLOAT         NOT NULL, 
 estado             TINYINT       NOT NULL)
CREATE INDEX #idx_cd27_01 ON #tmp_cuo_d27 (operacion, cod_tipo_cuota, num_cuota)
--
CREATE TABLE #tmp_mov_d27
(operacion          NUMERIC(20)   NOT NULL, 
 cod_tipo_cuota     TINYINT       NOT NULL,
 num_cuota          SMALLINT      NOT NULL,
 valor_cuota_total  FLOAT         NOT NULL,
 capital            FLOAT         NOT NULL,
 interes            FLOAT         NOT NULL,
 iva                FLOAT         NOT NULL,
 fecha_pago         SMALLDATETIME NULL)
CREATE INDEX #idx_md27_01 ON #tmp_mov_d27 (operacion, cod_tipo_cuota, num_cuota)
--
CREATE TABLE #tmp_dmora 
(operacion NUMERIC(20) NOT NULL,
 dmora SMALLINT NOT NULL,
 fecha_venc SMALLDATETIME NOT NULL)
CREATE INDEX #idx_dmora_01 ON #tmp_dmora (operacion)
--
--****************************************************************************************
------------------------------------------------------------------------------------------
SELECT @valor_uf = valor
 FROM leasecom..p_valor_paridades 
WHERE fecha = @fecha_cierre_mes
  AND cod_moneda = 2
IF ISNULL(@valor_uf, 0) = 0
BEGIN 
  RAISERROR  ('No existe paridad UF a la fecha de cierre.',16,1)
  SELECT @salida = 1
  RETURN @salida
END 
--
SELECT @valor_us = valor
 FROM leasecom..p_valor_paridades 
WHERE fecha = @fecha_cierre_mes
  AND cod_moneda = 4
IF ISNULL(@valor_us, 0) = 0
BEGIN 
    RAISERROR ('No existe paridad Dolar a la fecha de cierre.',16,1)
    SELECT @salida = 1
    RETURN @salida
END 

/*
 0 Crédito al día 
 1 Menos de 30 días 
 2 30 días o más, pero menos de 60 días 
 3 60 días o más, pero menos de 90 días 
 4 90 días o más, pero menos de 180 días 
 5 180 días o más, pero menos de un año 
 6 Un año o más, pero menos de dos años 
 7 Dos años o más, pero menos de 3 años 
 8 Tres años o más, pero menos de 4 años 
 9 Cuatro años o más
*/
--
INSERT INTO #tmp_cod_mora VALUES(0, 0,    0,    'Crédito al Día')
INSERT INTO #tmp_cod_mora VALUES(1, 1,    29,   'Menos de 30 días')
INSERT INTO #tmp_cod_mora VALUES(2, 30,   59,   '30 días o más, pero menos de 60 días')
INSERT INTO #tmp_cod_mora VALUES(3, 60,   89,   '60 días o más, pero menos de 90 días')
INSERT INTO #tmp_cod_mora VALUES(4, 90,   179,  '90 días o más, pero menos de 180 días')
INSERT INTO #tmp_cod_mora VALUES(5, 180,  364,  '180 días o más, pero menos de un año')
INSERT INTO #tmp_cod_mora VALUES(6, 365,  729,  'Un año o más, pero menos de dos años')
INSERT INTO #tmp_cod_mora VALUES(7, 730,  1094, 'Dos años o más, pero menos de tres años')
INSERT INTO #tmp_cod_mora VALUES(8, 1095, 1459, 'tres años o más, pero menos de cuatro años')
INSERT INTO #tmp_cod_mora VALUES(9, 1460, 40000,'cuatro años o más')

--
--
INSERT INTO #tmp_d27
SELECT c.operacion,
       c.cod_moneda_contrato,
       c.rut_cliente,
       ' ', -- DV
       'No Registrado', -- Cliente
       9, -- Tipo Arriendo
       0  --interes devengado.
 FROM leaseoper..t_contratos c, leaseoper..t_contratos_anexo x, leaseoper.dbo.t_d21 d
WHERE c.operacion = x.operacion 
  AND c.operacion = d.operacion
  AND d.periodo = @periodo_pcs
  --AND (c.estado_operacion = 2 OR (c.estado_operacion = 3 AND CONVERT(CHAR(08), x.fecha_termino_real,112) > @fecha_cierre_mes))
  --AND CONVERT(CHAR(08), c.fecha_ingreso_cont,112) <= @fecha_cierre_mes
  --AND (SELECT COUNT(1) FROM leaseoper..t_contratos_castigados cas WHERE cas.operacion=c.operacion)=0

-- ----------------------------------------------------------------------------------------
INSERT INTO #tmp_cuo_d27
SELECT cuo.operacion, 
       cuo.cod_tipo_cuota, 
       cuo.num_cuota, 
       cuo.valor_cuota_total, 
       cuo.capital,
       cuo.interes, 
       cuo.iva, 
       cuo.fecha_vencimiento, 
       0, 
       0, 
       cuo.estado,
       0
 FROM leaseoper..t_cuotas cuo, #tmp_d27 t
WHERE cuo.operacion = t.operacion 
  AND cuo.estado IN (1, 3)         -- CUOTRAS PENDIENTES DE PAGO O CUOTAS CON ABONO
--  AND cuo.valor_cuota_total > 0.01 -- NO CONSIDERA CUOTAS DE PERIODOS DE GRACIA

------------------------------------------------------------------------------------------
-- Carga Abonos de cuotas
INSERT INTO #tmp_mov_d27
SELECT mov.operacion, 
       mov.cod_tipo_cuota, 
       mov.num_cuota, 
       SUM(mov.valor_cuota_total), 
       SUM(mov.capital), 
       SUM(mov.interes), 
       SUM(mov.iva), 
       NULL
FROM leaseoper..t_cuotas_mov mov, #tmp_cuo_d27 cuo
WHERE cuo.operacion      = mov.operacion 
  AND cuo.cod_tipo_cuota = mov.cod_tipo_cuota 
  AND cuo.num_cuota      = mov.num_cuota 
  AND cuo.estado = 3 -- P. Parcial
GROUP BY mov.operacion, mov.cod_tipo_cuota, mov.num_cuota

------------------------------------------------------------------------------------------
-- Rebaja Abonos de cuotas
UPDATE #tmp_cuo_d27
  SET #tmp_cuo_d27.valor_cuota_total = #tmp_cuo_d27.valor_cuota_total - mov.valor_cuota_total, 
      #tmp_cuo_d27.capital           = #tmp_cuo_d27.capital - mov.capital, 
      #tmp_cuo_d27.interes           = #tmp_cuo_d27.interes - mov.interes, 
      #tmp_cuo_d27.iva               = #tmp_cuo_d27.iva - mov.iva
 FROM #tmp_mov_d27 mov
WHERE mov.operacion      = #tmp_cuo_d27.operacion 
  AND mov.cod_tipo_cuota = #tmp_cuo_d27.cod_tipo_cuota
  AND mov.num_cuota      = #tmp_cuo_d27.num_cuota
  
------------------------------------------------------------------------------------------
-- Calcula morosidad por cuota
UPDATE #tmp_cuo_d27
  SET d_mora = CASE WHEN DATEDIFF(DAY, fecha_vencimiento, @fecha_cierre_mes) <= 0 THEN 0 ELSE DATEDIFF(DAY, fecha_vencimiento, @fecha_cierre_mes) END

------------------------------------------------------------------------------------------
-- Determina codigo de morosidad por cuota
UPDATE #tmp_cuo_d27
  SET t_mora = x.cod_mora
 FROM #tmp_cod_mora x
WHERE #tmp_cuo_d27.d_mora >= x.mora_ini 
  AND #tmp_cuo_d27.d_mora <= x.mora_fin

------------------------------------------------------------------------------------------
-- Valoriza montos 
--UPDATE #tmp_cuo_d27
  --SET monto_$ = CASE WHEN x.cod_moneda = 2 THEN (valor_cuota_total) * @valor_uf
  --                   WHEN x.cod_moneda = 4 THEN (valor_cuota_total) * @valor_us
  --                   ELSE (valor_cuota_total)
  --              END
-- FROM #tmp_d27 x
--WHERE x.operacion = #tmp_cuo_d27.operacion 

--
UPDATE #tmp_cuo_d27
  SET monto_$ = CASE WHEN x.cod_moneda = 2 THEN (capital) * @valor_uf
                     WHEN x.cod_moneda = 4 THEN (capital) * @valor_us
                     ELSE capital
                END
 FROM #tmp_d27 x
WHERE x.operacion = #tmp_cuo_d27.operacion 
  AND t_mora = 0 

--
UPDATE #tmp_cuo_d27
  SET monto_$ = CASE WHEN x.cod_moneda = 2 THEN (capital+interes) * @valor_uf
                     WHEN x.cod_moneda = 4 THEN (capital+interes) * @valor_us
                     ELSE capital+interes
                END
 FROM #tmp_d27 x
WHERE x.operacion = #tmp_cuo_d27.operacion 
  AND t_mora > 0 


------------------------------------------------------------------------------------------
--UPDATE #tmp_d27 
--  SET cliente = CONVERT(CHAR(50), cli.nombre),
--      dv      = cli.dv
-- FROM leasecom..v_clientes cli
--WHERE cli.rut = #tmp_d27.rut
--
UPDATE #tmp_d27 
  SET cliente = LEFT( LTRIM(UPPER(cli.razon_social)),50),
      dv      = cli.digito
 FROM #tmp_d27 a, leasecom..t_clientes_empresas cli
WHERE a.rut = cli.rut
--
UPDATE #tmp_d27 
  SET cliente = LEFT( LTRIM( UPPER( LTRIM(RTRIM(cli.apellido_p))+'/'+LTRIM(RTRIM(cli.apellido_m))+'/'+LTRIM(RTRIM(cli.nombres)) )), 50),
      dv      = cli.digito
 FROM #tmp_d27 a, leasecom..t_clientes_personas cli
WHERE a.rut = cli.rut

--
-- ----------------------------------------------------------------------------------------
DELETE FROM leaseoper..t_d27 WHERE periodo = @periodo_pcs
-- ----------------------------------------------------------------------------------------
--
--
-- Clientes Relacionados
UPDATE #tmp_d27
  SET tipo_arr = 8
 FROM #tmp_d27 a, leaseoper..t_clientes_relacionados b
WHERE a.rut    = b.rut        
  AND b.periodo = (SELECT MAX(c.periodo) FROM leaseoper..t_clientes_relacionados c WHERE c.periodo<=@periodo_pcs)
--
--
SELECT @periodo_pcs AS 'periodo_pcs', 
       d27.operacion,
       d27.rut, 
       d27.dv,  
       d27.cliente,
       d27.tipo_arr,
       cuo.t_mora,
       ROUND(SUM(cuo.monto_$), 0) AS 'monto_$'
 INTO #d27_oper
 FROM #tmp_d27 d27, #tmp_cuo_d27 cuo
WHERE d27.operacion = cuo.operacion 
GROUP BY d27.operacion, d27.rut, d27.dv, d27.cliente, d27.tipo_arr, cuo.t_mora
ORDER BY rut, t_mora
--
UPDATE #d27_oper
  SET monto_$ = monto_$ + b.int_deven_$
 FROM #d27_oper a, leaseoper.dbo.t_interes_dev b
WHERE a.operacion = b.operacion
  AND a.t_mora = 0
  AND b.periodo = @fecha_cierre_mes
--
--
/*
INSERT INTO leaseoper..t_d27
SELECT @periodo_pcs, 
       d27.rut, 
       d27.dv,  
       d27.cliente,
       d27.tipo_arr,
       cuo.t_mora,
       ROUND(SUM(cuo.monto_$), 0),
       GETDATE()
FROM #tmp_d27 d27,
     #tmp_cuo_d27 cuo
WHERE d27.operacion = cuo.operacion 
GROUP BY d27.rut, 
         d27.dv,  
         d27.cliente,
         d27.tipo_arr,
         cuo.t_mora
ORDER BY rut, t_mora
*/

--
INSERT INTO leaseoper..t_d27
SELECT @periodo_pcs, 
       d27.rut, 
       d27.dv,  
       d27.cliente,
       d27.tipo_arr,
       t_mora,
       ROUND(SUM(d27.monto_$), 0),
       GETDATE()
 FROM #d27_oper d27
GROUP BY d27.rut, 
         d27.dv,  
         d27.cliente,
         d27.tipo_arr,
         t_mora
ORDER BY rut, t_mora
IF @@ERROR <> 0 
BEGIN
    RAISERROR  ('Error al ingresar en tabla D27.',16,1)
    SELECT @salida = 1
    RETURN @salida
END

--
------------------------------------------------------------------------------------------
DELETE FROM leaseoper..t_d27 
WHERE periodo = @periodo_pcs
  AND ISNULL(monto,0) <= 0

------------------------------------------------------------------------------------------
DROP TABLE #tmp_cod_mora
DROP TABLE #tmp_d27
DROP TABLE #tmp_cuo_d27
DROP TABLE #tmp_mov_d27
DROP TABLE #tmp_dmora
------------------------------------------------------------------------------------------
SELECT @salida = 0
RETURN @salida
------------------------------------------------------------------------------------------
RETURN




GO


GRANT EXECUTE ON dbo.pa_lo_genera_td27 TO Usuarios
GO


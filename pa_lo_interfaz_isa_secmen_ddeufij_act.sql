USE [leaseoper]
GO
/****** Object:  StoredProcedure [dbo].[pa_lo_interfaz_isa_secmen_ddeufij_act]    Script Date: 06/03/2014 16:20:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/****** Objeto:  procedimiento almacenado dbo.pa_lo_interfaz_isa_secmen_ddeufij_act    fecha de la secuencia de comandos: 09-07-2007 9:25:28 ******/
ALTER PROCEDURE [dbo].[pa_lo_interfaz_isa_secmen_ddeufij_act]
@fecha_proceso	   SMALLDATETIME,
@salida            INT OUTPUT
AS
/*
Nombre            :  pa_lo_interfaz_isa_secmen_ddeufij_act

Descripción       : Interfaz contratos clientes leasing

Parametros entrada: @fecha_proceso:

Parametros salida :  Ninguno.

Tablas entrada    :  t_contratos 

Tablas salida     :  Archivo plano.

Fecha             :  Julio 2014.

Modificaciones    :

Procedimientos que Llama :

Observaciones      :  

Autor              : Verónica Inzunza.

Ejecucion          :  

EXEC leaseoper..pa_lo_interfaz_isa_secmen_ddeufij_act '19/03/2014',0
EXEC leaseoper..pa_lo_interfaz_isa_secmen_ddeufij_act '24/03/2014',0

05/03/2007 15:33
*/
set nocount on
--

DECLARE  
	@operacion          INT,
	@rut_cliente        INT,
	@cod_moneda         TINYINT,
	@cod_oficina		SMALLINT,
	@num_contrato		INT, 
	@tasa_variable		FLOAT,
	@tasa_spred			FLOAT,
	@tasa_real			FLOAT,
	@cla_cartera		INT,
	@tipo_tasa			CHAR(1),
	@id_tip_inv			CHAR(1),
	@fec_extin_pac		CHAR(8),
	@id_mto_deriva		CHAR(1),
	@filler				CHAR(4),
	@id_tip_inv_sbif	CHAR(1),
	@filler2			CHAR(14),
	@filler3			CHAR(4),
	@filler4			CHAR(3),
	@filler5			CHAR(1),
	@tipo_reg			CHAR(1),
	@ppp_emb			CHAR(2),
	@capital			FLOAT, 
	@interes			FLOAT,
	@capital_s			CHAR(15), 
	@interes_s			CHAR(15),
	@ident_oper			CHAR(22),
	@total_reg			INT,
	@dv					CHAR(1),
	@id_cliente			INT,
	@oficina			CHAR(2),
	@cliente			CHAR(5),
	@contrato			CHAR(3),
	@tipo_oper			CHAR(5),
	@moneda				CHAR(3),
	@fec_suspen			CHAR(8),
	@fec_camb_tasa		CHAR(8),
	@modo_tasa			CHAR(1),
	@fec_extin_cred		CHAR(8),
	@plzo_contable		CHAR(2),
	@k_x_vencer			float,
	@k_mora				float,
	@cart_vencida		float,
	@iva_devengado		float,
	@int_devengado		float,
	@cod_tipo_per		int,
	@cod_tipo_tasa		INT,
	@fecha_inicio		CHAR(8),
	@fec_termino		CHAR(8) 

--
--
IF @fecha_proceso IS NULL OR @fecha_proceso = '01/01/1900'
BEGIN
   SELECT @salida = 0
   --RAISERROR 20000 'Debe Ingresar Periodo a Procesar'
   RETURN 1
END
--
--
CREATE TABLE #contratos(
	tipo_reg		CHAR(1) NULL,	
	rut				CHAR(9) NULL,
	dv				CHAR(1) NULL,
	oficina			CHAR(3) NULL,
	cartera			CHAR(5) NULL,
	ppp_emb			CHAR(2) NULL,
	num_docto		CHAR(9) NULL,
	ident_cli		CHAR(22) NULL,
	moneda			CHAR(3) NULL,
	fec_suspen		CHAR(8) NULL,
	fec_camb_tasa	CHAR(8) NULL,
	tipo_tasa		CHAR(1) NULL,
	modo_tasa		CHAR(1) NULL,
	tasa_real		CHAR(7) NULL,
	fec_inicio		CHAR(8) NULL,	
	fec_extin_cred	CHAR(8)	NULL,
	plzo_contable	CHAR(2) NULL,
	capital_vencer	CHAR(15) NULL,
	capital_mora	CHAR(15) NULL,
	cart_vencida	CHAR(15) NULL,
	iva_devengado	CHAR(15) NULL,	
	int_devengado	CHAR(15) NULL,
	id_tip_inv		CHAR(1) NULL,
	fec_extin_pac	CHAR(8) NULL,
	id_mto_deriva	CHAR(1) NULL,
	filler			CHAR(4) NULL,
	id_tip_inv_sbif	CHAR(1) NULL,
	filler2			CHAR(14) NULL,
	filler3			CHAR(4) NULL,
	filler4			CHAR(3) NULL,
	filler5			CHAR(1) NULL)


CREATE TABLE #trailer(
salida CHAR(210) NULL)

SET @id_tip_inv			= REPLICATE(' ',1)
SET @fec_extin_pac		= REPLICATE('0',8)
SET @id_mto_deriva		= REPLICATE(' ',1)
SET @filler				= REPLICATE(' ',4)
SET @id_tip_inv_sbif	= REPLICATE(' ',1)
SET @filler2			= REPLICATE(' ',14)
SET @filler3			= REPLICATE('0',4)
SET @filler4			= REPLICATE(' ',3)
SET @filler5			= REPLICATE(' ',1)
SET @ppp_emb			= REPLICATE('0',2)
SET @fec_suspen			= REPLICATE('0',8)
SET @plzo_contable		= REPLICATE('0',2)

SET @tipo_reg = 'D'

-- Cursor que recorre todos los contratos Vigentes y sus cuotas sin mora

DECLARE c_cto CURSOR LOCAL FOR
SELECT a.operacion,
	a.rut_cliente,
	a.cod_moneda_contrato,
	a.cod_oficina_real, 
	a.num_contrato,
	a.tasa_variable,
	a.tasa_spread,
	a.clasificacion_cartera,
	a.cod_tipo_tasa
FROM   leaseoper..t_contratos a
--WHERE  --a.estado_operacion = 2 --contrato vigente
  ---AND  a.estado in (1,3) -- estado cuota vigente y p.parcial
 --YEAR(a.fecha_ing_carta_recep)      = YEAR(@fecha_proceso)
 --AND MONTH(a.fecha_ing_carta_recep) = MONTH(@fecha_proceso)
OPEN c_cto
FETCH  c_cto INTO @operacion, @rut_cliente, @cod_moneda, @cod_oficina, @num_contrato,@tasa_variable,@tasa_spred,@cla_cartera,@cod_tipo_tasa
WHILE (@@FETCH_STATUS = 0)
BEGIN
		
	--dv

	SELECT @dv = ISNULL(dv,' ')
	FROM leasecom..v_clientes
	WHERE rut = @rut_cliente
	
	--identificacion de la operación 
	
	SELECT @id_cliente = ISNULL(id_cliente,0)
	FROM dbo.t_datos_cliente_banco
	WHERE lberut = @rut_cliente
	
	SET @oficina = REPLICATE('0', 2 - LEN(RTRIM(CONVERT(char(2),@cod_oficina)))) + RTRIM(CONVERT(char(2),@cod_oficina)) 
	SET @cliente = REPLICATE('0', 5 - LEN(RTRIM(convert(char(5),@id_cliente )))) + RTRIM(convert(char(5),@id_cliente )) 
	SET @contrato = REPLICATE('0', 3 - LEN(RTRIM(convert(char(3),@num_contrato)))) + RTRIM(convert(char(3),@num_contrato)) 

	SET @ident_oper = @oficina + @cliente + @contrato

	--cartera
	    IF @cla_cartera = 1 --comercial
        BEGIN
			IF @cod_moneda = 1 --pesos
				SET @tipo_oper = '35520'
			IF @cod_moneda = 2 --uf
				SET @tipo_oper = '35500'
			IF @cod_moneda = 4 --us
				SET @tipo_oper = '35510' 
		END
		
		IF @cla_cartera = 2 --consumo
        BEGIN
			IF @cod_moneda = 1 --pesos
				SET @tipo_oper = '36020'
			IF @cod_moneda = 2 --uf
				SET @tipo_oper = '36000'
			IF @cod_moneda = 4 --us
				SET @tipo_oper = '36610'
		END
		
		IF @cla_cartera = 3 --vivienda
        BEGIN
			IF @cod_moneda = 1 --pesos
				SET @tipo_oper = '37020'
			IF @cod_moneda = 2 --uf
				SET @tipo_oper = '37000'
			IF @cod_moneda = 4 --us
				SET @tipo_oper = '37610'
		END
		
		--moneda
		IF @cod_moneda = 1
		SET @moneda = '001'
		ELSE
		BEGIN
			IF @cod_moneda = 2
				SET @moneda = '098'
			ELSE
			BEGIN
				IF @cod_moneda = 4
					SET @moneda = '994'
				ELSE
					SET @moneda = 0
			END
		END

		--fecha repactacion t_repactacion ????
		SELECT @fec_camb_tasa = CONVERT(CHAR(8),MAX(fecha_proceso),112)
		FROM dbo.t_repactacion
		WHERE operacion = @operacion
		

		--tipo tasa fija, variable
		/*  1   	Fija                                                                                                
			2   	Libor 360                                                                                           
			3   	Libor 180                                                                                           
			4   	NULL
			5   	Tab 90*/
			
		SELECT @cod_tipo_tasa = ISNULL(cod_tipo_tasa,0)
		FROM dbo.t_contratos
		WHERE operacion = @operacion
		
		IF @cod_tipo_tasa = 1
			SET @tipo_tasa = 'F'
		ELSE
			SET @tipo_tasa = 'V'
			
		--modalidad tasa anual,mensual 
		/*	1   	Mensual                                                                                             
			2   	Bimensual                                                                                           
			3   	Trimestral                                                                                          
			4   	Semestral                                                                                           
			5   	Anual*/ 
		
		SELECT @cod_tipo_per = ISNULL(cod_tipo_periodo_arr,0)
		FROM dbo.t_contratos
		WHERE operacion = @operacion

		IF @cod_tipo_per = 1
			SET @modo_tasa = 'M'
		ELSE
		BEGIN
			IF @cod_tipo_per = 5
				SET @modo_tasa = 'A'
			ELSE
				SET @modo_tasa = ' '
		END                                                                                               

		--tasa real
		SET @tasa_real = ISNULL(@tasa_variable,0) + ISNULL(@tasa_spred,0)
		
		--fecha activación contrato t_contratos_contab ??? operacion se puede repetir
		SELECT @fecha_inicio = CONVERT(CHAR(8),fecha_contab,112)
		FROM dbo.t_contratos_contab
		WHERE operacion = @operacion
		AND estado = 2
		
		--fecha extincion contrato
		SELECT @fec_termino = CONVERT(CHAR(08),MAX(fecha_vencimiento),112)
		FROM dbo.t_cuotas
		WHERE operacion = @operacion
		AND cod_tipo_cuota = 2		
		
		--capital por vencer
		SELECT @k_x_vencer = SUM(capital) 
		FROM dbo.t_cuotas
		WHERE operacion = @operacion
		AND estado IN (1,3) --indica que esta impaga
		AND fecha_vencimiento > @fecha_proceso
		
		--capital en mora hasta 90 días
		SELECT @k_mora = SUM(capital) 
		FROM dbo.t_cuotas
		WHERE operacion = @operacion
		AND estado IN (1,3) --indica que esta impaga
		AND fecha_vencimiento < @fecha_proceso
		AND DATEDIFF(dd,fecha_vencimiento,@fecha_proceso) < 90
		
		--capital en mora igual o superior 90 días
		SELECT @cart_vencida = SUM(capital) 
		FROM dbo.t_cuotas
		WHERE operacion = @operacion
		AND estado IN (1,3) --indica que esta impaga
		AND fecha_vencimiento < @fecha_proceso
		AND DATEDIFF(dd,fecha_vencimiento,@fecha_proceso) > = 90
		
		--iva de la cuota ????
		SELECT @iva_devengado = SUM(iva) 
		FROM dbo.t_cuotas
		WHERE operacion = @operacion
		AND fecha_vencimiento < @fecha_proceso
		
		--interes de la cuota 
		SELECT @int_devengado = (int_moroso_$ + int_deven_$)
		FROM t_interes_dev
		WHERE operacion = @operacion
		AND periodo = @fecha_proceso


   -- Insertar registro.
    INSERT INTO #contratos
    VALUES( ISNULL(@tipo_reg,' '),
			ISNULL(@rut_cliente,' '),
			ISNULL(@dv,' '),
			ISNULL(@cod_oficina,' '),
			ISNULL(@tipo_oper,' '),
			ISNULL(@ppp_emb,' '),
			ISNULL(@operacion,' '),
			ISNULL(@ident_oper ,' '),
			ISNULL(@moneda,' '),
			ISNULL(@fec_suspen,'00000000'),
			ISNULL(@fec_camb_tasa,'00000000'),
			isnull(@tipo_tasa,' '),
			isnull(@modo_tasa,' '),
			ISNULL(@tasa_real,' '),
			ISNULL(@fecha_inicio,'00000000'),
			ISNULL(@fec_extin_cred,'19000101'),
			ISNULL(@plzo_contable,' '),
			ISNULL(@k_x_vencer,0),
			ISNULL(@k_mora,0),
			ISNULL(@cart_vencida,0),
			ISNULL(@iva_devengado,0),
			ISNULL(@int_devengado,0),
			ISNULL(@id_tip_inv,' '),
			ISNULL(@fec_extin_pac,'00000000'),
			ISNULL(@id_mto_deriva,' '),
			ISNULL(@filler,' '),
			ISNULL(@id_tip_inv_sbif,' '),
			ISNULL(@filler2,' '),
			ISNULL(@filler3,' '),
			ISNULL(@filler4,' '),
			ISNULL(@filler5,' '))
FETCH  c_cto INTO @operacion, @rut_cliente, @cod_moneda, @cod_oficina, @num_contrato,@tasa_variable,@tasa_spred,@cla_cartera,@cod_tipo_tasa

END
CLOSE c_cto
DEALLOCATE c_cto

SET @total_reg = (SELECT COUNT(*) FROM #contratos)

SELECT 
	tipo_reg		+
	REPLICATE('0', 9 - LEN(RTRIM(rut))) + RTRIM(rut) +
	rtrim(dv)   +
	REPLICATE('0', 3 - LEN(LTRIM(RTRIM(oficina)))) + LTRIM(RTRIM(oficina)) + 
	REPLICATE('0', 5 - LEN(LTRIM(RTRIM(cartera)))) + LTRIM(RTRIM(cartera)) + 
	ppp_emb	+
	REPLICATE('0', 9 - LEN(LTRIM(RTRIM(num_docto)))) + LTRIM(RTRIM(num_docto)) + 
	REPLICATE('0', 22 - LEN(LTRIM(RTRIM(ident_cli)))) + LTRIM(RTRIM(ident_cli)) + 
	REPLICATE('0', 3 - LEN(LTRIM(RTRIM(moneda)))) + LTRIM(RTRIM(moneda)) + 
	fec_suspen + 
	REPLICATE('0', 8 - LEN(LTRIM(RTRIM(fec_camb_tasa)))) + LTRIM(RTRIM(fec_camb_tasa)) + 
	REPLICATE('0', 1 - LEN(LTRIM(RTRIM(tipo_tasa)))) + LTRIM(RTRIM(tipo_tasa)) + 
	REPLICATE('0', 1 - LEN(LTRIM(RTRIM(modo_tasa)))) + LTRIM(RTRIM(modo_tasa)) + 
	REPLICATE('0', 7 - LEN(LTRIM(RTRIM(tasa_real)))) + LTRIM(RTRIM(tasa_real)) + 
	REPLICATE('0', 8 - LEN(LTRIM(RTRIM(fec_inicio)))) + LTRIM(RTRIM(fec_inicio)) + 
	REPLICATE('0', 8 - LEN(LTRIM(RTRIM(fec_extin_cred)))) + LTRIM(RTRIM(fec_extin_cred)) + 
	plzo_contable + 
	REPLICATE('0', 15 - LEN(LTRIM(RTRIM(capital_vencer)))) + LTRIM(RTRIM(capital_vencer)) + 
	REPLICATE('0', 15 - LEN(LTRIM(RTRIM(capital_mora)))) + LTRIM(RTRIM(capital_mora)) + 
	REPLICATE('0', 15 - LEN(LTRIM(RTRIM(cart_vencida)))) + LTRIM(RTRIM(cart_vencida)) + 
	REPLICATE('0', 15 - LEN(LTRIM(RTRIM(iva_devengado)))) + LTRIM(RTRIM(iva_devengado)) + 
	REPLICATE('0', 15 - LEN(LTRIM(RTRIM(int_devengado)))) + LTRIM(RTRIM(int_devengado)) + 
	id_tip_inv + 
	fec_extin_pac + 
	id_mto_deriva	+
	filler			+
	id_tip_inv_sbif	+
	filler2			+
	filler3			+
	filler4			+
	filler5			AS reg
INTO #final
FROM #contratos

insert into #final
SELECT 'C' + 
		'LSA' + 
		CONVERT(CHAR(08),@fecha_proceso,112) + 
		REPLICATE(' ', 198) 

insert into #trailer
SELECT 'T' + 
		replicate('0' , 7 - LEN(CONVERT(VARCHAR(7),@total_reg)))  + CONVERT(VARCHAR(7),@total_reg) +
		REPLICATE(' ', 202) 
	
SELECT reg
FROM #final
union
SELECT salida
FROM #trailer

RETURN 0

GRANT EXEC ON pa_lo_interfaz_isa_secmen_ddeufij_act TO Usuarios











USE leaseoper
GO

IF OBJECT_ID ('dbo.f_retorna_dv') IS NOT NULL
	DROP FUNCTION dbo.f_retorna_dv
GO

CREATE FUNCTION [dbo].[f_retorna_dv] (@ElNumero AS VARCHAR(8))
RETURNS VARCHAR(1)
AS
BEGIN
	DECLARE @Resultado AS CHAR(2)
	DECLARE @Multiplicador AS INT

	SET @Multiplicador = 2

	DECLARE @iNum AS INT

	SET @iNum = 0

	DECLARE @Suma AS INT

	SET @Suma = 0

	DECLARE @recorre AS INT

	SET @recorre = len(ltrim(rtrim(@ElNumero)))

	WHILE (@recorre >= 1)
	BEGIN
		SET @iNum = substring(@ElNumero, @recorre, 1)
		SET @Suma = @Suma + (@iNum * @Multiplicador)
		SET @Multiplicador = @Multiplicador + 1

		IF (@Multiplicador = 8)
			SET @Multiplicador = 2
		SET @recorre = @recorre - 1
	END

	SET @Resultado = rtrim(11 - (@Suma % 11))

	IF (@Resultado = '10')
		SET @Resultado = 'K'

	IF (@Resultado = '11')
		SET @Resultado = '0'

	RETURN ltrim(rtrim(@Resultado))
END


GO


GRANT EXECUTE ON dbo.fn_CodSigir TO Usuarios
GO 


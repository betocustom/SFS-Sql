USE leaseoper
GO

IF OBJECT_ID ('dbo.t_d27') IS NOT NULL
	DROP TABLE dbo.t_d27
GO

CREATE TABLE dbo.t_d27
	(
	periodo           INT NOT NULL,
	rut               INT NOT NULL,
	dv                CHAR (1) NOT NULL,
	cliente           CHAR (50) NOT NULL,
	tipo_arrendatario CHAR (1) NOT NULL,
	morosidad         TINYINT NOT NULL,
	monto             FLOAT NOT NULL,
	fecha_reg         SMALLDATETIME NOT NULL,
	CONSTRAINT pk_d27 PRIMARY KEY (periodo, rut, morosidad)
	)
GO


GRANT DELETE ON dbo.t_d27 TO Usuarios
GO

GRANT INSERT ON dbo.t_d27 TO Usuarios
GO

GRANT SELECT ON dbo.t_d27 TO Usuarios
GO
GRANT UPDATE ON dbo.t_d27 TO Usuarios
GO


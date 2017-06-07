
USE leasecom
go
IF OBJECT_ID('dbo.v_clientes') IS NOT NULL
BEGIN
    DROP VIEW dbo.v_clientes
    IF OBJECT_ID('dbo.v_clientes') IS NOT NULL
        PRINT '<<< FAILED DROPPING VIEW dbo.v_clientes >>>'
    ELSE
        PRINT '<<< DROPPED VIEW dbo.v_clientes >>>'
END
go
CREATE VIEW [dbo].[v_clientes]
AS
SELECT     TOP (100) PERCENT rut, dv, nombre, ejecutivo_cartera, cod_act_eco, giro, fecha_constitucion, email, telefono_1, contacto, direccion,cod_comuna
FROM         (SELECT     a.rut_cliente AS rut, c.digito AS dv, LTRIM(RTRIM(c.nombres)) + ' ' + LTRIM(RTRIM(c.apellido_p)) + ' ' + LTRIM(RTRIM(c.apellido_m)) AS nombre, 
                                              a.ejecutivo_cartera, c.cod_act_eco,
                                                  (SELECT     Descripcion
                                                    FROM          dbo.t_giros
                                                    WHERE      (ID = ISNULL(c.cod_giro, 0))) AS giro, c.fecha_nacimiento AS fecha_constitucion, c.email, c.telefono_1, c.contacto, c.direccion, c.cod_comuna
                       FROM          dbo.t_clientes AS a INNER JOIN
                                              dbo.t_clientes_personas AS c ON a.rut_cliente = c.rut
                       UNION
                       SELECT     a.rut_cliente AS rut, b.digito AS dv, LTRIM(RTRIM(b.razon_social)) AS nombre, a.ejecutivo_cartera, b.cod_act_eco,
                                                 (SELECT     Descripcion
                                                   FROM          dbo.t_giros AS t_giros_1
                                                   WHERE      (ID = ISNULL(b.cod_giro, 0))) AS giro, b.fecha_creacion, b.email, b.telefono_1, b.contacto, b.direccion,b.cod_comuna
                       FROM         dbo.t_clientes AS a INNER JOIN
                                             dbo.t_clientes_empresas AS b ON a.rut_cliente = b.rut) AS derivedtbl_1
ORDER BY nombre
go
IF OBJECT_ID('dbo.v_clientes') IS NOT NULL
    PRINT '<<< CREATED VIEW dbo.v_clientes >>>'
ELSE
    PRINT '<<< FAILED CREATING VIEW dbo.v_clientes >>>'
go
GRANT SELECT ON dbo.v_clientes TO Usuarios
go

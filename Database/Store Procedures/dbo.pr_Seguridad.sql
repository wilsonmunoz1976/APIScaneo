USE [dbJardiesaDC]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS(SELECT 1 FROM sysobjects WHERE id=OBJECT_ID('dbo.pr_Seguridad') AND type='P')
BEGIN
   EXEC ('CREATE PROCEDURE dbo.pr_Seguridad AS BEGIN RETURN 0 END')
END
GO

ALTER PROCEDURE dbo.pr_Seguridad
    @i_accion        varchar(2),
    @i_usuario       varchar(15)    = null,
    @i_password      varchar(15)    = null,
    @o_msgerror      varchar(200)   = '' OUTPUT 
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @w_password varchar(15)
    DECLARE @w_id       float
    DECLARE @w_nombres  varchar(100)
	DECLARE @w_email    varchar(200)

    IF @i_accion = 'EM'
    BEGIN
        SELECT ci_empresa, 
               tx_empresa
          FROM dbo.rolt_Empresa
        SELECT @o_msgerror = 'Consulta Ok'
    END

    IF @i_accion = 'LO'
    BEGIN
        IF ISNULL(@i_password,'')=''
        BEGIN
            SELECT @o_msgerror = 'Password vacío'
            RETURN -1
        END

        SELECT @w_password = tx_contrasena,
               @w_id       = CONVERT(INT,(RAND() * 100)),
               @w_nombres  = tx_usuario,
			   @w_email    = tx_correo
          FROM dbo.ssatUsuario
		  LEFT JOIN dbo.ssatCorreoUsuarios
		    ON ssatUsuario.ci_usuario = ssatCorreoUsuarios.ci_usuario
         WHERE ci_usuariointegrado = @i_usuario
        
        IF @@ROWCOUNT = 0
        BEGIN
            SELECT @o_msgerror = 'Usuario no existente'
            RETURN -2
        END

        If @i_password != @w_password
        BEGIN
            SELECT @o_msgerror = 'Contraseña incorrecta'
            RETURN -3
        END
        SELECT ci_usuario, 
               cod_aplicacion = ssatTransaccionxUsuario.ci_aplicacion,  
               cod_modulo = '0000', 
               des_modulo = (SELECT TOP 1 tx_transaccion from dbo.ssatTransaccion WHERE ci_aplicacion=ssatTransaccionxUsuario.ci_aplicacion AND ci_transaccion='0000'),
               cod_opcion = ssatTransaccion.ci_transaccion,  
               num_opcion = 0,  
               des_opcion = ssatTransaccion.tx_transaccion,
               permisos   = ssatTransaccionxUsuario.tx_permisos
          FROM dbo.ssatTransaccionxUsuario
         INNER JOIN dbo.ssatTransaccion
            ON ssatTransaccion.ci_aplicacion  = ssatTransaccionxUsuario.ci_aplicacion 
           AND ssatTransaccion.ci_transaccion = ssatTransaccionxUsuario.ci_transaccion 
           AND ssatTransaccion.ci_mayor != 'r'
         WHERE ssatTransaccionxUsuario.ci_usuario    = @i_usuario 
           AND ssatTransaccionxUsuario.ci_aplicacion = 'MOV'

        IF @@ROWCOUNT = 0
        BEGIN
            SELECT @o_msgerror = 'Usuario sin permisos asignados'
            RETURN -4
        END

        SELECT nom_parametro = ci_parametro,
               val_parametro = tx_parametro, 
               des_parametro = tx_descripcion 
          FROM dbo.ssatParametrosGenerales
         WHERE ci_aplicacion='MOV'

        IF @@ROWCOUNT = 0
        BEGIN
            SELECT @o_msgerror = 'La empresa no tiene registrado el parametro de Rango Horario de Emergencia'
            RETURN -5
        END

       SELECT  Id=@w_id, Nombres= @w_nombres, Email = @w_email

       SELECT @o_msgerror = 'Login correcto'
    END

    RETURN 0
END
GO

IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE major_id=OBJECT_ID('dbo.pr_Seguridad') and name='@i_accion')
   EXEC sp_dropextendedproperty  @name = '@i_accion' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'PROCEDURE', @level1name = 'pr_Seguridad'
GO
EXEC sys.sp_addextendedproperty @name=N'@i_accion', @value=N'Loginname de acceso' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'pr_Seguridad'
GO

IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE major_id=OBJECT_ID('dbo.pr_Seguridad') and name='@i_password')
   EXEC sp_dropextendedproperty  @name = '@i_password' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'PROCEDURE', @level1name = 'pr_Seguridad'
GO
EXEC sys.sp_addextendedproperty @name=N'@i_password', @value=N'Contraseña de acceso' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'pr_Seguridad'
GO

IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE major_id=OBJECT_ID('dbo.pr_Seguridad') and name='@o_msgerror')
   EXEC sp_dropextendedproperty  @name = '@o_msgerror' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'PROCEDURE', @level1name = 'pr_Seguridad'
GO
EXEC sys.sp_addextendedproperty @name=N'@o_msgerror', @value=N'Mensaje de respuesta del SP' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'pr_Seguridad'
GO

IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE major_id=OBJECT_ID('dbo.pr_Seguridad') and name='descripcion')
   EXEC sp_dropextendedproperty  @name = 'descripcion' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'PROCEDURE', @level1name = 'pr_Seguridad'
GO
EXEC sys.sp_addextendedproperty @name=N'descripcion', @value=N'SP para manejar la parte de seguridad de la APIRest' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'pr_Seguridad'
GO

dbo.sp_help pr_Seguridad
GO

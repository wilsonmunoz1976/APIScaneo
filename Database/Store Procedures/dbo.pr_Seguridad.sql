USE [dbJardinesEsperanza]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF EXISTS(SELECT 1 FROM sysobjects WHERE id = OBJECT_ID('dbo.pr_Seguridad') and type='P')
   DROP PROCEDURE dbo.pr_Seguridad
GO

CREATE PROCEDURE dbo.pr_Seguridad
    @i_accion        varchar(2),
    @i_usuario       varchar(15)    = null,
    @i_password      varchar(15)    = null,
    @o_msgerror      varchar(200)   = '' OUTPUT 
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @w_password varchar(15)
	DECLARE @w_id  float
	DECLARE @w_nombres varchar(100)

    IF @i_accion = 'EM'
    BEGIN
        SELECT ci_empresa, 
               tx_empresa
          FROM dbo.setEmpresa
        SELECT @o_msgerror = 'Consulta Ok'
    END

    IF @i_accion = 'LO'
    BEGIN
        IF ISNULL(@i_password,'')=''
        BEGIN
            SELECT @o_msgerror = 'Password vacío'
            RETURN -1
        END

        SELECT @w_password = tx_contraseña,
		       @w_id = ci_empleado,
			   @w_nombres = tx_usuario
          FROM dbo.setUsuario
         INNER JOIN dbo.setUsuarioEmpresa
            ON setUsuarioEmpresa.ci_usuario = setUsuario.ci_usuario
         WHERE setUsuario.ci_usuario = @i_usuario
        
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
        SELECT setPermisosUsuario.ci_usuario, 
               cod_aplicacion = setPermisosUsuario.ci_nivel0,  
               cod_modulo = setPermisosUsuario.ci_nivel1, 
               des_modulo = (SELECT TOP 1 tx_nivel1 from setMenuNivel1 WHERE ci_nivel0=setPermisosUsuario.ci_nivel0 AND ci_nivel1=setPermisosUsuario.ci_nivel1),
               cod_opcion = setPermisosUsuario.ci_nivel2,  
               num_opcion = setPermisosUsuario.ci_nivel3,  
               des_opcion = setMenuNivel3.tx_nivel3,
               permisos   = setPermisosUsuario.tx_permisos
          FROM dbo.setPermisosUsuario
         INNER JOIN dbo.setUsuarioEmpresa
            ON setUsuarioEmpresa.ci_usuario  = setPermisosUsuario.ci_usuario
         INNER JOIN dbo.setMenuNivel3
            ON setMenuNivel3.ci_nivel0       = setPermisosUsuario.ci_nivel0
           AND setMenuNivel3.ci_nivel1       = setPermisosUsuario.ci_nivel1
           AND setMenuNivel3.ci_nivel2       = setPermisosUsuario.ci_nivel2
           AND setMenuNivel3.ci_nivel3       = setPermisosUsuario.ci_nivel3
         WHERE setPermisosUsuario.ci_usuario = @i_usuario 
           AND setPermisosUsuario.ci_nivel0  = 'MOV'

        IF @@ROWCOUNT = 0
        BEGIN
            SELECT @o_msgerror = 'Usuario sin permisos asignados'
            RETURN -4
        END

        SELECT nom_parametro = ci_parametro,
               val_parametro = tx_parametro, 
               des_parametro = tx_descripcion 
          FROM dbo.setParametrosGenerales
         WHERE ci_empresa='000' 
           AND ci_aplicacion='MOV'

        IF @@ROWCOUNT = 0
        BEGIN
            SELECT @o_msgerror = 'La empresa no tiene registrado el parametro de Rango Horario de Emergencia'
            RETURN -5
        END

       SELECT  Id=@w_id, Nombres= @w_nombres

       SELECT @o_msgerror = 'Ejecucion Ok'
    END

    RETURN 0
END
GO

dbo.sp_help pr_Seguridad
GO

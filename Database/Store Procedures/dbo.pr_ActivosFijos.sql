USE dbJardinesEsperanza
GO
/****** Object:  StoredProcedure dbo.pr_ActivosFijos    Script Date: 11/07/2023 14:53:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS(SELECT 1 FROM sysobjects WHERE id=OBJECT_ID('dbo.pr_ActivosFijos') AND type='P')
BEGIN
   EXEC ('CREATE PROCEDURE dbo.pr_ActivosFijos AS BEGIN RETURN 0 END')
END
GO

ALTER PROCEDURE dbo.pr_ActivosFijos
    @i_accion     varchar(2),
    @i_codigo     varchar(50)   = null,
    @o_msgerror   varchar(200)  = '' OUTPUT 
AS
BEGIN
    SET NOCOUNT ON;

    IF @i_accion = 'LI'
    BEGIN

        SELECT Codigo     = ci_activo,
               CodigoQR   = null,
               Activo     = tx_caracteristicas,
               Existencia = 0,
               Custodio   = tx_usuarioasignado,
               Costo      = qn_valor,
               Comentario = null
          FROM dbJardiesaDC.dbo.acft_Activos
        SELECT @o_msgerror = 'Ejecucion OK'
    END --IF

    IF @i_accion = 'CO'
    BEGIN
        SELECT Codigo     = ci_activo,
               CodigoQR   = null,
               Activo     = tx_caracteristicas,
               Existencia = 0,
               Custodio   = tx_usuarioasignado,
               Costo      = qn_valor,
               Comentario = null
          FROM dbJardiesaDC.dbo.acft_Activos
         WHERE ci_activo = @i_codigo
        SELECT @o_msgerror = 'Ejecucion OK'
    END --IF

    RETURN 0

END
GO

IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE major_id=OBJECT_ID('dbo.pr_ActivosFijos') and name='@i_accion')
   EXEC sp_dropextendedproperty  @name = '@i_accion' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'PROCEDURE', @level1name = 'pr_ActivosFijos'
GO
EXEC sys.sp_addextendedproperty @name=N'@i_accion', @value=N'Parametro para establecer la accion a tomar en el SP' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'pr_ActivosFijos'
GO

IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE major_id=OBJECT_ID('dbo.pr_ActivosFijos') and name='@i_codigo')
   EXEC sp_dropextendedproperty  @name = '@i_codigo' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'PROCEDURE', @level1name = 'pr_ActivosFijos'
GO
EXEC sys.sp_addextendedproperty @name=N'@i_codigo', @value=N'Codigo del Activo Fijo a Consultar' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'pr_ActivosFijos'
GO

IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE major_id=OBJECT_ID('dbo.pr_ActivosFijos') and name='@i_custodio')
   EXEC sp_dropextendedproperty  @name = '@i_custodio' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'PROCEDURE', @level1name = 'pr_ActivosFijos'
GO
EXEC sys.sp_addextendedproperty @name=N'@i_custodio', @value=N'Nombre del Custodio' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'pr_ActivosFijos'
GO

IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE major_id=OBJECT_ID('dbo.pr_ActivosFijos') and name='@o_msgerror')
   EXEC sp_dropextendedproperty  @name = '@o_msgerror' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'PROCEDURE', @level1name = 'pr_ActivosFijos'
GO
EXEC sys.sp_addextendedproperty @name=N'@o_msgerror', @value=N'Mensaje de Respuesta del SP' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'pr_ActivosFijos'
GO

IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE major_id=OBJECT_ID('dbo.pr_ActivosFijos') and name='descripcion')
   EXEC sp_dropextendedproperty  @name = 'descripcion' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'PROCEDURE', @level1name = 'pr_ActivosFijos'
GO
EXEC sys.sp_addextendedproperty @name=N'descripcion', @value=N'SP que sive para consultar activos fijo mediante APIRest de Scaneo' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'pr_ActivosFijos'
GO

dbo.sp_help pr_ActivosFijos
GO

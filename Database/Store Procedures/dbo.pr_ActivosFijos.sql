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
    @i_custodio   varchar(50)   = null,
    @i_costo      decimal(18,2) = null,
    @i_comentario varchar(200)  = null,
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

dbo.sp_help pr_ActivosFijos
GO

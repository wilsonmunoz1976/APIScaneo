USE [dbJardiesaDC]
GO

IF NOT EXISTS(SELECT 1 FROM sysobjects WHERE id=OBJECT_ID('dbo.pr_sectrans') AND type='P')
    EXEC ('CREATE PROCEDURE dbo.pr_sectrans AS RETURN 0')
GO

ALTER PROCEDURE dbo.pr_sectrans (
    @i_bodega   VARCHAR(3)   = '009',
    @i_inout    varchar(3)   = 'OU',
    @o_sec      INT          = 0  OUTPUT,
    @o_msgerror VARCHAR(MAX) = '' OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @w_anio VARCHAR(4) = CONVERT(VARCHAR(4), YEAR(GETDATE()))
    BEGIN TRY
        SELECT @o_sec = 
           CASE WHEN @i_inout='OU'  THEN ISNULL(qn_sec_ou ,0) + 1
                WHEN @i_inout='IN'  THEN ISNULL(qn_sec_in ,0) + 1
                WHEN @i_inout='RB'  THEN ISNULL(qn_sec_rb ,0) + 1
                WHEN @i_inout='PED' THEN ISNULL(qn_sec_ped,0) + 1
                WHEN @i_inout='EGR' THEN ISNULL(qn_sec_egr,0) + 1
                WHEN @i_inout='OR'  THEN ISNULL(qn_sec_or ,0) + 1
                ELSE 0
           END
          FROM dbo.adqt_SecTrans 
         WHERE qn_anio   = @w_anio 
           AND ci_bodega = @i_bodega

        IF @@ROWCOUNT = 0
        BEGIN
            INSERT INTO dbo.adqt_SecTrans 
            (      qn_anio,
                   ci_bodega,
                   qn_sec_in,
                   qn_sec_ou,
                   qn_sec_rb,
                   qn_sec_ped,
                   qn_sec_egr,
                   qn_sec_or
            )
            SELECT qn_anio    = @w_anio,
                   ci_bodega  = @i_bodega,
                   qn_sec_in  = IIF(@i_inout='IN',  1, 0),
                   qn_sec_ou  = IIF(@i_inout='OU',  1, 0),
                   qn_sec_rb  = IIF(@i_inout='RB',  1, 0),
                   qn_sec_ped = IIF(@i_inout='PED', 1, 0),
                   qn_sec_egr = IIF(@i_inout='EGR', 1, 0),
                   qn_sec_or  = IIF(@i_inout='OR',  1, 0)

            IF @@ROWCOUNT = 0
            BEGIN
                SELECT @o_msgerror = 'No se pudo actualizar la secuencia de Transacciones'
                RETURN -2
            END

            SELECT @o_sec = 1
        END
        ELSE
        BEGIN
            UPDATE dbo.adqt_SecTrans
               SET qn_sec_in  = ISNULL(qn_sec_in  + IIF(@i_inout='IN',  1, 0), 1),
                   qn_sec_ou  = ISNULL(qn_sec_ou  + IIF(@i_inout='OU',  1, 0), 1),
                   qn_sec_rb  = ISNULL(qn_sec_rb  + IIF(@i_inout='RB',  1, 0), 1),
                   qn_sec_ped = ISNULL(qn_sec_ped + IIF(@i_inout='PED', 1, 0), 1),
                   qn_sec_egr = ISNULL(qn_sec_egr + IIF(@i_inout='EGR', 1, 0), 1),
                   qn_sec_or  = ISNULL(qn_sec_or  + IIF(@i_inout='OR',  1, 0), 1)
             WHERE qn_anio    = @w_anio
               AND ci_bodega  = @i_bodega

            IF @@ROWCOUNT = 0
            BEGIN
                SELECT @o_msgerror = 'No se pudo actualizar la secuencia de Transacciones'
                RETURN -2
            END
        END
    END TRY
    BEGIN CATCH
        SELECT @o_msgerror = ERROR_MESSAGE()
        RETURN -1
    END CATCH

    SELECT @o_msgerror = 'Secuencia obtenida correctamente'
    RETURN 0

END
GO

IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE major_id=OBJECT_ID('dbo.pr_sectrans') and name='@i_bodega')
   EXEC sp_dropextendedproperty  @name = '@i_bodega' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'PROCEDURE', @level1name = 'pr_sectrans'
GO
EXEC sys.sp_addextendedproperty @name=N'@i_bodega', @value=N'Bodega a Solicitar secuencial' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'pr_sectrans'
GO

IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE major_id=OBJECT_ID('dbo.pr_sectrans') and name='@i_inout')
   EXEC sp_dropextendedproperty  @name = '@i_inout' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'PROCEDURE', @level1name = 'pr_sectrans'
GO
EXEC sys.sp_addextendedproperty @name=N'@i_inout', @value=N'Tipo de Secuencial a solicitar' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'pr_sectrans'
GO

IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE major_id=OBJECT_ID('dbo.pr_sectrans') and name='@o_msgerror')
   EXEC sp_dropextendedproperty  @name = '@o_msgerror' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'PROCEDURE', @level1name = 'pr_sectrans'
GO
EXEC sys.sp_addextendedproperty @name=N'@o_msgerror', @value=N'Mensaje de respuesta del SP' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'pr_sectrans'
GO

IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE major_id=OBJECT_ID('dbo.pr_sectrans') and name='@o_sec')
   EXEC sp_dropextendedproperty  @name = '@o_sec' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'PROCEDURE', @level1name = 'pr_sectrans'
GO
EXEC sys.sp_addextendedproperty @name=N'@o_sec', @value=N'Numero secuencial a retornar' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'pr_sectrans'
GO

IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE major_id=OBJECT_ID('dbo.pr_sectrans') and name='descripcion')
   EXEC sp_dropextendedproperty  @name = 'descripcion' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'PROCEDURE', @level1name = 'pr_sectrans'
GO
EXEC sys.sp_addextendedproperty @name=N'descripcion', @value=N'SP para obtener el ultimo secuencial de una tabla' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'pr_sectrans'
GO

dbo.sp_help pr_sectrans
GO

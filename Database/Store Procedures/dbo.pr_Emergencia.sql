USE [dbJardiesaDC]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS(SELECT 1 FROM sysobjects WHERE id=OBJECT_ID('dbo.pr_Emergencia') AND type='P')
BEGIN
   EXEC ('CREATE PROCEDURE dbo.pr_Emergencia AS BEGIN RETURN 0 END')
END
GO

ALTER PROCEDURE dbo.pr_Emergencia
    @i_accion        varchar(2),
    @i_nombres       varchar(100),
    @i_articulo      varchar(20),
    @i_usuario       varchar(15)  = null,
    @o_msgerror      varchar(200) = '' OUTPUT,
    @o_codplanilla   varchar(15)  = '' OUTPUT,
    @o_codsoliegre   int          = 0  OUTPUT,
    @o_bodega        varchar(3)   = '' OUTPUT,
    @o_descarticulo  varchar(60)  = '' OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @w_planilla   VARCHAR(15),
            @w_soliegreso INT,
            @w_rgohor     VARCHAR(11),
            @w_ret        INT

    IF @i_accion = 'RG' --Registro de Emergencia
    BEGIN
        BEGIN TRANSACTION [RegistroEmergencia]
            BEGIN TRY

                SELECT TOP 1 @w_rgohor = tx_parametro
                  FROM dbo.ssatParametrosGenerales
                 WHERE ci_aplicacion = 'MOV'
                   AND ci_parametro  = 'RGOHOR'

                DECLARE @w_rango varchar(5) = CONVERT(VARCHAR(5),GETDATE(),108)
                IF (dbo.fu_validar_rango_horario(@w_rango, @w_rgohor) = 0)
                BEGIN
                    SELECT @o_msgerror = 'No puede registrar esta EMERGENCIA porque se encuentra fuera del rango horario permitido (' + REPLACE(@w_rgohor,'|', '-') + ')'
                    ROLLBACK TRANSACTION [RegistroEmergencia]
                    RETURN -1
                END

                IF EXISTS(SELECT 1 FROM dbJardinesEsperanza.dbo.futPlanilla WHERE tx_nombrefallecido = @i_nombres)
                BEGIN
                    SELECT @o_msgerror = 'No puede registrar esta EMERGENCIA porque el nombre del fallecido ya esta ingresado previamente'
                    ROLLBACK TRANSACTION [RegistroEmergencia]
                    RETURN -1
                END

                SELECT @o_bodega       = scit_ArticulosBodegas.ci_bodega,
                       @o_descarticulo = scit_Articulos.tx_articulo
                  FROM dbo.scit_Articulos
                  INNER JOIN dbo.scit_ArticulosBodegas
                    ON scit_ArticulosBodegas.ci_articulo = scit_Articulos.ci_articulo
                 WHERE scit_Articulos.ci_articulo = @i_articulo
                   AND scit_Articulos.ci_clase    = '0066' --COFRES

                IF @@ROWCOUNT = 0
                BEGIN
                    SELECT @o_msgerror = 'El codigo de Cofre especificado no existe (' + @i_articulo + ')'
                    ROLLBACK TRANSACTION [RegistroEmergencia]
                    RETURN -1
                END

                IF @o_bodega = '009'
                BEGIN
                    SELECT @w_planilla = 'I' 
                         + RIGHT(REPLICATE('0', 10) 
                         + CONVERT(VARCHAR, ISNULL(MAX(CONVERT(DECIMAL(19,0),
                                                   IIF(LTRIM(RTRIM(ISNULL(SUBSTRING(ci_planilla,2, 15),'0')))='',
                                                   '0',
                                                   LTRIM(RTRIM(ISNULL(SUBSTRING(ci_planilla,2, 15),'0')))
                                                   )))
                                            ,0)+1),10)
                    FROM [dbJardinesEsperanza].[dbo].[futPlanilla]
                    WHERE ci_planilla like 'I%' AND ci_anio= YEAR(GETDATE())
                    
                    INSERT INTO dbJardinesEsperanza.dbo.futPlanilla 
                          (ci_planilla, 
                           fx_fecharegistro,  
                           tx_nombrefallecido, 
                           fx_creacion, 
                           fx_fechareservacion,
                           ci_usuarioreservacion, 
                           ci_usuario,
                           te_planilla,
                           te_verificacion,
                           ci_tiporeserva,
                           ci_anio,
                           ci_mes,
                           ci_aniorealizable,
                           ci_mesrealizable)
                    SELECT ci_planilla           = @w_planilla, 
                           fx_fecharegistro      = GETDATE(), 
                           tx_nombrefallecido    = @i_nombres, 
                           fx_creacion           = GETDATE(), 
                           fx_fechareservacion   = GETDATE(), 
                           ci_usuarioreservacion = UPPER(@i_usuario), 
                           ci_usuario            = UPPER(@i_usuario), 
                           te_planilla           = 'A',
                           te_verificacion       = 'N',
                           ci_tiporeserva        = 'P',
                           ci_anio               = CONVERT(VARCHAR(15), YEAR(GETDATE())),
                           ci_mes                = RIGHT('00'+CONVERT(VARCHAR(2) , MONTH(GETDATE())),2),
                           ci_aniorealizable     = CONVERT(VARCHAR(15), YEAR(GETDATE())),
                           ci_mesrealizable      = RIGHT('00'+CONVERT(VARCHAR(2) , MONTH(GETDATE())),2)
                    
                    IF @@ROWCOUNT = 0
                    BEGIN
                        SELECT @o_msgerror = 'No se ingreso ningun registro'
                        ROLLBACK TRANSACTION [RegistroEmergencia]
                        RETURN -1
                    END
                    
                    SELECT @w_soliegreso = ISNULL(MAX(ci_solicitudegreso),0)+1 FROM dbJardinesEsperanza.dbo.futSolicitudEgreso
                    
                    INSERT INTO dbJardinesEsperanza.dbo.futSolicitudEgreso (
                           ci_solicitudegreso,
                           ci_articulo,
                           tx_documentoorigen,
                           tx_transaccionorigen,
                           te_ordenegreso,
                           te_proceso,
                           fx_creacion,
                           ci_usuario
                           )
                    SELECT ci_solicitudegreso   = @w_soliegreso,
                           ci_articulo          = @i_articulo,
                           tx_documentoorigen   = 'INH',
                           tx_transaccionorigen = @w_planilla,
                           te_ordenegreso       = 'A',
                           te_proceso           = 'IN',
                           fx_creacion          = GETDATE(),
                           ci_usuario           = @i_usuario
                    
                    IF @@ROWCOUNT = 0
                    BEGIN
                        SELECT @o_msgerror = 'No se ingreso ningun registro'
                        ROLLBACK TRANSACTION [RegistroEmergencia]
                        RETURN -1
                    END
                END
                        

                IF @o_bodega = '015'
                BEGIN
                    SELECT @w_planilla = 'I' 
                         + RIGHT(REPLICATE('0', 10) 
                         + CONVERT(VARCHAR, ISNULL(MAX(CONVERT(DECIMAL(19,0),
                                                   IIF(LTRIM(RTRIM(ISNULL(SUBSTRING(ci_planilla,2, 15),'0')))='',
                                                   '0',
                                                   LTRIM(RTRIM(ISNULL(SUBSTRING(ci_planilla,2, 15),'0')))
                                                   )))
                                            ,0)+1),10)
                    FROM [dbJardinesEsperanza].[dbo].[futPlanilla]
                    WHERE ci_planilla like 'I%' AND ci_anio= YEAR(GETDATE())
                    
                    INSERT INTO dbCautisaJE.dbo.futPlanilla 
                          (ci_planilla, 
                           fx_fecharegistro,  
                           tx_nombrefallecido, 
                           fx_creacion, 
                           fx_fechareservacion,
                           ci_usuarioreservacion, 
                           ci_usuario,
                           te_planilla,
                           te_verificacion,
                           ci_tiporeserva,
                           ci_anio,
                           ci_mes,
                           ci_aniorealizable,
                           ci_mesrealizable)
                    SELECT ci_planilla           = @w_planilla, 
                           fx_fecharegistro      = GETDATE(), 
                           tx_nombrefallecido    = @i_nombres, 
                           fx_creacion           = GETDATE(), 
                           fx_fechareservacion   = GETDATE(), 
                           ci_usuarioreservacion = UPPER(@i_usuario), 
                           ci_usuario            = UPPER(@i_usuario), 
                           te_planilla           = 'A',
                           te_verificacion       = 'N',
                           ci_tiporeserva        = 'P',
                           ci_anio               = CONVERT(VARCHAR(15), YEAR(GETDATE())),
                           ci_mes                = RIGHT('00'+CONVERT(VARCHAR(2) , MONTH(GETDATE())),2),
                           ci_aniorealizable     = CONVERT(VARCHAR(15), YEAR(GETDATE())),
                           ci_mesrealizable      = RIGHT('00'+CONVERT(VARCHAR(2) , MONTH(GETDATE())),2)
                    
                    IF @@ROWCOUNT = 0
                    BEGIN
                        SELECT @o_msgerror = 'No se ingreso ningun registro'
                        ROLLBACK TRANSACTION [RegistroEmergencia]
                        RETURN -1
                    END
                    
                    SELECT @w_soliegreso = ISNULL(MAX(ci_solicitudegreso),0)+1 FROM dbCautisaJE.dbo.futSolicitudEgreso
                    
                    INSERT INTO dbCautisaJE.dbo.futSolicitudEgreso (
                           ci_solicitudegreso,
                           ci_articulo,
                           tx_documentoorigen,
                           tx_transaccionorigen,
                           te_ordenegreso,
                           te_proceso,
                           fx_creacion,
                           ci_usuario
                           )
                    SELECT ci_solicitudegreso   = @w_soliegreso,
                           ci_articulo          = @i_articulo,
                           tx_documentoorigen   = 'INH',
                           tx_transaccionorigen = @w_planilla,
                           te_ordenegreso       = 'A',
                           te_proceso           = 'IN',
                           fx_creacion          = GETDATE(),
                           ci_usuario           = @i_usuario
                    
                    IF @@ROWCOUNT = 0
                    BEGIN
                        SELECT @o_msgerror = 'No se ingreso ningun registro'
                        ROLLBACK TRANSACTION [RegistroEmergencia]
                        RETURN -1
                    END
                END

                SELECT @o_codplanilla = @w_planilla, @o_codsoliegre = @w_soliegreso

                EXEC @w_ret           = dbo.pr_MovimientoBodega 
                     @i_tipomov       = 'OU',
                     @i_articulo      = @i_articulo,
                     @i_planilla      = @w_planilla,
                     @i_usuario       = @i_usuario,
                     @o_msgerror      = @o_msgerror OUTPUT
                
                IF @w_ret = 0    
                    COMMIT TRANSACTION [RegistroEmergencia]
                ELSE
                    ROLLBACK TRANSACTION [RegistroEmergencia]

            END TRY
            BEGIN CATCH
                SELECT @o_msgerror = 'ERROR: ' + ERROR_MESSAGE() + ' - ' + CONVERT(VARCHAR, ERROR_LINE())
                ROLLBACK TRANSACTION [RegistroEmergencia]
                RETURN -2
            END CATCH

            SELECT @o_msgerror = 'Se efectuo correctamente el registro de Emergencia'
      --END TRANSACTION
    END

    RETURN 0

END
GO

IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE major_id=OBJECT_ID('dbo.pr_Emergencia') and name='@i_accion')
   EXEC sp_dropextendedproperty  @name = '@i_accion' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'PROCEDURE', @level1name = 'pr_Emergencia'
GO
EXEC sys.sp_addextendedproperty @name=N'@i_accion', @value=N'Accion a realizar dentro del RG-Registro' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'pr_Emergencia'
GO

IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE major_id=OBJECT_ID('dbo.pr_Emergencia') and name='@i_articulo')
   EXEC sp_dropextendedproperty  @name = '@i_articulo' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'PROCEDURE', @level1name = 'pr_Emergencia'
GO
EXEC sys.sp_addextendedproperty @name=N'@i_articulo', @value=N'Codigo del Cofre o Urna elegido' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'pr_Emergencia'
GO

IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE major_id=OBJECT_ID('dbo.pr_Emergencia') and name='@i_nombres')
   EXEC sp_dropextendedproperty  @name = '@i_nombres' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'PROCEDURE', @level1name = 'pr_Emergencia'
GO
EXEC sys.sp_addextendedproperty @name=N'@i_nombres', @value=N'Nombre del Fallecido' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'pr_Emergencia'
GO

IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE major_id=OBJECT_ID('dbo.pr_Emergencia') and name='@i_usuario')
   EXEC sp_dropextendedproperty  @name = '@i_usuario' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'PROCEDURE', @level1name = 'pr_Emergencia'
GO
EXEC sys.sp_addextendedproperty @name=N'@i_usuario', @value=N'Loginname del usuario del sistema' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'pr_Emergencia'
GO

IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE major_id=OBJECT_ID('dbo.pr_Emergencia') and name='@o_bodega')
   EXEC sp_dropextendedproperty  @name = '@o_bodega' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'PROCEDURE', @level1name = 'pr_Emergencia'
GO
EXEC sys.sp_addextendedproperty @name=N'@o_bodega', @value=N'Codigo de Bodega del Articulo elegido' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'pr_Emergencia'
GO

IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE major_id=OBJECT_ID('dbo.pr_Emergencia') and name='@o_codplanilla')
   EXEC sp_dropextendedproperty  @name = '@o_codplanilla' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'PROCEDURE', @level1name = 'pr_Emergencia'
GO
EXEC sys.sp_addextendedproperty @name=N'@o_codplanilla', @value=N'Codigo de Planilla Generado' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'pr_Emergencia'
GO

IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE major_id=OBJECT_ID('dbo.pr_Emergencia') and name='@o_codsoliegre')
   EXEC sp_dropextendedproperty  @name = '@o_codsoliegre' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'PROCEDURE', @level1name = 'pr_Emergencia'
GO
EXEC sys.sp_addextendedproperty @name=N'@o_codsoliegre', @value=N'Codigo de Solicitud de Egreso generado' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'pr_Emergencia'
GO

IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE major_id=OBJECT_ID('dbo.pr_Emergencia') and name='@o_desarticulo')
   EXEC sp_dropextendedproperty  @name = '@o_desarticulo' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'PROCEDURE', @level1name = 'pr_Emergencia'
GO
EXEC sys.sp_addextendedproperty @name=N'@o_desarticulo', @value=N'Descripcion del articulo elegido' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'pr_Emergencia'
GO

IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE major_id=OBJECT_ID('dbo.pr_Emergencia') and name='@o_msgerror')
   EXEC sp_dropextendedproperty  @name = '@o_msgerror' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'PROCEDURE', @level1name = 'pr_Emergencia'
GO
EXEC sys.sp_addextendedproperty @name=N'@o_msgerror', @value=N'Mensaje de Respuesta del SP' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'pr_Emergencia'
GO

IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE major_id=OBJECT_ID('dbo.pr_Emergencia') and name='descripcion')
   EXEC sp_dropextendedproperty  @name = 'descripcion' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'PROCEDURE', @level1name = 'pr_Emergencia'
GO
EXEC sys.sp_addextendedproperty @name=N'descripcion', @value=N'SP para registrar Solicitud de Egreso en horario de Emergencia' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'pr_Emergencia'
GO

dbo.sp_help [pr_Emergencia]
GO

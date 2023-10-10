USE [dbJardiesaDC]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS(SELECT 1 FROM sysobjects WHERE id=OBJECT_ID('dbo.pr_CofresUrnas') AND type='P')
BEGIN
   EXEC ('CREATE PROCEDURE dbo.pr_CofresUrnas AS BEGIN  RETURN 0   END')
END
GO

ALTER PROCEDURE dbo.pr_CofresUrnas
    @i_accion        varchar(2),
    @i_bodega        varchar(3)     = null,
    @i_usuario       varchar(15)    = null,
    @i_codsolegre    bigint         = null,
    @i_articulo      varchar(20)    = null,
	@i_retapizado    bit            = 0,
    @i_estado        smallint       = 0,
    @i_comentario    varchar(500)   = null,
    @i_fotografia    nvarchar(max)   = null,
    @o_msgerror      varchar(200)   = '' OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO trace_0 (mensaje) SELECT 'DECLARE @w_ret int, @w_msgerror varchar(200); EXEC @w_ret = dbo.pr_CofresUrnas @i_accion='+ISNULL(CHAR(39)+@i_accion+CHAR(39),'null')+',@i_bodega='+isnull(CHAR(39)+@i_bodega+CHAR(39),'null')+', @i_usuario='+isnull(CHAR(39)+@i_usuario+CHAR(39),'null')+', @i_codsolegre='+ISNULL(convert(varchar,@i_codsolegre),'null')+',@i_articulo='+ISNULL(CHAR(39)+@i_articulo+CHAR(39),'null')+', @i_estado='+ISNULL(convert(varchar,@i_estado),'null')+', @i_comentario='+ISNULL(CHAR(39)+@i_comentario+CHAR(39),'null')+', @i_fotografia='+ISNULL(CHAR(39)+@i_fotografia+CHAR(39),'null')+', @o_msgerror=@w_msgerror OUTPUT; SELECT @w_ret, @w_msgerror'
    DECLARE @w_anio             varchar(4),
            @w_mes              varchar(2),
            @w_articulo         varchar(20),
            @w_planilla         varchar(20)  = '',
            @w_secuencia        varchar(4),
            @w_transaccion      varchar(11),
            @w_transaccionret   varchar(11),
            @w_transaccionreing varchar(11),
            @w_anterior         int          = null,
            @w_valorUnit        money        = 0,
            @w_total            money        = 0,
            @w_valorIVA         money        = 0,
            @w_fechacreacion    datetime,
            @w_medida           varchar(3)   = '',
            @w_observacion      varchar(255) = '',
            @w_nota_entrega     varchar(25)  = '',
            @w_inhumado         varchar(220) = '',
            @w_sectransac       int          = 0,
            @w_ctacontable      varchar(4)   = '0001',
            @w_ret              int          = 0,
            @w_articuloorg      varchar(60)  = '',
            @w_articulodes      varchar(60)  = '',
            @w_existencia       money        = 0,
            @w_existenciabod    money        = 0,
            @w_permisoprecio    bit          = 0,
            @w_fechaentrega     datetime,
			@w_codbodega        varchar(3),
			@w_desbodega        varchar(60)

    IF @i_accion = 'BO' --Listado de Bodegas
    BEGIN
        BEGIN TRY
            SELECT ci_bodega, 
                   tx_nombrebodega = ci_bodega + ' - ' + tx_nombrebodega
              FROM dbo.scit_Bodegas
             WHERE ce_estado='A'
               AND tx_nombrebodega LIKE '%COFRE%'
               AND ci_bodega IN (SELECT ci_bodega FROM dbo.scit_BodegaUsuario where ci_usuario=@i_usuario)

            SELECT @o_msgerror = 'Ejecucion OK'
        END TRY
        BEGIN CATCH
            SELECT @o_msgerror = 'Error: ' + ERROR_MESSAGE()
            RETURN -2
        END CATCH
    END

    IF @i_accion = 'RI' -- Reingreso de Cofre
    BEGIN
        IF ('0001' IN (SELECT ci_grupocontable from dbo.scit_BodegaUsuario a INNER JOIN dbo.scit_Bodegas b ON a.ci_bodega = b.ci_bodega WHERE a.ci_usuario = @i_usuario))
        BEGIN
            IF EXISTS(SELECT 1 FROM dbJardinesEsperanza.dbo.futSolicitudEgreso
                       WHERE ci_solicitudegreso = @i_codsolegre
                         AND (fx_retiro  IS NOT NULL OR fx_entrega IS NOT NULL) 
                         AND fx_sala    IS NULL)
            BEGIN
                BEGIN TRANSACTION [TranReingreso]
                    BEGIN TRY
            
                        SELECT @w_articulo     = ci_articulo,
                               @w_planilla     = tx_transaccionorigen,
                               @w_fechaentrega = fx_entrega, 
                               @w_codbodega    = ci_bodega
                          FROM dbJardinesEsperanza.dbo.futSolicitudEgreso
                         WHERE ci_solicitudegreso = @i_codsolegre
            
                        IF @w_articulo = @i_articulo 
                        BEGIN
                            ROLLBACK TRANSACTION [TranReingreso]
                            SELECT @o_msgerror = 'Elija un cofre/urna diferente al que retiró'
                            RETURN -2
                        END
                        
                        SELECT @w_articuloorg   = scit_Articulos.tx_articulo,
                               @w_desbodega     = scit_Bodegas.tx_nombrebodega,
                               @w_articulodes   = scit_Articulos.tx_articulo,
                               @w_existencia    = scit_Articulos.qn_existencia,
                               @w_existenciabod = scit_ArticulosBodegas.qn_existencia
                          FROM dbo.scit_Articulos 
                          LEFT JOIN dbo.scit_ArticulosBodegas
                            ON scit_ArticulosBodegas.ci_articulo = scit_Articulos.ci_articulo
                           AND scit_ArticulosBodegas.ci_bodega   = @i_bodega
                          LEFT JOIN dbo.scit_Bodegas
                            ON scit_Bodegas.ci_bodega     = scit_ArticulosBodegas.ci_bodega
                         WHERE scit_Articulos.ci_articulo = @i_articulo
            
                        IF @@ROWCOUNT = 0
                        BEGIN
                            ROLLBACK TRANSACTION [TranReingreso]
                            SELECT @o_msgerror = 'El cofre/urna seleccionado no existe en nuestra base de datos'
                            RETURN -2
                        END
            
                        IF @w_existencia <= 0
                        BEGIN
                            ROLLBACK TRANSACTION [TranReingreso]
                            SELECT @o_msgerror = 'El cofre/urna seleccionado no tiene existencia en el inventario'
                            RETURN -2
                        END

                        IF @w_existenciabod <= 0
                        BEGIN
                            ROLLBACK TRANSACTION [TranReingreso]
                            SELECT @o_msgerror = 'El cofre/urna seleccionado no tiene existencia en la bodega '+@i_bodega
                            RETURN -2
                        END
                        
                        
                        EXEC @w_ret           = dbo.pr_MovimientoBodega 
                             @i_tipomov       = 'RB',
                             @i_articulo      = @w_articulo,
                             @i_planilla      = @w_planilla,
                             @i_usuario       = @i_usuario,
                             @i_bodega        = @w_codbodega,
                             @i_solegre       = @i_codsolegre,
                             @o_transaccion   = @w_transaccionreing OUTPUT,
                             @o_msgerror      = @o_msgerror         OUTPUT
            
                        IF @w_ret != 0
                        BEGIN
                            ROLLBACK TRANSACTION [TranReingreso]
                            RETURN @w_ret
                        END
            
                        EXEC @w_ret           = dbo.pr_MovimientoBodega 
                             @i_tipomov       = 'OU',
                             @i_articulo      = @i_articulo,
                             @i_planilla      = @w_planilla,
                             @i_usuario       = @i_usuario,
                             @i_bodega        = @i_bodega,
                             @i_solegre       = @i_codsolegre,
                             @o_transaccion   = @w_transaccion OUTPUT,
                             @o_msgerror      = @o_msgerror OUTPUT
            
                        IF @w_ret != 0
                        BEGIN
                            ROLLBACK TRANSACTION [TranReingreso]
                            RETURN @w_ret
                        END

                        IF @i_retapizado = 1
                        BEGIN
                            EXEC @w_ret           = dbo.pr_MovimientoBodega 
                                 @i_tipomov       = 'RE',
                                 @i_articulo      = @w_articulo,
                                 @i_planilla      = @w_planilla,
                                 @i_usuario       = @i_usuario,
                                 @i_bodega        = @w_codbodega,
                                 @i_solegre       = @i_codsolegre,
                                 @o_transaccion   = @w_transaccionret OUTPUT,
                                 @o_msgerror      = @o_msgerror OUTPUT
            
                            IF @w_ret != 0
                            BEGIN
                                ROLLBACK TRANSACTION [TranReingreso]
                                --SELECT @o_msgerror = 'Error al efectuar movimiento de Bodega de Reingreso de Retapizado'
                                RETURN @w_ret
                            END

                            INSERT INTO dbJardinesEsperanza.dbo.futRetapizados 
                            (
                                   ci_articulo,      
                                   tx_planilla,    
                                   ci_solegreorg, 
                                   fx_fecharegistro, 
                                   ci_bodega,         
                                   ce_retapizado, 
                                   ci_usuarioretapizado,
                                   ci_transaccionegreso,
                                   ci_tipo_transaccionegreso
                            )
                            SELECT ci_articulo          = @w_articulo, 
                                   ci_planillaorg       = @w_planilla, 
                                   ci_solegreorg        = @i_codsolegre, 
                                   fx_fecharegistro     = GETDATE(), 
                                   ci_bodega            = @w_codbodega, 
                                   ce_retapizado        = 'I', 
                                   ci_usuarioretapizado = @i_usuario,
                                   ci_transaccionegreso = @w_transaccionret,
                                   ci_tipo_transaccionegreso = 'OU'


                            IF @@ROWCOUNT = 0
                            BEGIN
                                ROLLBACK TRANSACTION [TranReingreso]
                                SELECT @o_msgerror = 'Error al ingresar el registro del Retapizado'
                                RETURN @w_ret
                            END

                        END

                        UPDATE dbJardinesEsperanza.dbo.futSolicitudEgreso
                           SET ci_articulo                  = @i_articulo,
						       ci_usuario                   = @i_usuario,
							   ci_bodega                    = @i_bodega,
                               ci_tipo_transaccionegreso    = 'OU',
                               ci_transaccionegreso         = @w_transaccion,
                               ci_tipo_transaccionreingreso = 'RB',
                               ci_transaccionreingreso      = @w_transaccionreing
                         WHERE ci_solicitudegreso           = @i_codsolegre
                           AND te_ordenegreso               = 'A'
            
                        IF @@ROWCOUNT = 0
                        BEGIN
                            ROLLBACK TRANSACTION [TranReingreso]
                            SELECT @o_msgerror = 'No se actualizo ningun registro'
                            RETURN -1
                        END
                                    
 
                        SELECT CodArticuloOrigen  = @w_articulo,
                               DesArticuloOrigen  = @w_articuloorg,
                               CodArticuloDestino = @i_articulo,
                               DesArticuloDestino = @w_articulodes,
                               CodPlanilla        = @w_planilla,
                               CodSoliEgre        = @i_codsolegre,
                               NombreFallecido    = @w_inhumado,
                               Usuario            = @i_usuario,
                               CodBodega          = @w_codbodega,
                               DesBodega          = @w_desbodega
            
                        SELECT @o_msgerror = 'Se efectuo correctamente el Reingreso'
                        IF @w_fechaentrega IS NOT NULL SELECT @o_msgerror = @o_msgerror + '. El cofre fue enviado a Retapizar'
            
                        COMMIT TRAN [TranReingreso]
                    END TRY
                    BEGIN CATCH
                        ROLLBACK TRAN [TranReingreso]
                        SELECT @o_msgerror = 'ERROR: ' + ERROR_MESSAGE()
                        RETURN -9
                    END CATCH
              --END TRANSACTION
            END
            ELSE
            BEGIN
                SELECT @o_msgerror = 'Solicitud de Ingreso seleccionada no esta en estado de Cofre/Urna Retirado o Sala'
                RETURN -1
            END
        END
            
        IF ('0002' IN (SELECT ci_grupocontable from dbo.scit_BodegaUsuario a INNER JOIN dbo.scit_Bodegas b ON a.ci_bodega = b.ci_bodega WHERE a.ci_usuario = @i_usuario))
        BEGIN
            IF EXISTS(SELECT 1 FROM dbCautisaJE.dbo.futSolicitudEgreso
                       WHERE ci_solicitudegreso = @i_codsolegre
                         AND (fx_retiro  IS NOT NULL OR fx_entrega IS NOT NULL) 
                         AND fx_sala    IS NULL)
            BEGIN
                BEGIN TRANSACTION [TranReingresoMilagro]
                    BEGIN TRY
            
                        SELECT @w_articulo     = ci_articulo,
                               @w_planilla     = tx_transaccionorigen,
                               @w_fechaentrega = fx_entrega, 
                               @w_codbodega    = ci_bodega
                          FROM dbCautisaJE.dbo.futSolicitudEgreso
                         WHERE ci_solicitudegreso = @i_codsolegre
            
                        IF @w_articulo = @i_articulo 
                        BEGIN
                            ROLLBACK TRANSACTION [TranReingresoMilagro]
                            SELECT @o_msgerror = 'Elija un cofre/urna diferente al que retiró'
                            RETURN -2
                        END
                        
                        SELECT @w_articuloorg   = scit_Articulos.tx_articulo,
                               @w_desbodega     = scit_Bodegas.tx_nombrebodega,
                               @w_articulodes   = scit_Articulos.tx_articulo,
                               @w_existencia    = scit_Articulos.qn_existencia,
                               @w_existenciabod = scit_ArticulosBodegas.qn_existencia
                          FROM dbo.scit_Articulos 
                          LEFT JOIN dbo.scit_ArticulosBodegas
                            ON scit_ArticulosBodegas.ci_articulo = scit_Articulos.ci_articulo
                           AND scit_ArticulosBodegas.ci_bodega   = @w_codbodega
                          LEFT JOIN dbo.scit_Bodegas
                            ON scit_Bodegas.ci_bodega     = scit_ArticulosBodegas.ci_bodega
                         WHERE scit_Articulos.ci_articulo = @w_articulo
            
                        IF @@ROWCOUNT = 0
                        BEGIN
                            ROLLBACK TRANSACTION [TranReingresoMilagro]
                            SELECT @o_msgerror = 'El cofre/urna seleccionado no existe en nuestra base de datos'
                            RETURN -2
                        END
            
                        IF @w_existencia <= 0
                        BEGIN
                            ROLLBACK TRANSACTION [TranReingresoMilagro]
                            SELECT @o_msgerror = 'El cofre/urna seleccionado no tiene existencia en el inventario'
                            RETURN -2
                        END

                        IF @w_existenciabod <= 0
                        BEGIN
                            ROLLBACK TRANSACTION [TranReingresoMilagro]
                            SELECT @o_msgerror = 'El cofre/urna seleccionado no tiene existencia en la bodega '+@i_bodega
                            RETURN -2
                        END
                        
                        
                        EXEC @w_ret           = dbo.pr_MovimientoBodega 
                             @i_tipomov       = 'RB',
                             @i_articulo      = @w_articulo,
                             @i_planilla      = @w_planilla,
                             @i_usuario       = @i_usuario,
                             @i_bodega        = @w_codbodega,
                             @i_solegre       = @i_codsolegre,
                             @o_transaccion   = @w_transaccionreing OUTPUT,
                             @o_msgerror      = @o_msgerror OUTPUT
            
                        IF @w_ret != 0
                        BEGIN
                            ROLLBACK TRANSACTION [TranReingreso]
                            RETURN @w_ret
                        END
            
                        EXEC @w_ret           = dbo.pr_MovimientoBodega 
                             @i_tipomov       = 'OU',
                             @i_articulo      = @i_articulo,
                             @i_planilla      = @w_planilla,
                             @i_usuario       = @i_usuario,
                             @i_bodega        = @i_bodega,
                             @i_solegre       = @i_codsolegre,
                             @o_transaccion   = @w_transaccion OUTPUT,
                             @o_msgerror      = @o_msgerror OUTPUT
            
                        IF @w_ret != 0
                        BEGIN
                            ROLLBACK TRANSACTION [TranReingresoMilagro]
                            RETURN @w_ret
                        END


                        IF @i_retapizado = 1
                        BEGIN
                            EXEC @w_ret           = dbo.pr_MovimientoBodega 
                                 @i_tipomov       = 'RE',
                                 @i_articulo      = @w_articulo,
                                 @i_planilla      = @w_planilla,
                                 @i_usuario       = @i_usuario,
                                 @i_bodega        = @w_codbodega,
                                 @i_solegre       = @i_codsolegre,
                                 @o_transaccion   = @w_transaccionret OUTPUT,
                                 @o_msgerror      = @o_msgerror OUTPUT
            
                            IF @w_ret != 0
                            BEGIN
                               ROLLBACK TRANSACTION [TranReingresoMilagro]
                               SELECT @o_msgerror = 'Error al efectuar movimiento de Bodega de Reingreso de Retapizado'
                               RETURN @w_ret
                            END

                            INSERT INTO dbCautisaJE.dbo.futRetapizados 
                            (
                                   ci_articulo,      
                                   tx_planilla,    
                                   ci_solegreorg, 
                                   fx_fecharegistro, 
                                   ci_bodega,         
                                   ce_retapizado, 
                                   ci_usuarioretapizado,
                                   ci_transaccionegreso,
                                   ci_tipo_transaccionegreso
                            )
                            SELECT ci_articulo               = @w_articulo, 
                                   ci_planillaorg            = @w_planilla, 
                                   ci_solegreorg             = @i_codsolegre, 
                                   fx_fecharegistro          = GETDATE(), 
                                   ci_bodega                 = @w_codbodega, 
                                   ce_retapizado             = 'I', 
                                   ci_usuarioretapizado      = @i_usuario,
                                   ci_transaccionegreso      = @w_transaccionret,
                                   ci_tipo_transaccionegreso = 'OU'

                            IF @@ROWCOUNT = 0
                            BEGIN
                                ROLLBACK TRANSACTION [TranReingresoMilagro]
                                SELECT @o_msgerror = 'Error al ingresar el registro del Retapizado'
                                RETURN @w_ret
                            END
                        END
                                                
                        UPDATE dbCautisaJE.dbo.futSolicitudEgreso
                           SET ci_articulo                  = @i_articulo,
						       ci_usuario                   = @i_usuario,
							   ci_bodega                    = @i_bodega,
                               ci_tipo_transaccionegreso    = 'OU',
                               ci_transaccionegreso         = @w_transaccion,
                               ci_tipo_transaccionreingreso = 'RB',
                               ci_transaccionreingreso      = @w_transaccionreing
                         WHERE ci_solicitudegreso           = @i_codsolegre
                           AND te_ordenegreso               = 'A'
            
                        IF @@ROWCOUNT = 0
                        BEGIN
                            ROLLBACK TRANSACTION [TranReingresoMilagro]
                            SELECT @o_msgerror = 'No se actualizo ningun registro'
                            RETURN -1
                        END
            
                        SELECT CodArticuloOrigen  = @w_articulo,
                               DesArticuloOrigen  = @w_articuloorg,
                               CodArticuloDestino = @i_articulo,
                               DesArticuloDestino = @w_articulodes,
                               CodPlanilla        = @w_planilla,
                               CodSoliEgre        = @i_codsolegre,
                               NombreFallecido    = @w_inhumado,
                               Usuario            = @i_usuario,
                               CodBodega          = @w_codbodega,
                               DesBodega          = @w_desbodega
            
                        SELECT @o_msgerror = 'Se efectuo correctamente el Reingreso'
                        IF @w_fechaentrega IS NOT NULL SELECT @o_msgerror = @o_msgerror + '. El cofre fue enviado a Retapizar'
            
                        COMMIT TRAN [TranReingresoMilagro]
                    END TRY
                    BEGIN CATCH
                        ROLLBACK TRAN [TranReingresoMilagro]
                        SELECT @o_msgerror = 'ERROR: ' + ERROR_MESSAGE()
                        RETURN -9
                    END CATCH
              --END TRANSACTION
            END
            ELSE
            BEGIN
                SELECT @o_msgerror = 'Solicitud de Ingreso seleccionada no esta en estado de Cofre/Urna Retirado o Sala'
                RETURN -1
            END
        END
    END

    IF @i_accion = 'RR' -- Reingreso de Cofre Retapizado
    BEGIN
        IF ('0001' IN (SELECT ci_grupocontable from dbo.scit_BodegaUsuario a INNER JOIN dbo.scit_Bodegas b ON a.ci_bodega = b.ci_bodega WHERE a.ci_usuario = @i_usuario))
        BEGIN
            IF EXISTS(SELECT 1 FROM dbJardinesEsperanza.dbo.futRetapizados
                       WHERE ci_secuencia = @i_codsolegre
                         AND fx_fechareingreso IS NULL)
            BEGIN
                BEGIN TRANSACTION [TranReingresoRetapizadoGye]
                    BEGIN TRY
                        SELECT @w_articulo     = futRetapizados.ci_articulo,
                               @w_planilla     = futRetapizados.tx_planilla,
                               @w_fechaentrega = futRetapizados.fx_fecharegistro,
							   @w_codbodega    = futRetapizados.ci_bodega
                          FROM dbJardinesEsperanza.dbo.futRetapizados
                         WHERE ci_secuencia    = @i_codsolegre
                                     
                        SELECT @w_articuloorg = scit_Articulos.tx_articulo,
			                   @w_desbodega   = scit_Bodegas.tx_nombrebodega,
							   @w_articulodes = scit_Articulos.tx_articulo,
							   @w_existencia  = scit_Articulos.qn_existencia
                          FROM dbo.scit_Articulos 
						  LEFT JOIN dbo.scit_ArticulosBodegas
						    ON scit_ArticulosBodegas.ci_articulo = scit_Articulos.ci_articulo
						   AND scit_ArticulosBodegas.ci_bodega   = @w_codbodega
						  LEFT JOIN dbo.scit_Bodegas
						    ON scit_Bodegas.ci_bodega     = scit_ArticulosBodegas.ci_bodega
                         WHERE scit_Articulos.ci_articulo = @w_articulo

                        IF @@ROWCOUNT = 0
                        BEGIN
                            ROLLBACK TRANSACTION [TranReingresoRetapizadoGye]
                            SELECT @o_msgerror = 'El cofre/urna registrado no existe en nuestra base de datos'
                            RETURN -2
                        END
            
                        EXEC @w_ret           = dbo.pr_MovimientoBodega 
                             @i_tipomov       = 'RB',
                             @i_articulo      = @w_articulo,
                             @i_planilla      = @w_planilla,
                             @i_usuario       = @i_usuario,
							 @i_bodega        = @w_codbodega,
                             @i_solegre       = @i_codsolegre,
                             @o_transaccion   = @w_transaccion OUTPUT,
                             @o_msgerror      = @o_msgerror OUTPUT
            
                        IF @w_ret != 0
                        BEGIN
                            ROLLBACK TRANSACTION [TranReingresoRetapizadoGye]
                            RETURN @w_ret
                        END

						UPDATE dbJardinesEsperanza.dbo.futRetapizados
						   SET fx_fechareingreso   = GETDATE(),
						       ci_usuarioreingreso = @i_usuario,
						       ce_retapizado       = 'R'
						 WHERE ci_secuencia  = @i_codsolegre

						 IF @@ROWCOUNT = 0
						 BEGIN
                            ROLLBACK TRANSACTION [TranReingresoRetapizadoGye]
							SELECT @o_msgerror = 'Hubo un error al actualizar el Estado del Retapizado'
                            RETURN @w_ret
						 END
                   
                        SELECT CodArticuloOrigen  = @w_articulo,
                               DesArticuloOrigen  = @w_articuloorg,
                               CodArticuloDestino = null,
                               DesArticuloDestino = null,
                               CodPlanilla        = @w_planilla,
                               CodSoliEgre        = @i_codsolegre,
                               NombreFallecido    = null,
                               Usuario            = @i_usuario,
							   CodBodega          = @w_codbodega,
							   DesBodega          = @w_desbodega
            
                        SELECT @o_msgerror = 'Se efectuo correctamente el Reingreso'
            
                        COMMIT TRAN [TranReingresoRetapizadoGye]
                    END TRY
                    BEGIN CATCH
                        ROLLBACK TRAN [TranReingresoRetapizadoGye]
                        SELECT @o_msgerror = 'ERROR: ' + ERROR_MESSAGE()
                        RETURN -2
                    END CATCH
              --END TRANSACTION
            END
            ELSE
            BEGIN
                SELECT @o_msgerror = 'Solicitud de Ingreso seleccionada no esta en estado de Cofre/Urna Retirado o Sala'
                RETURN -1
            END
        END
        
        IF ('0002' IN (SELECT ci_grupocontable from dbo.scit_BodegaUsuario a INNER JOIN dbo.scit_Bodegas b ON a.ci_bodega = b.ci_bodega WHERE a.ci_usuario = @i_usuario))
        BEGIN
            IF EXISTS(SELECT 1 FROM dbCautisaJE.dbo.futRetapizados
                       WHERE ci_secuencia = @i_codsolegre
                         AND fx_fechareingreso IS NULL)
            BEGIN
                BEGIN TRANSACTION [TranReingresoRetapizado]
                    BEGIN TRY
                        SELECT @w_articulo     = ci_articulo,
                               @w_planilla     = futRetapizados.tx_planilla,
                               @w_fechaentrega = futRetapizados.fx_fecharegistro 
                          FROM dbCautisaJE.dbo.futRetapizados
                         WHERE ci_secuencia    = @i_codsolegre
                                     
                        SELECT @w_articuloorg = scit_Articulos.tx_articulo,
			                   @w_codbodega   = scit_ArticulosBodegas.ci_bodega,
			                   @w_desbodega   = scit_Bodegas.tx_nombrebodega,
							   @w_articulodes = scit_Articulos.tx_articulo,
							   @w_existencia  = scit_Articulos.qn_existencia
                          FROM dbo.scit_Articulos 
						  LEFT JOIN dbo.scit_ArticulosBodegas
						    ON scit_ArticulosBodegas.ci_articulo = scit_Articulos.ci_articulo
						  LEFT JOIN dbo.scit_Bodegas
						    ON scit_Bodegas.ci_bodega = scit_ArticulosBodegas.ci_bodega
                         WHERE scit_Articulos.ci_articulo = @w_articulo

                        IF @@ROWCOUNT = 0
                        BEGIN
                            ROLLBACK TRANSACTION [TranReingresoRetapizado]
                            SELECT @o_msgerror = 'El cofre/urna registrado no existe en nuestra base de datos'
                            RETURN -2
                        END
            
                        EXEC @w_ret           = dbo.pr_MovimientoBodega 
                             @i_tipomov       = 'RB',
                             @i_articulo      = @w_articulo,
                             @i_planilla      = @w_planilla,
                             @i_usuario       = @i_usuario,
							 @i_bodega        = @i_bodega,
                             @i_solegre       = @i_codsolegre,
                             @o_transaccion   = @w_transaccion OUTPUT,
                             @o_msgerror      = @o_msgerror OUTPUT
            
                        IF @w_ret != 0
                        BEGIN
                            ROLLBACK TRANSACTION [TranReingresoRetapizado]
                            RETURN @w_ret
                        END

						UPDATE dbCautisaJE.dbo.futRetapizados
						   SET fx_fechareingreso = GETDATE(),
						       ce_retapizado     = 'R'
						 WHERE ci_secuencia  = @i_codsolegre

						 IF @@ROWCOUNT = 0
						 BEGIN
                            ROLLBACK TRANSACTION [TranReingresoRetapizado]
							SELECT @o_msgerror = 'Hubo un error al actualizar el Estado del Retapizado'
                            RETURN @w_ret
						 END
                     
                        SELECT CodArticuloOrigen  = @w_articulo,
                               DesArticuloOrigen  = @w_articuloorg,
                               CodArticuloDestino = null,
                               DesArticuloDestino = null,
                               CodPlanilla        = @w_planilla,
                               CodSoliEgre        = @i_codsolegre,
                               NombreFallecido    = null,
                               Usuario            = @i_usuario,
							   CodBodega          = @w_codbodega,
							   DesBodega          = @w_desbodega
            
                        SELECT @o_msgerror = 'Se efectuo correctamente el Reingreso'
            
                        COMMIT TRAN [TranReingresoRetapizado]
                    END TRY
                    BEGIN CATCH
                        ROLLBACK TRAN [TranReingresoRetapizado]
                        SELECT @o_msgerror = 'ERROR: ' + ERROR_MESSAGE()
                        RETURN -2
                    END CATCH
              --END TRANSACTION
            END
            ELSE
            BEGIN
                SELECT @o_msgerror = 'Solicitud de Ingreso seleccionada no esta en estado de Cofre/Urna Retirado o Sala'
                RETURN -1
            END
		END

    END

    IF @i_accion = 'LR' -- Listado de Retapizados
	BEGIN
        BEGIN TRY
            SELECT Codigo             = futRetapizados.ci_secuencia,
                   Bodega             = futRetapizados.ci_bodega,
                   codProducto        = futRetapizados.ci_articulo,
                   Producto           = scit_Articulos.tx_articulo,
                   Inhumado           = NULL,
                   NombreProveedor    = LTRIM(RTRIM(cxpt_Proveedores.tx_razonsocial)),
                   Estado             = 4,
                   Comentario         = NULL,
                   ObservacionRetiro  = NULL,
                   ObservacionEntrega = NULL,
                   ObservacionSala    = NULL,
                   FotografiaSala     = NULL
              FROM dbJardinesEsperanza.dbo.futRetapizados
             INNER JOIN dbo.scit_Articulos
                ON scit_Articulos.ci_articulo = futRetapizados.ci_articulo
               AND scit_Articulos.ci_clase    = '0066' --COFRES
             INNER JOIN dbo.scit_ArticulosBodegas
                ON scit_ArticulosBodegas.ci_articulo = futRetapizados.ci_articulo
               AND scit_ArticulosBodegas.ci_bodega   = futRetapizados.ci_bodega
			   AND scit_ArticulosBodegas.ci_bodega IN (SELECT ci_bodega FROM dbo.scit_BodegaUsuario where ci_usuario=@i_usuario)
              LEFT JOIN dbo.cxpt_Proveedores
                ON cxpt_Proveedores.ci_proveedor = scit_Articulos.ci_proveedor
             WHERE futRetapizados.fx_fechareingreso IS NULL
               AND futRetapizados.ce_retapizado = 'I'
            UNION
            SELECT Codigo             = futRetapizados.ci_secuencia,
                   Bodega             = futRetapizados.ci_bodega,
                   codProducto        = futRetapizados.ci_articulo,
                   Producto           = scit_Articulos.tx_articulo,
                   Inhumado           = NULL,
                   NombreProveedor    = LTRIM(RTRIM(cxpt_Proveedores.tx_razonsocial)),
                   Estado             = 4,
                   Comentario         = NULL,
                   ObservacionRetiro  = NULL,
                   ObservacionEntrega = NULL,
                   ObservacionSala    = NULL,
                   FotografiaSala     = NULL
              FROM dbCautisaJE.dbo.futRetapizados
             INNER JOIN dbo.scit_Articulos
                ON scit_Articulos.ci_articulo = futRetapizados.ci_articulo
               AND scit_Articulos.ci_clase    = '0066' --COFRES
             INNER JOIN dbo.scit_ArticulosBodegas
                ON scit_ArticulosBodegas.ci_articulo = futRetapizados.ci_articulo
               AND scit_ArticulosBodegas.ci_bodega   = futRetapizados.ci_bodega
			   AND scit_ArticulosBodegas.ci_bodega IN (SELECT ci_bodega FROM dbo.scit_BodegaUsuario where ci_usuario=@i_usuario)
              LEFT JOIN dbo.cxpt_Proveedores
                ON cxpt_Proveedores.ci_proveedor = scit_Articulos.ci_proveedor
             WHERE futRetapizados.fx_fechareingreso IS NULL
               AND futRetapizados.ce_retapizado = 'I'
             ORDER BY futRetapizados.ci_secuencia
            
            SELECT @o_msgerror = 'Ejecucion OK'
        END TRY
        BEGIN CATCH
            SELECT @o_msgerror = ERROR_MESSAGE()
        END CATCH

	END

    IF @i_accion = 'LI' -- Listado de Solicitudes de Egreso
    BEGIN
        BEGIN TRY
            IF OBJECT_ID(N'tempdb..#tmpListadoSolicitud') IS NOT NULL
	           DROP TABLE #tmpListadoSolicitud

		    SELECT * 
			  INTO #tmpListadoSolicitud
			  FROM (
            SELECT Codigo          = futSolicitudEgreso.ci_solicitudegreso,
                   Bodega          = IIF(@i_bodega='000',futSolicitudEgreso.ci_bodega,@i_bodega),
                   codProducto     = futSolicitudEgreso.ci_articulo,
				   tipodocumento   = futSolicitudEgreso.tx_documentoorigen,
				   transaccionorgn = futSolicitudEgreso.tx_transaccionorigen,
                   Producto        = scit_Articulos.tx_articulo,
                   Inhumado        = LTRIM(RTRIM(futPlanilla.tx_nombrefallecido)),
                   NombreProveedor = LTRIM(RTRIM(cxpt_Proveedores.tx_razonsocial)),
                   Estado          = CASE 
                                      WHEN futSolicitudEgreso.fx_retiro   IS NULL 
                                       AND futSolicitudEgreso.fx_entrega  IS NULL
                                       AND futSolicitudEgreso.fx_sala     IS NULL
                                      THEN 0  --Inicial 
                                      WHEN futSolicitudEgreso.fx_retiro   IS NOT NULL 
                                       AND futSolicitudEgreso.fx_entrega  IS NULL
                                       AND futSolicitudEgreso.fx_sala     IS NULL
                                      THEN 1  --Retirado
                                      WHEN futSolicitudEgreso.fx_retiro   IS NOT NULL 
                                       AND futSolicitudEgreso.fx_entrega  IS NOT NULL 
                                       AND futSolicitudEgreso.fx_sala     IS NULL
                                      THEN 2  --Con Inhumado
                                      WHEN futSolicitudEgreso.fx_retiro   IS NOT NULL 
                                       AND futSolicitudEgreso.fx_entrega  IS NOT NULL 
                                       AND futSolicitudEgreso.fx_sala     IS NOT NULL
                                      THEN 3  --En Sala
                                      ELSE -1
                                     END,
                   Comentario         = futSolicitudEgreso.tx_observacion,
                   ObservacionRetiro  = futSolicitudEgreso.tx_observacionretiro,
                   ObservacionEntrega = futSolicitudEgreso.tx_observacionentrega,
                   ObservacionSala    = futSolicitudEgreso.tx_observacionsala,
                   FotografiaSala     = futSolicitudEgreso.tx_fotografiasala
              FROM dbJardinesEsperanza.dbo.futSolicitudEgreso WITH (NOLOCK)
             INNER JOIN dbo.scit_Articulos WITH (NOLOCK)
                ON scit_Articulos.ci_articulo = futSolicitudEgreso.ci_articulo
               AND scit_Articulos.ci_clase    = '0066' --COFRES
             INNER JOIN dbo.scit_ArticulosBodegas WITH (NOLOCK)
                ON scit_ArticulosBodegas.ci_articulo = futSolicitudEgreso.ci_articulo
               AND scit_ArticulosBodegas.ci_bodega   = IIF(@i_estado=0, @i_bodega, scit_ArticulosBodegas.ci_bodega)
              LEFT JOIN dbo.cxpt_Proveedores WITH (NOLOCK)
                ON cxpt_Proveedores.ci_proveedor = scit_Articulos.ci_proveedor
              LEFT JOIN dbJardinesEsperanza.dbo.futPlanilla WITH (NOLOCK)
                ON futPlanilla.ci_planilla = futSolicitudEgreso.tx_transaccionorigen
             WHERE futSolicitudEgreso.ci_usuario = IIF(@i_estado=0 OR @i_estado=2, futSolicitudEgreso.ci_usuario, @i_usuario)
               AND (IIF(futSolicitudEgreso.fx_retiro   IS NULL, 1, 0) = (CASE WHEN @i_estado<1 THEN 1 ELSE 0 END))
               AND (@i_estado = 9 OR (@i_estado != 9 AND (IIF(futSolicitudEgreso.fx_entrega  IS NULL ,1, 0) = (CASE WHEN @i_estado<2 THEN 1 ELSE 0 END))))
               AND ((@i_estado!=9 AND IIF(futSolicitudEgreso.fx_sala     IS NULL, 1, 0) = (CASE WHEN @i_estado<3 THEN 1 ELSE 0 END)) OR (@i_estado=9 AND futSolicitudEgreso.fx_sala IS NULL))
               AND ((@i_estado!=9 AND IIF(futSolicitudEgreso.fx_retapiza IS NULL, 1, 0) = (CASE WHEN @i_estado<4 THEN 1 ELSE 0 END)) OR (@i_estado=9 AND futSolicitudEgreso.fx_retapiza IS NULL))
               AND futSolicitudEgreso.te_ordenegreso = 'A'
            UNION
            SELECT Codigo          = futSolicitudEgreso.ci_solicitudegreso,
                   Bodega          = IIF(@i_bodega='000',futSolicitudEgreso.ci_bodega,@i_bodega),
                   codProducto     = futSolicitudEgreso.ci_articulo,
				   tipodocumento   = futSolicitudEgreso.tx_documentoorigen,
				   transaccionorgn = futSolicitudEgreso.tx_transaccionorigen,
                   Producto        = scit_Articulos.tx_articulo,
                   Inhumado        = LTRIM(RTRIM(futPlanilla.tx_nombrefallecido)),
                   NombreProveedor = LTRIM(RTRIM(cxpt_Proveedores.tx_razonsocial)),
                   Estado          = CASE 
                                      WHEN futSolicitudEgreso.fx_retiro   IS NULL 
                                       AND futSolicitudEgreso.fx_entrega  IS NULL
                                       AND futSolicitudEgreso.fx_sala     IS NULL
                                      THEN 0  --Inicial 
                                      WHEN futSolicitudEgreso.fx_retiro   IS NOT NULL 
                                       AND futSolicitudEgreso.fx_entrega  IS NULL
                                       AND futSolicitudEgreso.fx_sala     IS NULL
                                      THEN 1  --Retirado
                                      WHEN futSolicitudEgreso.fx_retiro   IS NOT NULL 
                                       AND futSolicitudEgreso.fx_entrega  IS NOT NULL 
                                       AND futSolicitudEgreso.fx_sala     IS NULL
                                      THEN 2  --Con Inhumado
                                      WHEN futSolicitudEgreso.fx_retiro   IS NOT NULL 
                                       AND futSolicitudEgreso.fx_entrega  IS NOT NULL 
                                       AND futSolicitudEgreso.fx_sala     IS NOT NULL
                                      THEN 3  --En Sala
                                      WHEN futSolicitudEgreso.fx_retiro   IS NULL 
                                       AND futSolicitudEgreso.fx_entrega  IS NULL 
                                       AND futSolicitudEgreso.fx_sala     IS NULL
                                      THEN 4  --Retapizado
                                      ELSE -1
                                     END,
                   Comentario         = futSolicitudEgreso.tx_observacion,
                   ObservacionRetiro  = futSolicitudEgreso.tx_observacionretiro,
                   ObservacionEntrega = futSolicitudEgreso.tx_observacionentrega,
                   ObservacionSala    = futSolicitudEgreso.tx_observacionsala,
                   FotografiaSala     = futSolicitudEgreso.tx_fotografiasala
              FROM dbCautisaJE.dbo.futSolicitudEgreso WITH (NOLOCK)
             INNER JOIN dbo.scit_Articulos
                ON scit_Articulos.ci_articulo = futSolicitudEgreso.ci_articulo
               AND scit_Articulos.ci_clase    = '0066' --COFRES
             INNER JOIN scit_ArticulosBodegas WITH (NOLOCK)
                ON scit_ArticulosBodegas.ci_articulo = futSolicitudEgreso.ci_articulo
               AND scit_ArticulosBodegas.ci_bodega   = IIF(@i_estado=0, @i_bodega, scit_ArticulosBodegas.ci_bodega)
              LEFT JOIN dbo.cxpt_Proveedores WITH (NOLOCK)
                ON cxpt_Proveedores.ci_proveedor = scit_Articulos.ci_proveedor
              LEFT JOIN dbCautisaJE.dbo.futPlanilla WITH (NOLOCK)
                ON futPlanilla.ci_planilla = futSolicitudEgreso.tx_transaccionorigen
             WHERE futSolicitudEgreso.ci_usuario = IIF(@i_estado=0 OR @i_estado=2, futSolicitudEgreso.ci_usuario, @i_usuario)
               AND (IIF(futSolicitudEgreso.fx_retiro   IS NULL, 1, 0) = (CASE WHEN @i_estado<1 THEN 1 ELSE 0 END))
               AND (@i_estado = 9 OR (@i_estado != 9 AND (IIF(futSolicitudEgreso.fx_entrega  IS NULL ,1, 0) = (CASE WHEN @i_estado<2 THEN 1 ELSE 0 END))))
               AND ((@i_estado!=9 AND IIF(futSolicitudEgreso.fx_sala     IS NULL, 1, 0) = (CASE WHEN @i_estado<3 THEN 1 ELSE 0 END)) OR (@i_estado=9 AND futSolicitudEgreso.fx_sala IS NULL))
               AND ((@i_estado!=9 AND IIF(futSolicitudEgreso.fx_retapiza IS NULL, 1, 0) = (CASE WHEN @i_estado<4 THEN 1 ELSE 0 END)) OR (@i_estado=9 AND futSolicitudEgreso.fx_retapiza IS NULL))
               AND futSolicitudEgreso.te_ordenegreso = 'A'
			) T


			UPDATE #tmpListadoSolicitud
			   SET Inhumado = vetCabeceraFactura.tx_fallecidofactura
			  FROM dbJardinesEsperanza.dbo.vetCabeceraFactura WITH (NOLOCK)
			 WHERE transaccionorgn = vetCabeceraFactura.ci_factura
			   AND tipodocumento   = 'FAC'
			   AND EXISTS (SELECT 1 
			                 FROM dbo.scit_Articulos WITH (NOLOCK)
						    INNER JOIN dbo.scit_ArticulosBodegas WITH (NOLOCK)
							   ON scit_ArticulosBodegas.ci_articulo = scit_Articulos.ci_articulo 
							INNER JOIN dbo.scit_Bodegas WITH (NOLOCK)
							   ON scit_Bodegas.ci_bodega = scit_ArticulosBodegas.ci_bodega
							  AND scit_Bodegas.ci_grupocontable = '0001'
							WHERE scit_Articulos.ci_articulo = codProducto)
			                                
			UPDATE #tmpListadoSolicitud
			   SET Inhumado = vetCabeceraFactura.tx_fallecidofactura
			  FROM dbCautisaJE.dbo.vetCabeceraFactura WITH (NOLOCK)
			 WHERE transaccionorgn = vetCabeceraFactura.ci_factura
			   AND tipodocumento   = 'FAC'
			   AND EXISTS (SELECT 1 
			                 FROM dbo.scit_Articulos WITH (NOLOCK)
						    INNER JOIN dbo.scit_ArticulosBodegas WITH (NOLOCK)
							   ON scit_ArticulosBodegas.ci_articulo = scit_Articulos.ci_articulo 
							INNER JOIN dbo.scit_Bodegas WITH (NOLOCK)
							   ON scit_Bodegas.ci_bodega = scit_ArticulosBodegas.ci_bodega
							  AND scit_Bodegas.ci_grupocontable = '0002'
							WHERE scit_Articulos.ci_articulo = codProducto)

            SELECT Codigo,
                   Bodega,
                   codProducto,
                   Producto,
                   Inhumado,
                   NombreProveedor,
                   Estado,
                   Comentario,
                   ObservacionRetiro,
                   ObservacionEntrega,
                   ObservacionSala,
                   FotografiaSala
			  FROM #tmpListadoSolicitud

            IF OBJECT_ID(N'tempdb..#tmpListadoSolicitud') IS NOT NULL
	           DROP TABLE #tmpListadoSolicitud

            SELECT @o_msgerror = 'Ejecucion OK'
        END TRY
        BEGIN CATCH
            SELECT @o_msgerror = ERROR_MESSAGE()
        END CATCH
    END --IF

    IF @i_accion = 'CO' -- Consulta individual de Cofre/Urna
    BEGIN
        BEGIN TRY
            IF EXISTS(SELECT 1 FROM [dbJardinesEsperanza].[dbo].[setPermisosUsuario] where ci_nivel0='MOV' AND ci_nivel2='MOV1110' and ci_nivel3=1 and ci_usuario=@i_usuario)
               SELECT @w_permisoprecio = 1
            ELSE 
               SELECT @w_permisoprecio = 0

            SELECT CodArticulo    = scit_Articulos.ci_articulo,
                   DesArticulo    = scit_Articulos.tx_articulo,
                   CodBodega      = scit_ArticulosBodegas.ci_bodega,
                   DesBodega      = scit_Bodegas.tx_nombrebodega,
                   Precio         = CONVERT(DECIMAL(19,2), IIF(@w_permisoprecio=1, scit_Articulos.va_costo, 0)),
                   Existencia     = CONVERT(BIGINT, scit_ArticulosBodegas.qn_existencia)
              FROM dbo.scit_Articulos
             INNER JOIN dbo.scit_ArticulosBodegas
                ON scit_ArticulosBodegas.ci_articulo = scit_Articulos.ci_articulo
			   AND scit_ArticulosBodegas.ci_bodega   = @i_bodega
              LEFT JOIN dbo.scit_Bodegas
                ON scit_Bodegas.ci_bodega = scit_ArticulosBodegas.ci_bodega
             WHERE scit_Articulos.ci_articulo = @i_articulo
               AND scit_Articulos.ci_clase = '0066' --COFRES

            IF @@ROWCOUNT = 0
            BEGIN
                SELECT @o_msgerror = 'Codigo de Cofre/Urna no existente (' + @i_articulo + ')'
                RETURN -1
            END
            ELSE
            BEGIN
                SELECT @o_msgerror = 'Ejecucion OK'
            END
        END TRY
        BEGIN CATCH
            SELECT @o_msgerror = ERROR_MESSAGE() + ' - ' + CONVERT(VARCHAR, ERROR_LINE())
            RETURN -2
        END CATCH
    END --IF

    IF @i_accion = 'UP' -- Actualizacion de Estado de Solicitud de Egreso
    BEGIN

        IF @i_estado <= 3
        BEGIN
            IF @i_estado = 1
            BEGIN
                SELECT @w_articulo        = ci_articulo, 
                       @w_planilla        = tx_transaccionorigen
                  FROM dbJardinesEsperanza.dbo.futSolicitudEgreso 
                 WHERE ci_solicitudegreso = @i_codsolegre

                SELECT @w_existencia = scit_Articulos.qn_existencia
                  FROM dbo.scit_Articulos
                 WHERE ci_articulo = @w_articulo

                 SELECT @w_existencia = ISNULL(@w_existencia, 0)

                 IF @w_existencia <= 0 
                 BEGIN
                     SELECT @o_msgerror = 'No se puede retirar un cofre sin existencia ' 
                     RETURN -2
                 END

                SELECT @w_existencia = scit_ArticulosBodegas.qn_existencia
                  FROM dbo.scit_ArticulosBodegas
                 WHERE ci_articulo = @w_articulo
				   AND ci_bodega   = @i_bodega

                 SELECT @w_existencia = ISNULL(@w_existencia, 0)

                 IF @w_existencia <= 0 
                 BEGIN
                     SELECT @o_msgerror = 'No se puede retirar un cofre sin existencia en Bodega' 
                     RETURN -2
                 END
            END

            IF @i_estado=3 AND ISNULL(@i_fotografia, '')= ''
            BEGIN
                SELECT @o_msgerror = 'Para hacer el cambio de estado a Puesto en Sala, se requiere que se envíe una fotografía'
                RETURN -9
            END

            IF @i_estado=2 AND ISNULL(@i_comentario, '')= ''
            BEGIN
                SELECT @o_msgerror = 'Para hacer el cambio de estado a Cofre con Inhumado, se requiere que se envíe un comentario'
                RETURN -9
            END

            IF @i_estado = 1
            BEGIN
                SELECT @w_articulo        = ci_articulo, 
                       @w_planilla        = tx_transaccionorigen
                  FROM dbJardinesEsperanza.dbo.futSolicitudEgreso 
                 WHERE ci_solicitudegreso = @i_codsolegre

                EXEC @w_ret           = dbo.pr_MovimientoBodega 
                        @i_tipomov       = 'OU',
                        @i_articulo      = @w_articulo,
                        @i_planilla      = @w_planilla,
                        @i_usuario       = @i_usuario,
						@i_bodega        = @i_bodega,
						@i_solegre       = @i_codsolegre,
						@o_transaccion   = @w_transaccion OUTPUT,
                        @o_msgerror      = @o_msgerror OUTPUT

                IF @w_ret != 0
                BEGIN
                    --ROLLBACK TRANSACTION [TranExistencia]
                    RETURN -1
                END
            END

            BEGIN TRANSACTION [TranExistencia]
                BEGIN TRY
                    IF ('0001' IN (SELECT ci_grupocontable from dbo.scit_BodegaUsuario a INNER JOIN dbo.scit_Bodegas b ON a.ci_bodega = b.ci_bodega WHERE a.ci_usuario = @i_usuario))
                    BEGIN
                        UPDATE dbJardinesEsperanza.dbo.futSolicitudEgreso
                           SET fx_retiro                 = IIF(@i_estado=1, GETDATE(), fx_retiro),
                               fx_entrega                = IIF(@i_estado=2, GETDATE(), fx_entrega),
                               fx_sala                   = IIF(@i_estado=3, GETDATE(), fx_sala),
                               tx_observacionretiro      = IIF(@i_estado=1, @i_comentario, tx_observacionretiro),
                               tx_observacionentrega     = IIF(@i_estado=2, @i_comentario, tx_observacionentrega),
                               tx_observacionsala        = IIF(@i_estado=3, @i_comentario, tx_observacionsala),
                               tx_fotografiasala         = IIF(@i_estado=3, @i_fotografia, null),
                               ci_usuarioretiro          = IIF(@i_estado=1, @i_usuario, ci_usuarioretiro),
                               ci_usuarioentrega         = IIF(@i_estado=2, @i_usuario, ci_usuarioentrega),
                               ci_usuariosala            = IIF(@i_estado=3, @i_usuario, ci_usuariosala),
                               ci_usuario                = @i_usuario,
							   ci_bodega                 = IIF(@i_estado=1, @i_bodega,  ci_bodega),
							   ci_transaccionegreso      = IIF(@i_estado=1, @w_transaccion, ci_transaccionegreso),
							   ci_tipo_transaccionegreso = IIF(@i_estado=1, 'OU', ci_tipo_transaccionreingreso)
                         WHERE ci_solicitudegreso    = @i_codsolegre
                           AND futSolicitudEgreso.te_ordenegreso = 'A'

                        IF @@ROWCOUNT = 0
                        BEGIN
                            SELECT @o_msgerror = 'No se actualizo ningun registro'
                            ROLLBACK TRANSACTION [TranExistencia]
                            RETURN -1
                        END
                    END

                    IF ('0002' IN (SELECT ci_grupocontable from dbo.scit_BodegaUsuario a INNER JOIN dbo.scit_Bodegas b ON a.ci_bodega = b.ci_bodega WHERE a.ci_usuario = @i_usuario))
                    BEGIN
                        UPDATE dbCautisaJE.dbo.futSolicitudEgreso
                           SET fx_retiro                 = IIF(@i_estado=1, GETDATE(), fx_retiro),
                               fx_entrega                = IIF(@i_estado=2, GETDATE(), fx_entrega),
                               fx_sala                   = IIF(@i_estado=3, GETDATE(), fx_sala),
                               tx_observacionretiro      = IIF(@i_estado=1, @i_comentario, tx_observacionretiro),
                               tx_observacionentrega     = IIF(@i_estado=2, @i_comentario, tx_observacionentrega),
                               tx_observacionsala        = IIF(@i_estado=3, @i_comentario, tx_observacionsala),
                               tx_fotografiasala         = IIF(@i_estado=3, @i_fotografia, null),
                               ci_usuarioretiro          = IIF(@i_estado=1, @i_usuario, ci_usuarioretiro),
                               ci_usuarioentrega         = IIF(@i_estado=2, @i_usuario, ci_usuarioentrega),
                               ci_usuariosala            = IIF(@i_estado=3, @i_usuario, ci_usuariosala),
                               ci_usuario                = @i_usuario,
							   ci_bodega                 = IIF(@i_estado=1, @i_bodega,  ci_bodega),
							   ci_transaccionegreso      = IIF(@i_estado=1, @w_transaccion, ci_transaccionegreso),
							   ci_tipo_transaccionegreso = IIF(@i_estado=1, 'OU', ci_tipo_transaccionreingreso)
                         WHERE ci_solicitudegreso    = @i_codsolegre
                           AND futSolicitudEgreso.te_ordenegreso = 'A'

                        IF @@ROWCOUNT = 0
                        BEGIN
                            SELECT @o_msgerror = 'No se actualizo ningun registro'
                            ROLLBACK TRANSACTION [TranExistencia]
                            RETURN -1
                        END

                    END

                    SELECT @o_msgerror = 'Se actualizo correctamente ' +
                            CASE WHEN @i_estado = 1 THEN 'el retiro de Cofre'
                                WHEN @i_estado = 2 THEN 'el Cofre con Inhumado'
                                WHEN @i_estado = 3 THEN 'la puesta en Sala'
                                ELSE ''
                            END

                    COMMIT TRAN [TranExistencia]

                END TRY
                BEGIN CATCH
                    ROLLBACK TRANSACTION [TranExistencia]
                    SELECT @o_msgerror = 'ERROR: ' + ERROR_MESSAGE()
                    RETURN -2
                END CATCH
             --END TRANSACTION
        END
        ELSE
        BEGIN
            SELECT 'Se especifico un Estado inexistente (' + CONVERT(VARCHAR,@i_codsolegre) + ')'
            RETURN -1
        END
    END

    IF @i_accion = 'CS' -- Consulta de Solicitud de Egreso
    BEGIN 
        IF OBJECT_ID(N'tempdb..#tmpListadoSolicitud') IS NOT NULL
           DROP TABLE #tmpConsultaSolEgreso

	    SELECT * 
		  INTO #tmpConsultaSolEgreso
		  FROM (
        SELECT Codigo          = futSolicitudEgreso.ci_solicitudegreso,
               Bodega          = scit_ArticulosBodegas.ci_bodega,
			   CodProducto     = futSolicitudEgreso.ci_articulo,
               Producto        = scit_Articulos.tx_articulo,
               Inhumado        = LTRIM(RTRIM(futPlanilla.tx_nombrefallecido)),
               NombreProveedor = LTRIM(RTRIM(cxpt_Proveedores.tx_razonsocial)),
               Estado          = CASE 
                                  WHEN futSolicitudEgreso.fx_retiro IS NULL 
                                   AND futSolicitudEgreso.fx_entrega IS NULL
                                   AND futSolicitudEgreso.fx_sala    IS NULL
                                  THEN 0
                                  WHEN futSolicitudEgreso.fx_retiro  IS NOT NULL 
                                   AND futSolicitudEgreso.fx_entrega IS NULL
                                   AND futSolicitudEgreso.fx_sala    IS NULL
                                  THEN 1
                                  WHEN futSolicitudEgreso.fx_retiro  IS NOT NULL 
                                   AND futSolicitudEgreso.fx_entrega IS NOT NULL 
                                   AND futSolicitudEgreso.fx_sala    IS NULL
                                  THEN 2
                                  WHEN futSolicitudEgreso.fx_retiro  IS NOT NULL 
                                   AND futSolicitudEgreso.fx_entrega IS NOT NULL 
                                   AND futSolicitudEgreso.fx_sala    IS NOT NULL
                                  THEN 3
                                  ELSE -1
                                 END,
               Comentario         = futSolicitudEgreso.tx_observacion,
               ObservacionRetiro  = futSolicitudEgreso.tx_observacionretiro,
               ObservacionEntrega = futSolicitudEgreso.tx_observacionentrega,
               ObservacionSala    = futSolicitudEgreso.tx_observacionsala,
               FotografiaSala     = futSolicitudEgreso.tx_fotografiasala,
			   transaccionorgn    = futSolicitudEgreso.tx_transaccionorigen,
			   tipodocumento      = futSolicitudEgreso.tx_documentoorigen
          FROM dbJardinesEsperanza.dbo.futSolicitudEgreso
         INNER JOIN dbo.scit_Articulos
            ON scit_Articulos.ci_articulo = futSolicitudEgreso.ci_articulo
           AND scit_Articulos.ci_clase    = '0066' --COFRES
         INNER JOIN dbo.scit_ArticulosBodegas
            ON scit_ArticulosBodegas.ci_articulo = futSolicitudEgreso.ci_articulo
		   AND scit_ArticulosBodegas.ci_bodega   = IIF(futSolicitudEgreso.ci_bodega='000',scit_ArticulosBodegas.ci_bodega,futSolicitudEgreso.ci_bodega)
          LEFT JOIN dbo.cxpt_Proveedores
            ON cxpt_Proveedores.ci_proveedor = scit_Articulos.ci_proveedor
          LEFT JOIN dbJardinesEsperanza.dbo.futPlanilla
            ON futPlanilla.ci_planilla = futSolicitudEgreso.tx_transaccionorigen
         WHERE futSolicitudEgreso.ci_usuario = ISNULL(@i_usuario, futSolicitudEgreso.ci_usuario)
           AND futSolicitudEgreso.ci_solicitudegreso = @i_codsolegre
           AND futSolicitudEgreso.te_ordenegreso = 'A'
        UNION
        SELECT Codigo          = futSolicitudEgreso.ci_solicitudegreso,
               Bodega          = scit_ArticulosBodegas.ci_bodega,
			   CodProducto     = futSolicitudEgreso.ci_articulo,
               Producto        = scit_Articulos.tx_articulo,
               Inhumado        = LTRIM(RTRIM(futPlanilla.tx_nombrefallecido)),
               NombreProveedor = LTRIM(RTRIM(cxpt_Proveedores.tx_razonsocial)),
               Estado          = CASE 
                                  WHEN futSolicitudEgreso.fx_retiro IS NULL 
                                   AND futSolicitudEgreso.fx_entrega IS NULL
                                   AND futSolicitudEgreso.fx_sala    IS NULL
                                  THEN 0
                                  WHEN futSolicitudEgreso.fx_retiro  IS NOT NULL 
                                   AND futSolicitudEgreso.fx_entrega IS NULL
                                   AND futSolicitudEgreso.fx_sala    IS NULL
                                  THEN 1
                                  WHEN futSolicitudEgreso.fx_retiro  IS NOT NULL 
                                   AND futSolicitudEgreso.fx_entrega IS NOT NULL 
                                   AND futSolicitudEgreso.fx_sala    IS NULL
                                  THEN 2
                                  WHEN futSolicitudEgreso.fx_retiro  IS NOT NULL 
                                   AND futSolicitudEgreso.fx_entrega IS NOT NULL 
                                   AND futSolicitudEgreso.fx_sala    IS NOT NULL
                                  THEN 3
                                  ELSE -1
                                 END,
               Comentario         = futSolicitudEgreso.tx_observacion,
               ObservacionRetiro  = futSolicitudEgreso.tx_observacionretiro,
               ObservacionEntrega = futSolicitudEgreso.tx_observacionentrega,
               ObservacionSala    = futSolicitudEgreso.tx_observacionsala,
               FotografiaSala     = futSolicitudEgreso.tx_fotografiasala,
			   transaccionorgn    = futSolicitudEgreso.tx_transaccionorigen,
			   tipodocumento      = futSolicitudEgreso.tx_documentoorigen
          FROM dbCautisaJE.dbo.futSolicitudEgreso
         INNER JOIN dbo.scit_Articulos
            ON scit_Articulos.ci_articulo = futSolicitudEgreso.ci_articulo
           AND scit_Articulos.ci_clase    = '0066' --COFRES
         INNER JOIN dbo.scit_ArticulosBodegas
            ON scit_ArticulosBodegas.ci_articulo = futSolicitudEgreso.ci_articulo
          LEFT JOIN dbo.cxpt_Proveedores
            ON cxpt_Proveedores.ci_proveedor = scit_Articulos.ci_proveedor
          LEFT JOIN dbCautisaJE.dbo.futPlanilla
            ON futPlanilla.ci_planilla = futSolicitudEgreso.tx_transaccionorigen
         WHERE futSolicitudEgreso.ci_usuario = ISNULL(@i_usuario, futSolicitudEgreso.ci_usuario)
           AND futSolicitudEgreso.ci_solicitudegreso = @i_codsolegre
           AND futSolicitudEgreso.te_ordenegreso = 'A'
		) T

			UPDATE #tmpConsultaSolEgreso
			   SET Inhumado = vetCabeceraFactura.tx_fallecidofactura
			  FROM dbJardinesEsperanza.dbo.vetCabeceraFactura WITH (NOLOCK)
			 WHERE transaccionorgn = vetCabeceraFactura.ci_factura
			   AND tipodocumento   = 'FAC'
			   AND EXISTS (SELECT 1 
			                 FROM dbo.scit_Articulos WITH (NOLOCK)
						    INNER JOIN dbo.scit_ArticulosBodegas WITH (NOLOCK)
							   ON scit_ArticulosBodegas.ci_articulo = scit_Articulos.ci_articulo 
							INNER JOIN dbo.scit_Bodegas WITH (NOLOCK)
							   ON scit_Bodegas.ci_bodega = scit_ArticulosBodegas.ci_bodega
							  AND scit_Bodegas.ci_grupocontable = '0001'
							WHERE scit_Articulos.ci_articulo = codProducto)
			                                
			UPDATE #tmpConsultaSolEgreso
			   SET Inhumado = vetCabeceraFactura.tx_fallecidofactura
			  FROM dbCautisaJE.dbo.vetCabeceraFactura WITH (NOLOCK)
			 WHERE transaccionorgn = vetCabeceraFactura.ci_factura
			   AND tipodocumento   = 'FAC'
			   AND EXISTS (SELECT 1 
			                 FROM dbo.scit_Articulos WITH (NOLOCK)
						    INNER JOIN dbo.scit_ArticulosBodegas WITH (NOLOCK)
							   ON scit_ArticulosBodegas.ci_articulo = scit_Articulos.ci_articulo 
							INNER JOIN dbo.scit_Bodegas WITH (NOLOCK)
							   ON scit_Bodegas.ci_bodega = scit_ArticulosBodegas.ci_bodega
							  AND scit_Bodegas.ci_grupocontable = '0002'
							WHERE scit_Articulos.ci_articulo = codProducto)

        SELECT * FROM #tmpConsultaSolEgreso

        IF OBJECT_ID(N'tempdb..#tmpListadoSolicitud') IS NOT NULL
           DROP TABLE #tmpConsultaSolEgreso

    END

    RETURN 0
END
GO

IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE major_id=OBJECT_ID('dbo.pr_CofresUrnas') and name='@i_accion')
   EXEC sp_dropextendedproperty  @name = '@i_accion' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'PROCEDURE', @level1name = 'pr_CofresUrnas'
GO
EXEC sys.sp_addextendedproperty @name=N'@i_accion', @value=N'Accion a ejecutar dentro del SP (BO-Listado de Bodegas, RI-Reingreso, LI-Listado de Solicitud de Egreso, CO-Consulta Individual)' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'pr_CofresUrnas'
GO

IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE major_id=OBJECT_ID('dbo.pr_CofresUrnas') and name='@i_articulo')
   EXEC sp_dropextendedproperty  @name = '@i_articulo' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'PROCEDURE', @level1name = 'pr_CofresUrnas'
GO
EXEC sys.sp_addextendedproperty @name=N'@i_articulo', @value=N'Codigo de Articulo' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'pr_CofresUrnas'
GO

IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE major_id=OBJECT_ID('dbo.pr_CofresUrnas') and name='@i_bodega')
   EXEC sp_dropextendedproperty  @name = '@i_bodega' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'PROCEDURE', @level1name = 'pr_CofresUrnas'
GO
EXEC sys.sp_addextendedproperty @name=N'@i_bodega', @value=N'Codigo de Bodega a consultar' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'pr_CofresUrnas'
GO

IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE major_id=OBJECT_ID('dbo.pr_CofresUrnas') and name='@i_codsolegre')
   EXEC sp_dropextendedproperty  @name = '@i_codsolegre' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'PROCEDURE', @level1name = 'pr_CofresUrnas'
GO
EXEC sys.sp_addextendedproperty @name=N'@i_codsolegre', @value=N'Codigo de Solicitud de Egreso' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'pr_CofresUrnas'
GO

IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE major_id=OBJECT_ID('dbo.pr_CofresUrnas') and name='@i_comentario')
   EXEC sp_dropextendedproperty  @name = '@i_comentario' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'PROCEDURE', @level1name = 'pr_CofresUrnas'
GO
EXEC sys.sp_addextendedproperty @name=N'@i_comentario', @value=N'Comentario para el cambio de estado' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'pr_CofresUrnas'
GO

IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE major_id=OBJECT_ID('dbo.pr_CofresUrnas') and name='@i_estado')
   EXEC sp_dropextendedproperty  @name = '@i_estado' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'PROCEDURE', @level1name = 'pr_CofresUrnas'
GO
EXEC sys.sp_addextendedproperty @name=N'@i_estado', @value=N'Codigo de Estado' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'pr_CofresUrnas'
GO

IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE major_id=OBJECT_ID('dbo.pr_CofresUrnas') and name='@i_fotografia')
   EXEC sp_dropextendedproperty  @name = '@i_fotografia' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'PROCEDURE', @level1name = 'pr_CofresUrnas'
GO
EXEC sys.sp_addextendedproperty @name=N'@i_fotografia', @value=N'Fotografía a cargar' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'pr_CofresUrnas'
GO

IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE major_id=OBJECT_ID('dbo.pr_CofresUrnas') and name='@i_usuario')
   EXEC sp_dropextendedproperty  @name = '@i_usuario' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'PROCEDURE', @level1name = 'pr_CofresUrnas'
GO
EXEC sys.sp_addextendedproperty @name=N'@i_usuario', @value=N'Usuario del sistema que realiza la operación' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'pr_CofresUrnas'
GO

IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE major_id=OBJECT_ID('dbo.pr_CofresUrnas') and name='@o_msgerror')
   EXEC sp_dropextendedproperty  @name = '@o_msgerror' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'PROCEDURE', @level1name = 'pr_CofresUrnas'
GO
EXEC sys.sp_addextendedproperty @name=N'@o_msgerror', @value=N'Respuesta del SP' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'pr_CofresUrnas'
GO

IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE major_id=OBJECT_ID('dbo.pr_CofresUrnas') and name='descripcion')
   EXEC sp_dropextendedproperty  @name = 'descripcion' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'PROCEDURE', @level1name = 'pr_CofresUrnas'
GO
EXEC sys.sp_addextendedproperty @name=N'descripcion', @value=N'SP de consulta de Cofres Urnas y Actualizacion de Estados de Solicitudes de Egreso' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'pr_CofresUrnas'
GO

sp_help pr_CofresUrnas
GO

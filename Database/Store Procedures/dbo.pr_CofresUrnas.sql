USE [dbJardiesaDC]
GO
/****** Object:  StoredProcedure [dbo].[pr_CofresUrnas]    Script Date: 10/11/2023 09:28:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[pr_CofresUrnas]
    @i_accion         varchar(2),
    @i_bodega         varchar(3)     = null,
    @i_usuario        varchar(15)    = null,
    @i_codsolegre     bigint         = null,
    @i_articulo       varchar(20)    = null,
    @i_estado         smallint       = 0,
    @i_retapizado     bit            = 0,
    @i_factura        varchar(20)    = null,
    @i_nombrelimpieza varchar(50)    = null,
    @i_observacion    varchar(200)   = null,
    @i_comentario     varchar(500)   = null,
    @i_fotografia     nvarchar(max)  = null,
    @o_msgerror       varchar(200)   = '' OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS(SELECT 1 FROM dbo.ssatParametrosGenerales WHERE ci_aplicacion='MOV' AND ci_parametro = 'DEBUG' AND tx_parametro = 'SI')
    BEGIN
        IF NOT EXISTS(SELECT 1 FROM sys.all_objects WHERE object_id=OBJECT_ID('dbo.trace_movil'))
        BEGIN
            CREATE TABLE trace_movil (fechahora datetime default getdate(), mensaje varchar(max))
        END

        INSERT INTO trace_movil (mensaje) 
        SELECT 'DECLARE @w_ret int, @w_msgerror varchar(200); '+ char(13)
               +'EXEC @w_ret = dbo.pr_CofresUrnas '+ char(13)
               +'  @i_accion='+ISNULL(CHAR(39)+@i_accion+CHAR(39),'null')+ char(13)
               +', @i_bodega='+isnull(CHAR(39)+@i_bodega+CHAR(39),'null')+ char(13)
               +', @i_usuario='+isnull(CHAR(39)+@i_usuario+CHAR(39),'null')+ char(13)
               +', @i_codsolegre='+ISNULL(convert(varchar,@i_codsolegre),'null')+ char(13)
               +', @i_articulo='+ISNULL(CHAR(39)+@i_articulo+CHAR(39),'null')+ char(13)
               +', @i_estado='+ISNULL(convert(varchar,@i_estado),'null')+ char(13)
               +', @i_retapizado=' + ISNULL(CONVERT(varchar,@i_retapizado),'null') + char(13)
               +', @i_factura='+ISNULL(CHAR(39)+@i_factura+CHAR(39),'null')+ char(13)
               +', @i_nombrelimpieza='+ISNULL(CHAR(39)+@i_nombrelimpieza+CHAR(39),'null')+ char(13)
               +', @i_observacion='+ISNULL(CHAR(39)+@i_observacion+CHAR(39),'null')+ char(13)
               +', @i_comentario='+ISNULL(CHAR(39)+@i_comentario+CHAR(39),'null')+ char(13)
               +', @i_fotografia='+ISNULL(CHAR(39)+@i_fotografia+CHAR(39),'null')+ char(13)
               +', @o_msgerror=@w_msgerror OUTPUT; '+ char(13)
               +'  SELECT @w_ret, @w_msgerror'+ char(13)
    END


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
            @w_desbodega        varchar(60),
            @w_alquilado        char(1),
            @w_estado           int,
            @w_tipotransac      varchar(3),
            @w_solicitudegreso  int

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
                         AND (fx_retiro IS NOT NULL OR fx_entrega IS NOT NULL) 
                         AND fx_sala    IS NULL
						 AND te_ordenegreso = 'A')
						 
            BEGIN
                BEGIN TRANSACTION [TranReingreso]
                    BEGIN TRY
                        SELECT @w_articulo     = ci_articulo,
                               @w_planilla     = tx_transaccionorigen,
                               @w_tipotransac  = tx_documentoorigen,
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

                            IF NOT EXISTS(SELECT 1 
                                        FROM dbJardinesEsperanza.dbo.futRetapizados 
                                       WHERE ci_articulo      = @w_articulo
                                         AND tx_planilla      = @w_planilla
                                         AND ci_solegreorg    = @i_codsolegre
                                         AND CONVERT(DATE,fx_fecharegistro) = CONVERT(DATE,GETDATE())
                                         AND ci_bodega        = @w_codbodega)
                            BEGIN
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
                                       ci_tipo_transaccionegreso,
                                       ci_transaccionreingreso,
                                       ci_tipo_transaccionreingreso,
                                       ci_factura
                                )
                                SELECT ci_articulo                  = @w_articulo, 
                                       tx_planilla                  = @w_planilla, 
                                       ci_solegreorg                = @i_codsolegre, 
                                       fx_fecharegistro             = GETDATE(), 
                                       ci_bodega                    = @w_codbodega, 
                                       ce_retapizado                = 'I', 
                                       ci_usuarioretapizado         = @i_usuario,
                                       ci_transaccionegreso         = @w_transaccionret,
                                       ci_tipo_transaccionegreso    = 'OU',
                                       ci_transaccionreingreso      = null,
                                       ci_tipo_transaccionreingreso = null,
                                       ci_factura                   = @i_factura

                                IF @@ROWCOUNT = 0
                                BEGIN
                                    ROLLBACK TRANSACTION [TranReingreso]
                                    SELECT @o_msgerror = 'Error al ingresar el registro del Retapizado'
                                    RETURN @w_ret
                                END
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

                        IF @w_tipotransac = 'INH' AND @w_planilla IS NOT NULL
                        BEGIN
                            UPDATE dbJardinesEsperanza.dbo.futDetalleOrdenTrabajo
                               SET ci_articulo = @i_articulo
                              FROM dbJardinesEsperanza.dbo.futCabeceraOrdenTrabajo 
                             WHERE ci_planilla = @w_planilla 
                               AND futDetalleOrdenTrabajo.ci_orden = futCabeceraOrdenTrabajo.ci_orden
                               AND futDetalleOrdenTrabajo.ci_articulo = @w_articulo

                            IF @@ROWCOUNT = 0
                            BEGIN
                                ROLLBACK TRANSACTION [TranReingreso]
                                SELECT @o_msgerror = 'No se actualizo el cofre en el detalle de orden de trabajo'
                                RETURN -1
                            END
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
                        IF @i_retapizado = 1 SELECT @o_msgerror = @o_msgerror + '. El cofre fue enviado a Retapizar'
            
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
                               @w_tipotransac  = tx_documentoorigen,
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

                            IF NOT EXISTS(SELECT 1 
                                        FROM dbCautisaJE.dbo.futRetapizados 
                                       WHERE ci_articulo      = @w_articulo
                                         AND tx_planilla      = @w_planilla
                                         AND ci_solegreorg    = @i_codsolegre
                                         AND CONVERT(DATE,fx_fecharegistro) = CONVERT(DATE,GETDATE())
                                         AND ci_bodega        = @w_codbodega)
                            BEGIN
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
                                       ci_tipo_transaccionegreso,
                                       ci_transaccionreingreso,
                                       ci_tipo_transaccionreingreso
                                )
                                SELECT ci_articulo                  = @w_articulo, 
                                       ci_planillaorg               = @w_planilla, 
                                       ci_solegreorg                = @i_codsolegre, 
                                       fx_fecharegistro             = GETDATE(), 
                                       ci_bodega                    = @w_codbodega, 
                                       ce_retapizado                = 'I', 
                                       ci_usuarioretapizado         = @i_usuario,
                                       ci_transaccionegreso         = @w_transaccionret,
                                       ci_tipo_transaccionegreso    = 'OU',
                                       ci_transaccionreingreso      = null,
                                       ci_tipo_transaccionreingreso = null

                                IF @@ROWCOUNT = 0
                                BEGIN
                                    ROLLBACK TRANSACTION [TranReingresoMilagro]
                                    SELECT @o_msgerror = 'Error al ingresar el registro del Retapizado'
                                    RETURN @w_ret
                                END
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
            
                        IF @w_tipotransac = 'INH' AND @w_planilla IS NOT NULL
                        BEGIN
                            UPDATE dbCautisaJE.dbo.futDetalleOrdenTrabajo
                               SET ci_articulo = @i_articulo
                              FROM dbCautisaJE.dbo.futCabeceraOrdenTrabajo 
                             WHERE ci_planilla = @w_planilla 
                               AND futDetalleOrdenTrabajo.ci_orden = futCabeceraOrdenTrabajo.ci_orden
                               AND futDetalleOrdenTrabajo.ci_articulo = @w_articulo

                            IF @@ROWCOUNT = 0
                            BEGIN
                                ROLLBACK TRANSACTION [TranReingreso]
                                SELECT @o_msgerror = 'No se actualizo el cofre en el detalle de orden de trabajo'
                                RETURN -1
                            END
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
                        IF @i_retapizado = 1 SELECT @o_msgerror = @o_msgerror + '. El cofre fue enviado a Retapizar'
            
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
                       WHERE ci_solegreorg  = @i_codsolegre
                         AND ce_retapizado = 'I'
                      )
            BEGIN
                BEGIN TRANSACTION [TranReingresoRetapizadoGye]
                    BEGIN TRY
                        SELECT @w_articulo     = futRetapizados.ci_articulo,
                               @w_planilla     = futRetapizados.tx_planilla,
                               @w_fechaentrega = futRetapizados.fx_fecharegistro,
                               @w_codbodega    = futRetapizados.ci_bodega
                          FROM dbJardinesEsperanza.dbo.futRetapizados
                         WHERE ci_solegreorg    = @i_codsolegre
                                     
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
                           SET ci_transaccionreingreso      = @w_transaccion,
                               ci_tipo_transaccionreingreso = 'RB',
                               fx_fechareingreso            = GETDATE(),
                               ci_usuarioreingreso          = @i_usuario,
                               ce_retapizado                = CASE WHEN @i_retapizado=0 THEN 'N'               ELSE 'R'  END,
                               ci_factura                   = CASE WHEN @i_retapizado=1 THEN @i_factura        ELSE null END,
                               tx_nombrelimpieza            = CASE WHEN @i_retapizado=0 THEN @i_nombrelimpieza ELSE null END,
                               tx_observacion               = @i_observacion
                         WHERE ci_solegreorg  = @i_codsolegre

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
                               DesBodega          = @w_desbodega,
                               Observacion        = CASE WHEN @i_retapizado=0 THEN 'El articulo no fue retapizado' + ISNULL(', pero fue limpiado por ' + @i_nombrelimpieza, '') + ISNULL(', bajo la siguiente observacion : ' + @i_observacion,'')
                                                         WHEN @i_retapizado=1 THEN 'El articulo fue retapizado' + ISNULL(', se emitio factura #' + @i_factura, '') + ISNULL(', bajo la siguiente observacion : ' + @i_observacion,'')
                                                         ELSE 'n/a'
                                                    END
            
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
                SELECT @o_msgerror = 'La solicitud de Retapizado no se encuentra disponible, probablemente ya fue encuentra Reingresada, por favor refresque la pantalla'
                RETURN -1
            END
        END
        
        IF ('0002' IN (SELECT ci_grupocontable from dbo.scit_BodegaUsuario a INNER JOIN dbo.scit_Bodegas b ON a.ci_bodega = b.ci_bodega WHERE a.ci_usuario = @i_usuario))
        BEGIN
            IF EXISTS(SELECT 1 FROM dbCautisaJE.dbo.futRetapizados
                       WHERE ci_solegreorg = @i_codsolegre
                         AND ce_retapizado = 'I')
            BEGIN
                BEGIN TRANSACTION [TranReingresoRetapizado]
                    BEGIN TRY
                        SELECT @w_articulo     = ci_articulo,
                               @w_planilla     = futRetapizados.tx_planilla,
                               @w_fechaentrega = futRetapizados.fx_fecharegistro 
                          FROM dbCautisaJE.dbo.futRetapizados
                         WHERE ci_solegreorg   = @i_codsolegre
                                     
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
                           SET ci_transaccionreingreso      = @w_transaccion,
                               ci_tipo_transaccionreingreso = 'RB',
                               fx_fechareingreso            = GETDATE(),
                               ci_usuarioreingreso          = @i_usuario,
                               ce_retapizado                = CASE WHEN @i_retapizado=0 THEN 'N'               ELSE 'R'  END,
                               ci_factura                   = CASE WHEN @i_retapizado=1 THEN @i_factura        ELSE null END,
                               tx_nombrelimpieza            = CASE WHEN @i_retapizado=0 THEN @i_nombrelimpieza ELSE null END,
                               tx_observacion               = @i_observacion
                         WHERE ci_solegreorg  = @i_codsolegre

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
                               DesBodega          = @w_desbodega,
                               Observacion        = CASE WHEN @i_retapizado=0 THEN 'El articulo no fue retapizado' + ISNULL(', pero fue limpiado por ' + @i_nombrelimpieza, '') + ISNULL(', bajo la siguiente observacion : ' + @i_observacion,'')
                                                         WHEN @i_retapizado=1 THEN 'El articulo fue retapizado' + ISNULL(', se emitio factura #' + @i_factura, '') + ISNULL(', bajo la siguiente observacion : ' + @i_observacion,'')
                                                         ELSE 'n/a'
                                                    END
            
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
                SELECT @o_msgerror = 'La solicitud de Retapizado no se encuentra disponible, probablemente ya fue encuentra Reingresada, por favor refresque la pantalla'
                RETURN -1
            END
        END

    END

    IF @i_accion = 'LR' -- Listado de Retapizados
    BEGIN
        BEGIN TRY
            IF OBJECT_ID(N'tempdb..#tmpListadoSolicitud') IS NOT NULL
               DROP TABLE #tmpListadoRetapizados

            SELECT * 
              INTO #tmpListadoRetapizados
              FROM (
            SELECT codigo             = futRetapizados.ci_solegreorg,
                   codigoretapizado   = futRetapizados.ci_secuencia,
                   bodega             = futRetapizados.ci_bodega,
                   codProducto        = futRetapizados.ci_articulo,
                   producto           = scit_Articulos.tx_articulo,
                   inhumado           = LTRIM(RTRIM(futPlanilla.tx_nombrefallecido)),
                   nombreproveedor    = LTRIM(RTRIM(cxpt_Proveedores.tx_razonsocial)),
                      SalaVelacion       = futSalasVelacion.tx_sala,
                   estado             = 4,
                   tipodocumento      = futSolicitudEgreso.tx_documentoorigen,
                   transaccionorgn    = futSolicitudEgreso.tx_transaccionorigen,
                   comentario         = NULL,
                   observacionretiro  = NULL,
                   observacionentrega = NULL,
                   observacionsala    = NULL,
                   fotografiasala     = NULL
              FROM dbJardinesEsperanza.dbo.futRetapizados
             INNER JOIN dbo.scit_Articulos
                ON scit_Articulos.ci_articulo = futRetapizados.ci_articulo
               AND scit_Articulos.ci_clase    = '0066' --COFRES
             INNER JOIN dbo.scit_ArticulosBodegas
                ON scit_ArticulosBodegas.ci_articulo = futRetapizados.ci_articulo
               AND scit_ArticulosBodegas.ci_bodega   = futRetapizados.ci_bodega
               --AND scit_ArticulosBodegas.ci_bodega IN (SELECT ci_bodega FROM dbo.scit_BodegaUsuario where ci_usuario=@i_usuario)
              LEFT JOIN dbJardinesEsperanza.dbo.futSolicitudEgreso WITH (NOLOCK)
                ON futSolicitudEgreso.ci_solicitudegreso = futRetapizados.ci_solegreorg
              LEFT JOIN dbJardinesEsperanza.dbo.futPlanilla WITH (NOLOCK)
                ON futPlanilla.ci_planilla = futSolicitudEgreso.tx_transaccionorigen
              LEFT JOIN dbo.cxpt_Proveedores
                ON cxpt_Proveedores.ci_proveedor = scit_Articulos.ci_proveedor
              LEFT JOIN dbJardinesEsperanza.dbo.futSalasVelacion WITH (NOLOCK)
                ON futSalasVelacion.ci_sala = futPlanilla.ci_sala
             WHERE futRetapizados.fx_fechareingreso IS NULL
               AND futRetapizados.ce_retapizado = 'I'
            UNION
            SELECT codigo             = futRetapizados.ci_solegreorg,
                   codigoretapizado   = futRetapizados.ci_secuencia,
                   bodega             = futRetapizados.ci_bodega,
                   codProducto        = futRetapizados.ci_articulo,
                   producto           = scit_Articulos.tx_articulo,
                   inhumado           = LTRIM(RTRIM(futPlanilla.tx_nombrefallecido)),
                   nombreProveedor    = LTRIM(RTRIM(cxpt_Proveedores.tx_razonsocial)),
                      SalaVelacion       = futSalasVelacion.tx_sala,
                   estado             = 4,
                   tipodocumento      = futSolicitudEgreso.tx_documentoorigen,
                   transaccionorgn    = futSolicitudEgreso.tx_transaccionorigen,
                   comentario         = NULL,
                   observacionretiro  = NULL,
                   observacionentrega = NULL,
                   observacionsala    = NULL,
                   fotografiasala     = NULL
              FROM dbCautisaJE.dbo.futRetapizados
             INNER JOIN dbo.scit_Articulos
                ON scit_Articulos.ci_articulo = futRetapizados.ci_articulo
               AND scit_Articulos.ci_clase    = '0066' --COFRES
             INNER JOIN dbo.scit_ArticulosBodegas
                ON scit_ArticulosBodegas.ci_articulo = futRetapizados.ci_articulo
               AND scit_ArticulosBodegas.ci_bodega   = futRetapizados.ci_bodega
               AND scit_ArticulosBodegas.ci_bodega IN (SELECT ci_bodega FROM dbo.scit_BodegaUsuario where ci_usuario=@i_usuario)
              LEFT JOIN dbJardinesEsperanza.dbo.futSolicitudEgreso WITH (NOLOCK)
                ON futSolicitudEgreso.ci_solicitudegreso = futRetapizados.ci_solegreorg
              LEFT JOIN dbJardinesEsperanza.dbo.futPlanilla WITH (NOLOCK)
                ON futPlanilla.ci_planilla = futSolicitudEgreso.tx_transaccionorigen
              LEFT JOIN dbo.cxpt_Proveedores
                ON cxpt_Proveedores.ci_proveedor = scit_Articulos.ci_proveedor
              LEFT JOIN dbJardinesEsperanza.dbo.futSalasVelacion WITH (NOLOCK)
                ON futSalasVelacion.ci_sala = futPlanilla.ci_sala
             WHERE futRetapizados.fx_fechareingreso IS NULL
               AND futRetapizados.ce_retapizado = 'I') t
             --ORDER BY futRetapizados.ci_secuencia

            UPDATE #tmpListadoRetapizados
               SET inhumado = vetCabeceraFactura.tx_fallecidofactura
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
                                            
            UPDATE #tmpListadoRetapizados
               SET inhumado = vetCabeceraFactura.tx_fallecidofactura
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

            SELECT codigo,
                   codigoretapizado,
                   Bodega,
                   codProducto,
                   Producto,
                   Inhumado,
                   NombreProveedor,
                   SalaVelacion,
                   Estado,
                   Comentario,
                   ObservacionRetiro,
                   ObservacionEntrega,
                   ObservacionSala,
                   FotografiaSala
              FROM #tmpListadoRetapizados
             ORDER BY Codigo
            
            IF OBJECT_ID(N'tempdb..#tmpListadoSolicitud') IS NOT NULL
               DROP TABLE #tmpListadoRetapizados

            SELECT @o_msgerror = 'Ejecucion OK'
        END TRY
        BEGIN CATCH
            SELECT @o_msgerror = ERROR_MESSAGE()
            RETURN -9
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
                   NombreBodega    = scit_Bodegas.ci_bodega + ' - ' + scit_Bodegas.tx_nombrebodega,
                   codProducto     = futSolicitudEgreso.ci_articulo,
                   tipodocumento   = futSolicitudEgreso.tx_documentoorigen,
                   transaccionorgn = futSolicitudEgreso.tx_transaccionorigen,
                   Producto        = scit_Articulos.tx_articulo,
                   Inhumado        = LTRIM(RTRIM(ISNULL(futSolicitudEgreso.tx_nombrefallecido, futPlanilla.tx_nombrefallecido))),
                   NombreProveedor = LTRIM(RTRIM(cxpt_Proveedores.tx_razonsocial)),
                   SalaVelacion    = futSalasVelacion.tx_sala,
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
              LEFT JOIN dbo.scit_Bodegas WITH (NOLOCK)
                ON scit_Bodegas.ci_bodega = futSolicitudEgreso.ci_bodega
              LEFT JOIN dbo.cxpt_Proveedores WITH (NOLOCK)
                ON cxpt_Proveedores.ci_proveedor = scit_Articulos.ci_proveedor
              LEFT JOIN dbJardinesEsperanza.dbo.futPlanilla WITH (NOLOCK)
                ON futPlanilla.ci_planilla = futSolicitudEgreso.tx_transaccionorigen
              LEFT JOIN dbJardinesEsperanza.dbo.futSalasVelacion WITH (NOLOCK)
                ON futSalasVelacion.ci_sala = futPlanilla.ci_sala
             WHERE futSolicitudEgreso.ci_usuario = IIF(@i_estado IN (0, 2, 9), futSolicitudEgreso.ci_usuario, @i_usuario)
               AND (IIF(futSolicitudEgreso.fx_retiro   IS NULL, 1, 0) = (CASE WHEN @i_estado<1 THEN 1 ELSE 0 END))
               AND ( @i_estado = 9 OR (@i_estado != 9 AND (IIF(futSolicitudEgreso.fx_entrega IS NULL ,1, 0) = (CASE WHEN @i_estado<2 THEN 1 ELSE 0 END))))
               AND ((@i_estado = 9 AND futSolicitudEgreso.fx_sala IS NULL) OR (@i_estado!=9 AND IIF(futSolicitudEgreso.fx_sala IS NULL, 1, 0) = (CASE WHEN @i_estado<3 THEN 1 ELSE 0 END)))
               AND futSolicitudEgreso.te_ordenegreso = 'A'
            UNION
            SELECT Codigo          = futSolicitudEgreso.ci_solicitudegreso,
                   Bodega          = IIF(@i_bodega='000',futSolicitudEgreso.ci_bodega,@i_bodega),
                   NombreBodega    = scit_Bodegas.ci_bodega + ' - ' + scit_Bodegas.tx_nombrebodega,
                   codProducto     = futSolicitudEgreso.ci_articulo,
                   tipodocumento   = futSolicitudEgreso.tx_documentoorigen,
                   transaccionorgn = futSolicitudEgreso.tx_transaccionorigen,
                   Producto        = scit_Articulos.tx_articulo,
                   Inhumado        = LTRIM(RTRIM(ISNULL(futSolicitudEgreso.tx_nombrefallecido, futPlanilla.tx_nombrefallecido))),
                   NombreProveedor = LTRIM(RTRIM(cxpt_Proveedores.tx_razonsocial)),
                   SalaVelacion    = futSalasVelacion.tx_sala,
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
              LEFT JOIN dbo.scit_Bodegas WITH (NOLOCK)
                ON scit_Bodegas.ci_bodega = futSolicitudEgreso.ci_bodega
              LEFT JOIN dbo.cxpt_Proveedores WITH (NOLOCK)
                ON cxpt_Proveedores.ci_proveedor = scit_Articulos.ci_proveedor
              LEFT JOIN dbCautisaJE.dbo.futPlanilla WITH (NOLOCK)
                ON futPlanilla.ci_planilla = futSolicitudEgreso.tx_transaccionorigen
              LEFT JOIN dbCautisaJE.dbo.futSalasVelacion WITH (NOLOCK)
                ON futSalasVelacion.ci_sala = futPlanilla.ci_sala
             WHERE futSolicitudEgreso.ci_usuario = IIF(@i_estado IN (0, 2, 9), futSolicitudEgreso.ci_usuario, @i_usuario)
               AND (IIF(futSolicitudEgreso.fx_retiro   IS NULL, 1, 0) = (CASE WHEN @i_estado<1 THEN 1 ELSE 0 END))
               AND (@i_estado = 9 OR (@i_estado != 9 AND (IIF(futSolicitudEgreso.fx_entrega  IS NULL ,1, 0) = (CASE WHEN @i_estado<2 THEN 1 ELSE 0 END))))
               AND ((@i_estado!=9 AND IIF(futSolicitudEgreso.fx_sala     IS NULL, 1, 0) = (CASE WHEN @i_estado<3 THEN 1 ELSE 0 END)) OR (@i_estado=9 AND futSolicitudEgreso.fx_sala IS NULL))
               AND futSolicitudEgreso.te_ordenegreso = 'A'
            ) T

            DELETE #tmpListadoSolicitud 
             WHERE tipodocumento = 'FAC'
               AND Estado > 0

            UPDATE #tmpListadoSolicitud
               SET Inhumado = ISNULL(#tmpListadoSolicitud.Inhumado, vetCabeceraFactura.tx_fallecidofactura)
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
               SET Inhumado = ISNULL(#tmpListadoSolicitud.Inhumado, vetCabeceraFactura.tx_fallecidofactura)
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

            SELECT DISTINCT
                   Codigo,
                   Bodega,
                   NombreBodega,
                   codProducto,
                   Producto,
                   Inhumado,
                   NombreProveedor,
                   SalaVelacion,
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
            RETURN -9
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
        SELECT @w_articulo   = ci_articulo, 
               @w_planilla   = tx_transaccionorigen,
               @w_alquilado  = te_alquilado,
               @w_codbodega  = ci_bodega,
               @w_estado     = CASE
                                 WHEN fx_retiro IS NULL     AND fx_entrega IS NULL     AND fx_sala IS NULL THEN 0
                                 WHEN fx_retiro IS NOT NULL AND fx_entrega IS NULL     AND fx_sala IS NULL THEN 1
                                 WHEN fx_retiro IS NOT NULL AND fx_entrega IS NOT NULL AND fx_sala IS NULL THEN 2
                                 WHEN fx_retiro IS NOT NULL AND fx_entrega IS NOT NULL AND fx_sala IS NOT NULL THEN 3
                                 ELSE 4
                               END
          FROM dbJardinesEsperanza.dbo.futSolicitudEgreso WITH(NOLOCK)
         WHERE ci_solicitudegreso = @i_codsolegre
    
        IF @w_estado = @i_estado 
        BEGIN
            SELECT @o_msgerror = 'El cofre/urna ya fue ' + 
                      CASE WHEN @i_estado = 1 THEN 'retirado'
                           WHEN @i_estado = 2 THEN 'entregado'
                           WHEN @i_estado = 3 THEN 'puesto en sala'
                           ELSE 'procesado'
                       END
                       + ' previamente, por favor actualice el listado'
            RETURN -2
        END

        IF @i_estado <= 3
        BEGIN
            IF @i_estado = 1
            BEGIN

                SELECT @w_existencia = scit_Articulos.qn_existencia
                  FROM dbo.scit_Articulos WITH(NOLOCK)
                 WHERE ci_articulo = @w_articulo

                 SELECT @w_existencia = ISNULL(@w_existencia, 0)

                 IF @w_existencia <= 0 
                 BEGIN
                     SELECT @o_msgerror = 'No se puede retirar un cofre sin existencia ' 
                     RETURN -2
                 END

                SELECT @w_existencia = scit_ArticulosBodegas.qn_existencia
                  FROM dbo.scit_ArticulosBodegas WITH(NOLOCK)
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
                  FROM dbJardinesEsperanza.dbo.futSolicitudEgreso WITH(NOLOCK)
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
				    SELECT @o_msgerror = 'No se pudo efectuar moviemiento en la Bodega'
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
                               tx_observacionretiro      = IIF(@i_estado=1, ISNULL(@i_comentario,'n/a'), tx_observacionretiro),
                               tx_observacionentrega     = IIF(@i_estado=2, ISNULL(@i_comentario,'n/a'), tx_observacionentrega),
                               tx_observacionsala        = IIF(@i_estado=3, ISNULL(@i_comentario,'n/a'), tx_observacionsala),
                               tx_fotografiasala         = IIF(@i_estado=3, @i_fotografia, null),
                               ci_usuarioretiro          = IIF(@i_estado=1, @i_usuario, ci_usuarioretiro),
                               ci_usuarioentrega         = IIF(@i_estado=2, @i_usuario, ci_usuarioentrega),
                               ci_usuariosala            = IIF(@i_estado=3, @i_usuario, ci_usuariosala),
                               ci_usuario                = @i_usuario,
                               ci_bodega                 = IIF(@i_estado=1, @i_bodega,  ci_bodega),
                               ci_transaccionegreso      = IIF(@i_estado=1, @w_transaccion, ci_transaccionegreso),
                               ci_tipo_transaccionegreso = IIF(@i_estado=1, 'OU', ci_tipo_transaccionreingreso)
                         WHERE ci_solicitudegreso        = @i_codsolegre
                           AND te_ordenegreso            = 'A'

                        IF @@ROWCOUNT = 0
                        BEGIN
                            SELECT @o_msgerror = 'No se actualizo ningun registro'
                            ROLLBACK TRANSACTION [TranExistencia]
                            RETURN -1
                        END

                        IF @w_alquilado = 'A' AND @i_estado=3
                        BEGIN
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
                                   ci_tipo_transaccionegreso,
                                   ci_transaccionreingreso,
                                   ci_tipo_transaccionreingreso
                            )
                            SELECT ci_articulo                  = @w_articulo, 
                                   ci_planillaorg               = @w_planilla, 
                                   ci_solegreorg                = @i_codsolegre, 
                                   fx_fecharegistro             = GETDATE(), 
                                   ci_bodega                    = @w_codbodega, 
                                   ce_retapizado                = 'I', 
                                   ci_usuarioretapizado         = @i_usuario,
                                   ci_transaccionegreso         = null,
                                   ci_tipo_transaccionegreso    = null,
                                   ci_transaccionreingreso      = null,
                                   ci_tipo_transaccionreingreso = null

                            IF @@ROWCOUNT = 0
                            BEGIN
                                ROLLBACK TRANSACTION [TranExistencia]
                                SELECT @o_msgerror = 'No se actualizo ningun registro'
                                RETURN -1
                            END
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

                        IF @w_alquilado = 'A' AND @i_estado=3
                        BEGIN
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
                                   ci_tipo_transaccionegreso,
                                   ci_transaccionreingreso,
                                   ci_tipo_transaccionreingreso
                            )
                            SELECT ci_articulo                  = @w_articulo, 
                                   ci_planillaorg               = @w_planilla, 
                                   ci_solegreorg                = @i_codsolegre, 
                                   fx_fecharegistro             = GETDATE(), 
                                   ci_bodega                    = @w_codbodega, 
                                   ce_retapizado                = 'I', 
                                   ci_usuarioretapizado         = @i_usuario,
                                   ci_transaccionegreso         = null,
                                   ci_tipo_transaccionegreso    = null,
                                   ci_transaccionreingreso      = null,
                                   ci_tipo_transaccionreingreso = null

                            IF @@ROWCOUNT = 0
                            BEGIN
                                SELECT @o_msgerror = 'No se actualizo ningun registro'
                                ROLLBACK TRANSACTION [TranExistencia]
                                RETURN -1
                            END

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
               SalaVelacion    = futSalasVelacion.tx_sala,
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
          FROM dbJardinesEsperanza.dbo.futSolicitudEgreso WITH(NOLOCK)
         INNER JOIN dbo.scit_Articulos WITH(NOLOCK)
            ON scit_Articulos.ci_articulo = futSolicitudEgreso.ci_articulo
           AND scit_Articulos.ci_clase    = '0066' --COFRES
         INNER JOIN dbo.scit_ArticulosBodegas WITH(NOLOCK)
            ON scit_ArticulosBodegas.ci_articulo = futSolicitudEgreso.ci_articulo
           AND scit_ArticulosBodegas.ci_bodega   = IIF(futSolicitudEgreso.ci_bodega='000',scit_ArticulosBodegas.ci_bodega,futSolicitudEgreso.ci_bodega)
          LEFT JOIN dbo.cxpt_Proveedores WITH(NOLOCK)
            ON cxpt_Proveedores.ci_proveedor = scit_Articulos.ci_proveedor
          LEFT JOIN dbJardinesEsperanza.dbo.futPlanilla WITH(NOLOCK)
            ON futPlanilla.ci_planilla = futSolicitudEgreso.tx_transaccionorigen
          LEFT JOIN dbJardinesEsperanza.dbo.futSalasVelacion WITH (NOLOCK)
            ON futSalasVelacion.ci_sala = futPlanilla.ci_sala
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
               SalaVelacion    = futSalasVelacion.tx_sala,
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
          FROM dbCautisaJE.dbo.futSolicitudEgreso WITH(NOLOCK)
         INNER JOIN dbo.scit_Articulos WITH(NOLOCK)
            ON scit_Articulos.ci_articulo = futSolicitudEgreso.ci_articulo
           AND scit_Articulos.ci_clase    = '0066' --COFRES
         INNER JOIN dbo.scit_ArticulosBodegas WITH(NOLOCK)
            ON scit_ArticulosBodegas.ci_articulo = futSolicitudEgreso.ci_articulo
          LEFT JOIN dbo.cxpt_Proveedores WITH(NOLOCK)
            ON cxpt_Proveedores.ci_proveedor = scit_Articulos.ci_proveedor
          LEFT JOIN dbCautisaJE.dbo.futPlanilla WITH(NOLOCK)
            ON futPlanilla.ci_planilla = futSolicitudEgreso.tx_transaccionorigen
          LEFT JOIN dbCautisaJE.dbo.futSalasVelacion WITH (NOLOCK)
            ON futSalasVelacion.ci_sala = futPlanilla.ci_sala
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

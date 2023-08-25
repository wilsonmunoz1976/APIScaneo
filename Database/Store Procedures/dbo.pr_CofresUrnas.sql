USE dbJardinesEsperanza
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
    @i_codsolegre    int            = null,
    @i_articulo      varchar(20)    = null,
    @i_estado        smallint       = 0,
    @i_comentario    varchar(500)   = null,
    @i_fotografia    nvarchar(max)   = null,
    @o_msgerror      varchar(200)   = '' OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @w_anio          varchar(4),
            @w_mes           varchar(2),
            @w_id            int = 0,
            @w_articulo      varchar(20),
            @w_planilla      varchar(20)  = '',
            @w_secuencia     varchar(4),
            @w_transaccion   varchar(11),
            @w_anterior      int          = null,
            @w_valorUnit     money        = 0,
            @w_total         money        = 0,
            @w_valorIVA      money        = 0,
            @w_fechacreacion datetime,
            @w_medida        varchar(3)   = '',
            @w_observacion   varchar(255) = '',
            @w_nota_entrega  varchar(25)  = '',
            @w_inhumado      varchar(220) = '',
            @w_sectransac    int          = 0,
            @w_bodega        varchar(3)   = '',
            @w_ret           int          = 0,
			@w_articuloorg   varchar(60)  = '',
			@w_articulodes   varchar(60)  = '',
			@w_existencia    money        = 0,
			@w_permisoprecio bit          = 0

    IF @i_accion = 'BO' --Listado de Bodegas
    BEGIN
        BEGIN TRY
            SELECT ci_bodega, 
			       tx_nombrebodega = ci_bodega + ' - ' + tx_nombrebodega
              FROM dbJardiesaDC.dbo.scit_Bodegas
             WHERE ce_estado='A'
               AND tx_nombrebodega LIKE '%COFRE%'

            SELECT @o_msgerror = 'Ejecucion OK'
        END TRY
        BEGIN CATCH
            SELECT @o_msgerror = 'Error: ' + ERROR_MESSAGE()
            RETURN -2
        END CATCH
    END

    IF @i_accion = 'RI' --Reingreso de Cofre
    BEGIN
        IF EXISTS(SELECT 1 FROM dbo.futSolicitudEgreso
                   WHERE ci_solicitudegreso = @i_codsolegre
                     AND fx_retiro  IS NOT NULL
                     AND fx_entrega IS NULL
                     AND fx_sala    IS NULL)
        BEGIN
            BEGIN TRANSACTION [TranReingreso]
                BEGIN TRY

                    SELECT @w_articulo = ci_articulo,
                           @w_planilla = tx_transaccionorigen
                      FROM dbo.futSolicitudEgreso
                     WHERE ci_solicitudegreso = @i_codsolegre
                       AND fx_retiro  IS NOT NULL
                       AND fx_entrega IS NULL
                       AND fx_sala    IS NULL

					IF @w_articulo = @i_articulo 
					BEGIN
						ROLLBACK TRANSACTION [TranReingreso]
					    SELECT @o_msgerror = 'Elija un cofre/urna diferente al que retiró'
					    RETURN -2
					END
					
					SELECT @w_articuloorg = tx_articulo
					  FROM dbJardiesaDC.dbo.scit_Articulos 
					 WHERE ci_articulo = @w_articulo

					SELECT @w_articulodes = tx_articulo,
					       @w_existencia  = qn_existencia
					  FROM dbJardiesaDC.dbo.scit_Articulos 
					 WHERE ci_articulo = @i_articulo

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

					SELECT @w_inhumado = tx_nombrefallecido 
					  FROM dbo.futPlanilla
					 WHERE ci_planilla = @w_planilla
					
                    UPDATE dbo.futSolicitudEgreso
                       SET fx_retiro             = NULL,
                           fx_entrega            = NULL,
                           fx_sala               = NULL,
                           tx_observacionretiro  = NULL,
                           tx_observacionentrega = NULL,
                           tx_observacionsala    = NULL,
                           tx_fotografiasala     = NULL,
                           ci_articulo           = ISNULL(@i_articulo, ci_articulo),
						   ci_usuario            = @i_usuario
                     WHERE ci_solicitudegreso    = @i_codsolegre

                    IF @@ROWCOUNT = 0
                    BEGIN
                        SELECT @o_msgerror = 'No se actualizo ningun registro'
                        ROLLBACK TRANSACTION [TranReingreso]
                        RETURN -1
                    END

                    EXEC @w_ret           = dbo.pr_MovimientoBodega 
                         @i_tipomov       = 'IN',
                         @i_articulo      = @w_articulo,
                         @i_planilla      = @w_planilla,
                         @i_usuario       = @i_usuario,
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
                         @o_msgerror      = @o_msgerror OUTPUT

                    IF @w_ret != 0
                    BEGIN
                        ROLLBACK TRANSACTION [TranReingreso]
                        RETURN @w_ret
                    END

					SELECT CodArticuloOrigen  = @w_articulo,
                           DesArticuloOrigen  = @w_articuloorg,
                           CodArticuloDestino = @i_articulo,
                           DesArticuloDestino = @w_articulodes,
                           CodPlanilla        = @w_planilla,
                           CodSoliEgre        = @i_codsolegre,
                           NombreFallecido    = @w_inhumado,
                           Usuario            = @i_usuario

                    SELECT @o_msgerror = 'Se efectuo correctamente el Reingreso'

                    COMMIT TRAN [TranReingreso]
                END TRY
                BEGIN CATCH
                    SELECT @o_msgerror = 'ERROR: ' + ERROR_MESSAGE()
                    ROLLBACK TRAN [TranReingreso]
                    RETURN -2
                END CATCH
          --END TRANSACTION
        END
        ELSE
        BEGIN
            SELECT @o_msgerror = 'Solicitud de Ingreso seleccionada no esta en estado de Cofre/Urna Retirado'
            RETURN -1
        END
    END

    IF @i_accion = 'LI'  -- Listado de Solicitudes de Egreso
    BEGIN
        BEGIN TRY
            SELECT Codigo          = futSolicitudEgreso.ci_solicitudegreso,
                   Bodega          = scit_ArticulosBodegas.ci_bodega,
				   codProducto     = futSolicitudEgreso.ci_articulo,
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
                   FotografiaSala     = futSolicitudEgreso.tx_fotografiasala
              FROM dbo.futSolicitudEgreso
             INNER JOIN dbJardiesaDC.dbo.scit_Articulos
                ON scit_Articulos.ci_articulo = futSolicitudEgreso.ci_articulo
               AND scit_Articulos.ci_clase    = '0066' --COFRES
             INNER JOIN dbJardiesaDC.dbo.scit_ArticulosBodegas
                ON scit_ArticulosBodegas.ci_articulo = futSolicitudEgreso.ci_articulo
               AND scit_ArticulosBodegas.ci_bodega   = IIF(@i_estado=0, @i_bodega, scit_ArticulosBodegas.ci_bodega)
              LEFT JOIN [dbJardiesaDC].dbo.cxpt_Proveedores
                ON cxpt_Proveedores.ci_proveedor = scit_Articulos.ci_proveedor
              LEFT JOIN dbo.futPlanilla
                ON futPlanilla.ci_planilla = futSolicitudEgreso.tx_transaccionorigen
             WHERE futSolicitudEgreso.ci_usuario = IIF(@i_estado=0, futSolicitudEgreso.ci_usuario, @i_usuario)
               AND IIF(futSolicitudEgreso.fx_retiro  IS NULL, 1, 0) = (CASE WHEN @i_estado<1 THEN 1 ELSE 0 END)
               AND IIF(futSolicitudEgreso.fx_entrega IS NULL, 1, 0) = (CASE WHEN @i_estado<2 THEN 1 ELSE 0 END)
               AND IIF(futSolicitudEgreso.fx_sala    IS NULL, 1, 0) = (CASE WHEN @i_estado<3 THEN 1 ELSE 0 END)
             ORDER BY futSolicitudEgreso.ci_solicitudegreso

             SELECT @o_msgerror = 'Ejecucion OK'
        END TRY
        BEGIN CATCH
            SELECT @o_msgerror = ERROR_MESSAGE()
        END CATCH
    END --IF

    IF @i_accion = 'CO' --Consulta individual de Cofre/Urna
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
				   Existencia     = CONVERT(BIGINT, scit_Articulos.qn_existencia)
              FROM dbJardiesaDC.dbo.scit_Articulos
             INNER JOIN dbJardiesaDC.dbo.scit_ArticulosBodegas
                ON scit_ArticulosBodegas.ci_articulo = scit_Articulos.ci_articulo
              LEFT JOIN dbJardiesaDC.dbo.scit_Bodegas
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

    IF @i_accion = 'UP'  --Actualizacion de Estado de Solicitud de Egreso
    BEGIN

        IF @i_estado <= 3
        BEGIN
            IF @i_estado = 1
            BEGIN
                SELECT @w_articulo        = ci_articulo, 
                       @w_planilla        = tx_transaccionorigen
                  FROM futSolicitudEgreso 
                  WHERE ci_solicitudegreso = @i_codsolegre

			    SELECT @w_existencia = scit_Articulos.qn_existencia
                  FROM dbJardiesaDC.dbo.scit_Articulos
			     WHERE ci_articulo = @w_articulo

				 SELECT @w_existencia = ISNULL(@w_existencia, 0)

				 IF @w_existencia <= 0 
				 BEGIN
				     SELECT @o_msgerror = 'No se puede retirar un cofre sin existencia ' 
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

            BEGIN TRANSACTION [TranExistencia]
                BEGIN TRY
                    UPDATE dbo.futSolicitudEgreso
                       SET fx_retiro             = IIF(@i_estado=1, GETDATE(), fx_retiro),
                           fx_entrega            = IIF(@i_estado=2, GETDATE(), fx_entrega),
                           fx_sala               = IIF(@i_estado=3, GETDATE(), fx_sala),
                           tx_observacionretiro  = IIF(@i_estado=1, @i_comentario, tx_observacionretiro),
                           tx_observacionentrega = IIF(@i_estado=2, @i_comentario, tx_observacionentrega),
                           tx_observacionsala    = IIF(@i_estado=3, @i_comentario, tx_observacionsala),
                           tx_fotografiasala     = IIF(@i_estado=3, @i_fotografia, null),
						   ci_usuarioretiro      = IIF(@i_estado=1, @i_usuario, ci_usuarioretiro),
						   ci_usuarioentrega     = IIF(@i_estado=2, @i_usuario, ci_usuarioentrega),
						   ci_usuariosala        = IIF(@i_estado=3, @i_usuario, ci_usuariosala)
                     WHERE ci_solicitudegreso    = @i_codsolegre

                    IF @@ROWCOUNT = 0
                    BEGIN
                        SELECT @o_msgerror = 'No se actualizo ningun registro'
                        ROLLBACK TRANSACTION [TranExistencia]
                        RETURN -1
                    END

                    IF @i_estado = 1
                    BEGIN
                        SELECT @w_articulo        = ci_articulo, 
                               @w_planilla        = tx_transaccionorigen
                          FROM futSolicitudEgreso 
                         WHERE ci_solicitudegreso = @i_codsolegre

                        EXEC @w_ret           = dbo.pr_MovimientoBodega 
                             @i_tipomov       = 'OU',
                             @i_articulo      = @w_articulo,
                             @i_planilla      = @w_planilla,
                             @i_usuario       = @i_usuario,
                             @o_msgerror      = @o_msgerror OUTPUT

                        IF @w_ret != 0
                        BEGIN
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
                    SELECT @o_msgerror = 'ERROR: ' + ERROR_MESSAGE()
                    ROLLBACK TRANSACTION [TranExistencia]
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

	IF @i_accion = 'CS'  --Consulta de Solicitud de Egreso
	BEGIN 
            SELECT Codigo          = futSolicitudEgreso.ci_solicitudegreso,
                   Bodega          = scit_ArticulosBodegas.ci_bodega,
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
                   FotografiaSala     = futSolicitudEgreso.tx_fotografiasala
              FROM dbo.futSolicitudEgreso
             INNER JOIN dbJardiesaDC.dbo.scit_Articulos
                ON scit_Articulos.ci_articulo = futSolicitudEgreso.ci_articulo
               AND scit_Articulos.ci_clase    = '0066' --COFRES
             INNER JOIN dbJardiesaDC.dbo.scit_ArticulosBodegas
                ON scit_ArticulosBodegas.ci_articulo = futSolicitudEgreso.ci_articulo
               --AND scit_ArticulosBodegas.ci_bodega   = IIF(@i_estado=0, @i_bodega, scit_ArticulosBodegas.ci_bodega)
              LEFT JOIN dbo.cxpt_Proveedores
                ON cxpt_Proveedores.ci_proveedor = scit_Articulos.ci_proveedor
              LEFT JOIN dbo.futPlanilla
                ON futPlanilla.ci_planilla = futSolicitudEgreso.tx_transaccionorigen
             WHERE futSolicitudEgreso.ci_usuario = ISNULL(@i_usuario, futSolicitudEgreso.ci_usuario)
               AND futSolicitudEgreso.ci_solicitudegreso = @i_codsolegre
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

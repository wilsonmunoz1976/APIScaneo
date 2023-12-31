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
    @i_bodega        varchar(3),
	@i_tipogestion   bit  = 1,
	@i_tipoingreso   bit  = 1,
    @o_msgerror      varchar(200) = '' OUTPUT,
    @o_codplanilla   varchar(15)  = '' OUTPUT,
    @o_codsoliegre   int          = 0  OUTPUT,
    @o_bodega        varchar(3)   = '' OUTPUT,
    @o_descarticulo  varchar(60)  = '' OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @w_secorden      bigint,
	        @w_letraplanilla char(1)

    IF EXISTS(SELECT 1 FROM dbo.ssatParametrosGenerales WHERE ci_aplicacion='MOV' AND ci_parametro = 'DEBUG' AND tx_parametro = 'SI')
	BEGIN
	    IF NOT EXISTS(SELECT 1 FROM sys.all_objects WHERE object_id=OBJECT_ID('dbo.trace_movil'))
		BEGIN
		    CREATE TABLE trace_movil (fechahora datetime default getdate(), mensaje varchar(max))
		END

		INSERT INTO trace_movil (mensaje) 
		SELECT 'DECLARE @w_ret int, @w_msgerror varchar(200), @w_codplanilla varchar(15), @w_codsoliegre int, @w_bodega varchar(3), @w_descarticulo varchar(60); '+ CHAR(13)
			   +'EXEC @w_ret = dbo.pr_Emergencia ' + CHAR(13)
			   + ' @i_accion       ='+ISNULL(CHAR(39) + @i_accion + CHAR(39),'null') + CHAR(13)
			   +', @i_nombres      ='+ISNULL(CHAR(39) + @i_nombres + CHAR(39),'null')+ CHAR(13)
			   +', @i_articulo     ='+ISNULL(CHAR(39) + @i_articulo + CHAR(39),'null')+ CHAR(13)
			   +', @i_usuario      ='+ISNULL(CHAR(39) + @i_usuario + CHAR(39),'null')+ CHAR(13)
			   +', @i_bodega       ='+ISNULL(CHAR(39) + @i_bodega + CHAR(39),'null') + CHAR(13)
			   +', @i_tipogestion  ='+ISNULL(CONVERT(VARCHAR, @i_tipogestion),'null') + CHAR(13)
			   +', @i_tipoingreso  ='+ISNULL(CONVERT(VARCHAR, @i_tipoingreso),'null') + CHAR(13)
			   +', @o_msgerror     = @w_msgerror     OUTPUT '+ CHAR(13)
			   +', @o_codplanilla  = @w_codplanilla  OUTPUT '+ CHAR(13)
			   +', @o_codsoliegre  = @w_codsoliegre  OUTPUT '+ CHAR(13)
			   +', @o_bodega       = @w_bodega       OUTPUT '+ CHAR(13)
			   +', @o_descarticulo = @w_descarticulo OUTPUT; '+ CHAR(13)
			   +'SELECT @w_ret, @w_msgerror, @w_codplanilla, @w_codsoliegre, @w_bodega, @w_descarticulo '+ CHAR(13)

	END

    DECLARE @w_planilla      VARCHAR(15) = null,
            @w_soliegreso    INT = 0,
            @w_rgohor        VARCHAR(11),
            @w_ret           INT,
			@w_grupocontable VARCHAR(6),
			@w_qnexistartic  int,
			@w_qnexistartbod int

    IF @i_accion = 'RG' --Registro de Emergencia
    BEGIN
        BEGIN TRANSACTION [RegistroEmergencia]
            BEGIN TRY
			    
				IF @i_tipogestion = 1
				   SELECT @w_letraplanilla = 'I' 
				ELSE
				   SELECT @w_letraplanilla = 'C' 

                SELECT TOP 1 @w_rgohor = tx_parametro
                  FROM dbo.ssatParametrosGenerales
                 WHERE ci_aplicacion = 'MOV'
                   AND ci_parametro  = 'RGOHOR'

                DECLARE @w_rango varchar(5) = CONVERT(VARCHAR(5),GETDATE(),108)
                IF (dbo.fu_validar_rango_horario(@w_rango, @w_rgohor) = 0)
                BEGIN
                    ROLLBACK TRANSACTION [RegistroEmergencia]
                    SELECT @o_msgerror = 'No puede registrar esta EMERGENCIA porque se encuentra fuera del rango horario permitido (' + REPLACE(@w_rgohor,'|', '-') + ')'
                    RETURN -1
                END

                IF EXISTS(SELECT 1 FROM dbJardinesEsperanza.dbo.futPlanilla WHERE tx_nombrefallecido = @i_nombres)
                BEGIN
                    ROLLBACK TRANSACTION [RegistroEmergencia]
                    SELECT @o_msgerror = 'No puede registrar esta EMERGENCIA porque el nombre del fallecido ya esta ingresado previamente'
                    RETURN 500
                END

                SELECT @o_bodega        = scit_ArticulosBodegas.ci_bodega,
                       @o_descarticulo  = scit_Articulos.tx_articulo,
					   @w_grupocontable = scit_Bodegas.ci_grupocontable,
			           @w_qnexistartic  = scit_Articulos.qn_existencia,
			           @w_qnexistartbod = scit_ArticulosBodegas.qn_existencia
                  FROM dbo.scit_Articulos
                  INNER JOIN dbo.scit_ArticulosBodegas
                    ON scit_ArticulosBodegas.ci_articulo = scit_Articulos.ci_articulo
				   AND scit_ArticulosBodegas.ci_bodega   = @i_bodega
				  INNER JOIN dbo.scit_Bodegas
				    ON scit_Bodegas.ci_bodega = scit_ArticulosBodegas.ci_bodega
                 WHERE scit_Articulos.ci_articulo = @i_articulo
                   AND scit_Articulos.ci_clase    = '0066' --COFRES

                IF @@ROWCOUNT = 0
                BEGIN
                    ROLLBACK TRANSACTION [RegistroEmergencia]
                    SELECT @o_msgerror = 'El código de Cofre especificado no existe (' + @i_articulo + ') o no corresponde a la bodega seleccionada'
                    RETURN -1
                END

				IF @w_qnexistartbod <= 0
				BEGIN
                    ROLLBACK TRANSACTION [RegistroEmergencia]
                    SELECT @o_msgerror = 'El artículo seleccionado no tiene existencia, por favor seleccione otro'
                    RETURN -1
				END


                IF @w_grupocontable = '0001'
                BEGIN
				    IF @i_tipoingreso = 1
					BEGIN
						SELECT @w_planilla = @w_letraplanilla 
							 + RIGHT(REPLICATE('0', 10) 
							 + CONVERT(VARCHAR, ISNULL(MAX(CONVERT(DECIMAL(19,0),
													   IIF(LTRIM(RTRIM(ISNULL(SUBSTRING(ci_planilla,2, 15),'0')))='',
													   '0',
													   LTRIM(RTRIM(ISNULL(SUBSTRING(ci_planilla,2, 15),'0')))
													   )))
												,0)+1),10)
						FROM [dbJardinesEsperanza].[dbo].[futPlanilla]
						WHERE ci_planilla like @w_letraplanilla + '%' AND ci_anio= YEAR(GETDATE())

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
							   ci_tiporeserva        = CASE WHEN @i_tipogestion = 1 THEN 'P' ELSE 'E' END,
							   ci_anio               = CONVERT(VARCHAR(15), YEAR(GETDATE())),
							   ci_mes                = RIGHT('00'+CONVERT(VARCHAR(2) , MONTH(GETDATE())),2),
							   ci_aniorealizable     = CONVERT(VARCHAR(15), YEAR(GETDATE())),
							   ci_mesrealizable      = RIGHT('00'+CONVERT(VARCHAR(2) , MONTH(GETDATE())),2)
                    
						IF @@ROWCOUNT = 0
						BEGIN
							ROLLBACK TRANSACTION [RegistroEmergencia]
							SELECT @o_msgerror = 'No se pudo generar planilla'
							RETURN -1
						END

						IF @i_tipogestion = 1
						BEGIN
							SELECT @w_secorden = MAX(CONVERT(bigint,ci_orden)) FROM dbJardinesEsperanza.dbo.futCabeceraOrdenTrabajo
							SELECT @w_secorden = ISNULL(@w_secorden,0) + 1

							INSERT dbJardinesEsperanza.dbo.futCabeceraOrdenTrabajo (
									ci_orden,
									ci_planilla,
									tx_titulo,
									tx_profesion,
									tx_nombre,
									tx_apellido,
									tx_ubicacion,
									tx_observacion,
									tx_glosa,
									tx_nacimiento,
									tx_fallecimiento,
									tx_autorizado,
									tx_tipoidentificacion,
									tx_identificacion,
									ci_parentesco,
									tx_nota,
									tx_sucursal,
									ci_ordenlapida,
									tx_fechaordenada,
									tx_horaordenada,
									tx_fechabodega,
									tx_horabodega,
									tx_fechagrabada,
									tx_horagrabada,
									tx_fechacolocada,
									tx_horacolocada,
									te_proceso,
									ci_usuariomodificacion,
									fx_modificacion,
									te_orden,
									tx_direccioncontacto,
									tx_telefonocontacto,
									tx_sexo,
									ci_tipoperdida,
									ci_ciudad,
									tx_correocontacto,
									tx_facebookcontacto
									)
							SELECT  ci_orden               = RIGHT(REPLICATE('0',10) + LTRIM(RTRIM(CONVERT(VARCHAR(10),@w_secorden))),10),
									ci_planilla            = @w_planilla,
									tx_titulo              = null,
									tx_profesion           = null,
									tx_nombre              = @i_nombres,
									tx_apellido            = null,
									tx_ubicacion           = null,
									tx_observacion         = 'Ingresado por Emergencia de la Aplicación Móvil',
									tx_glosa               = null,
									tx_nacimiento          = null,
									tx_fallecimiento       = null,
									tx_autorizado          = null,
									tx_tipoidentificacion  = null,
									tx_identificacion      = null,
									ci_parentesco          = null,
									tx_nota                = null,
									tx_sucursal            = null,
									ci_ordenlapida         = null,
									tx_fechaordenada       = CONVERT(VARCHAR(10), GETDATE(), 111),
									tx_horaordenada        = CONVERT(VARCHAR(8) , GETDATE(), 108),
									tx_fechabodega         = null,
									tx_horabodega          = null,
									tx_fechagrabada        = CONVERT(VARCHAR(10), GETDATE(), 111),
									tx_horagrabada         = CONVERT(VARCHAR(8) , GETDATE(), 108),
									tx_fechacolocada       = null,
									tx_horacolocada        = null,
									te_proceso             = 'N',
									ci_usuariomodificacion = null,
									fx_modificacion        = null,
									te_orden               = 'A',
									tx_direccioncontacto   = null,
									tx_telefonocontacto    = null,
									tx_sexo                = null,
									ci_tipoperdida         = null,
									ci_ciudad              = null,
									tx_correocontacto      = null,
									tx_facebookcontacto    = null

							IF @@ROWCOUNT = 0
							BEGIN
								ROLLBACK TRANSACTION [RegistroEmergencia]
								SELECT @o_msgerror = 'No se pudo ingresar datos de Cabecera orden de trabajo'
								RETURN -1
							END

							INSERT dbJardinesEsperanza.dbo.futDetalleOrdenTrabajo
									(ci_orden, 
									ci_secuencia, 
									ci_articulo, 
									ci_medida, 
									cn_cantidad, 
									cn_cantidadentregada, 
									ci_secuenciadetalle, 
									ci_proveedor, 
									ce_alquilado, 
									ce_devuelto)
							SELECT  ci_orden             = RIGHT(REPLICATE('0',10) + LTRIM(RTRIM(CONVERT(VARCHAR(10),@w_secorden))),10), 
									ci_secuencia         = 1, 
									ci_articulo          = @i_articulo, 
									ci_medida            = 1, 
									cn_cantidad          = 1, 
									cn_cantidadentregada = 0, 
									ci_secuenciadetalle  = null,  
									ci_proveedor         = '000', 
									ce_alquilado         = 'N', 
									ce_devuelto          = 'D'

							IF @@ROWCOUNT = 0
							BEGIN
								ROLLBACK TRANSACTION [RegistroEmergencia]
								SELECT @o_msgerror = 'No se pudo ingresar datos de Detalle orden de trabajo'
								RETURN -1
							END
						END
                    END

                    SELECT @w_soliegreso = ISNULL(MAX(ci_solicitudegreso),0)+1 FROM dbJardinesEsperanza.dbo.futSolicitudEgreso
                    
                    INSERT INTO dbJardinesEsperanza.dbo.futSolicitudEgreso (
                           ci_solicitudegreso,
                           ci_articulo,
                           tx_documentoorigen,
                           tx_transaccionorigen,
						   ci_secuencia, 
                           te_ordenegreso,
                           te_proceso,
                           fx_creacion,
                           ci_usuario,
						   tx_tipoegreso,
						   tx_observacion,
						   ci_bodega,
						   te_porfacturar,
						   tx_nombrefallecido,
						   te_emergencia
                           )
                    SELECT ci_solicitudegreso   = @w_soliegreso,
                           ci_articulo          = @i_articulo,
                           tx_documentoorigen   = CASE WHEN @i_tipoingreso=1 THEN 'INH' ELSE 'FAC' END,
                           tx_transaccionorigen = @w_planilla,
						   ci_secuencia         = 1,
                           te_ordenegreso       = 'A',
                           te_proceso           = null,
                           fx_creacion          = GETDATE(),
                           ci_usuario           = @i_usuario,
						   tx_tipoegreso        = 'N',
						   tx_observacion       = 'Egreso por ' + 
						                          CASE WHEN @i_tipoingreso=1 THEN 'Planilla ' ELSE 'Factura 'END +
												  @w_planilla + ', del Inhumado ' + @i_nombres,
						   ci_bodega            = @i_bodega,
						   te_porfacturar       = CASE WHEN @i_tipoingreso=1 THEN 0 ELSE 1 END,
						   tx_nombrefallecido   = @i_nombres,
						   te_emergencia        = 'I'
                    
                    IF @@ROWCOUNT = 0
                    BEGIN
                        ROLLBACK TRANSACTION [RegistroEmergencia]
                        SELECT @o_msgerror = 'No se puedo ingresar solicitud de egreso'
                        RETURN -1
                    END

					INSERT INTO dbJardinesEsperanza.dbo.futEmergencia 
					(
					       ci_solicitudegreso,
                           ci_planilla,
                           ci_articulo,
						   ci_bodega,
                           tx_nombrefallecido,
                           fx_fecharegistro,
                           ci_usuarioregistro,
                           fx_finalizacion,
                           ci_usuariofinalizacion,
						   tipoingreso,
						   tipogestion
                    )
					SELECT ci_solicitudegreso     = @w_soliegreso,
                           ci_planilla            = @w_planilla,
                           ci_articulo            = @i_articulo,
						   ci_bodega              = @i_bodega, 
                           tx_nombrefallecido     = @i_nombres,
                           fx_fecharegistro       = GETDATE(),
                           ci_usuarioregistro     = @i_usuario,
                           fx_finalizacion        = null,
                           ci_usuariofinalizacion = null,
						   tipoingreso            = @i_tipoingreso,
						   tipogestion            = @i_tipogestion

                    IF @@ROWCOUNT = 0
                    BEGIN
                        ROLLBACK TRANSACTION [RegistroEmergencia]
                        SELECT @o_msgerror = 'No se pudo ingresar el Registro de Emergencia'
                        RETURN -1
                    END

                END
                        

                IF @w_grupocontable = '0002'
                BEGIN
					IF @i_tipoingreso = 1
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
							ROLLBACK TRANSACTION [RegistroEmergencia]
							SELECT @o_msgerror = 'No se ingreso ningún registro'
							RETURN -1
						END

						IF @i_tipogestion = 1
						BEGIN					
							SELECT @w_secorden = MAX(CONVERT(bigint,ci_orden)) FROM dbJardinesEsperanza.dbo.futCabeceraOrdenTrabajo
							SELECT @w_secorden = ISNULL(@w_secorden,0) + 1

							INSERT dbCautisaJE.dbo.futCabeceraOrdenTrabajo (
									ci_orden,
									ci_planilla,
									tx_titulo,
									tx_profesion,
									tx_nombre,
									tx_apellido,
									tx_ubicacion,
									tx_observacion,
									tx_glosa,
									tx_nacimiento,
									tx_fallecimiento,
									tx_autorizado,
									tx_tipoidentificacion,
									tx_identificacion,
									ci_parentesco,
									tx_nota,
									tx_sucursal,
									ci_ordenlapida,
									tx_fechaordenada,
									tx_horaordenada,
									tx_fechabodega,
									tx_horabodega,
									tx_fechagrabada,
									tx_horagrabada,
									tx_fechacolocada,
									tx_horacolocada,
									te_proceso,
									ci_usuariomodificacion,
									fx_modificacion,
									te_orden,
									tx_direccioncontacto,
									tx_telefonocontacto,
									tx_sexo,
									ci_tipoperdida,
									ci_ciudad,
									tx_correocontacto,
									tx_facebookcontacto
									)
							SELECT  ci_orden               = RIGHT(REPLICATE('0',10) + LTRIM(RTRIM(CONVERT(VARCHAR(10),@w_secorden))),10),
									ci_planilla            = @w_planilla,
									tx_titulo              = null,
									tx_profesion           = null,
									tx_nombre              = @i_nombres,
									tx_apellido            = null,
									tx_ubicacion           = null,
									tx_observacion         = 'Ingresado por opción Emergencia de la Aplicación Móvil',
									tx_glosa               = null,
									tx_nacimiento          = null,
									tx_fallecimiento       = null,
									tx_autorizado          = null,
									tx_tipoidentificacion  = null,
									tx_identificacion      = null,
									ci_parentesco          = null,
									tx_nota                = null,
									tx_sucursal            = null,
									ci_ordenlapida         = null,
									tx_fechaordenada       = null,
									tx_horaordenada        = null,
									tx_fechabodega         = null,
									tx_horabodega          = null,
									tx_fechagrabada        = CONVERT(VARCHAR(10), GETDATE(), 111),
									tx_horagrabada         = CONVERT(VARCHAR(8) , GETDATE(), 108),
									tx_fechacolocada       = null,
									tx_horacolocada        = null,
									te_proceso             = 'N',
									ci_usuariomodificacion = null,
									fx_modificacion        = null,
									te_orden               = 'A',
									tx_direccioncontacto   = null,
									tx_telefonocontacto    = null,
									tx_sexo                = null,
									ci_tipoperdida         = null,
									ci_ciudad              = null,
									tx_correocontacto      = null,
									tx_facebookcontacto    = null

							IF @@ROWCOUNT = 0
							BEGIN
								ROLLBACK TRANSACTION [RegistroEmergencia]
								SELECT @o_msgerror = 'No se pudo ingresar datos de Cabecera orden de trabajo'
								RETURN -1
							END

							INSERT dbCautisaJE.dbo.futDetalleOrdenTrabajo
									(ci_orden, 
									ci_secuencia, 
									ci_articulo, 
									ci_medida, 
									cn_cantidad, 
									cn_cantidadentregada, 
									ci_secuenciadetalle, 
									ci_proveedor, 
									ce_alquilado, 
									ce_devuelto)
							SELECT  ci_orden             = RIGHT(REPLICATE('0',10) + LTRIM(RTRIM(CONVERT(VARCHAR(10),@w_secorden))),10), 
									ci_secuencia         = 1, 
									ci_articulo          = @i_articulo, 
									ci_medida            = 1, 
									cn_cantidad          = 1, 
									cn_cantidadentregada = 0, 
									ci_secuenciadetalle  = null,  
									ci_proveedor         = '000', 
									ce_alquilado         = 'N', 
									ce_devuelto          = 'D'

							IF @@ROWCOUNT = 0
							BEGIN
								ROLLBACK TRANSACTION [RegistroEmergencia]
								SELECT @o_msgerror = 'No se pudo ingresar datos de Detalle orden de trabajo'
								RETURN -1
							END
						END

						SELECT @w_soliegreso = ISNULL(MAX(ci_solicitudegreso),0)+1 FROM dbCautisaJE.dbo.futSolicitudEgreso

						INSERT INTO dbCautisaJE.dbo.futSolicitudEgreso (
							   ci_solicitudegreso,
							   ci_articulo,
							   tx_documentoorigen,
							   tx_transaccionorigen,
							   ci_secuencia, 
							   te_ordenegreso,
							   te_proceso,
							   fx_creacion,
							   ci_usuario,
							   tx_tipoegreso,
							   tx_observacion,
							   ci_bodega,
							   te_porfacturar,
						       tx_nombrefallecido,
						       te_emergencia
							   )
						SELECT ci_solicitudegreso   = @w_soliegreso,
							   ci_articulo          = @i_articulo,
							   tx_documentoorigen   = CASE WHEN @i_tipoingreso=1 THEN 'INH' ELSE 'FAC' END,
							   tx_transaccionorigen = @w_planilla,
							   ci_secuencia         = 1,
							   te_ordenegreso       = 'A',
							   te_proceso           = null,
							   fx_creacion          = GETDATE(),
							   ci_usuario           = @i_usuario,
							   tx_tipoegreso        = 'N',
							   tx_observacion       = 'Egreso por Planilla ' + 
						                               CASE WHEN @i_tipoingreso=1 THEN 'Planilla ' ELSE 'Factura 'END +
												       @w_planilla + ', del Inhumado ' + @i_nombres,
							   ci_bodega            = @i_bodega,
							   te_porfacturar       = CASE WHEN @i_tipoingreso=1 THEN 0 ELSE 1 END,
						       tx_nombrefallecido   = @i_nombres,
						       te_emergencia        = 'I'
                    
						IF @@ROWCOUNT = 0
						BEGIN
							ROLLBACK TRANSACTION [RegistroEmergencia]
							SELECT @o_msgerror = 'No se ingreso ningún registro'
							RETURN -1
						END

						INSERT INTO dbCautisaJE.dbo.futEmergencia 
						(
							   ci_solicitudegreso,
							   ci_planilla,
							   ci_articulo,
							   ci_bodega,
							   tx_nombrefallecido,
							   fx_fecharegistro,
							   ci_usuarioregistro,
							   fx_finalizacion,
							   ci_usuariofinalizacion,
							   tipoingreso,
							   tipogestion

						)
						SELECT ci_solicitudegreso     = @w_soliegreso,
							   ci_planilla            = @w_planilla,
							   ci_articulo            = @i_articulo,
							   ci_bodega              = @i_bodega,
							   tx_nombrefallecido     = @i_nombres,
							   fx_fecharegistro       = GETDATE(),
							   ci_usuarioregistro     = @i_usuario,
							   fx_finalizacion        = null,
							   ci_usuariofinalizacion = null,
							   tipoingreso            = @i_tipoingreso,
							   tipogestion            = @i_tipogestion

						IF @@ROWCOUNT = 0
						BEGIN
							ROLLBACK TRANSACTION [RegistroEmergencia]
							SELECT @o_msgerror = 'No se pudo ingresar el log de registro de emergencia'
							RETURN -1
						END
                    END
				END						                   

                SELECT @o_codplanilla = @w_planilla, 
				       @o_codsoliegre = @w_soliegreso

      --          EXEC @w_ret           = dbo.pr_MovimientoBodega 
      --               @i_tipomov       = 'OU',
      --               @i_articulo      = @i_articulo,
      --               @i_planilla      = @w_planilla,
      --               @i_usuario       = @i_usuario,
					 --@i_bodega        = @i_bodega,
      --               @o_msgerror      = @o_msgerror OUTPUT
                
                COMMIT TRANSACTION [RegistroEmergencia]
            END TRY
            BEGIN CATCH
                SELECT @o_msgerror = 'ERROR: ' + ERROR_MESSAGE() + ' - ' + CONVERT(VARCHAR, ERROR_LINE())
                ROLLBACK TRANSACTION [RegistroEmergencia]
                RETURN -2
            END CATCH

            SELECT @o_msgerror = 'Se efectuó correctamente el registro de emergencia'
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

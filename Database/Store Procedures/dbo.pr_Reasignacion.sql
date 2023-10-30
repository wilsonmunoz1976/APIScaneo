USE [dbJardiesaDC]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS(SELECT 1 FROM sysobjects WHERE id=OBJECT_ID('dbo.pr_Reasignacion') AND type='P')
BEGIN
   EXEC ('CREATE PROCEDURE dbo.pr_Reasignacion AS BEGIN RETURN 0 END')
END
GO

ALTER PROCEDURE dbo.pr_Reasignacion
    @i_accion        varchar(2),
    @i_usuario       varchar(15)    = null,
    @i_usuarionew    varchar(15)    = null,
	@i_codsolegre    int            = null,
    @o_msgerror      varchar(200)   = '' OUTPUT 
AS
BEGIN
    DECLARE @w_return INT = 0, @w_estado int

    IF EXISTS(SELECT 1 FROM dbo.ssatParametrosGenerales WHERE ci_aplicacion='MOV' AND ci_parametro = 'DEBUG' AND tx_parametro = 'SI')
	BEGIN
	    IF NOT EXISTS(SELECT 1 FROM sys.all_objects WHERE object_id=OBJECT_ID('dbo.trace_movil'))
		BEGIN
		    CREATE TABLE trace_movil (fechahora datetime default getdate(), mensaje varchar(max))
		END

		INSERT INTO trace_movil (mensaje) 
		SELECT 'DECLARE @w_ret int, @w_msgerror varchar(200), @w_codplanilla varchar(15), @w_codsoliegre int, @w_bodega varchar(3), @w_descarticulo varchar(60); '+ CHAR(13)
			   +'EXEC @w_ret = dbo.pr_Reasignacion ' + CHAR(13)
			   + ' @i_accion       ='+ISNULL(CHAR(39) + @i_accion + CHAR(39),'null') + CHAR(13)
			   +', @i_usuario      ='+ISNULL(CHAR(39) + @i_usuario + CHAR(39),'null')+ CHAR(13)
			   +', @i_usuarionew   ='+ISNULL(CHAR(39) + @i_usuarionew + CHAR(39),'null')+ CHAR(13)
			   +', @i_codsolegre   ='+ISNULL(CONVERT(VARCHAR,@i_codsolegre),'null') + CHAR(13)
			   +', @o_msgerror     = @w_msgerror     OUTPUT '+ CHAR(13)
			   +'SELECT @w_ret, @w_msgerror'+ CHAR(13)
	END

	IF @i_accion = 'US'  -- Listado de usuarios
	BEGIN
	    BEGIN TRY
			SELECT DISTINCT ci_usuario = lower(a.ci_usuario), 
			                tx_usuario = lower(a.ci_usuario) + ' - ' + a.tx_usuario
			  FROM dbo.ssatUsuario a
			 INNER JOIN dbo.ssatTransaccionxUsuario b
				ON a.ci_usuario = b.ci_usuario
			   AND b.ci_aplicacion = 'MOV'
			 INNER JOIN dbo.scit_BodegaUsuario c
				ON c.ci_usuario = a.ci_usuario
			   AND c.ci_bodega IN (SELECT ci_bodega 
									  FROM dbo.scit_BodegaUsuario 
									 WHERE ci_usuario=@i_usuario)
			  LEFT JOIN dbo.scit_Bodegas d
			    ON d.ci_bodega = c.ci_bodega
			WHERE a.ci_usuario != @i_usuario

			SELECT @o_msgerror = 'Ejecucion OK', @w_return = 0

		END TRY
		BEGIN CATCH
			SELECT @o_msgerror = ERROR_MESSAGE(), @w_return = -1
		END CATCH
	END --IF

	IF @i_accion = 'RS'  -- Reasignar Usuario usuarios
	BEGIN
	    DECLARE @w_bodega varchar(3)

	    BEGIN TRY
			IF ('0001' IN (SELECT ci_grupocontable from dbo.scit_BodegaUsuario a INNER JOIN dbo.scit_Bodegas b ON a.ci_bodega = b.ci_bodega WHERE a.ci_usuario = @i_usuario))
			BEGIN
				UPDATE dbJardinesEsperanza.dbo.futSolicitudEgreso
				   SET ci_usuario         = lower(@i_usuarionew)
				 WHERE ci_usuario         = @i_usuario
				   AND ci_solicitudegreso = @i_codsolegre 

			    SELECT @w_estado = CASE 
				                      WHEN fx_retiro IS NULL AND fx_entrega IS NULL AND fx_sala IS NULL
									  THEN 0
				                      WHEN fx_retiro IS NOT NULL AND fx_entrega IS NULL AND fx_sala IS NULL
									  THEN 1
				                      WHEN fx_retiro IS NOT NULL AND fx_entrega IS NOT NULL AND fx_sala IS NULL
									  THEN 2
				                      WHEN fx_retiro IS NOT NULL AND fx_entrega IS NOT NULL AND fx_sala IS NOT NULL
									  THEN 3
									  ELSE -1
				                   END
				  FROM dbJardinesEsperanza.dbo.futSolicitudEgreso
				 WHERE ci_solicitudegreso = @i_codsolegre 

				INSERT INTO dbJardinesEsperanza.dbo.futLogReasignacion (ci_usuarioorigen, ci_usuariodestino, fx_fechareasignacion, ci_solicitudegreso, ce_estadosolicitud)
				SELECT lower(@i_usuario), lower(@i_usuarionew), GETDATE(), @i_codsolegre , @w_estado
			END

			IF ('0002' IN (SELECT ci_grupocontable from dbo.scit_BodegaUsuario a INNER JOIN dbo.scit_Bodegas b ON a.ci_bodega = b.ci_bodega WHERE a.ci_usuario = @i_usuario))
			BEGIN
				UPDATE dbCautisaJE.dbo.futSolicitudEgreso
				   SET ci_usuario         = @i_usuarionew
				 WHERE ci_usuario         = @i_usuario
				   AND ci_solicitudegreso = @i_codsolegre 

			    SELECT @w_estado = CASE 
				                      WHEN fx_retiro IS NULL AND fx_entrega IS NULL AND fx_sala IS NULL
									  THEN 0
				                      WHEN fx_retiro IS NOT NULL AND fx_entrega IS NULL AND fx_sala IS NULL
									  THEN 1
				                      WHEN fx_retiro IS NOT NULL AND fx_entrega IS NOT NULL AND fx_sala IS NULL
									  THEN 2
				                      WHEN fx_retiro IS NOT NULL AND fx_entrega IS NOT NULL AND fx_sala IS NOT NULL
									  THEN 3
									  ELSE -1
				                   END
				  FROM dbCautisaJE.dbo.futSolicitudEgreso
				 WHERE ci_solicitudegreso = @i_codsolegre 

				INSERT INTO dbCautisaJE.dbo.futLogReasignacion (ci_usuarioorigen, ci_usuariodestino, fx_fechareasignacion, ci_solicitudegreso, ce_estadosolicitud)
				SELECT @i_usuario, @i_usuarionew, GETDATE(), @i_codsolegre , @w_estado
			END

			SELECT @o_msgerror = 'Ejecucion OK', @w_return = 0

		END TRY
		BEGIN CATCH
			SELECT @o_msgerror = ERROR_MESSAGE(), @w_return = -1
		END CATCH

	END
	RETURN @w_return
END
GO

sp_help pr_Reasignacion
GO
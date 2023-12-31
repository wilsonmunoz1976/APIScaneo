USE [dbJardiesaDC]
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
    @i_usuario    varchar(15)   = null,
	@i_bodega     varchar(3)    = null,
    @o_msgerror   varchar(200)  = '' OUTPUT 
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @w_permisocosto bit

    IF EXISTS(SELECT 1 FROM dbo.ssatParametrosGenerales WHERE ci_aplicacion='MOV' AND ci_parametro = 'DEBUG' AND tx_parametro = 'SI')
	BEGIN
	    IF NOT EXISTS(SELECT 1 FROM sys.all_objects WHERE object_id=OBJECT_ID('dbo.trace_movil'))
		BEGIN
		    CREATE TABLE trace_movil (fechahora datetime default getdate(), mensaje varchar(max))
		END

		INSERT INTO trace_movil (mensaje) 
		SELECT 'DECLARE @w_ret int, @w_msgerror varchar(200), @w_codplanilla varchar(15), @w_codsoliegre int, @w_bodega varchar(3), @w_descarticulo varchar(60); '+ CHAR(13)
			   +'EXEC @w_ret = dbo.pr_ActivosFijos ' + CHAR(13)
			   + ' @i_accion       ='+ISNULL(CHAR(39) + @i_accion + CHAR(39),'null') + CHAR(13)
			   +', @i_codigo       ='+ISNULL(CHAR(39) + @i_codigo + CHAR(39),'null')+ CHAR(13)
			   +', @i_usuario      ='+ISNULL(CHAR(39) + @i_usuario + CHAR(39),'null')+ CHAR(13)
			   +', @i_bodega       ='+ISNULL(CHAR(39) + @i_bodega + CHAR(39),'null') + CHAR(13)
			   +', @o_msgerror     = @w_msgerror     OUTPUT '+ CHAR(13)
			   +'SELECT @w_ret, @w_msgerror'+ CHAR(13)
	END

    IF @i_accion = 'LI'
    BEGIN

        SELECT Codigo     = ci_activo,
               CodigoQR   = null,
               Activo     = tx_caracteristicas,
               Existencia = 0,
               Custodio   = tx_usuarioasignado,
               Costo      = qn_valor,
               Comentario = null,
			   Existencia = null
          FROM dbJardiesaDC.dbo.acft_Activos
        SELECT @o_msgerror = 'Ejecucion OK'
    END --IF

    IF @i_accion = 'CO'
    BEGIN
        IF EXISTS(SELECT 1 FROM dbo.ssatTransaccionxUsuario where ci_usuario=@i_usuario AND ci_aplicacion='MOV' AND ci_transaccion='2100')
           SELECT @w_permisocosto = 1
        ELSE
           SELECT @w_permisocosto = 0

		IF @i_codigo IN (SELECT ci_activo FROM dbJardiesaDC.dbo.acft_Activos)
		BEGIN
			SELECT Codigo      = ci_activo,
				   Descripcion = tx_caracteristicas,
				   Custodio    = tx_usuarioasignado,
				   Costo       = IIF(@w_permisocosto=1,qn_valor,0),
				   Existencia  = null
			  FROM dbJardiesaDC.dbo.acft_Activos
			 WHERE ci_activo = @i_codigo

			 SELECT CodBodega  = scit_ArticulosBodegas.ci_bodega,
			        DesBodega  = null,
					Existencia = scit_ArticulosBodegas.qn_existencia
			   FROM dbo.scit_ArticulosBodegas
			  WHERE 1 = 2
		END
		ELSE 
		BEGIN
			SELECT Codigo      = scit_Articulos.ci_articulo,
				   Descripcion = scit_Articulos.tx_articulo,
				   Custodio    = ISNULL(cxpt_Proveedores.tx_contacto,'n/a'),
				   Costo       = IIF(@w_permisocosto=1,va_costo,0),
				   Existencia  = scit_Articulos.qn_existencia
			  FROM dbo.scit_Articulos
			  LEFT JOIN dbo.cxpt_Proveedores 
				ON cxpt_Proveedores.ci_proveedor = scit_Articulos.ci_proveedor
			 WHERE scit_Articulos.ci_articulo = @i_codigo

			 SELECT CodBodega  = scit_ArticulosBodegas.ci_bodega,
			        DesBodega  = scit_Bodegas.tx_nombrebodega,
					Existencia = scit_ArticulosBodegas.qn_existencia
			   FROM dbo.scit_ArticulosBodegas
			  INNER JOIN dbo.scit_Bodegas
			     ON scit_Bodegas.ci_bodega = scit_ArticulosBodegas.ci_bodega
			  WHERE scit_ArticulosBodegas.ci_articulo = @i_codigo
		END
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

USE [dbJardiesaDC]
GO
/****** Object:  StoredProcedure dbo.pr_Inventario    Script Date: 12/07/2023 12:12:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS(SELECT 1 FROM sysobjects WHERE id=OBJECT_ID('dbo.pr_Inventario') and type='P')
BEGIN
   EXEC ('CREATE PROCEDURE dbo.pr_Inventario AS BEGIN  RETURN 0   END')
END
GO

ALTER PROCEDURE dbo.pr_Inventario 
    @i_accion     varchar(2),
    @i_bodega     varchar(3)   = NULL,
    @i_codigo     varchar(50)  = NULL,
    @i_dataxml    xml          = NULL,
    @i_usuario    varchar(15)    = null,
    @o_msgerror   varchar(200) = '' OUTPUT 
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @w_anio          varchar(4),
            @w_mes           varchar(2),
            @w_usuario       varchar(20),
            @w_id            int = 0,
            @w_articulo      varchar(20),
            @w_secuencia     varchar(4),
            @w_transaccion   varchar(11),
            @w_anterior      int,
            @w_valorUnit     money,
            @w_total         money,
            @w_valorIVA      money,
			@w_costo         money,
            @w_fechacreacion datetime,
            @w_medida        varchar(3),
			@w_permisofun    bit
            
    DECLARE @tb_nodos TABLE (id int identity(1,1), Articulo varchar(20), Existencia bigint, TomaFisica bigint, Diferencia bigint, Retapizando bigint, Consignacion bigint, PlanillaxCerrar bigint, Observacion varchar(200))

    IF @i_accion = 'BO' --Listado de Bodegas
    BEGIN
        BEGIN TRY
	    
		    SELECT @w_permisofun = IIF(EXISTS(SELECT 1 FROM dbo.ssatUsuario a INNER JOIN dbo.ssatTransaccionxUsuario b ON a.ci_usuario=b.ci_usuario AND b.ci_transaccion='3101' and ci_aplicacion='MOV' and a.ci_usuario=@i_usuario), 1, 0)

			IF @w_permisofun = 1
			BEGIN
                SELECT ci_bodega, 
                       tx_nombrebodega = ci_bodega + ' - ' + tx_nombrebodega
                  FROM dbo.scit_Bodegas
                 WHERE ce_estado='A'
			       AND ci_bodega IN (SELECT ci_bodega FROM dbo.scit_BodegaUsuario WHERE ci_usuario=@i_usuario)
            END 
			ELSE
			BEGIN
                SELECT ci_bodega, 
                       tx_nombrebodega = ci_bodega + ' - ' + tx_nombrebodega
                  FROM dbo.scit_Bodegas
                 WHERE ce_estado='A'
			END 
            SELECT @o_msgerror = 'Ejecucion OK'
        END TRY
        BEGIN CATCH
            SELECT @o_msgerror = 'Error: ' + ERROR_MESSAGE()
            RETURN -2
        END CATCH
    END


    IF @i_accion = 'LI'
    BEGIN
        BEGIN TRY
		    SELECT @w_permisofun = IIF(EXISTS(SELECT 1 FROM dbo.ssatUsuario a INNER JOIN dbo.ssatTransaccionxUsuario b ON a.ci_usuario=b.ci_usuario AND b.ci_transaccion='3101' and ci_aplicacion='MOV' and a.ci_usuario=@i_usuario), 'False', 'True')

            SELECT Codigo            = scit_Articulos.ci_articulo,
                   Bodega            = scit_ArticulosBodegas.ci_bodega,
                   Articulo          = scit_Articulos.tx_articulo,
                   Existencia        = scit_ArticulosBodegas.qn_existencia,
                   EnConsignacion    = ISNULL(scit_DetInventario.qn_consignacion,0),
                   Retapizandose     = ISNULL(scit_DetInventario.qn_retapizandose,0),
                   PlanillaPorCerrar = ISNULL(scit_DetInventario.qn_panillaxcerrar,0),
                   TomaFisica        = ISNULL(scit_DetInventario.qn_toma_fisica,0),
                   Diferencia        = ISNULL(scit_DetInventario.qn_diferencia,0),
                   Observacion       = ISNULL(scit_DetInventario.tx_observacion,''),
				   Modificar         = @w_permisofun
              FROM dbo.scit_Articulos
             INNER JOIN dbo.scit_ArticulosBodegas
                ON scit_ArticulosBodegas.ci_articulo = scit_Articulos.ci_articulo
               AND scit_ArticulosBodegas.ci_bodega   = ISNULL(@i_bodega, scit_ArticulosBodegas.ci_bodega)
               --AND scit_ArticulosBodegas.qn_existencia > 0
              LEFT JOIN dbo.scit_DetInventario
                ON scit_DetInventario.ci_anio = CONVERT(VARCHAR(4), YEAR(GETDATE()))
               AND scit_DetInventario.ci_mes  = RIGHT('00' + CONVERT(VARCHAR(2), MONTH(GETDATE())), 2)
               AND scit_DetInventario.ci_articulo = scit_Articulos.ci_articulo
           --WHERE scit_Articulos.ci_clase          != '0066' --COFRES
        
            SELECT @o_msgerror = 'Ejecucion OK'

        END TRY
        BEGIN CATCH
            SELECT @o_msgerror = 'Error: ' + ERROR_MESSAGE()
            RETURN -2
        END CATCH

    END --IF

    IF @i_accion = 'CO'
    BEGIN
        BEGIN TRY

		    SELECT @w_permisofun = IIF(EXISTS(SELECT 1 FROM dbo.ssatUsuario a INNER JOIN dbo.ssatTransaccionxUsuario b ON a.ci_usuario=b.ci_usuario AND b.ci_transaccion='3101' and ci_aplicacion='MOV' and a.ci_usuario=@i_usuario), 'False', 'True')

            SELECT Codigo            = scit_Articulos.ci_articulo,
                   Bodega            = ISNULL(scit_ArticulosBodegas.ci_bodega, '') + ' - ' + ISNULL(scit_Bodegas.tx_nombrebodega, ''),
                   Articulo          = ISNULL(scit_Articulos.tx_articulo, ''),
                   Existencia        = scit_ArticulosBodegas.qn_existencia,
                   EnConsignacion    = ISNULL(scit_DetInventario.qn_consignacion,0),
                   Retapizandose     = ISNULL(scit_DetInventario.qn_retapizandose,0),
                   PlanillaPorCerrar = ISNULL(scit_DetInventario.qn_panillaxcerrar,0),
                   TomaFisica        = ISNULL(scit_DetInventario.qn_toma_fisica,0),
                   Diferencia        = ISNULL(scit_DetInventario.qn_diferencia,0),
                   Observacion       = ISNULL(scit_DetInventario.tx_observacion,''),
				   Modificar         = @w_permisofun
              FROM dbo.scit_Articulos
             INNER JOIN dbo.scit_ArticulosBodegas
                ON scit_ArticulosBodegas.ci_articulo = scit_Articulos.ci_articulo
               AND scit_ArticulosBodegas.ci_bodega   = ISNULL(@i_bodega, scit_ArticulosBodegas.ci_bodega)
			  INNER JOIN dbo.scit_Bodegas
			     ON scit_Bodegas.ci_bodega = scit_ArticulosBodegas.ci_bodega
              LEFT JOIN dbo.scit_DetInventario
                ON scit_DetInventario.ci_anio = CONVERT(VARCHAR(4), YEAR(GETDATE()))
               AND scit_DetInventario.ci_mes  = RIGHT('00' + CONVERT(VARCHAR(2), MONTH(GETDATE())), 2)
               AND scit_DetInventario.ci_articulo = scit_Articulos.ci_articulo
             WHERE scit_Articulos.ci_articulo        = @i_codigo

            SELECT @o_msgerror = 'Ejecucion OK'

        END TRY
        BEGIN CATCH
            SELECT @o_msgerror = 'Error: ' + ERROR_MESSAGE()
            RETURN -2
        END CATCH
    END --IF

    IF @i_accion = 'UP'
    BEGIN
            /*
             *****************************************
             * Ejemplo de XML a enviar:              *
             *****************************************
             <Inventario>
               <Cabecera>
                  <usuario>CGONZALEZ</usuario>
                  <anio>2023</anio>
                  <mes>07</mes>
               </Cabecera>
               <Detalle>
                    <Conteo>
                        <articulo>C91</articulo>
                        <existencia>5</existencia>
                        <tomafisica>5</tomafisica>
                        <diferencia>0</diferencia>
                    </Conteo>
                    <Conteo>
                        <articulo>C92</articulo>
                        <existencia>3</existencia>
                        <tomafisica>2</tomafisica>
                        <diferencia>1</diferencia>
                    </Conteo>
                    <Conteo>
                        <articulo>C98</articulo>
                        <existencia>6</existencia>
                        <tomafisica>6</tomafisica>
                        <diferencia>0</diferencia>
                    </Conteo>
               </Detalle>
            </Inventario>
            *****************************************
             */
        BEGIN TRANSACTION [ActualizacionInventario]
        BEGIN TRY
            SELECT @w_anio     = @i_dataxml.value('/Inventario[1]/Cabecera[1]/anio[1]'    ,'varchar(4)'),
                   @w_mes      = @i_dataxml.value('/Inventario[1]/Cabecera[1]/mes[1]'     ,'varchar(2)'),
                   @w_usuario  = @i_dataxml.value('/Inventario[1]/Cabecera[1]/usuario[1]' ,'varchar(20)')
            

            --SELECT @w_anio     = CONVERT(VARCHAR(4), YEAR(GETDATE())),
            --       @w_mes      = RIGHT('00' + CONVERT(VARCHAR(2), MONTH(GETDATE())),2)
            
            IF ISNUMERIC(@w_anio)=0
            BEGIN
                SELECT @o_msgerror = 'Año especificado no es un valor numerico'
                ROLLBACK TRANSACTION [ActualizacionInventario]
                RETURN -9
            END

            IF ISNUMERIC(@w_mes)=0
            BEGIN
                SELECT @o_msgerror = 'Mes especificado no es un valor numerico'
                ROLLBACK TRANSACTION [ActualizacionInventario]
                RETURN -9
            END

            IF NOT EXISTS(SELECT * FROM dbo.scit_Bodegas WHERE ci_bodega=@i_bodega)
            BEGIN
                SELECT @o_msgerror = 'Bodega especificada no existe (' + CONVERT(VARCHAR,@i_bodega) + ')'
                ROLLBACK TRANSACTION [ActualizacionInventario]
                RETURN -9
            END

            SELECT @w_usuario = LTRIM(RTRIM(ISNULL(@w_usuario,'')))
            IF (NOT EXISTS(SELECT 1 FROM dbo.ssatUsuario where ci_usuario=@w_usuario)) AND @w_usuario != ''
            BEGIN
                SELECT @o_msgerror = 'Usuario especificado no existe (' + @w_usuario + ')'
                ROLLBACK TRANSACTION [ActualizacionInventario]
                RETURN -9
            END

            INSERT INTO @tb_nodos (Articulo, Existencia, TomaFisica, Diferencia, Retapizando, Consignacion, PlanillaxCerrar, Observacion)
            SELECT Articulo   = Conteo.value('articulo[1]','NVARCHAR(20)'), 
                   Existencia = Conteo.value('existencia[1]','bigint'),
                   TomaFisica = Conteo.value('tomafisica[1]','bigint'),
                   Diferencia = Conteo.value('diferencia[1]','bigint'),
                   Retapizando = Conteo.value('retapizando[1]','bigint'),
                   Consignacion = Conteo.value('consignacion[1]','bigint'),
                   PlanillaxCerrar = Conteo.value('planillaxcerrar[1]','bigint'),
                   Observacion = Conteo.value('observacion[1]','varchar(200)')
             FROM @i_dataxml.nodes('/Inventario/detalle/Conteo') as Detalle(Conteo)

            IF @@ROWCOUNT = 0
            BEGIN
                SELECT @o_msgerror = 'No se pasaron detalles para guardar'
                ROLLBACK TRANSACTION [ActualizacionInventario]
                RETURN -1
            END

            WHILE (1=1)
            BEGIN
                SELECT TOP 1 @w_articulo=Articulo FROM @tb_nodos WHERE id > @w_id
                IF NOT EXISTS(SELECT * FROM dbo.scit_Articulos WHERE ci_articulo=@w_articulo) 
                BEGIN
                    SELECT @o_msgerror='Articulo ' + @w_articulo + ' no existe en la base de datos. Se cancela inserción'
                    ROLLBACK TRANSACTION [ActualizacionInventario]
                    RETURN -2
                END
                IF @@ROWCOUNT=0 BREAK
            END

            DELETE dbo.scit_DetInventario 
              FROM @tb_nodos n
            WHERE ci_anio=@w_anio AND ci_mes=@w_mes AND ci_articulo=n.Articulo

            --DELETE dbo.scit_CabInventario WHERE ci_anio=@w_anio AND ci_mes=@w_mes

            IF NOT EXISTS(SELECT 1 FROM dbo.scit_CabInventario WHERE ci_anio=@w_anio AND ci_mes=@w_mes)
            BEGIN
                INSERT INTO dbo.scit_CabInventario 
                      (ci_anio, ci_mes, fx_creacion, ci_usuario)
                SELECT @w_anio, @w_mes, GETDATE(),   @w_usuario
            
                IF @@ROWCOUNT = 0
                BEGIN
                    SELECT @o_msgerror = 'No se pudo ingresar Cabecera del Inventario'
                    ROLLBACK TRANSACTION [ActualizacionInventario]
                    RETURN -1
                END
            END

            INSERT INTO dbo.scit_DetInventario 
                  (ci_anio,         
				   ci_mes,            
				   ci_bodega, 
                   ci_articulo,     
				   qn_existencia,     
				   qn_retapizandose,
				   qn_consignacion, 
				   qn_panillaxcerrar, 
				   qn_toma_fisica, 
                   qn_diferencia,   
				   tx_observacion,
				   va_costo)
            SELECT ci_anio           = @w_anio, 
                   ci_mes            = @w_mes, 
                   ci_bodega         = @i_bodega,
                   ci_articulo       = N.Articulo,
                   qn_existencia     = A.qn_existencia, 
				   qn_retapizandose  = N.Retapizando, 
				   qn_consignacion   = N.Consignacion, 
				   qn_panillaxcerrar = N.PlanillaxCerrar, 
                   qn_toma_fisica    = N.TomaFisica,
                   qn_diferencia     = A.qn_existencia - N.TomaFisica,
                   tx_observacion    = Observacion,
				   va_costo          = A.va_costo
              FROM @tb_nodos N
             INNER JOIN dbo.scit_Articulos A 
                ON A.ci_articulo=N.Articulo

            IF @@ROWCOUNT = 0
            BEGIN
                SELECT @o_msgerror = 'No se pudo ingresar Detalle del Inventario'
                ROLLBACK TRANSACTION [ActualizacionInventario]
                RETURN -1
            END

            SELECT @o_msgerror = 'Se actualizo el inventario correctamente'
            COMMIT TRANSACTION [ActualizacionInventario]

        END TRY
        BEGIN CATCH
           SELECT @o_msgerror = 'Error: '  + ERROR_MESSAGE() + ' - Linea: ' + CONVERT(VARCHAR,ERROR_LINE())
           ROLLBACK TRANSACTION [ActualizacionInventario]
           RETURN -3
        END CATCH

    END --IF

    RETURN 0
END
GO

IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE major_id=OBJECT_ID('dbo.pr_Inventario') and name='@i_accion')
   EXEC sp_dropextendedproperty  @name = '@i_accion' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'PROCEDURE', @level1name = 'pr_Inventario'
GO
EXEC sys.sp_addextendedproperty @name=N'@i_accion', @value=N'Accion a realizar dentro del SP (BO-Listado de Bodegas, LI-Listado de Inventario, CO-Consulta de Articulo, UP-Actualizacion del Inventario)' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'pr_Inventario'
GO

IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE major_id=OBJECT_ID('dbo.pr_Inventario') and name='@i_bodega')
   EXEC sp_dropextendedproperty  @name = '@i_bodega' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'PROCEDURE', @level1name = 'pr_Inventario'
GO
EXEC sys.sp_addextendedproperty @name=N'@i_bodega', @value=N'Bodega elegida' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'pr_Inventario'
GO

IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE major_id=OBJECT_ID('dbo.pr_Inventario') and name='@i_codigo')
   EXEC sp_dropextendedproperty  @name = '@i_codigo' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'PROCEDURE', @level1name = 'pr_Inventario'
GO
EXEC sys.sp_addextendedproperty @name=N'@i_codigo', @value=N'Codigo de Articulo' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'pr_Inventario'
GO

IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE major_id=OBJECT_ID('dbo.pr_Inventario') and name='@i_dataxml')
   EXEC sp_dropextendedproperty  @name = '@i_dataxml' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'PROCEDURE', @level1name = 'pr_Inventario'
GO
EXEC sys.sp_addextendedproperty @name=N'@i_dataxml', @value=N'Parametro XML con los articulos a actualizar' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'pr_Inventario'
GO

IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE major_id=OBJECT_ID('dbo.pr_Inventario') and name='@o_msgerror')
   EXEC sp_dropextendedproperty  @name = '@o_msgerror' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'PROCEDURE', @level1name = 'pr_Inventario'
GO
EXEC sys.sp_addextendedproperty @name=N'@o_msgerror', @value=N'Mensaje de respuesa del SP' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'pr_Inventario'
GO

IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE major_id=OBJECT_ID('dbo.pr_Inventario') and name='descripcion')
   EXEC sp_dropextendedproperty  @name = 'descripcion' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'PROCEDURE', @level1name = 'pr_Inventario'
GO
EXEC sys.sp_addextendedproperty @name=N'descripcion', @value=N'SP para manejar inventario' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'pr_Inventario'
GO

dbo.sp_help pr_Inventario
GO

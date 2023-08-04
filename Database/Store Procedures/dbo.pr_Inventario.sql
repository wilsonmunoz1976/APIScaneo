USE dbJardinesEsperanza
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
			@w_fechacreacion datetime,
			@w_medida        varchar(3)
			
    DECLARE @tb_nodos TABLE (id int identity(1,1), Articulo varchar(20), Existencia bigint, TomaFisica bigint, Diferencia bigint)

    IF @i_accion = 'BO' --Listado de Bodegas
    BEGIN
        BEGIN TRY
            SELECT ci_bodega, tx_nombrebodega
              FROM dbJardiesaDC.dbo.scit_Bodegas
             WHERE ce_estado='A'

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
            SELECT Codigo     = scit_Articulos.ci_articulo,
                   Bodega     = scit_ArticulosBodegas.ci_bodega,
                   Articulo   = scit_Articulos.tx_articulo,
                   Existencia = scit_ArticulosBodegas.qn_existencia,
                   TomaFisica = 0,
                   Diferencia = 0,
                   Comentario = null
              FROM dbJardiesaDC.dbo.scit_Articulos
             INNER JOIN dbJardiesaDC.dbo.scit_ArticulosBodegas
                ON scit_ArticulosBodegas.ci_articulo = scit_Articulos.ci_articulo
               AND scit_ArticulosBodegas.ci_bodega   = ISNULL(@i_bodega, scit_ArticulosBodegas.ci_bodega)
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
            SELECT Codigo     = scit_Articulos.ci_articulo,
                   Bodega     = scit_ArticulosBodegas.ci_bodega,
                   Articulo   = scit_Articulos.tx_articulo,
                   Existencia = scit_ArticulosBodegas.qn_existencia,
                   TomaFisica = 0,
                   Diferencia = 0,
                   Comentario = null
              FROM dbJardiesaDC.dbo.scit_Articulos
             INNER JOIN dbJardiesaDC.dbo.scit_ArticulosBodegas
                ON scit_ArticulosBodegas.ci_articulo = scit_Articulos.ci_articulo
               AND scit_ArticulosBodegas.ci_bodega   = ISNULL(@i_bodega, scit_ArticulosBodegas.ci_bodega)
             WHERE scit_Articulos.ci_articulo        = @i_codigo
             --AND scit_Articulos.ci_clase          != '0066' --COFRES

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

			IF NOT EXISTS(SELECT * FROM dbJardiesaDC.dbo.scit_Bodegas WHERE ci_bodega=@i_bodega)
			BEGIN
			    SELECT @o_msgerror = 'Bodega especificada no existe (' + CONVERT(VARCHAR,@i_bodega) + ')'
				ROLLBACK TRANSACTION [ActualizacionInventario]
				RETURN -9
			END

			SELECT @w_usuario = LTRIM(RTRIM(ISNULL(@w_usuario,'')))
			IF (NOT EXISTS(SELECT 1 FROM setUsuario where ci_usuario=@w_usuario)) AND @w_usuario != ''
			BEGIN
			    SELECT @o_msgerror = 'Usuario especificado no existe (' + @w_usuario + ')'
				ROLLBACK TRANSACTION [ActualizacionInventario]
				RETURN -9
			END

            INSERT INTO @tb_nodos (Articulo, Existencia, TomaFisica, Diferencia)
            SELECT Articulo   = Conteo.value('articulo[1]','NVARCHAR(20)'), 
                   Existencia = Conteo.value('existencia[1]','bigint'),
                   TomaFisica = Conteo.value('tomafisica[1]','bigint'),
                   Diferencia = Conteo.value('diferencia[1]','bigint')
             FROM @i_dataxml.nodes('/Inventario/Detalle/Conteo') as Detalle(Conteo)

            IF @@ROWCOUNT = 0
            BEGIN
                SELECT @o_msgerror = 'No se pasaron detalles para guardar'
				ROLLBACK TRANSACTION [ActualizacionInventario]
                RETURN -1
            END

			WHILE (1=1)
			BEGIN
			    SELECT TOP 1 @w_articulo=Articulo FROM @tb_nodos WHERE id > @w_id
				IF NOT EXISTS(SELECT * FROM dbJardiesaDC.dbo.scit_Articulos WHERE ci_articulo=@w_articulo) 
				BEGIN
					SELECT @o_msgerror='Articulo ' + @w_articulo + ' no existe en la base de datos. Se cancela inserción'
					ROLLBACK TRANSACTION [ActualizacionInventario]
					RETURN -2
				END
				IF @@ROWCOUNT=0 BREAK
			END
            
            DELETE dbJardiesaDC.dbo.scit_CabInventario WHERE ci_anio=@w_anio AND ci_mes=@w_mes
            DELETE dbJardiesaDC.dbo.scit_DetInventario WHERE ci_anio=@w_anio AND ci_mes=@w_mes
            
            INSERT INTO dbJardiesaDC.dbo.scit_CabInventario 
                  (ci_anio, ci_mes, fx_creacion, ci_usuario)
            SELECT @w_anio, @w_mes, GETDATE(),   @w_usuario
            
            IF @@ROWCOUNT = 0
            BEGIN
                SELECT @o_msgerror = 'No se pudo ingresar Cabecera del Inventario'
				ROLLBACK TRANSACTION [ActualizacionInventario]
                RETURN -1
            END

            INSERT INTO dbJardiesaDC.dbo.scit_DetInventario 
                  (ci_anio,       ci_mes,        ci_bodega, 
                   ci_articulo,   qn_existencia, qn_toma_fisica, 
                   qn_diferencia)
            SELECT @w_anio, 
                   @w_mes, 
                   @i_bodega,
                   Articulo,
                   Existencia,
                   TomaFisica,
                   Diferencia
              FROM @tb_nodos

            IF @@ROWCOUNT = 0
            BEGIN
                SELECT @o_msgerror = 'No se pudo ingresar Detalle del Inventario'
				ROLLBACK TRANSACTION [ActualizacionInventario]
                RETURN -1
            END

            SELECT @o_msgerror = 'Ejecucion OK'
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

dbo.sp_help pr_Inventario
GO

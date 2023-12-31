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
    @i_codigo     varchar(50)  = NULL,
    @i_dataxml    xml          = NULL,
    @i_usuario    varchar(15)  = NULL,
	@i_anio       varchar(4)   = NULL,
	@i_mes        varchar(2)   = NULL,
	@i_secuencia  int          = NULL, 
    @i_bodega     varchar(3)   = NULL,
	@i_forzar     char(1)      = 'N',
    @o_msgerror   varchar(200) = '' OUTPUT 
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @w_anio          varchar(4),
            @w_mes           varchar(2),
            @w_usuario       varchar(20),
            @w_id            int = 0,
            @w_articulo      varchar(20),
            @w_secuencia     int,
            @w_transaccion   varchar(11),
            @w_anterior      int,
            @w_valorUnit     money,
            @w_total         money,
            @w_valorIVA      money,
			@w_costo         money,
            @w_fechacreacion datetime,
            @w_medida        varchar(3),
			@w_permisofun    bit,
			@w_mostrarfun    bit,
			@w_totaltomafis  bigint,
			@w_rowcount      int,
			@w_estado        char(1)
			

    IF EXISTS(SELECT 1 FROM dbo.ssatParametrosGenerales WHERE ci_aplicacion='MOV' AND ci_parametro = 'DEBUG' AND tx_parametro = 'SI')
	BEGIN
	    IF NOT EXISTS(SELECT 1 FROM sys.all_objects WHERE object_id=OBJECT_ID('dbo.trace_movil'))
		BEGIN
		    CREATE TABLE trace_movil (fechahora datetime default getdate(), mensaje varchar(max))
		END

		INSERT INTO trace_movil (mensaje) 
		SELECT 'DECLARE @w_ret int, @w_msgerror varchar(200); '+ CHAR(13)
			   +'EXEC @w_ret = dbo.pr_Inventario ' + CHAR(13)
			   + ' @i_accion      ='+ISNULL(CHAR(39) + @i_accion + CHAR(39),'null') + CHAR(13)
			   +', @i_codigo      ='+ISNULL(CHAR(39) + @i_codigo + CHAR(39),'null')+ CHAR(13)
			   +', @i_dataxml     ='+ISNULL(CHAR(39) + CONVERT(VARCHAR(MAX),@i_dataxml) + CHAR(39),'null')+ CHAR(13)
			   +', @i_usuario     ='+ISNULL(CHAR(39) + @i_usuario + CHAR(39),'null')+ CHAR(13)
			   +', @i_anio        ='+ISNULL(CHAR(39) + @i_anio + CHAR(39),'null') + CHAR(13)
			   +', @i_mes         ='+ISNULL(CHAR(39) + @i_mes  + CHAR(39),'null') + CHAR(13)
			   +', @i_secuencia   ='+ISNULL(CONVERT(varchar,@i_secuencia),'null') + CHAR(13)
			   +', @i_bodega      ='+ISNULL(CHAR(39) + @i_bodega + CHAR(39),'null')+ CHAR(13)
			   +', @i_forzar      ='+ISNULL(CHAR(39) + @i_forzar + CHAR(39),'null') + CHAR(13)
			   +', @o_msgerror    = @w_msgerror    OUTPUT; '+ CHAR(13)
			   +'  SELECT @w_ret, @w_msgerror'+ CHAR(13)
	END
            
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

		    SELECT @w_permisofun = IIF(EXISTS(SELECT 1 FROM dbo.ssatUsuario a INNER JOIN dbo.ssatTransaccionxUsuario b ON a.ci_usuario=b.ci_usuario AND b.ci_transaccion='3101' and ci_aplicacion='MOV' and a.ci_usuario=@i_usuario), 0, 1)
			SELECT @w_mostrarfun = @w_permisofun

			SELECT TOP 1 
				   @w_anio      = ci_anio, 
				   @w_mes       = ci_mes,
				   @w_secuencia = ci_secuencia
			  FROM dbo.scit_CabInventario 
			 WHERE ci_bodega = @i_bodega
			   AND te_estado='A'
			 ORDER BY fx_creacion DESC

			 IF @@ROWCOUNT = 0
			 BEGIN
			    SELECT @o_msgerror = 'No existe un período activo para la Bodega [' + @i_bodega + ']. Consulte con Sistemas'
				RETURN -2
			    --IF CONVERT(VARCHAR(4), YEAR(GETDATE())) = @w_anio and RIGHT('00' + CONVERT(VARCHAR(2), MONTH(GETDATE())),2)=@w_mes
				--   SELECT @w_secuencia = @w_secuencia + 1
				--ELSE 
				--   SELECT @w_secuencia = 1

			 --   INSERT INTO dbo.scit_CabInventario (ci_anio,  ci_mes,  ci_secuencia, fx_creacion,  ci_usuario, te_estado, ci_bodega)
				--SELECT ci_anio = CONVERT(VARCHAR(4), YEAR(GETDATE())),  
				--       ci_mes  = RIGHT('00' + CONVERT(VARCHAR(2), MONTH(GETDATE())),2),  
				--	   ci_secuencia = @w_secuencia,
				--	   fx_creacion = GETDATE(),  
				--	   ci_usuario = @i_usuario, 
				--	   te_estado  = 'A', 
				--	   ci_bodega  = @i_bodega

				--SELECT TOP 1 
				--	     @w_anio = ci_anio, 
				--	     @w_mes  = ci_mes 
				--  FROM dbo.scit_CabInventario 
				-- WHERE ci_bodega = @i_bodega
   	            --	 AND te_estado='A'
				-- ORDER BY fx_creacion DESC
			 END

			IF @w_permisofun = 1
			BEGIN
			    IF EXISTS(SELECT 1 FROM dbo.scit_CabInventario WHERE te_estado='A' and ci_anio=@w_anio AND ci_mes=@w_mes)
					SELECT @w_permisofun = 1
				ELSE
					SELECT @w_permisofun = 0
            END

            IF OBJECT_ID(N'tempdb..#tmpListadoSolicitud') IS NOT NULL
	           DROP TABLE #tmpListadoSolicitud

            SELECT Codigo            = scit_Articulos.ci_articulo,
                   Bodega            = scit_ArticulosBodegas.ci_bodega,
                   Articulo          = scit_Articulos.tx_articulo,
                   Existencia        = ISNULL(scit_DetInventario.qn_existencia,0),
                   EnConsignacion    = ISNULL(scit_DetInventario.qn_consignacion,0),
                   Retapizandose     = ISNULL(scit_DetInventario.qn_retapizandose,0),
                   PlanillaPorCerrar = ISNULL(scit_DetInventario.qn_panillaxcerrar,0),
                   TomaFisica        = ISNULL(scit_DetInventario.qn_toma_fisica,0),
                   Diferencia        = ISNULL(scit_DetInventario.qn_diferencia,0),
                   Observacion       = ISNULL(scit_DetInventario.tx_observacion,''),
				   Modificar         = @w_permisofun,
				   Proveedor         = scit_Articulos.ci_proveedor,
				   Clase             = scit_Articulos.ci_clase,
				   Foto              = scit_Articulos.im_foto
			  INTO #tmpListadoSolicitud
              FROM dbo.scit_Articulos
              INNER JOIN dbo.scit_ArticulosBodegas
                ON scit_ArticulosBodegas.ci_articulo = scit_Articulos.ci_articulo
               AND scit_ArticulosBodegas.ci_bodega   = @i_bodega
              LEFT JOIN dbo.scit_DetInventario
                ON scit_DetInventario.ci_anio      = @w_anio
               AND scit_DetInventario.ci_mes       = @w_mes
			   AND scit_DetInventario.ci_secuencia = @w_secuencia
			   AND scit_DetInventario.ci_bodega    = @i_bodega
               AND scit_DetInventario.ci_articulo  = scit_Articulos.ci_articulo
			 ORDER BY scit_DetInventario.ci_articulo

		     DELETE #tmpListadoSolicitud
			  WHERE Foto IS NULL AND Clase='0066'
				         
		    IF @w_mostrarfun = 0
			BEGIN
			    UPDATE #tmpListadoSolicitud
				   SET Existencia = scit_ArticulosBodegas.qn_existencia
				  FROM #tmpListadoSolicitud
				 INNER JOIN dbo.scit_ArticulosBodegas
				    ON scit_ArticulosBodegas.ci_bodega   = #tmpListadoSolicitud.Bodega
				   AND scit_ArticulosBodegas.ci_articulo = #tmpListadoSolicitud.Codigo

		        DELETE #tmpListadoSolicitud
			     WHERE Existencia <= 0
			END
			ELSE
			BEGIN
		        DELETE #tmpListadoSolicitud
			     WHERE Proveedor IS NULL
				   AND Clase = '0066'
			END

		    IF @w_mostrarfun = 0
			BEGIN
				SELECT Codigo,
					   Bodega,
					   Articulo,
					   Existencia,
					   EnConsignacion,
					   Retapizandose,
					   PlanillaPorCerrar,
					   TomaFisica,
					   Diferencia,
					   Observacion,
					   Modificar
				  FROM #tmpListadoSolicitud
				 ORDER BY CONVERT(INT, SUBSTRING(Codigo, 2, LEN(Codigo)-1))
		    END
			ELSE
			BEGIN
			    IF EXISTS(SELECT 1 FROM #tmpListadoSolicitud WHERE Clase='0066')
					SELECT Codigo,
						   Bodega,
						   Articulo,
						   Existencia,
						   EnConsignacion,
						   Retapizandose,
						   PlanillaPorCerrar,
						   TomaFisica,
						   Diferencia,
						   Observacion,
						   Modificar
					  FROM #tmpListadoSolicitud
					 ORDER BY CONVERT(INT, SUBSTRING(Codigo, 2, LEN(Codigo)-1))
				ELSE
					SELECT Codigo,
						   Bodega,
						   Articulo,
						   Existencia,
						   EnConsignacion,
						   Retapizandose,
						   PlanillaPorCerrar,
						   TomaFisica,
						   Diferencia,
						   Observacion,
						   Modificar
					  FROM #tmpListadoSolicitud
					 ORDER BY Codigo
			END

            SELECT @o_msgerror = 'Ejecucion OK'

            IF OBJECT_ID(N'tempdb..#tmpListadoSolicitud') IS NOT NULL
	           DROP TABLE #tmpListadoSolicitud

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
			SELECT TOP 1 
				   @w_anio = ci_anio, 
				   @w_mes  = ci_mes 
			  FROM dbo.scit_CabInventario 
			 WHERE ci_bodega = @i_bodega
			   AND te_estado = 'A'
			 ORDER BY fx_creacion DESC

            SELECT Codigo            = scit_Articulos.ci_articulo,
                   Bodega            = ISNULL(scit_ArticulosBodegas.ci_bodega, '') + ' - ' + ISNULL(scit_Bodegas.tx_nombrebodega, ''),
                   Articulo          = ISNULL(scit_Articulos.tx_articulo, ''),
                   Existencia        = ISNULL(scit_DetInventario.qn_existencia,0),
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
                ON scit_DetInventario.ci_anio = @w_anio
               AND scit_DetInventario.ci_mes  = @w_mes
               AND scit_DetInventario.ci_articulo = scit_Articulos.ci_articulo
			   AND scit_DetInventario.ci_bodega = @i_bodega
             WHERE scit_Articulos.ci_articulo   = @i_codigo

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

            SELECT @w_usuario  = @i_dataxml.value('/Inventario[1]/Cabecera[1]/usuario[1]' ,'varchar(20)')

			SELECT TOP 1 
			       @w_anio      = ci_anio, 
				   @w_mes       = ci_mes,
				   @w_secuencia = ci_secuencia
			  FROM dbo.scit_CabInventario 
			 WHERE ci_bodega    = @i_bodega
			   AND te_estado    = 'A' 
			 ORDER BY fx_creacion DESC

			IF @@ROWCOUNT = 0
			BEGIN
                ROLLBACK TRANSACTION [ActualizacionInventario]
                SELECT @o_msgerror = 'No hay período de inventario activo para esta Bodega (' + @i_bodega + ')'
                RETURN -9
			END

		    IF EXISTS(SELECT 1 FROM dbo.scit_CabInventario WHERE ci_anio=@w_anio AND ci_mes=@w_mes AND te_estado='F')
			BEGIN
                ROLLBACK TRANSACTION [ActualizacionInventario]
                SELECT @o_msgerror = 'El período de inventario ya se encuentra cerrado, no puede modificar los valores'
                RETURN -9
			END

            IF ISNUMERIC(@w_anio)=0
            BEGIN
                ROLLBACK TRANSACTION [ActualizacionInventario]
                SELECT @o_msgerror = 'Año especificado no es un valor numérico'
                RETURN -9
            END

            IF ISNUMERIC(@w_mes)=0
            BEGIN
                ROLLBACK TRANSACTION [ActualizacionInventario]
                SELECT @o_msgerror = 'Mes especificado no es un valor numérico'
                RETURN -9
            END

            IF NOT EXISTS(SELECT * FROM dbo.scit_Bodegas WHERE ci_bodega=@i_bodega)
            BEGIN
                ROLLBACK TRANSACTION [ActualizacionInventario]
                SELECT @o_msgerror = 'Bodega especificada no existe (' + CONVERT(VARCHAR,@i_bodega) + ')'
                RETURN -9
            END

            SELECT @w_usuario = LTRIM(RTRIM(ISNULL(@w_usuario,'')))
            IF (NOT EXISTS(SELECT 1 FROM dbo.ssatUsuario where ci_usuario=@w_usuario)) AND @w_usuario != ''
            BEGIN
                ROLLBACK TRANSACTION [ActualizacionInventario]
                SELECT @o_msgerror = 'Usuario especificado no existe (' + @w_usuario + ')'
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
                ROLLBACK TRANSACTION [ActualizacionInventario]
                SELECT @o_msgerror = 'No se enviaron detalles para guardar'
                RETURN -1
            END

            WHILE (1=1)
            BEGIN
                SELECT TOP 1 @w_articulo=Articulo FROM @tb_nodos WHERE id > @w_id
                IF NOT EXISTS(SELECT * FROM dbo.scit_Articulos WHERE ci_articulo=@w_articulo) 
                BEGIN
                    ROLLBACK TRANSACTION [ActualizacionInventario]
                    SELECT @o_msgerror='Articulo ' + @w_articulo + ' no existe en la base de datos. Se cancela inserción'
                    RETURN -2
                END
                IF @@ROWCOUNT=0 BREAK
            END

            DELETE dbo.scit_DetInventario 
              FROM @tb_nodos n
            WHERE ci_anio=@w_anio AND ci_mes=@w_mes AND ci_articulo=n.Articulo AND ci_bodega=@i_bodega

            --DELETE dbo.scit_CabInventario WHERE ci_anio=@w_anio AND ci_mes=@w_mes

            IF NOT EXISTS(SELECT 1 FROM dbo.scit_CabInventario WHERE ci_anio=@w_anio AND ci_mes=@w_mes AND ci_bodega=@i_bodega)
            BEGIN
                INSERT INTO dbo.scit_CabInventario 
                      (ci_anio, ci_mes, ci_secuencia, fx_creacion, ci_usuario, ci_bodega)
                SELECT @w_anio, @w_mes, @w_secuencia, GETDATE(),   @w_usuario, @i_bodega
            
                IF @@ROWCOUNT = 0
                BEGIN
                    ROLLBACK TRANSACTION [ActualizacionInventario]
                    SELECT @o_msgerror = 'No se pudo ingresar Cabecera del Inventario'
                    RETURN -1
                END
            END

            INSERT INTO dbo.scit_DetInventario 
                  (ci_anio,         
				   ci_mes,            
				   ci_bodega, 
				   ci_secuencia,
                   ci_articulo,     
				   qn_existencia,     
				   qn_retapizandose,
				   qn_consignacion, 
				   qn_panillaxcerrar, 
				   qn_toma_fisica, 
                   qn_diferencia,   
				   tx_observacion,
				   va_costo,
				   te_ingreso)
            SELECT ci_anio           = @w_anio, 
                   ci_mes            = @w_mes, 
                   ci_bodega         = @i_bodega,
				   ci_secuencia      = @w_secuencia,
                   ci_articulo       = N.Articulo,
                   qn_existencia     = B.qn_existencia, 
				   qn_retapizandose  = N.Retapizando, 
				   qn_consignacion   = N.Consignacion, 
				   qn_panillaxcerrar = N.PlanillaxCerrar, 
                   qn_toma_fisica    = N.TomaFisica,
                   qn_diferencia     = B.qn_existencia - N.TomaFisica,
                   tx_observacion    = Observacion,
				   va_costo          = A.va_costo,
				   te_ingreso        = 'M'
              FROM @tb_nodos N
             INNER JOIN dbo.scit_Articulos A 
                ON A.ci_articulo=N.Articulo
			 INNER JOIN dbo.scit_ArticulosBodegas B
			    ON B.ci_articulo = A.ci_articulo
			   AND B.ci_bodega   = @i_bodega

            IF @@ROWCOUNT = 0
            BEGIN
                ROLLBACK TRANSACTION [ActualizacionInventario]
                SELECT @o_msgerror = 'No se pudo ingresar Detalle del Inventario'
                RETURN -1
            END

            COMMIT TRANSACTION [ActualizacionInventario]
            SELECT @o_msgerror = 'Se actualizo el inventario correctamente'

        END TRY
        BEGIN CATCH
           ROLLBACK TRANSACTION [ActualizacionInventario]
           SELECT @o_msgerror = 'Error: '  + ERROR_MESSAGE() + ' - Linea: ' + CONVERT(VARCHAR,ERROR_LINE())
           RETURN -3
        END CATCH

    END --IF

	IF @i_accion IN ('AI', 'AC') --Consutar el ultimo período activo de conteo de Inventario
	BEGIN
		SELECT TOP 1 
		       @w_anio      = ci_anio, 
			   @w_mes       = ci_mes,
			   @w_secuencia = ci_secuencia,
			   @w_estado    = te_estado 
		  FROM dbo.scit_CabInventario 
		 WHERE ci_bodega = @i_bodega
		 ORDER BY fx_creacion DESC

		 IF @w_estado = 'A' AND @i_accion = 'AI'
		 BEGIN
		    SELECT @o_msgerror = 'Ya se encuentra iniciada una toma de inventario, si desea iniciar un nuevo período, debe cerrar el vigente'
			SELECT anio      = @w_anio, 
				   mes       = @w_mes,
			       secuencia = @w_secuencia
			RETURN -2
		 END

		 IF @w_estado = 'C' AND @i_accion = 'AC'
		 BEGIN
		    SELECT @o_msgerror = 'No existe un período marcado con inicio de conteo para esta bodega que se pueda cerrar'
			SELECT anio      = @w_anio, 
				   mes       = @w_mes,
			       secuencia = @w_secuencia
			RETURN -2
		 END

		 IF  @i_accion = 'AI' 
		 BEGIN
			 IF @w_anio = YEAR(GETDATE()) AND @w_mes = RIGHT('00' + CONVERT(VARCHAR(2), MONTH(GETDATE())),2)
				SELECT @w_secuencia = @w_secuencia + 1
			 ELSE
  				SELECT @w_secuencia = 1

			 SELECT @w_anio = CONVERT(VARCHAR(4), YEAR(GETDATE())),
		  			@w_mes  = RIGHT('00' + CONVERT(VARCHAR(2), MONTH(GETDATE())),2)
		 END

		 SELECT anio      = @w_anio, 
	 		    mes       = @w_mes,
			    secuencia = @w_secuencia

	END

	IF @i_accion = 'CC' --Consultar conteo de Inventario
	BEGIN
	    DECLARE @w_conteo bigint, @w_cantidad bigint

		SELECT @w_cantidad = COUNT(1)
		  FROM sciv_ArticulosBodega
		 WHERE sciv_ArticulosBodega.ci_bodega = @i_bodega

		SELECT @w_conteo = COUNT(1)
		  FROM sciv_ArticulosBodega
		  LEFT JOIN dbo.scit_CabInventario 
  		    ON scit_CabInventario.ci_anio      = @i_anio
		   AND scit_CabInventario.ci_mes       = @i_mes
		   AND scit_CabInventario.ci_secuencia = @i_secuencia
		   AND scit_CabInventario.ci_bodega = sciv_ArticulosBodega.ci_bodega
		  LEFT JOIN dbo.scit_DetInventario 
		    ON scit_DetInventario.ci_anio      = scit_CabInventario.ci_anio
		   AND scit_DetInventario.ci_mes       = scit_CabInventario.ci_mes
		   AND scit_DetInventario.ci_bodega    = scit_CabInventario.ci_bodega
		   AND scit_DetInventario.ci_secuencia = scit_CabInventario.ci_secuencia
		   AND scit_DetInventario.ci_articulo  = sciv_ArticulosBodega.ci_articulo
		 WHERE sciv_ArticulosBodega.ci_bodega = @i_bodega
		   AND scit_DetInventario.ci_articulo IS NOT NULL

	    SELECT qn_conteo = @w_conteo, qn_cantidad = @w_cantidad
	END

	IF @i_accion = 'IT' --Iniciar toma de Inventario
	BEGIN
       BEGIN TRANSACTION [IniciarConteo]
	   BEGIN TRY

			SELECT TOP 1 
				   @w_anio      = ci_anio, 
				   @w_mes       = ci_mes,
				   @w_secuencia = ci_secuencia,
				   @w_estado    = te_estado 
			  FROM dbo.scit_CabInventario 
			 WHERE ci_bodega = @i_bodega
			 ORDER BY fx_creacion DESC

			IF @w_estado = 'A'
			BEGIN
			    ROLLBACK TRAN [IniciarConteo]
				SELECT @o_msgerror = 'Ya se encuentra iniciada una toma de inventario, si desea iniciar un nuevo período, debe cerrar el vigente'
				RETURN -2
			END

			IF NOT EXISTS(SELECT 1 FROM dbo.scit_CabInventario WHERE ci_anio=@i_anio and ci_mes=@i_mes and ci_secuencia=@i_secuencia and ci_bodega=@i_bodega)
			BEGIN
				INSERT INTO dbo.scit_CabInventario (
							ci_anio,
							ci_mes,
							ci_secuencia,
							fx_creacion,
							ci_usuario,
							te_estado,
							ci_bodega
							)
					 SELECT ci_anio      = @i_anio,
							ci_mes       = @i_mes,
							ci_secuencia = @i_secuencia,
							fx_creacion  = GETDATE(),
							ci_usuario   = @i_usuario,
							te_estado    = 'A',
							ci_bodega    = @i_bodega

					IF @@ROWCOUNT = 0
					BEGIN
						ROLLBACK TRAN [IniciarConteo]
						SELECT @o_msgerror = 'No se pudo ingresar la cabecera de Inventario para el nuevo periodo'
						RETURN -1
					END

				DELETE dbo.scit_DetInventario 
				 WHERE ci_bodega    = @i_bodega
				   AND ci_anio      = @i_anio
				   AND ci_mes       = @i_mes
				   AND ci_secuencia = @i_secuencia

				IF OBJECT_ID(N'tempdb..#tmpTomaFisica') IS NOT NULL
					DROP TABLE #tmpTomaFisica

				SELECT  ci_anio           = scit_CabInventario.ci_anio,
						ci_mes            = scit_CabInventario.ci_mes,
						ci_secuencia      = scit_CabInventario.ci_secuencia,
						ci_bodega         = scit_CabInventario.ci_bodega,
						ci_articulo       = sciv_ArticulosBodega.ci_articulo,
						qn_existencia     = sciv_ArticulosBodega.qn_existencia,
						qn_toma_fisica    = 0,
						qn_diferencia     = 0,
						qn_consignacion   = 0,
						qn_retapizandose  = CASE WHEN scit_Bodegas.ci_grupocontable = '0001' 
												 THEN (SELECT COUNT(1) 
														 FROM dbJardinesEsperanza.dbo.futRetapizados 
														WHERE futRetapizados.ci_bodega=scit_CabInventario.ci_bodega 
														  AND futRetapizados.ci_articulo=sciv_ArticulosBodega.ci_articulo
														  AND futRetapizados.ce_retapizado='I')
												 WHEN scit_Bodegas.ci_grupocontable = '0002' 
												 THEN (SELECT COUNT(1) 
														 FROM dbCautisaJE.dbo.futRetapizados 
														WHERE futRetapizados.ci_bodega=scit_CabInventario.ci_bodega 
														  AND futRetapizados.ci_articulo=sciv_ArticulosBodega.ci_articulo
														  AND futRetapizados.ce_retapizado='I')
												 ELSE 0
											END,
						qn_panillaxcerrar = CASE WHEN scit_Bodegas.ci_grupocontable = '0001' 
												 THEN (SELECT COUNT(1) 
														 FROM dbJardinesEsperanza.dbo.futSolicitudEgreso
														INNER JOIN dbJardinesEsperanza.dbo.futPlanilla 
														   ON futPlanilla.ci_planilla = futSolicitudEgreso.tx_transaccionorigen
														  AND futPlanilla.ci_planilla LIKE 'I%'
														WHERE futSolicitudEgreso.ci_bodega   = scit_CabInventario.ci_bodega 
														  AND futSolicitudEgreso.ci_articulo = sciv_ArticulosBodega.ci_articulo
														  AND (futSolicitudEgreso.fx_retiro IS NULL OR futSolicitudEgreso.fx_entrega IS NULL OR futSolicitudEgreso.fx_sala IS NULL) 
													   )
												 WHEN scit_Bodegas.ci_grupocontable = '0002' 
												 THEN (SELECT COUNT(1) 
														 FROM dbCautisaJE.dbo.futSolicitudEgreso
														INNER JOIN dbCautisaJE.dbo.futPlanilla 
														   ON futPlanilla.ci_planilla = futSolicitudEgreso.tx_transaccionorigen
														  AND futPlanilla.ci_planilla LIKE 'I%'
														WHERE futSolicitudEgreso.ci_bodega   = scit_CabInventario.ci_bodega 
														  AND futSolicitudEgreso.ci_articulo = sciv_ArticulosBodega.ci_articulo
														  AND (futSolicitudEgreso.fx_retiro IS NULL OR futSolicitudEgreso.fx_entrega IS NULL OR futSolicitudEgreso.fx_sala IS NULL) 
													   )
												 ELSE 0
											END,
						tx_observacion    = '',
						va_costo          = scit_Articulos.va_costo,
						te_ingreso        = 'A'
				 INTO #tmpTomaFisica
				 FROM sciv_ArticulosBodega
				INNER JOIN dbo.scit_Articulos
				   ON scit_Articulos.ci_articulo = sciv_ArticulosBodega.ci_articulo
				  AND scit_Articulos.ci_proveedor IS NOT NULL
				 INNER JOIN dbo.scit_Bodegas 
				   ON scit_Bodegas.ci_bodega = sciv_ArticulosBodega.ci_bodega
				 INNER JOIN dbo.scit_CabInventario 
				   ON scit_CabInventario.ci_anio      = @i_anio
				  AND scit_CabInventario.ci_mes       = @i_mes
				  AND scit_CabInventario.ci_secuencia = @i_secuencia
				  AND scit_CabInventario.ci_bodega = sciv_ArticulosBodega.ci_bodega
				WHERE sciv_ArticulosBodega.ci_bodega = @i_bodega

				UPDATE #tmpTomaFisica SET qn_diferencia = qn_existencia - qn_toma_fisica - qn_consignacion - qn_retapizandose - qn_panillaxcerrar

				INSERT INTO dbo.scit_DetInventario 
				(
						ci_anio,
						ci_mes,
						ci_secuencia,
						ci_bodega,
						ci_articulo,
						qn_existencia,
						qn_toma_fisica,
						qn_diferencia,
						qn_consignacion,
						qn_retapizandose,
						qn_panillaxcerrar,
						tx_observacion,
						va_costo,
						te_ingreso
				)
				SELECT  ci_anio,
						ci_mes,
						ci_secuencia,
						ci_bodega,
						ci_articulo,
						qn_existencia,
						qn_toma_fisica,
						qn_diferencia,
						qn_consignacion,
						qn_retapizandose,
						qn_panillaxcerrar,
						tx_observacion,
						va_costo,
						te_ingreso
				  FROM #tmpTomaFisica

				SELECT @w_rowcount = @@ROWCOUNT

				IF OBJECT_ID(N'tempdb..#tmpTomaFisica') IS NOT NULL
					DROP TABLE #tmpTomaFisica

				IF @w_rowcount = 0
				BEGIN
					ROLLBACK TRAN [IniciarConteo]
					SELECT @o_msgerror = 'No se pudo completar los registros faltantes automaticos del inventario'
					RETURN -1
				END
		    END
		END TRY
		BEGIN CATCH
			ROLLBACK TRAN [IniciarConteo]
			SELECT @o_msgerror = 'Error: ' + ERROR_MESSAGE()
			RETURN -1
		END CATCH
		COMMIT TRAN [IniciarConteo]

	END

	IF @i_accion = 'CE' --Cerrar conteo de Inventario
	BEGIN
	  BEGIN TRANSACTION [CerrarConteo]
	    BEGIN TRY

		   SELECT @w_totaltomafis = SUM(qn_toma_fisica)
			 FROM dbo.scit_DetInventario 
			 WHERE ci_bodega    = @i_bodega
			   AND ci_anio      = @i_anio
			   AND ci_mes       = @i_mes
			   AND ci_secuencia = @i_secuencia

			IF @w_totaltomafis = 0  AND @i_forzar = 'N'
			BEGIN
				ROLLBACK TRAN [CerrarConteo]
				SELECT @o_msgerror = 'En este período de toma de inventario no existen registros modificados, esta seguro de igual manera cerrarlo?'
				RETURN 20
			END 

			UPDATE dbo.scit_CabInventario 
			   SET te_estado    = 'C'
			 WHERE ci_anio      = @i_anio
			   AND ci_mes       = @i_mes
			   AND ci_bodega    = @i_bodega
			   AND ci_secuencia = @i_secuencia

			IF @@ROWCOUNT = 0
			BEGIN
				ROLLBACK TRAN [CerrarConteo]
				SELECT @o_msgerror = 'No se pudo actualizar la cabecera de Inventario a estado Cerrado'
				RETURN -1
			END


			COMMIT TRAN [CerrarConteo]
			SELECT @o_msgerror = 'Se cerro correctamente la toma física del período seleccionado'
			RETURN 0
         END TRY
		 BEGIN CATCH
		     ROLLBACK TRANSACTION [CerrarConteo]
		     SELECT @o_msgerror = ERROR_MESSAGE()
			 RETURN -9
		 END CATCH
	END

	SELECT @o_msgerror = 'Ejecución correcta'
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

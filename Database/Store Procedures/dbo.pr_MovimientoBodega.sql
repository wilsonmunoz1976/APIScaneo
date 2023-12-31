USE [dbJardiesaDC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS(SELECT 1 FROM sysobjects WHERE id=OBJECT_ID('dbo.pr_MovimientoBodega') and type='P')
BEGIN
   EXEC ('CREATE PROCEDURE dbo.pr_MovimientoBodega AS BEGIN RETURN 0 END')
END
GO

ALTER PROCEDURE dbo.pr_MovimientoBodega
(
    @i_tipomov       CHAR(2),
    @i_articulo      varchar(20)    = '',
    @i_planilla      varchar(20)    = '',
    @i_usuario       varchar(15)    = null,
    @i_bodega        varchar(3)     = null,
    @i_solegre       int            = 0,
    @o_transaccion   varchar(11)    = '' OUTPUT,
    @o_msgerror      varchar(200)   = '' OUTPUT

)
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
        SELECT 'DECLARE @w_ret int, @w_msgerror varchar(200), @w_transaccion varchar(11); '+ CHAR(13)
               +'EXEC @w_ret = dbo.pr_MovimientoBodega ' + CHAR(13)
               + ' @i_tipomov     ='+ISNULL(CHAR(39) + @i_tipomov + CHAR(39),'null') + CHAR(13)
               +', @i_articulo    ='+ISNULL(CHAR(39) + @i_articulo + CHAR(39),'null')+ CHAR(13)
               +', @i_planilla    ='+ISNULL(CHAR(39) + @i_planilla + CHAR(39),'null')+ CHAR(13)
               +', @i_usuario     ='+ISNULL(CONVERT(VARCHAR,@i_usuario),'null')+ CHAR(13)
               +', @i_bodega      ='+ISNULL(CHAR(39) + @i_bodega + CHAR(39),'null')+ CHAR(13)
               +', @i_solegre     ='+ISNULL(CONVERT(varchar,@i_solegre),'null') + CHAR(13)
               +', @o_transaccion = @w_transaccion OUTPUT'+ CHAR(13)
               +', @o_msgerror    = @w_msgerror    OUTPUT; '+ CHAR(13)
               +'  SELECT @w_ret, @w_msgerror, @w_transaccion'+ CHAR(13)
    END

    DECLARE @w_anio           varchar(4),
            @w_mes            varchar(2),
            @w_secuencia      varchar(4),
            @w_transaccion    varchar(11),
            @w_anterior       int          = null,
            @w_valorUnit      money        = 0,
            @w_total          money        = 0,
            @w_valorIVA       money        = 0,
            @w_porciva        money        = 0,
            @w_fechacreacion  datetime,
            @w_fecharegistro  datetime,
            @w_medida         varchar(3)   = '',
            @w_observacion    varchar(255) = '',
            @w_nota_entrega   varchar(25)  = '',
            @w_nombreinhumado varchar(255) = '',
            @w_nombrefamiliar varchar(255) = '',
            @w_sectransac     int          = 0,
            @w_articulo       varchar(20)  = '',
            @w_fechacontable  datetime,
            @w_ret            int,
            @w_va_costo       money,
            @w_qn_existencia  money,
            @w_costopromedio  money,
            @w_tipotransacc   varchar(3),
            @w_tx_observacion varchar(500),
            @w_tipoid         int,
            @w_identificacion varchar(15),
            @w_trasladar      varchar(200),
            @w_empresa        varchar(8),
            @w_empleado       numeric(5,0),
            @w_vehiculo       varchar(5),
            @w_factura        varchar(20),
            @w_qnsecuencia    int

        BEGIN TRY
    
            IF ('0001' IN (SELECT ci_grupocontable from dbo.scit_BodegaUsuario a  WITH (NOLOCK) INNER JOIN dbo.scit_Bodegas b  WITH (NOLOCK) ON a.ci_bodega = b.ci_bodega WHERE a.ci_usuario = @i_usuario))
            BEGIN
                SELECT @w_tipotransacc = futSolicitudEgreso.tx_documentoorigen,
                       @w_nombreinhumado     = futSolicitudEgreso.tx_nombrefallecido
                  FROM dbJardinesEsperanza.dbo.futSolicitudEgreso WITH (NOLOCK)
                 WHERE ci_solicitudegreso = @i_solegre

                IF @w_tipotransacc = 'FAC'
                    SELECT @w_nombreinhumado = ISNULL(@w_nombreinhumado, vetCabeceraFactura.tx_fallecidofactura),
                           @w_nombrefamiliar = vetCabeceraFactura.tx_cliente, 
                           @w_fechacreacion  = vetCabeceraFactura.fx_creacion,
                           @w_fecharegistro  = vetCabeceraFactura.fx_factura,
                           @w_tx_observacion = vetCabeceraFactura.tx_descripcion,
                           @w_tipoid         = CASE WHEN tx_tipoidentificacion = 'C' THEN 0 WHEN tx_tipoidentificacion = 'R' THEN 1 WHEN tx_tipoidentificacion = 'P' THEN 2 ELSE 3 END,
                           @w_identificacion = vetCabeceraFactura.tx_identificacion,
                           @w_trasladar      = '',
                           @w_empresa        = rolt_Empleado.ci_empresa,
                           @w_empleado       = rolt_Empleado.ci_empleado,
                           @w_vehiculo       = '',
                           @w_factura        = vetCabeceraFactura.ci_factura
                      FROM dbJardinesEsperanza.dbo.vetCabeceraFactura WITH (NOLOCK)
                      LEFT OUTER JOIN dbJardiesaDC.dbo.rolt_Empleado WITH (NOLOCK)
                        ON vetCabeceraFactura.ci_empleadovendedor = rolt_Empleado.ci_empleado 
                     WHERE vetCabeceraFactura.ci_factura = @i_planilla
                       AND vetCabeceraFactura.tx_tipodocumento = 'FA'

                IF @w_tipotransacc = 'INH'
                    SELECT @w_nombreinhumado = ISNULL(@w_nombreinhumado, futPlanilla.tx_nombrefallecido),
                           @w_nombrefamiliar = futPlanilla.tx_reporta, 
                           @w_fechacreacion  = futPlanilla.fx_creacion,
                           @w_fecharegistro  = futPlanilla.fx_fecharegistro,
                           @w_tx_observacion = futPlanilla.tx_observacion,
                           @w_tipoid         = CASE WHEN futPlanilla.tx_tipoid = 'C' THEN 0 WHEN futPlanilla.tx_tipoid = 'R' THEN 1 WHEN futPlanilla.tx_tipoid = 'P' THEN 2 ELSE 3 END,
                           @w_identificacion = futPlanilla.tx_idreporta,
                           @w_trasladar      = futPlanilla.tx_trasladar,
                           @w_empresa        = rolt_Empleado.ci_empresa,
                           @w_empleado       = rolt_Empleado.ci_empleado,
                           @w_vehiculo       = futPlanilla.ci_vehiculo,
                           @w_factura        = ''
                      FROM dbJardinesEsperanza.dbo.futPlanilla WITH (NOLOCK)
                      LEFT OUTER JOIN dbJardiesaDC.dbo.rolt_Empleado WITH (NOLOCK)
                        ON futPlanilla.ci_chofer = rolt_Empleado.ci_empleado 
                      LEFT OUTER JOIN dbJardiesaDC.dbo.scit_Vehiculos WITH (NOLOCK)
                        ON futPlanilla.ci_vehiculo = scit_Vehiculos.ci_vehiculo 
                     WHERE ci_planilla      = @i_planilla
            END

            IF ('0002' IN (SELECT ci_grupocontable from dbo.scit_BodegaUsuario a WITH (NOLOCK) INNER JOIN dbo.scit_Bodegas b WITH (NOLOCK) ON a.ci_bodega = b.ci_bodega WHERE a.ci_usuario = @i_usuario))
            BEGIN
                SELECT @w_tipotransacc    = futSolicitudEgreso.tx_documentoorigen,
                       @w_nombreinhumado  = futSolicitudEgreso.tx_nombrefallecido
                  FROM dbCautisaJE.dbo.futSolicitudEgreso WITH (NOLOCK)
                 WHERE ci_solicitudegreso = @i_solegre

                IF @w_tipotransacc = 'FAC'
                    SELECT @w_nombreinhumado = ISNULL(@w_nombreinhumado, vetCabeceraFactura.tx_fallecidofactura),
                           @w_nombrefamiliar = vetCabeceraFactura.tx_cliente, 
                           @w_fechacreacion  = vetCabeceraFactura.fx_creacion,
                           @w_fecharegistro  = vetCabeceraFactura.fx_factura,
                           @w_tx_observacion = vetCabeceraFactura.tx_descripcion,
                           @w_tipoid         = CASE WHEN tx_tipoidentificacion = 'C' THEN 0 WHEN tx_tipoidentificacion = 'R' THEN 1 WHEN tx_tipoidentificacion = 'P' THEN 2 ELSE 3 END,
                           @w_identificacion = vetCabeceraFactura.tx_identificacion,
                           @w_trasladar      = '',
                           @w_empresa        = rolt_Empleado.ci_empresa,
                           @w_empleado       = rolt_Empleado.ci_empleado,
                           @w_vehiculo       = '',
                           @w_factura        = vetCabeceraFactura.ci_factura
                      FROM dbCautisaJE.dbo.vetCabeceraFactura WITH (NOLOCK)
                      LEFT OUTER JOIN dbJardiesaDC.dbo.rolt_Empleado WITH (NOLOCK)
                        ON vetCabeceraFactura.ci_empleadovendedor = rolt_Empleado.ci_empleado 
                     WHERE vetCabeceraFactura.ci_factura = @i_planilla
                       AND vetCabeceraFactura.tx_tipodocumento = 'FA'

                IF @w_tipotransacc = 'INH'
                    SELECT @w_nombreinhumado = ISNULL(@w_nombreinhumado, futPlanilla.tx_nombrefallecido),
                           @w_nombrefamiliar = futPlanilla.tx_reporta, 
                           @w_fechacreacion  = futPlanilla.fx_creacion,
                           @w_fecharegistro  = futPlanilla.fx_fecharegistro,
                           @w_tx_observacion = futPlanilla.tx_observacion,
                           @w_tipoid         = CASE WHEN futPlanilla.tx_tipoid = 'C' THEN 0 WHEN futPlanilla.tx_tipoid = 'R' THEN 1 WHEN futPlanilla.tx_tipoid = 'P' THEN 2 ELSE 3 END,
                           @w_identificacion = futPlanilla.tx_idreporta,
                           @w_trasladar      = futPlanilla.tx_trasladar,
                           @w_empresa        = rolt_Empleado.ci_empresa,
                           @w_empleado       = rolt_Empleado.ci_empleado,
                           @w_vehiculo       = futPlanilla.ci_vehiculo,
                           @w_factura        = ''
                      FROM dbCautisaJE.dbo.futPlanilla WITH (NOLOCK)
                      LEFT OUTER JOIN dbJardiesaDC.dbo.rolt_Empleado WITH (NOLOCK)
                        ON futPlanilla.ci_chofer = rolt_Empleado.ci_empleado 
                      LEFT OUTER JOIN dbJardiesaDC.dbo.scit_Vehiculos WITH (NOLOCK)
                        ON futPlanilla.ci_vehiculo = scit_Vehiculos.ci_vehiculo 
                     WHERE ci_planilla      = @i_planilla
            END

            SELECT @w_va_costo = scit_Articulos.va_costo,
                   @w_qn_existencia = scit_Articulos.qn_existencia
              FROM dbJardiesaDC.dbo.scit_Articulos WITH (NOLOCK)
             INNER JOIN dbJardiesaDC.dbo.scit_ArticulosBodegas WITH (NOLOCK)
                ON scit_ArticulosBodegas.ci_articulo = scit_Articulos.ci_articulo
               AND scit_ArticulosBodegas.ci_bodega   = @i_bodega
             WHERE scit_Articulos.ci_articulo   = @i_articulo

            IF @w_qn_existencia <= 0
            BEGIN
                SELECT @o_msgerror = 'No hay existencia para el producto ' + @i_articulo + ' en la bodega ' + @i_bodega
                RETURN -2
            END

            SELECT @w_observacion = CASE WHEN @i_tipomov = 'IN' THEN 'Ingreso'
                                         WHEN @i_tipomov = 'OU' THEN 'Egreso'
                                         WHEN @i_tipomov = 'RB' THEN 'Reingreso'
                                         WHEN @i_tipomov = 'RE' THEN 'Egreso de Retapizado'
                                         WHEN @i_tipomov = 'RT' THEN 'Reingreso de Retapizado'
                                         ELSE 'Movimiento'
                                    END
              + ' por ' +  
              CASE WHEN @w_tipotransacc = 'INH' THEN 'planilla '
                   WHEN @w_tipotransacc = 'FAC' THEN 'factura '
                   ELSE '' 
              END 
            + ISNULL(@i_planilla,'pendiente') + ', del Inhumado ' + @w_nombreinhumado
    
            IF @i_tipomov = 'RE' SELECT @i_tipomov = 'OU'
            IF @i_tipomov = 'RT' SELECT @i_tipomov = 'RB'

            SELECT @w_fechacontable = fx_fechacontable
              FROM dbJardiesaDC.dbo.ssatFechaContable WITH (NOLOCK)
             WHERE ci_aplicacion = 'SCG'

            SELECT @w_anio = CONVERT(VARCHAR(4), YEAR(GETDATE()))
    
            SELECT @w_porciva = va_iva FROM dbo.ssatIva WITH (NOLOCK) WHERE ce_iva=1

            EXEC @w_ret      = dbo.pr_sectrans 
                 @i_bodega   = @i_bodega, 
                 @i_inout    = @i_tipomov, 
                 @o_sec      = @w_sectransac OUTPUT, 
                 @o_msgerror = @o_msgerror OUTPUT
    
            IF @w_ret != 0
            BEGIN
                SELECT @o_msgerror = 'Error: No se pudo obtener secuencia de Transaccion'
                RETURN -2
            END 

            SELECT @w_secuencia = FORMAT(@w_sectransac,'0000')
            SELECT @w_transaccion = @w_anio+@i_bodega+@w_secuencia
            SELECT @o_transaccion = @w_transaccion
    
            SELECT @w_anterior = qn_existencia 
              FROM dbJardiesaDC.dbo.scit_ArticulosBodegas 
             WHERE ci_articulo = @i_articulo
               AND ci_bodega   = @i_bodega
    
            IF @i_tipomov = 'RB'
            BEGIN
                IF ('0001' IN (SELECT ci_grupocontable from dbo.scit_BodegaUsuario a WITH (NOLOCK) INNER JOIN dbo.scit_Bodegas b WITH (NOLOCK) ON a.ci_bodega = b.ci_bodega WHERE a.ci_usuario = @i_usuario))
                BEGIN
                    SELECT @w_valorUnit    = scit_DetTransaccion.va_costo_unitario,
                           @w_nota_entrega = futSolicitudEgreso.ci_transaccionegreso
                      FROM dbJardinesEsperanza.dbo.futSolicitudEgreso WITH (NOLOCK)
                     INNER JOIN dbo.scit_DetTransaccion WITH (NOLOCK)
                        ON scit_DetTransaccion.ci_transaccion      = futSolicitudEgreso.ci_transaccionegreso
                       AND scit_DetTransaccion.ci_tipo_transaccion = futSolicitudEgreso.ci_tipo_transaccionegreso
                     WHERE futSolicitudEgreso.ci_solicitudegreso   = @i_solegre
                END
                IF ('0002' IN (SELECT ci_grupocontable from dbo.scit_BodegaUsuario a WITH (NOLOCK) INNER JOIN dbo.scit_Bodegas b WITH (NOLOCK) ON a.ci_bodega = b.ci_bodega WHERE a.ci_usuario = @i_usuario))
                BEGIN
                    SELECT @w_valorUnit    = scit_DetTransaccion.va_costo_unitario,
                           @w_nota_entrega = futSolicitudEgreso.ci_transaccionegreso
                      FROM dbCautisaJE.dbo.futSolicitudEgreso WITH (NOLOCK)
                     INNER JOIN dbo.scit_DetTransaccion WITH (NOLOCK)
                        ON scit_DetTransaccion.ci_transaccion      = futSolicitudEgreso.ci_transaccionegreso
                       AND scit_DetTransaccion.ci_tipo_transaccion = futSolicitudEgreso.ci_tipo_transaccionegreso
                     WHERE futSolicitudEgreso.ci_solicitudegreso   = @i_solegre
                END
            END
            ELSE
            BEGIN
                SELECT @w_valorUnit = scit_Articulos.va_costo
                  FROM dbo.scit_Articulos WITH (NOLOCK)
                 WHERE ci_articulo = @i_articulo
            END

            SELECT @w_medida    = ci_medida
              FROM dbo.scit_Articulos WITH (NOLOCK)
             WHERE ci_articulo = @i_articulo
    
            SELECT @w_valorIVA = @w_valorUnit * (@w_porciva / 100)
            SELECT @w_total = @w_valorUnit + @w_valorIVA

            INSERT INTO scit_CabTransaccion 
                (ci_tipo_transaccion,   ci_transaccion,                        ci_motivo,                           ci_bodega,
                 ci_bodega_destino,     fx_creacion,                           hr_creacion,                         ci_moneda,
                 va_tipo_cambio,        tx_observacion,                        ci_usuario,                          tx_nota_entrega,
                 ci_solicitud,          ci_factura,                            qn_anio,                             qn_mes,
                 ce_transaccion,        ce_cierre,                             bd_solicitud,                        qs_secasiento,
                 tx_tipo,               ci_cuentacontable,                     ci_proveedor,                        bd_obras,
                 fx_contable)               
            VALUES                      
                (@i_tipomov,            @w_transaccion,                        'NONE',                              @i_bodega,
                 '',                    FORMAT(GETDATE(),'yyyy-MM-dd'),        FORMAT(GETDATE(),'HH:mm:ss'),        '02',
                 1.00,                  LEFT(@w_observacion,255),              ISNULL(@i_usuario,''),               @w_nota_entrega,
                 '',                    '',                                    YEAR(GETDATE()),                     MONTH(GETDATE()),
                 'S',                   'N',                                   0,                                   '',
                 '',                    '',                                    '',                                  '',
                 FORMAT(@w_fechacontable,'yyyy-MM-dd'))
    
            IF @@ROWCOUNT = 0
            BEGIN
                SELECT @o_msgerror = 'Error: No se pudo ingresar Cabecera de Transacci�n'
                RETURN -2
            END 
            
            SELECT @w_qnsecuencia      = MAX(qn_secuencia) 
              FROM dbo.scit_DetTransaccion 
             WHERE ci_tipo_transaccion = @i_tipomov 
               AND ci_transaccion      = @w_transaccion

            SELECT @w_qnsecuencia = ISNULL(@w_qnsecuencia, 0) + 1

            INSERT INTO dbo.scit_DetTransaccion
                (ci_tipo_transaccion, ci_transaccion,       qn_secuencia,    ci_articulo,
                 qn_existencia_ant,   qn_cantidad,          ci_medida,       va_costo_unitario,    
                 va_iva,              va_precio_unitario,   qn_devolucion,   bd_promedioincluyeimpuestos)
            VALUES 
                (@i_tipomov,          @w_transaccion,       @w_qnsecuencia,  ISNULL(@i_articulo,''), 
                 @w_anterior,         1,                    @w_medida,       @w_valorUnit, 
                 0,                   @w_valorUnit,         0.00,            'S')    
            
            IF @@ROWCOUNT = 0
            BEGIN
                SELECT @o_msgerror = 'Error: No se pudo ingresar Detalle de Transacci�n'
                RETURN -2
            END 

            IF @i_tipomov IN ('IN', 'RB')
            BEGIN
                SELECT @w_costopromedio = ((@w_va_costo * @w_qn_existencia) + @w_valorUnit) / (@w_qn_existencia +  CASE WHEN @i_tipomov IN ('IN', 'RB') THEN 1
                                                                                                                        WHEN @i_tipomov = 'OU' THEN 0
                                                                                                                        ELSE 0
                                                                                                                    END)   
            END 
            ELSE
            BEGIN
                SELECT @w_costopromedio = @w_va_costo
            END

            UPDATE dbJardiesaDC.dbo.scit_Articulos 
               SET qn_existencia = qn_existencia + 
                                   CASE WHEN @i_tipomov IN ('IN', 'RB') THEN 1
                                        WHEN @i_tipomov = 'OU' THEN -1
                                        ELSE 0
                                   END,
                   va_costo      = ROUND(@w_costopromedio,4)
                WHERE ci_articulo   = @i_articulo

            IF @@ROWCOUNT = 0
            BEGIN
                SELECT @o_msgerror = 'Error: No se pudo actualizar la existencia del Articulo'
                RETURN -2
            END 

            UPDATE dbJardiesaDC.dbo.scit_ArticulosBodegas 
               SET qn_existencia = qn_existencia + 
                                 CASE WHEN @i_tipomov IN ('IN', 'RB') THEN 1
                                      WHEN @i_tipomov = 'OU' THEN -1
                                      ELSE 0
                                 END 
             WHERE ci_articulo   = @i_articulo
               AND ci_bodega     = @i_bodega
    
            IF @@ROWCOUNT = 0
            BEGIN
                SELECT @o_msgerror = 'Error: No se pudo actualizar la existencia del Articulo Bodega'
                RETURN -2
            END 

            IF @i_tipomov = 'OU'
            BEGIN
			    BEGIN TRY
					EXEC @w_ret      = dbo.pr_sectrans 
						 @i_bodega   = @i_bodega, 
						 @i_inout    = 'PED', 
						 @o_sec      = @w_sectransac OUTPUT, 
						 @o_msgerror = @o_msgerror   OUTPUT
    
					IF @w_ret != 0
					BEGIN
						SELECT @o_msgerror = 'Error: No se pudo obtener secuencia de Transaccion'
						INSERT INTO trace_movil (mensaje) SELECT '2 - '+@o_msgerror
						RETURN 0 -- -2
					END 

					SELECT @w_secuencia = FORMAT(@w_sectransac,'0000')
					SELECT @w_transaccion = @w_anio+@i_bodega+@w_secuencia

					INSERT INTO dbJardiesaDC.dbo.scit_CabPedidoBodega 
						 ( 
						   ci_pedidobodega, 
						   fx_fecha, 
						   tx_observacion, 
						   ci_bodega, 
						   tx_nombrefallecido, 
						   tx_familiar, 
						   ci_tipoid, 
						   ci_identificacion, 
						   tx_puntopartida, 
						   tx_puntollegada,
						   ci_empresa, 
						   ci_empleado, 
						   ci_vehiculo, 
						   tx_factura, 
						   te_pedidobodega, 
						   te_egresado, 
						   ci_usuario, 
						   fx_creacion, 
						   ci_reserva, 
						   ci_usuarioegreso, 
						   fx_egreso
						 ) 
					SELECT ci_pedidobodega    = @w_transaccion, 
						   fx_fecha           = @w_fecharegistro, 
						   tx_observacion     = @w_tx_observacion, 
						   ci_bodega          = @i_bodega, 
						   tx_nombrefallecido = @w_nombreinhumado, 
						   tx_familiar        = @w_nombrefamiliar, 
						   ci_tipoid          = @w_tipoid, 
						   ci_identificacion  = @w_identificacion, 
						   tx_puntopartida    = 'CEMENTERIO JARDINES DE ESPERANZA', 
						   tx_puntollegada    = @w_trasladar,
						   ci_empresa         = @w_empresa, 
						   ci_empleado        = @w_empleado, 
						   ci_vehiculo        = @w_vehiculo, 
						   tx_factura         = @w_factura, 
						   te_pedidobodega    = 'A', 
						   te_egresado        = 'T', 
						   ci_usuario         = @i_usuario, 
						   fx_creacion        = FORMAT(GETDATE(),'yyyy-MM-dd'), 
						   ci_reserva         = @i_planilla, 
						   ci_usuarioegreso   = @i_usuario, 
						   fx_egreso          = GETDATE() 

					IF @@ROWCOUNT = 0
					BEGIN
						SELECT @o_msgerror = 'Error: No se pudo Ingresar Cabecera de Pedido a Bodega'
						INSERT INTO trace_movil (mensaje) SELECT '2 - '+@o_msgerror
						RETURN -2
					END 

					INSERT INTO  dbJardiesaDC.DBO.scit_DetPedidoBodega 
						(  ci_pedidobodega, 
						   ci_detalle, 
						   ci_articulo, 
						   qn_cantSolicitada,
						   va_costo, 
						   va_IVAporcen, 
						   va_IVA, 
						   va_total,
						   te_detalle, 
						   fx_fecha, 
						   tx_observacion, 
						   qn_cantExistencia, 
						   qn_cantDespacho, 
						   fx_despacho
						) 
					SELECT ci_pedidobodega   = @w_transaccion,
						   ci_detalle        = @w_qnsecuencia, 
						   ci_articulo       = ISNULL(@i_articulo,''), 
						   qn_cantSolicitada = 1, 
						   va_costo          = @w_valorUnit, 
						   va_IVAporcen      = 0, 
						   va_IVA            = 0,  
						   va_total          = @w_valorUnit, 
						   te_detalle        = 'A', 
						   fx_fecha          = @w_fechacreacion,
						   tx_observacion    = 'ND', 
						   qn_cantExistencia = @w_anterior, 
						   qn_cantDespacho   = 1, 
						   fx_despacho       = GETDATE()

					IF @@ROWCOUNT = 0
					BEGIN
						SELECT @o_msgerror = 'Error: No se pudo Ingresar Detalle de Pedido a Bodega'
						INSERT INTO trace_movil (mensaje) SELECT '2 - '+@o_msgerror
						RETURN -2
					END 
				END TRY
				BEGIN CATCH
				    SELECT @o_msgerror = 'Hubo un error al grabar Pedido Bodega, pero grabo lo dem�s'
					INSERT INTO trace_movil (mensaje) SELECT '2 - '+@o_msgerror
					RETURN -2
				END CATCH
            END
       END TRY
    BEGIN CATCH
        SELECT @o_msgerror = 'Error: ' + ERROR_MESSAGE() + ' - ' + CONVERT(VARCHAR(MAX), ERROR_LINE())
		INSERT INTO trace_movil (mensaje) SELECT '1 - '+@o_msgerror
        RETURN -1
    END CATCH
    SELECT @o_msgerror = 'Movimiento de Bodega registrado correctamente'
    INSERT INTO trace_movil (mensaje) SELECT '0 - '+@o_msgerror
    RETURN 0
END
GO

IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE major_id=OBJECT_ID('dbo.pr_MovimientoBodega') and name='@i_articulo')
   EXEC sp_dropextendedproperty  @name = '@i_articulo' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'PROCEDURE', @level1name = 'pr_MovimientoBodega'
GO
EXEC sys.sp_addextendedproperty @name=N'@i_articulo', @value=N'Codigo de Articulo' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'pr_MovimientoBodega'
GO

IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE major_id=OBJECT_ID('dbo.pr_MovimientoBodega') and name='@i_planilla')
   EXEC sp_dropextendedproperty  @name = '@i_planilla' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'PROCEDURE', @level1name = 'pr_MovimientoBodega'
GO
EXEC sys.sp_addextendedproperty @name=N'@i_planilla', @value=N'Codigo de Planilla' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'pr_MovimientoBodega'
GO

IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE major_id=OBJECT_ID('dbo.pr_MovimientoBodega') and name='@i_tipomov')
   EXEC sp_dropextendedproperty  @name = '@i_tipomov' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'PROCEDURE', @level1name = 'pr_MovimientoBodega'
GO
EXEC sys.sp_addextendedproperty @name=N'@i_tipomov', @value=N'Tipo de Movimiento' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'pr_MovimientoBodega'
GO

IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE major_id=OBJECT_ID('dbo.pr_MovimientoBodega') and name='@i_usuario')
   EXEC sp_dropextendedproperty  @name = '@i_usuario' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'PROCEDURE', @level1name = 'pr_MovimientoBodega'
GO
EXEC sys.sp_addextendedproperty @name=N'@i_usuario', @value=N'Loginname de Usuario que invoca el SP' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'pr_MovimientoBodega'
GO

IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE major_id=OBJECT_ID('dbo.pr_MovimientoBodega') and name='@o_msgerror')
   EXEC sp_dropextendedproperty  @name = '@o_msgerror' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'PROCEDURE', @level1name = 'pr_MovimientoBodega'
GO
EXEC sys.sp_addextendedproperty @name=N'@o_msgerror', @value=N'Mensaje de Error que devuelve el SP' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'pr_MovimientoBodega'
GO

IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE major_id=OBJECT_ID('dbo.pr_MovimientoBodega') and name='descripcion')
   EXEC sp_dropextendedproperty  @name = 'descripcion' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'PROCEDURE', @level1name = 'pr_MovimientoBodega'
GO
EXEC sys.sp_addextendedproperty @name=N'descripcion', @value=N'Registra Movimientos de Bodega y es auxiliar de pr_Emergencia' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'pr_MovimientoBodega'
GO

dbo.sp_help pr_MovimientoBodega
GO

USE dbJardinesEsperanza
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
    @o_msgerror      varchar(200)   = '' OUTPUT
)
AS
BEGIN

    DECLARE @w_anio          varchar(4),
            @w_mes           varchar(2),
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
			@w_fechacontable datetime,
			@w_ret           int    

    BEGIN TRANSACTION [MovimientoBodega]
        BEGIN TRY
    
            SELECT @w_fechacontable = fx_fechacontable
              FROM dbJardiesaDC.dbo.ssatFechaContable
             WHERE ci_aplicacion = 'SCG'

	        SELECT @w_anio = CONVERT(VARCHAR(4), YEAR(GETDATE()))
            SELECT @w_bodega   = ci_bodega
              FROM dbJardiesaDC.dbo.scit_ArticulosBodegas
             WHERE ci_articulo = @i_articulo 
    
            EXEC @w_ret      = dbJardiesaDC.dbo.pr_sec 
			     @i_bodega   = @w_bodega, 
				 @i_inout    = @i_tipomov, 
				 @o_sec      = @w_sectransac OUTPUT, 
				 @o_msgerror = @o_msgerror OUTPUT
    
	        IF @w_ret != 0
			BEGIN
        		SELECT @o_msgerror = 'Error: No se pudo obtener secuencia de Transaccion'
        		ROLLBACK TRANSACTION [MovimientoBodega]
				RETURN -2
			END 

            SELECT @w_secuencia = FORMAT(@w_sectransac,'0000')
            SELECT @w_transaccion = @w_anio+@w_bodega+@w_secuencia
    
            SELECT @w_inhumado      = tx_nombrefallecido,
                   @w_fechacreacion = fx_creacion 
              FROM futPlanilla 
             WHERE ci_planilla      = @i_planilla
    
            SELECT @w_anterior = qn_existencia 
              FROM dbJardiesaDC.dbo.scit_Articulos 
             WHERE ci_articulo=@i_articulo
    
            SELECT @w_valorUnit = va_costo,
                   @w_medida    = ci_medida
              FROM dbJardiesaDC.dbo.scit_Articulos
             WHERE ci_articulo = @i_articulo
    
            SELECT @w_valorIVA = @w_valorUnit * 0.12
            SELECT @w_total = @w_valorUnit + @w_valorIVA
    
            SELECT @w_observacion = CASE WHEN @i_tipomov = 'IN' THEN 'Ingreso'
                                         WHEN @i_tipomov = 'OU' THEN 'Egreso'
                                         ELSE 'Movimiento'
                                    END
              + ' por planilla ' + @i_planilla + ', del Inhumado ' + @w_inhumado
    
            INSERT INTO dbJardiesaDC.dbo.scit_CabTransaccion 
                (ci_tipo_transaccion,   ci_transaccion,                        ci_motivo,                           ci_bodega,
                 ci_bodega_destino,     fx_creacion,                           hr_creacion,                         ci_moneda,
                 va_tipo_cambio,        tx_observacion,                        ci_usuario,                          tx_nota_entrega,
                 ci_solicitud,          ci_factura,                            qn_anio,                             qn_mes,
                 ce_transaccion,        ce_cierre,                             bd_solicitud,                        qs_secasiento,
                 tx_tipo,               ci_cuentacontable,                     ci_proveedor,                        bd_obras,
                 fx_contable)               
            VALUES                      
                (@i_tipomov,            @w_transaccion,                        'NONE',                              @w_bodega,
                 '',                    FORMAT(GETDATE(),'yyyy-MM-dd'),        FORMAT(GETDATE(),'HH:mm:ss'),        '02',
                 1.00,                  @w_observacion,                        ISNULL(@i_usuario,''),               @w_nota_entrega,
                 '',                    '',                                    YEAR(GETDATE()),                     MONTH(GETDATE()),
                 'S',                   'S',                                   0,                                   '',
                 '',                    '',                                    '',                                  '',
                 FORMAT(@w_fechacontable,'yyyy-MM-dd'))
    
	        IF @@ROWCOUNT = 0
			BEGIN
        		SELECT @o_msgerror = 'Error: No se pudo ingresar Cabecera de Transacción'
        		ROLLBACK TRANSACTION [MovimientoBodega]
				RETURN -2
			END 

            INSERT INTO dbJardiesaDC.dbo.scit_DetTransaccion
                (ci_tipo_transaccion, ci_transaccion,       qn_secuencia,    ci_articulo,
                 qn_existencia_ant,   qn_cantidad,          ci_medida,       va_costo_unitario,    
                 va_iva,              va_precio_unitario,   qn_devolucion,   bd_promedioincluyeimpuestos)
            VALUES 
                (@i_tipomov,          @w_transaccion,       7,               ISNULL(@i_articulo,''), 
                 @w_anterior,         1,                    @w_medida,       @w_valorUnit, 
                 @w_valorIVA,         @w_total,             0.00,            'S')    
            
	        IF @@ROWCOUNT = 0
			BEGIN
        		SELECT @o_msgerror = 'Error: No se pudo ingresar Detalle de Transacción'
        		ROLLBACK TRANSACTION [MovimientoBodega]
				RETURN -2
			END 

            UPDATE dbJardiesaDC.dbo.scit_Articulos 
               SET qn_existencia = qn_existencia + 
                                 CASE WHEN @i_tipomov = 'IN' THEN 1
                                      WHEN @i_tipomov = 'OU' THEN -1
                                      ELSE 0
                                 END 
             WHERE ci_articulo   = @i_articulo
    
	        IF @@ROWCOUNT = 0
			BEGIN
        		SELECT @o_msgerror = 'Error: No se pudo actualizar la existencia del Articulo'
        		ROLLBACK TRANSACTION [MovimientoBodega]
				RETURN -2
			END 

            UPDATE dbJardiesaDC.dbo.scit_ArticulosBodegas 
               SET qn_existencia = qn_existencia + 
                                   CASE WHEN @i_tipomov = 'IN' THEN 1
                                        WHEN @i_tipomov = 'OU' THEN -1
                                        ELSE 0
                                   END  
             WHERE ci_bodega     = @w_bodega 
			   AND ci_articulo   = @i_articulo

	        IF @@ROWCOUNT = 0
			BEGIN
        		SELECT @o_msgerror = 'Error: No se pudo actualizar la existencia de la Bodega'
        		ROLLBACK TRANSACTION [MovimientoBodega]
				RETURN -2
			END 
    
        COMMIT TRANSACTION [MovimientoBodega]
    
       END TRY
    BEGIN CATCH
        SELECT @o_msgerror = 'Error: ' + ERROR_MESSAGE() + ' - ' + CONVERT(VARCHAR(MAX), ERROR_LINE())
        ROLLBACK TRANSACTION [MovimientoBodega]
        RETURN -1
    END CATCH
  --END TRANSACTION
    RETURN 0
END
GO

dbo.sp_help pr_MovimientoBodega
GO

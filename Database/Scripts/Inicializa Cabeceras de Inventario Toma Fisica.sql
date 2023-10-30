DECLARE @w_anio varchar(4), @w_mes varchar(2)


SELECT @w_anio = RIGHT('0000' + CONVERT(VARCHAR(4), YEAR (GETDATE())),4),
       @w_mes  = RIGHT('00'   + CONVERT(VARCHAR(2), MONTH(GETDATE())),2)

IF OBJECT_ID(N'tempdb..#tmpCabInventario') IS NOT NULL
	DROP TABLE #tmpCabInventario

SELECT scit_Bodegas.ci_bodega,  bodegainv = scit_CabInventario.ci_bodega
  INTO #tmpCabInventario
  FROM dbJardiesaDC.dbo.scit_Bodegas
  LEFT JOIN dbJardiesaDC.dbo.scit_CabInventario
    ON scit_CabInventario.ci_bodega = scit_Bodegas.ci_bodega
   AND scit_CabInventario.te_estado = 'A'
 WHERE scit_Bodegas.ce_estado       = 'A'

 DELETE #tmpCabInventario WHERE bodegainv IS NOT NULL
 SELECT * FROM #tmpCabInventario
 
INSERT INTO dbJardiesaDC.dbo.scit_CabInventario (
       ci_anio,
       ci_mes,
       ci_bodega,
       ci_secuencia,
       fx_creacion,
       ci_usuario,
       te_estado)
SELECT ci_anio      = @w_anio,
       ci_mes       = @w_mes,
       ci_bodega    = ci_bodega,
       ci_secuencia = 1,
       fx_creacion  = GETDATE(),
       ci_usuario   = 'sa',
       te_estado    = 'A'
  FROM #tmpCabInventario


 IF OBJECT_ID(N'tempdb..#tmpCabInventario') IS NOT NULL
	DROP TABLE #tmpCabInventario
GO

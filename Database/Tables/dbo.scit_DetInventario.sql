USE dbJardiesaDC
GO

/****** Object:  Table dbo.scit_DetInventario    Script Date: 20/07/2023 11:10:20 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

IF EXISTS(SELECT 1 FROM sysobjects WHERE id=OBJECT_ID('dbo.scit_DetInventario'))
    DROP TABLE dbo.scit_DetInventario
GO

CREATE TABLE dbo.scit_DetInventario(
	ci_anio        varchar(4) NOT NULL,
	ci_mes         varchar(2) NOT NULL,
	ci_bodega      varchar(3) NOT NULL,
	ci_articulo    varchar(20) NOT NULL,
	qn_existencia  bigint NOT NULL,
	qn_toma_fisica bigint NOT NULL,
	qn_diferencia  bigint NOT NULL,
	tx_observacion varchar(200) NULL,
 CONSTRAINT PK_scit_DetInventario PRIMARY KEY NONCLUSTERED 
(
	ci_anio ASC,
	ci_mes ASC,
	ci_bodega ASC,
	ci_articulo ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80)
)

GO

SET ANSI_PADDING OFF
GO

ALTER TABLE dbo.scit_DetInventario ADD  CONSTRAINT DF_scit_DetInventario_qn_existencia   DEFAULT ((0)) FOR qn_existencia
GO

ALTER TABLE dbo.scit_DetInventario ADD  CONSTRAINT DF_scit_DetInventario_qn_toma_fisica  DEFAULT ((0)) FOR qn_toma_fisica
GO

ALTER TABLE dbo.scit_DetInventario ADD  CONSTRAINT DF_scit_DetInventario_qn_diferencia   DEFAULT ((0)) FOR qn_diferencia
GO


ALTER TABLE dbo.scit_DetInventario  WITH NOCHECK ADD  CONSTRAINT FK_scit_DetInventario_scit_Articulos FOREIGN KEY(ci_articulo)
REFERENCES dbo.scit_Articulos (ci_articulo)
GO

ALTER TABLE dbo.scit_DetInventario CHECK CONSTRAINT FK_scit_DetInventario_scit_Articulos
GO

ALTER TABLE dbo.scit_DetInventario  WITH CHECK ADD  CONSTRAINT FK_scit_DetInventario_scit_Bodegas FOREIGN KEY(ci_bodega)
REFERENCES dbo.scit_Bodegas (ci_bodega)
GO

ALTER TABLE dbo.scit_DetInventario CHECK CONSTRAINT FK_scit_DetInventario_scit_Bodegas
GO

ALTER TABLE dbo.scit_DetInventario  WITH CHECK ADD  CONSTRAINT FK_scit_DetInventario_scit_DetInventario FOREIGN KEY(ci_anio, ci_mes)
REFERENCES dbo.scit_CabInventario (ci_anio, ci_mes)
GO

ALTER TABLE dbo.scit_DetInventario CHECK CONSTRAINT FK_scit_DetInventario_scit_DetInventario
GO


IF EXISTS(SELECT 1 FROM sys.extended_properties INNER JOIN sys.all_columns ON extended_properties.major_id=all_columns.object_id and extended_properties.minor_id=all_columns.column_id WHERE extended_properties.major_id=OBJECT_ID('dbo.scit_DetInventario') and extended_properties.name='MS_Description' AND all_columns.name='ci_anio')
   EXEC sp_dropextendedproperty  @name=N'MS_Description' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'TABLE', @level1name = 'scit_DetInventario', @level2type = 'COLUMN', @level2name = 'ci_anio'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Año del Inventario' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'scit_DetInventario', @level2type=N'COLUMN',@level2name=N'ci_anio'
GO

IF EXISTS(SELECT 1 FROM sys.extended_properties INNER JOIN sys.all_columns ON extended_properties.major_id=all_columns.object_id and extended_properties.minor_id=all_columns.column_id WHERE extended_properties.major_id=OBJECT_ID('dbo.scit_DetInventario') and extended_properties.name='MS_Description' AND all_columns.name='ci_articulo')
   EXEC sp_dropextendedproperty  @name=N'MS_Description' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'TABLE', @level1name = 'scit_DetInventario', @level2type = 'COLUMN', @level2name = 'ci_articulo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Codigo de Articulo' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'scit_DetInventario', @level2type=N'COLUMN',@level2name=N'ci_articulo'
GO

IF EXISTS(SELECT 1 FROM sys.extended_properties INNER JOIN sys.all_columns ON extended_properties.major_id=all_columns.object_id and extended_properties.minor_id=all_columns.column_id WHERE extended_properties.major_id=OBJECT_ID('dbo.scit_DetInventario') and extended_properties.name='MS_Description' AND all_columns.name='ci_bodega')
   EXEC sp_dropextendedproperty  @name=N'MS_Description' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'TABLE', @level1name = 'scit_DetInventario', @level2type = 'COLUMN', @level2name = 'ci_bodega'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Codigo de Bodega' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'scit_DetInventario', @level2type=N'COLUMN',@level2name=N'ci_bodega'
GO

IF EXISTS(SELECT 1 FROM sys.extended_properties INNER JOIN sys.all_columns ON extended_properties.major_id=all_columns.object_id and extended_properties.minor_id=all_columns.column_id WHERE extended_properties.major_id=OBJECT_ID('dbo.scit_DetInventario') and extended_properties.name='MS_Description' AND all_columns.name='ci_mes')
   EXEC sp_dropextendedproperty  @name=N'MS_Description' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'TABLE', @level1name = 'scit_DetInventario', @level2type = 'COLUMN', @level2name = 'ci_mes'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Mes del Inventario' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'scit_DetInventario', @level2type=N'COLUMN',@level2name=N'ci_mes'
GO

IF EXISTS(SELECT 1 FROM sys.extended_properties INNER JOIN sys.all_columns ON extended_properties.major_id=all_columns.object_id and extended_properties.minor_id=all_columns.column_id WHERE extended_properties.major_id=OBJECT_ID('dbo.scit_DetInventario') and extended_properties.name='MS_Description' AND all_columns.name='qn_diferencia')
   EXEC sp_dropextendedproperty  @name=N'MS_Description' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'TABLE', @level1name = 'scit_DetInventario', @level2type = 'COLUMN', @level2name = 'qn_diferencia'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Valor de diferencia' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'scit_DetInventario', @level2type=N'COLUMN',@level2name=N'qn_diferencia'
GO

IF EXISTS(SELECT 1 FROM sys.extended_properties INNER JOIN sys.all_columns ON extended_properties.major_id=all_columns.object_id and extended_properties.minor_id=all_columns.column_id WHERE extended_properties.major_id=OBJECT_ID('dbo.scit_DetInventario') and extended_properties.name='MS_Description' AND all_columns.name='qn_existencia')
   EXEC sp_dropextendedproperty  @name=N'MS_Description' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'TABLE', @level1name = 'scit_DetInventario', @level2type = 'COLUMN', @level2name = 'qn_existencia'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Valor de Existencia' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'scit_DetInventario', @level2type=N'COLUMN',@level2name=N'qn_existencia'
GO

IF EXISTS(SELECT 1 FROM sys.extended_properties INNER JOIN sys.all_columns ON extended_properties.major_id=all_columns.object_id and extended_properties.minor_id=all_columns.column_id WHERE extended_properties.major_id=OBJECT_ID('dbo.scit_DetInventario') and extended_properties.name='MS_Description' AND all_columns.name='qn_toma_fisica')
   EXEC sp_dropextendedproperty  @name=N'MS_Description' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'TABLE', @level1name = 'scit_DetInventario', @level2type = 'COLUMN', @level2name = 'qn_toma_fisica'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Valor de Toma Fisica' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'scit_DetInventario', @level2type=N'COLUMN',@level2name=N'qn_toma_fisica'
GO

IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE major_id=OBJECT_ID('dbo.scit_DetInventario') and name='descripcion')
   EXEC sp_dropextendedproperty  @name = 'descripcion' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'TABLE', @level1name = 'scit_DetInventario'
GO
EXEC sys.sp_addextendedproperty @name=N'descripcion', @value=N'Tabla de Detalle de Inventario' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'scit_DetInventario'
GO

dbo.sp_help scit_DetInventario
GO

USE dbJardiesaDC
GO

/****** Object:  Table dbo.scit_CabCierre    Script Date: 20/07/2023 11:12:02 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

IF EXISTS(SELECT 1 FROM sysobjects WHERE id=OBJECT_ID('dbo.scit_CabInventario'))
    DROP TABLE dbo.scit_CabInventario
GO

CREATE TABLE dbo.scit_CabInventario
(
	ci_anio     varchar(4)  NOT NULL,
	ci_mes      varchar(2)  NOT NULL,
	fx_creacion datetime    NOT NULL,
	ci_usuario  varchar(20) NOT NULL,
 CONSTRAINT PK_scit_CabInventario PRIMARY KEY NONCLUSTERED 
(
	ci_anio ASC,
	ci_mes ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80)
)

GO


IF EXISTS(SELECT * FROM sys.extended_properties INNER JOIN sys.all_columns ON extended_properties.major_id=all_columns.object_id and extended_properties.minor_id=all_columns.column_id WHERE extended_properties.major_id=OBJECT_ID('dbo.scit_CabInventario') and extended_properties.name='MS_Description' AND all_columns.name='ci_anio')
   EXEC sp_dropextendedproperty  @name=N'MS_Description' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'TABLE', @level1name = 'scit_CabInventario', @level2type = 'COLUMN', @level2name = 'ci_anio'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Año del inventario' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'scit_CabInventario', @level2type=N'COLUMN',@level2name=N'ci_anio'
GO

IF EXISTS(SELECT * FROM sys.extended_properties INNER JOIN sys.all_columns ON extended_properties.major_id=all_columns.object_id and extended_properties.minor_id=all_columns.column_id WHERE extended_properties.major_id=OBJECT_ID('dbo.scit_CabInventario') and extended_properties.name='MS_Description' AND all_columns.name='ci_mes')
   EXEC sp_dropextendedproperty  @name=N'MS_Description' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'TABLE', @level1name = 'scit_CabInventario', @level2type = 'COLUMN', @level2name = 'ci_mes'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Mes del inventario' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'scit_CabInventario', @level2type=N'COLUMN',@level2name=N'ci_mes'
GO

IF EXISTS(SELECT * FROM sys.extended_properties INNER JOIN sys.all_columns ON extended_properties.major_id=all_columns.object_id and extended_properties.minor_id=all_columns.column_id WHERE extended_properties.major_id=OBJECT_ID('dbo.scit_CabInventario') and extended_properties.name='MS_Description' AND all_columns.name='fx_creacion')
   EXEC sp_dropextendedproperty  @name=N'MS_Description' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'TABLE', @level1name = 'scit_CabInventario', @level2type = 'COLUMN', @level2name = 'fx_creacion'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Fecha de Creación' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'scit_CabInventario', @level2type=N'COLUMN',@level2name=N'fx_creacion'
GO

IF EXISTS(SELECT * FROM sys.extended_properties INNER JOIN sys.all_columns ON extended_properties.major_id=all_columns.object_id and extended_properties.minor_id=all_columns.column_id WHERE extended_properties.major_id=OBJECT_ID('dbo.scit_CabInventario') and extended_properties.name='MS_Description' AND all_columns.name='ci_usuario')
   EXEC sp_dropextendedproperty  @name=N'MS_Description' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'TABLE', @level1name = 'scit_CabInventario', @level2type = 'COLUMN', @level2name = 'ci_usuario'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Usuario de Creación/Modificación' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'scit_CabInventario', @level2type=N'COLUMN',@level2name=N'ci_usuario'
GO

IF EXISTS(SELECT * FROM sys.extended_properties WHERE major_id=OBJECT_ID('dbo.scit_CabInventario') and name='descripcion')
   EXEC sp_dropextendedproperty  @name = 'descripcion' ,@level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'TABLE', @level1name = 'scit_CabInventario'
GO
EXEC sys.sp_addextendedproperty @name=N'descripcion', @value=N'Tabla cabecera de Inventario' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'scit_CabInventario'
GO

dbo.sp_help scit_CabInventario
GO


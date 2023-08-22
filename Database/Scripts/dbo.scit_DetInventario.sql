USE dbJardiesaDC
GO

/****** Object:  Table dbo.scit_DetInventario    Script Date: 28/07/2023 17:58:37 ******/
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
	ci_anio varchar(4) NOT NULL,
	ci_mes varchar(2) NOT NULL,
	ci_bodega varchar(3) NOT NULL,
	ci_articulo varchar(20) NOT NULL,
	qn_existencia bigint NOT NULL,
	qn_toma_fisica bigint NOT NULL,
	qn_diferencia bigint NOT NULL,
	tx_observacion varchar(200) NULL
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

ALTER TABLE dbo.scit_DetInventario ADD  CONSTRAINT DF_scit_DetInventario_qn_existencia  DEFAULT ((0)) FOR qn_existencia
GO

ALTER TABLE dbo.scit_DetInventario ADD  CONSTRAINT DF_scit_DetInventario_qn_toma_fisica  DEFAULT ((0)) FOR qn_toma_fisica
GO

ALTER TABLE dbo.scit_DetInventario ADD  CONSTRAINT DF_scit_DetInventario_qn_diferencia  DEFAULT ((0)) FOR qn_diferencia
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

ALTER TABLE dbo.scit_DetInventario  WITH CHECK ADD  CONSTRAINT FK_scit_DetInventario_scit_CabInventario FOREIGN KEY(ci_anio, ci_mes)
REFERENCES dbo.scit_CabInventario (ci_anio, ci_mes)
GO

ALTER TABLE dbo.scit_DetInventario CHECK CONSTRAINT FK_scit_DetInventario_scit_CabInventario
GO



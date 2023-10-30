ALTER TABLE dbJardiesaDC.dbo.scit_DetInventario DROP CONSTRAINT FK_scit_DetInventario_scit_Articulos
GO

ALTER TABLE dbJardiesaDC.dbo.scit_DetInventario DROP CONSTRAINT PK_scit_DetInventario
GO

ALTER TABLE dbJardiesaDC.dbo.scit_CabInventario DROP CONSTRAINT PK_scit_CabInventario
GO

ALTER TABLE dbJardiesaDC.dbo.scit_CabInventario ADD ci_secuencia smallint DEFAULT(1)
GO

ALTER TABLE dbJardiesaDC.dbo.scit_DetInventario ADD ci_secuencia smallint DEFAULT(1)
GO

UPDATE dbJardiesaDC.dbo.scit_CabInventario SET ci_secuencia=1
GO

UPDATE dbJardiesaDC.dbo.scit_DetInventario SET ci_secuencia=1
GO

ALTER TABLE [dbo].[scit_CabInventario] ADD  CONSTRAINT [PK_scit_CabInventario] PRIMARY KEY CLUSTERED 
(
	[ci_anio] ASC,
	[ci_mes] ASC,
	[ci_bodega] ASC,
	[ci_secuencia] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

ALTER TABLE [dbo].[scit_DetInventario] ADD  CONSTRAINT [PK_scit_DetInventario] PRIMARY KEY CLUSTERED 
(
	[ci_anio] ASC,
	[ci_mes] ASC,
	[ci_bodega] ASC,
	[ci_secuencia] ASC,
	[ci_articulo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

ALTER TABLE dbo.scit_DetInventario  WITH CHECK ADD  CONSTRAINT FK_scit_CabInventario_scit_DetInventario FOREIGN KEY(ci_anio, ci_mes, ci_bodega, ci_secuencia)
REFERENCES dbo.scit_CabInventario (ci_anio, ci_mes, ci_bodega, ci_secuencia)
GO

ALTER TABLE [dbo].[scit_DetInventario] CHECK CONSTRAINT [FK_scit_CabInventario_scit_DetInventario]
GO

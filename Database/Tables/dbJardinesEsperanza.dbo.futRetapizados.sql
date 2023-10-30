USE dbJardinesEsperanza
GO

/****** Object:  Table [dbo].[futPlanilla]    Script Date: 21/09/2023 17:32:03 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

IF EXISTS(SELECT 1 FROM sysobjects WHERE id=OBJECT_ID('dbo.futRetapizados') and type='U')
    DROP TABLE dbo.futRetapizados
GO

CREATE TABLE [dbo].[futRetapizados](
    [ci_secuencia] bigint identity(1,1),
	[ci_articulo] [varchar](20) NULL,
	[tx_planilla] [varchar](20) NOT NULL,
	[ci_solegreorg] int NOT NULL,
	[fx_fecharegistro] [datetime] NOT NULL,
	[ci_bodega] [varchar](3) NOT NULL,
	[ce_retapizado] varchar(2) DEFAULT('I'),
	[fx_fechareingreso] [datetime] NULL,
	[ci_usuarioretapizado]  [varchar](15) NOT NULL,
	[ci_usuarioreingreso]  [varchar](15) NULL,
	[ci_transaccionegreso] varchar(11) NULL,
	[ci_tipo_transaccionegreso] varchar(2) null,
	[ci_factura] varchar(20) null,
	[tx_observacion] varchar(200) null,
	[tx_nombrelimpieza] varchar(50) null,
	[tx_observacionbaja] varchar(300) null,
	[fx_eliminacion] datetime null,
	[ci_usuarioeliminacion] varchar(15) null
 CONSTRAINT [PK_futRetapizados] PRIMARY KEY CLUSTERED 
(
	[ci_secuencia] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [ix_fecharegistro] ON [dbo].[futRetapizados]
(
	[fx_fecharegistro] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [ix_articulo] ON [dbo].[futRetapizados]
(
	[ci_articulo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

[dbo].sp_help [futRetapizados]
GO

SET ANSI_PADDING OFF
GO




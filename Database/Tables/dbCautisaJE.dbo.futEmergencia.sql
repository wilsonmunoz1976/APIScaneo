USE dbCautisaJE
GO

/****** Object:  Table [dbo].[futPlanilla]    Script Date: 21/09/2023 17:32:03 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

IF EXISTS(SELECT 1 FROM sysobjects WHERE id=OBJECT_ID('dbo.futEmergencia') and type='U')
    DROP TABLE dbo.futEmergencia
GO

CREATE TABLE [dbo].[futEmergencia](
	[ci_solicitudegreso] bigint NOT NULL,
	[ci_planilla] [varchar](15) NOT NULL,
	[ci_articulo]	varchar(20),
	[ci_bodega] varchar(3) NULL,
	[tx_nombrefallecido] varchar(100) NULL,
	[fx_fecharegistro] [datetime] NULL,
	[ci_usuarioregistro] [varchar](15) NULL,
	[fx_finalizacion] [datetime] NULL,
	[ci_usuariofinalizacion] [varchar](15) NULL,
 CONSTRAINT [PK_futEmergencia] PRIMARY KEY CLUSTERED 
(
	[ci_solicitudegreso] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]

GO

sp_help futEmergencia
GO

SET ANSI_PADDING OFF
GO



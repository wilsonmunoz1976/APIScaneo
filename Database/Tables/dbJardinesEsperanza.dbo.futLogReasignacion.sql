USE dbJardinesEsperanza
GO

/****** Object:  Table [dbo].[futPlanilla]    Script Date: 21/09/2023 17:32:03 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

IF EXISTS(SELECT 1 FROM sysobjects WHERE id=OBJECT_ID('dbo.futLogReasignacion') and type='U')
    DROP TABLE dbo.futLogReasignacion
GO

CREATE TABLE [dbo].[futLogReasignacion](
    [ci_secuencia] bigint identity(1,1),
    [ci_usuarioorigen] [varchar](25) NOT NULL,
	[ci_usuariodestino] [varchar](25) NOT NULL,
	[fx_fechareasignacion] datetime NOT NULL,
	[ci_solicitudegreso] int NOT NULL,
	[ce_estadosolicitud] int NOT NULL,
 CONSTRAINT [PK_futLogReasignacion] PRIMARY KEY CLUSTERED 
(
	[ci_secuencia] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [ix_fechareasignacion] ON [dbo].[futLogReasignacion]
(
	[fx_fechareasignacion] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO


[dbo].sp_help [futLogReasignacion]
GO

SET ANSI_PADDING OFF
GO




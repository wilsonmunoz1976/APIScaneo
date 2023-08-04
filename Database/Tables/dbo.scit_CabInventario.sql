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

dbo.sp_help scit_CabInventario
GO


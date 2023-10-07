ALTER TABLE dbJardinesEsperanza.dbo.futSolicitudEgreso DROP CONSTRAINT PK_futSolicitudEgreso
GO

ALTER TABLE dbJardinesEsperanza.dbo.futSolicitudEgreso ALTER COLUMN ci_solicitudegreso BIGINT NOT NULL
GO

ALTER TABLE dbJardinesEsperanza.dbo.futSolicitudEgreso ADD CONSTRAINT PK_futSolicitudEgreso PRIMARY KEY CLUSTERED 
(
	ci_solicitudegreso ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) 
GO

ALTER TABLE dbCautisaJE.dbo.futSolicitudEgreso DROP CONSTRAINT PK_futSolicitudEgreso
GO

ALTER TABLE dbCautisaJE.dbo.futSolicitudEgreso ALTER COLUMN ci_solicitudegreso BIGINT NOT NULL
GO

ALTER TABLE dbCautisaJE.dbo.futSolicitudEgreso ADD CONSTRAINT PK_futSolicitudEgreso PRIMARY KEY CLUSTERED 
(
	ci_solicitudegreso ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) 
GO
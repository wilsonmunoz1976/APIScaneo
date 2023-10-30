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


ALTER TABLE dbJardinesEsperanza.dbo.futSolicitudEgreso ADD ci_bodega varchar(3) NOT NULL DEFAULT '009'
GO


ALTER TABLE dbCautisaJE.dbo.futSolicitudEgreso ADD ci_bodega varchar(3) NOT NULL DEFAULT '015'
GO


ALTER TABLE dbJardinesEsperanza.dbo.futSolicitudEgreso ADD te_alquilado char(1) NULL
GO

ALTER TABLE dbCautisaJE.dbo.futSolicitudEgreso ADD te_alquilado char(1) NULL
GO

--2023-10-24
ALTER TABLE dbJardinesEsperanza.dbo.futSolicitudEgreso ADD te_porfacturar bit default(0) NOT NULL
ALTER TABLE dbCautisaJE.dbo.futSolicitudEgreso ADD te_porfacturar bit default(0) NOT NULL
GO

ALTER TABLE dbJardinesEsperanza.dbo.futEmergencia ADD tipoingreso bit default(0) NOT NULL
ALTER TABLE dbJardinesEsperanza.dbo.futEmergencia ADD tipogestion bit default(0) NOT NULL
ALTER TABLE dbCautisaJE.dbo.futEmergencia ADD tipoingreso bit default(0) NOT NULL
ALTER TABLE dbCautisaJE.dbo.futEmergencia ADD tipogestion bit default(0) NOT NULL
GO

--2023-10-27
ALTER TABLE dbJardinesEsperanza.dbo.futSolicitudEgreso ADD tx_nombrefallecido varchar(100) NULL
ALTER TABLE dbCautisaJE.dbo.futSolicitudEgreso ADD tx_nombrefallecido varchar(100) NULL
ALTER TABLE dbJardinesEsperanza.dbo.futSolicitudEgreso ADD te_emergencia BIT DEFAULT(0) NOT NULL
ALTER TABLE dbCautisaJE.dbo.futSolicitudEgreso ADD te_emergencia BIT DEFAULT(0) NOT NULL

GO

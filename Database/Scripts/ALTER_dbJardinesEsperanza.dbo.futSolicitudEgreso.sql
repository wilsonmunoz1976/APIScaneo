USE dbJardinesEsperanza
GO

IF NOT EXISTS(SELECT 1 FROM sys.all_columns WHERE object_id=OBJECT_ID('dbo.futSolicitudEgreso') and name='tx_observacionentrega')
	ALTER TABLE dbo.futSolicitudEgreso ADD tx_observacionentrega varchar(250) null
GO

IF NOT EXISTS(SELECT 1 FROM sys.all_columns WHERE object_id=OBJECT_ID('dbo.futSolicitudEgreso') and name='tx_fotografiasala')
	ALTER TABLE dbo.futSolicitudEgreso ADD tx_fotografiasala nvarchar(max) null
GO

dbo.sp_help futSolicitudEgreso
GO

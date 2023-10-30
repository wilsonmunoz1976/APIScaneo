USE dbJardinesEsperanza
GO

ALTER TABLE futRetapizados ADD ci_transaccionreingreso      varchar(11) null
ALTER TABLE futRetapizados ADD ci_tipo_transaccionreingreso varchar(2)  null
GO


USE dbCautisaJE
GO
ALTER TABLE futRetapizados ADD ci_transaccionreingreso      varchar(11) null
ALTER TABLE futRetapizados ADD ci_tipo_transaccionreingreso varchar(2)  null
GO

ALTER TABLE dbJardinesEsperanza.dbo.futRetapizados ADD ci_factura varchar(20) null
GO

ALTER TABLE dbCautisaJE.dbo.futRetapizados ADD ci_factura varchar(20) null
GO
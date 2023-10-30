USE dbJardiesaDC
GO

ALTER TABLE dbo.scit_DetInventario ADD va_costo money NOT NULL
go

ALTER TABLE dbo.scit_DetInventario ADD te_ingreso char(1) NOT NULL DEFAULT('M')
GO
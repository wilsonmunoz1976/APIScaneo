 ALTER TABLE dbJardiesaDC.dbo.scit_CabInventario ADD te_estado char(1) default 'A'
 GO
 ALTER TABLE dbJardiesaDC.dbo.scit_CabInventario ADD ci_bodega varchar(3) NOT NULL DEFAULT('000')
 go

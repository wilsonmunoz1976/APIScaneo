USE dbJardinesEsperanza
GO

SELECT * FROM setMenuNivel0 WHERE ci_nivel0='MOV'

INSERT INTO setMenuNivel0 (ci_nivel0, tx_nivel0) VALUES ('MOV', 'APLICACION MOVIL')

SELECT * FROM setMenuNivel1 WHERE ci_nivel0='MOV'

INSERT INTO setMenuNivel1 (ci_nivel0, ci_nivel1, tx_nivel1) VALUES('MOV', 'MOV1000', 'URNAS Y COFRES')
INSERT INTO setMenuNivel1 (ci_nivel0, ci_nivel1, tx_nivel1) VALUES('MOV', 'MOV2000', 'LECTURA ACTIVOS FIJOS')
INSERT INTO setMenuNivel1 (ci_nivel0, ci_nivel1, tx_nivel1) VALUES('MOV', 'MOV3000', 'INVENTARIO')

SELECT * FROM setMenuNivel2 WHERE ci_nivel0='MOV'

INSERT INTO setMenuNivel2 (ci_nivel0, ci_nivel1, ci_nivel2, tx_nivel2, ci_tipo) VALUES('MOV', 'MOV1000', 'MOV1100', 'Retiro Cofre', 'A')
INSERT INTO setMenuNivel2 (ci_nivel0, ci_nivel1, ci_nivel2, tx_nivel2, ci_tipo) VALUES('MOV', 'MOV1000', 'MOV1110', 'Reingreso Cofre', 'A')
INSERT INTO setMenuNivel2 (ci_nivel0, ci_nivel1, ci_nivel2, tx_nivel2, ci_tipo) VALUES('MOV', 'MOV1000', 'MOV1120', 'Cofre con inhumado', 'A')
INSERT INTO setMenuNivel2 (ci_nivel0, ci_nivel1, ci_nivel2, tx_nivel2, ci_tipo) VALUES('MOV', 'MOV1000', 'MOV1130', 'Puesta en Sala', 'A')
INSERT INTO setMenuNivel2 (ci_nivel0, ci_nivel1, ci_nivel2, tx_nivel2, ci_tipo) VALUES('MOV', 'MOV1000', 'MOV1140', 'Emergencia', 'A')

SELECT * FROM setMenuNivel3 WHERE ci_nivel0='MOV'

INSERT INTO setMenuNivel3 (ci_nivel0, ci_nivel1, ci_nivel2, ci_nivel3, 
                           tx_nivel3, ci_codigo, ce_nivel3, tx_ejecutable, 
						   te_web, tx_carpeta, tx_clase, te_presentaweb, 
						   tx_pagina, te_marketingapp, tx_rutamarketingapp, te_integradoweb, 
						   tx_rutapaginaintegradoweb, ci_webexterna, tx_rutapaginawebexterna) 
				    VALUES('MOV', 'MOV1000', 'MOV1100', 0, 
					       'Retiro Cofre', 'MOV11000', 'A', '',
						   'A', null, null, 'N', 
						   null, null, null, null, 
						   null, null, null)

INSERT INTO setMenuNivel3 (ci_nivel0, ci_nivel1, ci_nivel2, ci_nivel3, 
                           tx_nivel3, ci_codigo, ce_nivel3, tx_ejecutable, 
						   te_web, tx_carpeta, tx_clase, te_presentaweb, 
						   tx_pagina, te_marketingapp, tx_rutamarketingapp, te_integradoweb, 
						   tx_rutapaginaintegradoweb, ci_webexterna, tx_rutapaginawebexterna) 
				    VALUES('MOV', 'MOV1000', 'MOV1110', 0, 
					       'Reingreso Cofre', 'MOV11100', 'A', '',
						   'A', null, null, 'N', 
						   null, null, null, null, 
						   null, null, null)

INSERT INTO setMenuNivel3 (ci_nivel0, ci_nivel1, ci_nivel2, ci_nivel3, 
                           tx_nivel3, ci_codigo, ce_nivel3, tx_ejecutable, 
						   te_web, tx_carpeta, tx_clase, te_presentaweb, 
						   tx_pagina, te_marketingapp, tx_rutamarketingapp, te_integradoweb, 
						   tx_rutapaginaintegradoweb, ci_webexterna, tx_rutapaginawebexterna) 
				    VALUES('MOV', 'MOV1000', 'MOV1120', 0, 
					       'Cofre con inhumado', 'MOV11200', 'A', '',
						   'A', null, null, 'N', 
						   null, null, null, null, 
						   null, null, null)

INSERT INTO setMenuNivel3 (ci_nivel0, ci_nivel1, ci_nivel2, ci_nivel3, 
                           tx_nivel3, ci_codigo, ce_nivel3, tx_ejecutable, 
						   te_web, tx_carpeta, tx_clase, te_presentaweb, 
						   tx_pagina, te_marketingapp, tx_rutamarketingapp, te_integradoweb, 
						   tx_rutapaginaintegradoweb, ci_webexterna, tx_rutapaginawebexterna) 
				    VALUES('MOV', 'MOV1000', 'MOV1130', 0, 
					       'Puesta en Sala', 'MOV11300', 'A', '',
						   'A', null, null, 'N', 
						   null, null, null, null, 
						   null, null, null)

INSERT INTO setMenuNivel3 (ci_nivel0, ci_nivel1, ci_nivel2, ci_nivel3, 
                           tx_nivel3, ci_codigo, ce_nivel3, tx_ejecutable, 
						   te_web, tx_carpeta, tx_clase, te_presentaweb, 
						   tx_pagina, te_marketingapp, tx_rutamarketingapp, te_integradoweb, 
						   tx_rutapaginaintegradoweb, ci_webexterna, tx_rutapaginawebexterna) 
				    VALUES('MOV', 'MOV1000', 'MOV1140', 0, 
					       'Emergencia', 'MOV11400', 'A', '',
						   'A', null, null, 'N', 
						   null, null, null, null, 
						   null, null, null)

SELECT * FROM [dbJardinesEsperanza].[dbo].[setUsuario] where ci_usuario='JFALQUEZ'
insert into [dbJardinesEsperanza].[dbo].[setUsuario]
SELECT [ci_usuario]='JFALQUEZ'
      ,[tx_usuario]='Jaime Falquez'
      ,[ci_empleado]
      ,[tx_contraseña]='123456'
      ,[tx_contraseñaanterior]
      ,[tx_verificar]
      ,[tx_expira]
      ,[cn_expira]
      ,[fx_contraseñaactualizada]
      ,[tx_tipo]
      ,[fx_creacion]
      ,[ci_usuarioingreso]
      ,[fx_modificacion]
      ,[ci_usuariomodificacion]
      ,[te_usuario]
      ,[te_autorizadescuento]
      ,[tx_claveautorizacion]
      ,[tx_autorizacionpagare]
      ,[ci_codigoempresa]
      ,[te_reportevisitas]
      ,[tx_operador]
      ,[tx_extension]
      ,[ci_operador]
      ,[ci_formapago]
      ,[tx_filtragrupos]
      ,[ci_seguimiento]
      ,[tx_impresorapp]
      ,[ci_recibomovil]
      ,[ci_generarrecibos]
      ,[tx_opcion]
      ,[te_creditodistribucioninterna]
      ,[te_verificacreditosolicitud]
      ,[te_solicitudfuneraria]
      ,[te_generafacturafunerario]
      ,[te_apruebaprecioalza]
      ,[tx_claveapruebaprecioalza]
      ,[tx_celular]
      ,[te_confirmaciondeposito]
      ,[ci_usuariocajaconfirmadeposito]
      ,[te_reparticionreferidos]
      ,[tx_opcionesorigenreferidos]
      ,[te_esempleado]
      ,[tx_titulo]
      ,[tx_ventascredito]
      ,[te_validaautorizacion]
      ,[te_departamento]
      ,[te_tipodocumento]
      ,[te_departamentoConf]
      ,[te_tipodocumentoConf]
      ,[ci_cajaVF]
  FROM [dbJardinesEsperanza].[dbo].[setUsuario]
  where ci_usuario='ADMIN'

  SELECT * FROM [dbo].[setEmpresa]

  SELECT * FROM [dbJardinesEsperanza].[dbo].[setUsuarioEmpresa] WHERE ci_usuario='JFALQUEZ'

  INSERT INTO [dbJardinesEsperanza].[dbo].[setUsuarioEmpresa] (ci_codigo, ci_usuario, ci_empresa) VALUES (null, 'JFALQUEZ', 'J01')

  SELECT * FROM [dbo].[setUsuarioSucursal] WHERE ci_usuario='WMUNOZ'

  INSERT INTO [dbo].[setUsuarioSucursal] (ci_usuario, ci_empresa, tx_tipodocumento, ci_sucursal) VALUES ('JFALQUEZ', 'J01', 'FV', '001')

  SELECT * FROM [dbo].[setParametrosGenerales]

  INSERT INTO [dbo].[setParametrosGenerales] (ci_empresa, ci_aplicacion, ci_parametro, tx_parametro, tx_descripcion)
  SELECT '000','MOV','RGOHOR', '19:00|09:00', 'Rango Horario de Emergencia'
  
  SELECT * FROM [dbJardinesEsperanza].[dbo].[setPermisosUsuario] where ci_usuario='JFALQUEZ' AND ci_nivel0='MOV'

  DELETE [dbJardinesEsperanza].[dbo].[setPermisosUsuario] where ci_usuario='JFALQUEZ' and ci_nivel2='MOV1120'
  select * from [dbJardinesEsperanza].[dbo].setMenuNivel2 where ci_nivel2='MOV1120'
  INSERT INTO [dbJardinesEsperanza].[dbo].[setPermisosUsuario] (ci_usuario, ci_nivel0, ci_nivel1, ci_nivel2, ci_nivel3, tx_permisos)
  SELECT ci_usuario='JFALQUEZ', ci_nivel0, ci_nivel1, ci_nivel2, ci_nivel3, tx_permisos='NMECI' from [dbJardinesEsperanza].[dbo].setMenuNivel3 WHERE ci_nivel0='MOV'
  
  GO


update [setParametrosGenerales] SET ci_empresa = '000' WHERE  ci_aplicacion='MOV'
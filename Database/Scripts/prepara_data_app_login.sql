USE dbJardinesEsperanza
GO

INSERT INTO [dbJardiesaDC].[dbo].ssatAplicacion
SELECT ci_aplicacion='MOV', tx_aplicacion='Aplicacion Scaneo Movil', tx_basedatos='dbJardinesEsperanza', tx_servidor='192.168.0.98', ci_user='sa', tx_password='J173@2016¡p', bd_mostrar=0, ci_secuencia=0

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

INSERT INTO setMenuNivel2 (ci_nivel0, ci_nivel1, ci_nivel2, tx_nivel2, ci_tipo) VALUES('MOV', 'MOV2000', 'MOV2100', 'Consulta de Activos Fijos', 'A')

INSERT INTO setMenuNivel2 (ci_nivel0, ci_nivel1, ci_nivel2, tx_nivel2, ci_tipo) VALUES('MOV', 'MOV3000', 'MOV3100', 'Actualizacion de Inventario', 'A')

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
				    VALUES('MOV', 'MOV1000', 'MOV1110', 1, 
					       'Permiso de visualizar precios', 'MOV11100', 'A', '',
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

INSERT INTO setMenuNivel3 (ci_nivel0, ci_nivel1, ci_nivel2, ci_nivel3, 
                           tx_nivel3, ci_codigo, ce_nivel3, tx_ejecutable, 
						   te_web, tx_carpeta, tx_clase, te_presentaweb, 
						   tx_pagina, te_marketingapp, tx_rutamarketingapp, te_integradoweb, 
						   tx_rutapaginaintegradoweb, ci_webexterna, tx_rutapaginawebexterna) 
				    VALUES('MOV', 'MOV2000', 'MOV2100', 0, 
					       'Activos Fijos', 'MOV21000', 'A', '',
						   'A', null, null, 'N', 
						   null, null, null, null, 
						   null, null, null)

INSERT INTO setMenuNivel3 (ci_nivel0, ci_nivel1, ci_nivel2, ci_nivel3, 
                           tx_nivel3, ci_codigo, ce_nivel3, tx_ejecutable, 
						   te_web, tx_carpeta, tx_clase, te_presentaweb, 
						   tx_pagina, te_marketingapp, tx_rutamarketingapp, te_integradoweb, 
						   tx_rutapaginaintegradoweb, ci_webexterna, tx_rutapaginawebexterna) 
				    VALUES('MOV', 'MOV2000', 'MOV2100', 1, 
					       'Permiso de visualizar costos', 'MOV21001', 'A', '',
						   'A', null, null, 'N', 
						   null, null, null, null, 
						   null, null, null)

INSERT INTO setMenuNivel3 (ci_nivel0, ci_nivel1, ci_nivel2, ci_nivel3, 
                           tx_nivel3, ci_codigo, ce_nivel3, tx_ejecutable, 
						   te_web, tx_carpeta, tx_clase, te_presentaweb, 
						   tx_pagina, te_marketingapp, tx_rutamarketingapp, te_integradoweb, 
						   tx_rutapaginaintegradoweb, ci_webexterna, tx_rutapaginawebexterna) 
				    VALUES('MOV', 'MOV3000', 'MOV3100', 0, 
					       'Mantenimiento de Inventario', 'MOV31000', 'A', '',
						   'A', null, null, 'N', 
						   null, null, null, null, 
						   null, null, null)



SELECT * FROM [dbJardinesEsperanza].[dbo].[setUsuario] where ci_usuario='CGONZALEZ'
insert into [dbJardinesEsperanza].[dbo].[setUsuario]
SELECT [ci_usuario]='CGONZALEZ'
      ,[tx_usuario]='Cinthya Gonzalez'
      ,[ci_empleado]
      ,[tx_contraseña]='12345'
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

INSERT INTO [dbJardiesaDC].[dbo].ssatUsuario
SELECT ci_usuario='JFALQUEZ', tx_usuario='Jaime Falquez', tx_contrasena='123456', ce_tipousuario='A', tx_observacion='', ci_expira=0, qn_dias=15, fx_ultcambioclave=GETDATE(), tx_terminal=@@SERVERNAME, ce_usuario='A', ci_usuariointegrado='JFALQUEZ', ci_usuarioprodubanco=null

INSERT INTO [dbJardiesaDC].[dbo].ssatUsuario
SELECT ci_usuario='WMUNOZ', tx_usuario='Wilson Muñoz', tx_contrasena='12345', ce_tipousuario='A', tx_observacion='', ci_expira=0, qn_dias=15, fx_ultcambioclave=GETDATE(), tx_terminal=@@SERVERNAME, ce_usuario='A', ci_usuariointegrado='WMUNOZ', ci_usuarioprodubanco=null

  SELECT * FROM [dbo].[setEmpresa]

  SELECT * FROM [dbJardinesEsperanza].[dbo].[setUsuarioEmpresa] WHERE ci_usuario='CGONZALEZ'

  INSERT INTO [dbJardinesEsperanza].[dbo].[setUsuarioEmpresa] (ci_codigo, ci_usuario, ci_empresa) VALUES (null, 'CGONZALEZ', 'J01')

  SELECT * FROM [dbo].[setUsuarioSucursal] WHERE ci_usuario='WMUNOZ'

  INSERT INTO [dbo].[setUsuarioSucursal] (ci_usuario, ci_empresa, tx_tipodocumento, ci_sucursal) VALUES ('CGONZALEZ', 'J01', 'FV', '001')

SELECT * FROM [dbJardiesaDC].[dbo].[ssatParametrosGenerales]

INSERT INTO [dbJardiesaDC].[dbo].[ssatParametrosGenerales]
SELECT ci_aplicacion='MOV', ci_parametro='DEBUG', tx_parametro='SI', tx_descripcion='Se indica si hay modalidad Debug', ci_banco=null

INSERT INTO [dbJardiesaDC].[dbo].[ssatParametrosGenerales]
SELECT ci_aplicacion='MOV', ci_parametro='RGOHOR', tx_parametro='08:00|18:00', tx_descripcion='Rango Horario de Emergencia', ci_banco=null


  SELECT * FROM [dbJardinesEsperanza].[dbo].[setPermisosUsuario] where ci_usuario='wmunoz' AND ci_nivel0='MOV'
  DELETE [dbJardinesEsperanza].[dbo].[setPermisosUsuario] where ci_usuario='wmunoz' AND ci_nivel0='MOV' and ci_nivel2='MOV3100'

  DELETE [dbJardinesEsperanza].[dbo].[setPermisosUsuario] where ci_usuario='jfalquez' and ci_nivel2='MOV1120'
  select * from [dbJardinesEsperanza].[dbo].setMenuNivel2 where ci_nivel2='MOV1120'
  
  DELETE [dbJardinesEsperanza].[dbo].[setPermisosUsuario] where ci_usuario='cgonzalez' and ci_nivel0='MOV'

  INSERT INTO [dbJardinesEsperanza].[dbo].[setPermisosUsuario] (ci_usuario, ci_nivel0, ci_nivel1, ci_nivel2, ci_nivel3, tx_permisos)
  SELECT ci_usuario='CGONZALEZ', ci_nivel0, ci_nivel1, ci_nivel2, ci_nivel3, tx_permisos='NMECI' 
  from [dbJardinesEsperanza].[dbo].setMenuNivel3 WHERE ci_nivel0='MOV' 
  
  GO


update [setParametrosGenerales] SET ci_empresa = '000' WHERE  ci_aplicacion='MOV'


select * from [dbJardinesEsperanza].[dbo].[setUsuario] where ci_usuario='CGONZALEZ'
update [dbJardinesEsperanza].[dbo].[setUsuario] SET tx_contraseña='12345' where ci_usuario='CGONZALEZ'

select * from [dbJardinesEsperanza].[dbo].[setUsuario] where ci_usuario='wmunoz'

SELECT * FROM [dbJardinesEsperanza].[dbo].[setPermisosUsuario] where ci_usuario='CGONZALEZ' AND ci_nivel0='MOV'
SELECT * FROM [dbJardinesEsperanza].[dbo].[setPermisosUsuario] where ci_usuario='wmunoz' AND ci_nivel0='MOV'


delete [dbJardinesEsperanza].[dbo].[setPermisosUsuario] where ci_usuario='YRODRIGUEZ'
select * from [dbJardinesEsperanza].[dbo].[setPermisosUsuario] where ci_usuario='JFALQUEZ'

insert into [dbJardinesEsperanza].[dbo].[setPermisosUsuario]
SELECT ci_usuario='YRODRIGUEZ',ci_nivel0, ci_nivel1, ci_nivel2, ci_nivel3, tx_permisos='NMECI' FROM [dbJardinesEsperanza].[dbo].setMenuNivel3 WHERE ci_nivel0='MOV'
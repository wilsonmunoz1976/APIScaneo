USE dbJardinesEsperanza
GO

DELETE [dbJardiesaDC].[dbo].ssatTransaccionxUsuario  WHERE ci_aplicacion='MOV'
GO

DELETE [dbJardiesaDC].[dbo].ssatTransaccion  WHERE ci_aplicacion='MOV'
GO

DELETE [dbJardiesaDC].[dbo].ssatAplicacion WHERE ci_aplicacion='MOV'
GO

INSERT INTO [dbJardiesaDC].[dbo].ssatAplicacion
SELECT ci_aplicacion='MOV', tx_aplicacion='Aplicacion Scaneo Movil', tx_basedatos, tx_servidor, ci_user, tx_password, bd_mostrar=0, ci_secuencia=0
 FROM [dbJardiesaDC].[dbo].ssatAplicacion WHERE ci_aplicacion='SCG'
GO

INSERT INTO [dbJardiesaDC].[dbo].[ssatTransaccion]
SELECT ci_aplicacion='MOV', ci_transaccion='0000',	tx_transaccion='Aplicación Movil de Cofres', ce_transaccion='P',tx_ejecutable='NA', tx_parametro= '', ci_mayor='r'
GO

INSERT INTO [dbJardiesaDC].[dbo].[ssatTransaccion]
SELECT ci_aplicacion='MOV', ci_transaccion='1100',	tx_transaccion='Retiro Cofre', ce_transaccion='P',tx_ejecutable='NA', tx_parametro= '', ci_mayor='0000'
GO

INSERT INTO [dbJardiesaDC].[dbo].[ssatTransaccion]
SELECT ci_aplicacion='MOV', ci_transaccion='1110',	tx_transaccion='Reingreso Cofre', ce_transaccion='S',tx_ejecutable='NA', tx_parametro= '', ci_mayor='0000'
GO

INSERT INTO [dbJardiesaDC].[dbo].[ssatTransaccion]
SELECT ci_aplicacion='MOV', ci_transaccion='1120',	tx_transaccion='Cofre con inhumado', ce_transaccion='S',tx_ejecutable='NA', tx_parametro= '', ci_mayor='0000'
GO

INSERT INTO [dbJardiesaDC].[dbo].[ssatTransaccion]
SELECT ci_aplicacion='MOV', ci_transaccion='1130',	tx_transaccion='Puesta en Sala', ce_transaccion='S',tx_ejecutable='NA', tx_parametro= '', ci_mayor='0000'
GO

INSERT INTO [dbJardiesaDC].[dbo].[ssatTransaccion]
SELECT ci_aplicacion='MOV', ci_transaccion='1140',	tx_transaccion='Emergencia', ce_transaccion='S',tx_ejecutable='NA', tx_parametro= '', ci_mayor='0000'
GO

INSERT INTO [dbJardiesaDC].[dbo].[ssatTransaccion]
SELECT ci_aplicacion='MOV', ci_transaccion='2100',	tx_transaccion='Consulta de Activos Fijos', ce_transaccion='S',tx_ejecutable='NA', tx_parametro= '', ci_mayor='0000'
GO

INSERT INTO [dbJardiesaDC].[dbo].[ssatTransaccion]
SELECT ci_aplicacion='MOV', ci_transaccion='3100',	tx_transaccion='Actualizacion de Inventario', ce_transaccion='S',tx_ejecutable='NA', tx_parametro= '', ci_mayor='0000'
GO

DELETE [dbJardiesaDC].[dbo].[ssatParametrosGenerales] WHERE ci_aplicacion='MOV'
GO
INSERT INTO [dbJardiesaDC].[dbo].[ssatParametrosGenerales]
SELECT ci_aplicacion='MOV', ci_parametro='DEBUG', tx_parametro='SI', tx_descripcion='Se indica si hay modalidad Debug', ci_banco=null
GO
INSERT INTO [dbJardiesaDC].[dbo].[ssatParametrosGenerales]
SELECT ci_aplicacion='MOV', ci_parametro='USOSSL', tx_parametro='SI', tx_descripcion='Se indica si se usa SSL', ci_banco=null
GO
INSERT INTO [dbJardiesaDC].[dbo].[ssatParametrosGenerales]
SELECT ci_aplicacion='MOV', ci_parametro='RGOHOR', tx_parametro='08:00|18:00', tx_descripcion='Rango Horario de Emergencia', ci_banco=null
GO

IF NOT EXISTS(SELECT 1 FROM dbJardiesaDC.dbo.ssatUsuario WHERE ci_usuario='WMUNOZ')
BEGIN
	INSERT INTO dbJardiesaDC.dbo.ssatUsuario (ci_usuario, tx_usuario, tx_contrasena, ce_tipousuario, tx_observacion, ci_expira, qn_dias, fx_ultcambioclave, tx_terminal, ce_usuario, ci_usuariointegrado, ci_usuarioprodubanco)
	SELECT 'WMUNOZ', 'Wilson Muñoz', 'wFmR1976', 'A', '', 0, 15, GETDATE(), 'GYE01-ITNV1', 'A', 'WMUNOZ', null

	INSERT INTO dbJardiesaDC.dbo.ssatUsuario (ci_usuario, tx_usuario, tx_contrasena, ce_tipousuario, tx_observacion, ci_expira, qn_dias, fx_ultcambioclave, tx_terminal, ce_usuario, ci_usuariointegrado, ci_usuarioprodubanco)
	SELECT 'rruiz', 'Roberto Ruiz', 'rruiz', 'A', '', 0, 15, GETDATE(), 'GYE01-ITNV1', 'A', 'WMUNOZ', null
	
	INSERT INTO dbJardiesaDC.dbo.ssatCorreoUsuarios (ci_usuario, tx_nombre, tx_correo, te_correo, fx_creacion, ci_usuariocreacion, te_fuerarol, te_fuerarolcopia, te_generacionjubilacion, te_aprobacionprovisionesrecibe, te_aprobacionprovisionesrecibecopia)
	SELECT 'WMUNOZ', 'Wilson Muñoz', 'wmunoz@jardinesdeesperanza.net', 'A', GETDATE(), 'JROMERO', 'N', 'N', NULL, NULL, NULL

	INSERT INTO dbJardiesaDC.dbo.scit_BodegaUsuario (ci_bodega, ci_usuario, ci_usuariocreacion, fx_creacion) SELECT '009', 'WMUNOZ', 'CMEDINA', GETDATE()
END
GO

DECLARE @w_usuario varchar(15)
SELECT @w_usuario = 'CGONZALE'
INSERT INTO [dbJardiesaDC].[dbo].ssatTransaccionxUsuario
SELECT ci_usuario=@w_usuario, ci_aplicacion, ci_transaccion, tx_permisos='NMCEIA' FROM   [dbJardiesaDC].[dbo].[ssatTransaccion]
WHERE ci_aplicacion='MOV'

--DECLARE @W_USUARIO VARCHAR(15)
SELECT @w_usuario = 'WMUNOZ'
DELETE [dbJardiesaDC].[dbo].ssatTransaccionxUsuario WHERE ci_usuario = @w_usuario and ci_aplicacion='MOV'
INSERT INTO [dbJardiesaDC].[dbo].ssatTransaccionxUsuario
SELECT ci_usuario=@w_usuario, ci_aplicacion, ci_transaccion, tx_permisos='NMCEIA' FROM   [dbJardiesaDC].[dbo].[ssatTransaccion]
WHERE ci_aplicacion='MOV'
GO
DELETE [dbJardiesaDC].[dbo].ssatTransaccionxUsuario WHERE ci_usuario = 'WMUNOZ' AND ci_transaccion = '3101'

INSERT INTO [dbJardiesaDC].[dbo].[ssatTransaccion]
SELECT ci_aplicacion='MOV', ci_transaccion='3101',	tx_transaccion='Permiso para ver solo listado', ce_transaccion='S',tx_ejecutable='NA', tx_parametro= '', ci_mayor='0000'
GO


DECLARE @w_usuario varchar(15)
SELECT @w_usuario = 'rruiz'
DELETE [dbJardiesaDC].[dbo].ssatTransaccionxUsuario WHERE ci_usuario = @w_usuario and ci_aplicacion='MOV' and ci_transaccion='2100'
INSERT INTO [dbJardiesaDC].[dbo].ssatTransaccionxUsuario
SELECT ci_usuario=@w_usuario, ci_aplicacion, ci_transaccion, tx_permisos='NMCEIA' FROM   [dbJardiesaDC].[dbo].[ssatTransaccion]
WHERE ci_aplicacion='MOV' AND ci_transaccion='2100' 

select * from [dbJardiesaDC].[dbo].ssatTransaccionxUsuario 
select * from [dbJardiesaDC].[dbo].ssatTransaccionxUsuario where ci_usuario='rruiz'
select * from [dbJardiesaDC].[dbo].ssatTransaccion where ci_aplicacion='MOV'

DELETE [dbJardiesaDC].[dbo].ssatTransaccionxUsuario where ci_usuario='rruiz' AND ci_aplicacion='MOV' AND ci_transaccion IN ('0000', '2100')

        SELECT w_password = tx_contrasena,
               w_id       = CONVERT(INT,(RAND() * 100)),
               w_nombres  = tx_usuario,
			   w_email    = tx_correo
          FROM dbo.ssatUsuario
		  LEFT JOIN dbo.ssatCorreoUsuarios
		    ON ssatUsuario.ci_usuario = ssatCorreoUsuarios.ci_usuario
         WHERE ssatUsuario.ci_usuario = 'wmunoz'

SELECT * from scit_BodegaUsuario 
insert into scit_BodegaUsuario select '009', 'rruiz', 'wmunoz', GETDATE()
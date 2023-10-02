USE dbCautisaJE
GO

/****** Object:  Table [dbo].[futPlanilla]    Script Date: 21/09/2023 17:32:03 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

IF EXISTS(SELECT 1 FROM sysobjects WHERE id=OBJECT_ID('dbo.futPlanilla') and type='U')
    DROP TABLE dbo.futPlanilla
GO

CREATE TABLE [dbo].[futPlanilla](
	[ci_planilla] [varchar](15) NOT NULL,
	[fx_fecharegistro] [datetime] NULL,
	[tx_horallamada] [varchar](15) NULL,
	[fx_fechallamada] [datetime] NULL,
	[tx_horainicioservicio] [varchar](15) NULL,
	[tx_horafinservicio] [varchar](15) NULL,
	[tx_horainhumacion] [varchar](15) NULL,
	[fx_fechainhumacion] [datetime] NULL,
	[tx_reporta] [varchar](100) NULL,
	[tx_telefono] [varchar](50) NULL,
	[tx_nombrefallecido] [varchar](100) NULL,
	[tx_tipoidentificacion] [char](1) NULL,
	[tx_identificacion] [varchar](15) NULL,
	[fx_nacimiento] [datetime] NULL,
	[fx_fallecimiento] [datetime] NULL,
	[tx_trasladar] [varchar](200) NULL,
	[tx_sitiovelacion] [varchar](200) NULL,
	[ci_atendio] [varchar](2) NULL,
	[tx_observacion] [varchar](500) NULL,
	[ci_planillaexhumacion] [varchar](15) NULL,
	[tx_planillainscripcion] [varchar](20) NULL,
	[tx_tomo] [varchar](20) NULL,
	[tx_pagina] [varchar](4) NULL,
	[tx_acta] [varchar](20) NULL,
	[fx_fechainscripcion] [datetime] NULL,
	[ci_proveedor] [varchar](3) NULL,
	[ci_articulo] [varchar](25) NULL,
	[ci_ubicacion] [varchar](25) NULL,
	[ci_nivel] [smallint] NULL,
	[tx_tipoplanilla] [char](1) NULL,
	[fx_fechareservacion] [datetime] NULL,
	[ci_usuarioreservacion] [varchar](15) NULL,
	[fx_creacion] [datetime] NULL,
	[ci_usuario] [varchar](15) NULL,
	[fx_modificacion] [datetime] NULL,
	[ci_usuariomodificacion] [varchar](15) NULL,
	[te_planilla] [char](1) NOT NULL,
	[tx_inhumado] [varchar](100) NULL,
	[ci_anio] [varchar](15) NULL,
	[ci_mes] [varchar](2) NULL,
	[ci_aniorealizable] [varchar](4) NULL,
	[ci_mesrealizable] [varchar](2) NULL,
	[ci_factura] [varchar](20) NULL,
	[ci_secuenciafactura] [smallint] NULL,
	[ci_cofre] [varchar](25) NULL,
	[ci_clase] [varchar](3) NULL,
	[tx_tipo] [char](1) NULL,
	[ci_transaccion] [int] NULL,
	[ci_proveedorcofre] [varchar](3) NULL,
	[ci_atendio1] [varchar](2) NULL,
	[ci_atendio2] [varchar](2) NULL,
	[ci_atendio3] [varchar](2) NULL,
	[fx_elaboracion] [date] NULL,
	[fx_instalacion] [date] NULL,
	[ci_cementerio] [smallint] NULL,
	[ci_asistentefamiliar] [smallint] NULL,
	[ci_funerariatramite] [smallint] NULL,
	[te_sitiovelaciondomicilio] [char](1) NULL,
	[ci_causa] [varchar](4) NULL,
	[ci_datoslapida] [smallint] NULL,
	[ci_codigolapida] [smallint] NULL,
	[ci_codigodetallelapida] [smallint] NULL,
	[ci_motivoexhumacion] [smallint] NULL,
	[ci_facturaexhumacion] [varchar](20) NULL,
	[ci_clientefactura] [int] NULL,
	[tx_tipoid] [varchar](1) NULL,
	[tx_idreporta] [varchar](20) NULL,
	[ci_vehiculo] [varchar](5) NULL,
	[ci_chofer] [numeric](5, 0) NULL,
	[tx_contextura] [varchar](100) NULL,
	[ci_sala] [smallint] NULL,
	[tx_largo] [smallint] NULL,
	[tx_ancho] [smallint] NULL,
	[tx_alto] [smallint] NULL,
	[ci_tipoemergencia] [smallint] NULL,
	[te_verificacion] [varchar](1) NULL,
	[tx_verificacion] [varchar](4000) NULL,
	[ci_usuarioverificacion] [varchar](15) NULL,
	[fx_verificacion] [datetime] NULL,
	[ci_usuariomodificaplanilla] [varchar](15) NULL,
	[fx_modificaplanilla] [datetime] NULL,
	[ci_compensacion] [int] NULL,
	[ci_facturaalquiler] [varchar](20) NULL,
	[ci_tiporeserva] [varchar](1) NULL,
	[ci_prereserva] [varchar](15) NULL,
	[tx_linkcondolencias] [varchar](500) NULL,
 CONSTRAINT [PK_fuPlanilla] PRIMARY KEY CLUSTERED 
(
	[ci_planilla] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [dbo].[futPlanilla] ADD  CONSTRAINT [DF_futPlanilla_te_verificacion]  DEFAULT ('N') FOR [te_verificacion]
GO



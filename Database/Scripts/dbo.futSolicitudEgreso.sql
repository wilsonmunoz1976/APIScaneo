USE dbJardinesEsperanza
GO

IF EXISTS(SELECT 1 FROM sysobjects WHERE id=OBJECT_ID('dbo.futSolicitudEgreso') and type='U')
    DROP TABLE dbo.futSolicitudEgreso 
GO


CREATE TABLE dbo.futSolicitudEgreso(
	ci_solicitudegreso           int          NOT NULL,
	tx_tipoegreso                varchar(1)   NOT NULL,
	ci_articulo                  varchar(20)  NOT NULL,
	tx_documentoorigen           varchar(3)       NULL,
	tx_transaccionorigen         varchar(20)      NULL,
	tx_observacion               varchar(250)     NULL,
	te_ordenegreso               varchar(1)       NULL,
	te_proceso                   varchar(2)       NULL,
	fx_creacion                  datetime         NULL,
	ci_usuario                   varchar(15)      NULL,
	fx_retiro                    datetime         NULL,
	ci_usuarioretiro             varchar(15)      NULL,
	tx_observacionretiro         varchar(250)     NULL,
	fx_entrega                   datetime         NULL,
	ci_usuarioentrega            varchar(15)      NULL,
	tx_observacionentrega        varchar(250)     NULL,
	fx_sala                      datetime         NULL,
	ci_usuariosala               varchar(15)      NULL,
	tx_observacionsala           varchar(250)     NULL,
	tx_fotografiasala            varchar(max)     NULL,
	ci_tipo_transaccionegreso    varchar(2)       NULL,
	ci_transaccionegreso         varchar(11)      NULL,
	ci_tipo_transaccionreingreso varchar(2)       NULL,
	ci_transaccionreingreso      varchar(11)      NULL,
 CONSTRAINT PK_futSolicitudEgreso PRIMARY KEY CLUSTERED 
(
	ci_solicitudegreso ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) 
) 
GO

SET ANSI_PADDING OFF
GO

ALTER TABLE dbo.futSolicitudEgreso ADD  CONSTRAINT DF_futSolicitudEgreso_te_ordenegreso  DEFAULT ('A') FOR te_ordenegreso
GO

ALTER TABLE dbo.futSolicitudEgreso ADD  CONSTRAINT DF_futSolicitudEgreso_fx_creacion  DEFAULT (getdate()) FOR fx_creacion
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'''FAC FACTURA''' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'futSolicitudEgreso', @level2type=N'COLUMN',@level2name=N'tx_documentoorigen'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'''A ACTIVO'' ''I INACTIVO''' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'futSolicitudEgreso', @level2type=N'COLUMN',@level2name=N'te_ordenegreso'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'''IN'' INGRESADO  ''EG'' EGRESADO  ''RE'' RETIRO ''SA'' SALA' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'futSolicitudEgreso', @level2type=N'COLUMN',@level2name=N'te_proceso'
GO


--ALTER TABLE futSolicitudEgreso add tx_observacioncofre varchar(250) null
--GO

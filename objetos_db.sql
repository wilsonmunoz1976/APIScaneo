use nts_clientes
GO

DROP TABLE IF EXISTS tb_usuario 
GO

CREATE TABLE tb_usuario (
   loginname varchar(20),
   nombre_completo varchar(100),
   estado char(1)
)
GO


DROP TABLE IF EXISTS tb_pelicula
GO

CREATE TABLE [dbo].[tb_pelicula](
	[codigo] [int] IDENTITY(1,1) NOT NULL,
	[tipopelicula] [int] NULL,
	[descripcion] [varchar](50) NULL,
 CONSTRAINT [PK_tb_pelicula] PRIMARY KEY CLUSTERED 
(
	[codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


IF EXISTS(SELECT 1 FROM sysobjects WHERE name='tb_pelicula' and type='U')
   ALTER TABLE [dbo].[tb_pelicula]  DROP CONSTRAINT [FK_tb_pelicula_tb_tipopelicula] 
GO

DROP TABLE IF EXISTS tb_tipopelicula
GO

CREATE TABLE [dbo].[tb_tipopelicula](
	[codigo] [int] IDENTITY(1,1) NOT NULL,
	[descripcion] [varchar](50) NULL,
 CONSTRAINT [PK_tb_tipopelicula] PRIMARY KEY CLUSTERED 
(
	[codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[tb_pelicula]  WITH CHECK ADD  CONSTRAINT [FK_tb_pelicula_tb_tipopelicula] FOREIGN KEY([tipopelicula])
REFERENCES [dbo].[tb_tipopelicula] ([codigo])
GO

ALTER TABLE [dbo].[tb_pelicula] CHECK CONSTRAINT [FK_tb_pelicula_tb_tipopelicula]
GO

DROP TABLE IF EXISTS tb_preferencia
GO

CREATE TABLE tb_preferencia (
   numero int identity(1,1),
   loginname varchar(20),
   tipopelicula int
)
GO

ALTER TABLE [dbo].[tb_preferencia]  WITH CHECK ADD  CONSTRAINT [FK_tb_preferencia_tb_usuario] FOREIGN KEY([loginname])
REFERENCES [dbo].[tb_usuario] ([loginname])
GO

ALTER TABLE [dbo].[tb_preferencia] CHECK CONSTRAINT [FK_tb_preferencia_tb_usuario]
GO



use dbJardinesEsperanza
GO
-- ================================================
-- Template generated from Template Explorer using:
-- Create Scalar Function (New Menu).SQL
--
-- Use the Specify Values for Template Parameters 
-- command (Ctrl-Shift-M) to fill in the parameter 
-- values below.
--
-- This block of comments will not be included in
-- the definition of the function.
-- ================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS(SELECT * FROM sysobjects WHERE id=OBJECT_ID('dbo.fu_validar_rango_horario'))
    EXEC ('CREATE FUNCTION dbo.fu_validar_rango_horario (@i_horaactual varchar(5)) RETURNS bit AS BEGIN RETURN 0 END ')
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
ALTER FUNCTION dbo.fu_validar_rango_horario
(
	-- Add the parameters for the function here
	@i_horaactual varchar(5),
	@i_rgohorario varchar(11) = '19:00|09:00'
)
RETURNS BIT
AS
BEGIN
	DECLARE @tb_rango TABLE (id int identity(1,1), valor varchar(5))
	DECLARE @w_rango1 time
	DECLARE @w_rango2 time
	DECLARE @w_rango time
	DECLARE @w_return bit

	INSERT INTO @tb_rango (valor)
	SELECT part FROM dbo.SDF_SplitString(@i_rgohorario, '|')

	SELECT @w_rango1 = convert(time, valor) from @tb_rango where id=1
	SELECT @w_rango2 = convert(time, valor) from @tb_rango where id=2


	SELECT @w_rango=convert(time,@i_horaactual)

	IF @w_rango>=@w_rango1 AND @w_rango<=@w_rango2 
	   SELECT @w_return = 1
	ELSE
	   SELECT @w_return = 0

	RETURN @w_return
END
GO

dbo.sp_help fu_validar_rango_horario
GO
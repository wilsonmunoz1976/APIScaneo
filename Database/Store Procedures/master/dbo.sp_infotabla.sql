USE master
GO

IF EXISTS(SELECT 1 FROM SYS.all_objects WHERE object_id=OBJECT_ID('dbo.sp_infotabla') and type='P')
   DROP PROCEDURE dbo.sp_infotabla
GO

CREATE PROCEDURE dbo.sp_infotabla (
    @pr_objectname varchar(max))
AS
BEGIN
    DECLARE @objectid int
    SELECT @objectid = OBJECT_ID(@pr_objectname)

	DECLARE @w_sentencia nvarchar(MAX)

    DECLARE @tipo varchar(3)

	SELECT @w_sentencia = '
	SELECT @tipoobj = a.type
	  FROM ' + DB_NAME() + '.sys.all_objects A 
	 WHERE A.object_id = @objectid'
    
	EXECUTE sp_executesql @w_sentencia, N'@objectid int, @tipoobj varchar(3) OUTPUT', @objectid = @objectid, @tipoobj = @tipo output
    
	SELECT @w_sentencia = '
	SELECT Nombre=A.name, 
	       Propietario=SCHEMA_NAME(a.schema_id), 
		   Tipo = lower(a.type_desc), 
		   Fecha_Creacion=a.create_date,
		   Descripcion = D.value 
	  FROM ' + DB_NAME() + '.sys.all_objects A 
	  LEFT JOIN ' + DB_NAME() + '.sys.extended_properties D
	    ON D.major_id = A.object_id
	   AND D.minor_id = 0
	   AND D.name = ' + char(39) + 'descripcion' + char(39) + ' 
	 WHERE A.object_id = ' + CONVERT(Varchar(max), @objectid)

	EXEC (@w_sentencia)

	IF @tipo IN ('U', 'V','TF')
	BEGIN
		SELECT @w_sentencia = '
		SELECT [Nombre_Columna]      = A.name,
			   [Tipo]                = TYPE_NAME(A.user_type_id),
			   [Computado]           = IIF(A.is_computed=0,' + char(39) + 'no' + char(39) + ',' + char(39) + 'si' + char(39) + '),
			   [Longitud]            = A.max_length,
			   [Precision]           = A.precision,
			   [Escala]              = a.scale,
			   [Admite nulos]        = IIF(a.is_nullable=0,' + char(39) + 'no' + char(39) + ',' + char(39) + 'si' + char(39) + '),
			   [Descripcion_Columna] = C.VALUE
		  FROM ' + DB_NAME() + '.sys.all_columns A
		 INNER JOIN ' + DB_NAME() + '.sys.all_objects B 
			ON B.object_id = ' + CONVERT(Varchar(max), @objectid) + ' 
		   AND A.object_id = B.object_id
		  LEFT JOIN ' + DB_NAME() + '.sys.extended_properties C
			ON C.major_id = A.object_id
		   AND C.minor_id = A.column_id
		 WHERE B.schema_id != SCHEMA_ID(' + char(39) + 'sys' + char(39) + ')'

  	    EXEC (@w_sentencia)
    END

	IF @tipo IN ('P', 'FN', 'TF')
	BEGIN
		SELECT @w_sentencia = '
		SELECT [Nombre_Columna]      = A.name,
			   [Tipo]                = TYPE_NAME(A.user_type_id),
			   [Longitud]            = A.max_length,
			   [Precision]           = A.precision,
			   [Escala]              = a.scale,
			   [Orden]               = a.parameter_id ,
			   [Output]              = IIF(a.is_output=1,' + char(39) + 'si' + char(39) + ', ' + char(39) + 'no' + char(39) + '),
			   [Descripcion_Columna] = c.value
		  FROM ' + DB_NAME() + '.sys.all_parameters A
		 INNER JOIN ' + DB_NAME() + '.sys.all_objects B 
			ON B.object_id = ' + CONVERT(Varchar(max), @objectid) + ' 
		   AND A.object_id = B.object_id
		  LEFT JOIN ' + DB_NAME() + '.sys.extended_properties C
			ON C.major_id = A.object_id
		   AND C.name = A.name
		 WHERE B.schema_id != SCHEMA_ID(' + char(39) + 'sys' + char(39) + ')'

  	    EXEC (@w_sentencia)
    END


END
GO


using Microsoft.Data.SqlClient;
using System.Data;
using clsScaneo.Entidades;
using NLog;
using Microsoft.Extensions.Configuration;
using SixLabors.ImageSharp.Formats.Webp;
using SixLaborsResizeMode = SixLabors.ImageSharp.Processing.ResizeMode;
using SixLabors.ImageSharp;

namespace clsScaneo.Clases
{
    public class CofresUrnas
    {
        #region "Construccion"
        public SqlConnection oConnection = new();
        private static readonly Logger logger = LogManager.GetCurrentClassLogger();
        public CofresUrnas(string? connectionString)
        {
            try
            {
                if (!string.IsNullOrEmpty(connectionString))
                {
                    oConnection.ConnectionString = connectionString;
                    oConnection.Open();
                }
            }
            catch (Exception ex)
            {
                logger.Error("Error instanciando clase CofreUrnas: " + ex.Message + "\r\n" + ex.StackTrace);
            }
        }
        #endregion "Construccion"

        #region "Cofres Urnas"
        public DataTable GetBodegas(string usuario, ref RespuestaEjecucion oResp)
        {
            DataTable dt = new("tb0");
            try
            {
                SqlCommand cmd = oConnection.CreateCommand();
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.CommandText = "dbo.pr_CofresUrnas";
                cmd.Parameters.Clear();
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_accion", SqlDbType = SqlDbType.VarChar, Size = 2, Value = "BO" });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_usuario", SqlDbType = SqlDbType.VarChar, Size = 15, Value = usuario });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.InputOutput, ParameterName = "@o_msgerror", SqlDbType = SqlDbType.VarChar, Size = 200 });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.ReturnValue, ParameterName = "@return_value", SqlDbType = SqlDbType.Int });

                dt.Load(cmd.ExecuteReader());
                oResp = new()
                {
                    codigo = Convert.ToInt16(cmd.Parameters["@return_value"].Value),
                    mensaje = Convert.ToString(cmd.Parameters["@o_msgerror"].Value)
                };
            }
            catch (Exception ex)
            {
                oResp = new()
                {
                    codigo = -9,
                    mensaje = ex.Message
                };
                logger.Error($"Error en la clase [{ex.GetType().Name}], metodo [{ex.GetType().FullName}" + "\r\n" + ex.StackTrace);
            }

            return dt;
        }
        public DataTable GetCofresUrnas(string Bodega, int? Estado, string? Usuario, ref RespuestaEjecucion oResp)
        {
            DataTable dt = new("tb0");
            try
            {
                SqlCommand cmd = oConnection.CreateCommand();
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.CommandText = "dbo.pr_CofresUrnas";
                cmd.Parameters.Clear();
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_accion", SqlDbType = SqlDbType.VarChar, Size = 2, Value = "LI" });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_bodega", SqlDbType = SqlDbType.VarChar, Size = 3, Value = Bodega });
                if (Usuario != null)
                {
                    cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_usuario", SqlDbType = SqlDbType.VarChar, Size = 15, Value = Usuario });
                }
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_estado", SqlDbType = SqlDbType.SmallInt, Value = Estado });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.InputOutput, ParameterName = "@o_msgerror", SqlDbType = SqlDbType.VarChar, Size = 200 });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.ReturnValue, ParameterName = "@return_value", SqlDbType = SqlDbType.Int });

                dt.Load(cmd.ExecuteReader());
                oResp = new()
                {
                    codigo = Convert.ToInt16(cmd.Parameters["@return_value"].Value),
                    mensaje = Convert.ToString(cmd.Parameters["@o_msgerror"].Value)
                };
            }
            catch (Exception ex)
            {
                oResp = new()
                {
                    codigo = -9,
                    mensaje = ex.Message
                };
                logger.Error($"Error en la clase [{ex.GetType().Name}], metodo [{ex.GetType().FullName}" + "\r\n" + ex.StackTrace);
            }

            return dt;
        }
        public DataTable GetCofreUrna(string? codigoArticulo, ref RespuestaEjecucion oResp)
        {
            DataTable dt = new("tb0");
            try { 
            SqlCommand cmd = oConnection.CreateCommand();
            cmd.CommandType = CommandType.StoredProcedure;
            cmd.CommandText = "dbo.pr_CofresUrnas";
            cmd.Parameters.Clear();
            cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_accion", SqlDbType = SqlDbType.VarChar, Size = 2, Value = "CO" });
            cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_articulo", SqlDbType = SqlDbType.VarChar, Size=20, Value = codigoArticulo });
            cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.InputOutput, ParameterName = "@o_msgerror", SqlDbType = SqlDbType.VarChar, Size = 200 });
            cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.ReturnValue, ParameterName = "@return_value", SqlDbType = SqlDbType.Int });

            dt.Load(cmd.ExecuteReader());
                oResp = new()
                {
                    codigo = Convert.ToInt16(cmd.Parameters["@return_value"].Value),
                    mensaje = Convert.ToString(cmd.Parameters["@o_msgerror"].Value)
                };
            }
            catch (Exception ex)
            {
                oResp = new()
                {
                    codigo = -9,
                    mensaje = ex.Message
                };

            }
            return dt;
        }
        public DataTable GetSolEgreCofreUrna(int? CodSolEgre, string? Usuario, ref RespuestaEjecucion oResp)
        {
            DataTable dt = new("tb0");
            try
            {
                SqlCommand cmd = oConnection.CreateCommand();
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.CommandText = "dbo.pr_CofresUrnas";
                cmd.Parameters.Clear();
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_accion", SqlDbType = SqlDbType.VarChar, Size = 2, Value = "CS" });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_codsolegre", SqlDbType = SqlDbType.Int, Value = CodSolEgre });
                if (Usuario != null)
                {
                    cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_usuario", SqlDbType = SqlDbType.VarChar, Size = 15, Value = Usuario });
                }
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.InputOutput, ParameterName = "@o_msgerror", SqlDbType = SqlDbType.VarChar, Size = 200 });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.ReturnValue, ParameterName = "@return_value", SqlDbType = SqlDbType.Int });

                dt.Load(cmd.ExecuteReader());
                oResp = new()
                {
                    codigo = Convert.ToInt16(cmd.Parameters["@return_value"].Value),
                    mensaje = Convert.ToString(cmd.Parameters["@o_msgerror"].Value)
                };
            }
            catch (Exception ex)
            {
                oResp = new()
                {
                    codigo = -9,
                    mensaje = ex.Message
                };
                logger.Error($"Error en la clase [{ex.GetType().Name}], metodo [{ex.GetType().FullName}" + "\r\n" + ex.StackTrace);
            }

            return dt;
        }
        public RespuestaEjecucion? CambiaEstadoCofresUrnas(string? Bodega, int? Codigo, int? Estado, string? Comentario, string? Fotografia, string? Usuario)
        {
            RespuestaEjecucion oResp;
            try
            {
                SqlCommand cmd = oConnection.CreateCommand();
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.CommandText = "dbo.pr_CofresUrnas";
                cmd.Parameters.Clear();
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_accion", SqlDbType = SqlDbType.VarChar, Size = 2, Value = "UP" });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_bodega", SqlDbType = SqlDbType.VarChar, Size = 3, Value = Bodega });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_codsolegre", SqlDbType = SqlDbType.Int, Value = Codigo });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_estado", SqlDbType = SqlDbType.SmallInt, Value = Estado });
                if (Comentario != null)
                {
                    cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_comentario", SqlDbType = SqlDbType.VarChar, Value = Comentario });
                }
                
                if (Fotografia == null) { Fotografia = ""; }

                if (Fotografia != "")
                {
                    byte[] imageBytes = Convert.FromBase64String(Fotografia);
                    var image = SixLabors.ImageSharp.Image.Load(imageBytes);
                    image.Mutate(x => x.Resize(new ResizeOptions
                    {
                        Size = new SixLabors.ImageSharp.Size(1280, 720), // Tamaño en HD
                        Mode = SixLaborsResizeMode.Max
                    }));
                    string sFilenameOrig = Environment.CurrentDirectory + "\\" + DateTime.Now.ToString("yyyyMMddHHmmssfff") + ".webp";
                    image.SaveAsWebp(sFilenameOrig);
                    imageBytes = File.ReadAllBytes(sFilenameOrig);
                    File.Delete(sFilenameOrig);
                    Fotografia = Convert.ToBase64String(imageBytes);
                    cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_fotografia", SqlDbType = SqlDbType.NVarChar, Value = Fotografia });
                }
                if (Usuario != null)
                {
                    cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_usuario", SqlDbType = SqlDbType.VarChar, Size = 15, Value = Usuario });
                }
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.InputOutput, ParameterName = "@o_msgerror", SqlDbType = SqlDbType.VarChar, Size = 200 });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.ReturnValue, ParameterName = "@return_value", SqlDbType = SqlDbType.Int });

                _ = cmd.ExecuteNonQuery();

                oResp = new()
                {
                    codigo = Convert.ToInt16(cmd.Parameters["@return_value"].Value),
                    mensaje = Convert.ToString(cmd.Parameters["@o_msgerror"].Value)
                };
            }
            catch (Exception ex)
            {
                oResp = new()
                {
                    codigo = -2,
                    mensaje = "Error: " + ex.Message
                };
                logger.Error($"Error en la clase [{ex.GetType().Name}], metodo [{ex.GetType().FullName}" + "\r\n" + ex.StackTrace);
            }

            return oResp;
        }
        public DataTable ReingresoCofresUrnas(ReingresoCofreUrnaRequest reingresoCofreUrna, ref RespuestaEjecucion oResp)
        {
            DataTable dt = new();
            try
            {
                SqlCommand cmd = oConnection.CreateCommand();
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.CommandText = "dbo.pr_CofresUrnas";
                cmd.Parameters.Clear();
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_accion", SqlDbType = SqlDbType.VarChar, Size = 2, Value = "RI" });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_usuario", SqlDbType = SqlDbType.VarChar, Size = 15, Value = reingresoCofreUrna.usuario });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_codsolegre", SqlDbType = SqlDbType.Int, Value = reingresoCofreUrna.codSolicitudEgreso });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_articulo", SqlDbType = SqlDbType.VarChar, Size=20, Value = reingresoCofreUrna.codCofreUrnaNuevo });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.InputOutput, ParameterName = "@o_msgerror", SqlDbType = SqlDbType.VarChar, Size = 200 });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.ReturnValue, ParameterName = "@return_value", SqlDbType = SqlDbType.Int });

                dt.Load(cmd.ExecuteReader());

                oResp = new()
                {
                    codigo = Convert.ToInt16(cmd.Parameters["@return_value"].Value),
                    mensaje = Convert.ToString(cmd.Parameters["@o_msgerror"].Value)
                };
            } catch (Exception ex)
            {
                oResp = new()
                {
                    codigo = -2,
                    mensaje = "Error: " + ex.Message
                };
                logger.Error($"Error en la clase [{ex.GetType().Name}], metodo [{ex.GetType().FullName}" + "\r\n" + ex.StackTrace);
            }
            return dt;
        }

        public DataTable GetListadoUsuariosApp(string? usuario, ref RespuestaEjecucion oResp)
        {
            DataTable dt = new("tb0");
            try
            {
                SqlCommand cmd = oConnection.CreateCommand();
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.CommandText = "dbo.pr_Reasignacion";
                cmd.Parameters.Clear();
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_accion", SqlDbType = SqlDbType.VarChar, Size = 2, Value = "US" });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_usuario", SqlDbType = SqlDbType.VarChar, Size = 15, Value = usuario });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.InputOutput, ParameterName = "@o_msgerror", SqlDbType = SqlDbType.VarChar, Size = 200 });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.ReturnValue, ParameterName = "@return_value", SqlDbType = SqlDbType.Int });

                dt.Load(cmd.ExecuteReader());
                oResp = new()
                {
                    codigo = Convert.ToInt16(cmd.Parameters["@return_value"].Value),
                    mensaje = Convert.ToString(cmd.Parameters["@o_msgerror"].Value)
                };
            }
            catch (Exception ex)
            {
                oResp = new()
                {
                    codigo = -9,
                    mensaje = ex.Message
                };

            }
            return dt;
        }

        public RespuestaEjecucion ReasignacionUsuario(ReasignacionRequest oReq)
        {
            RespuestaEjecucion oResp;
            DataTable dt = new("tb0");
            try
            {
                SqlCommand cmd = oConnection.CreateCommand();
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.CommandText = "dbo.pr_Reasignacion";
                cmd.Parameters.Clear();
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_accion", SqlDbType = SqlDbType.VarChar, Size = 2, Value = "RS" });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_usuario", SqlDbType = SqlDbType.VarChar, Size = 15, Value = oReq.usuario });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_usuarionew", SqlDbType = SqlDbType.VarChar, Size = 15, Value = oReq.usuarionuevo });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_codsolegre", SqlDbType = SqlDbType.Int, Value = oReq.codigosolegre });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.InputOutput, ParameterName = "@o_msgerror", SqlDbType = SqlDbType.VarChar, Size = 200 });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.ReturnValue, ParameterName = "@return_value", SqlDbType = SqlDbType.Int });

                _ = cmd.ExecuteNonQuery();
                oResp = new()
                {
                    codigo = Convert.ToInt16(cmd.Parameters["@return_value"].Value),
                    mensaje = Convert.ToString(cmd.Parameters["@o_msgerror"].Value)
                };
            }
            catch (Exception ex)
            {
                oResp = new()
                {
                    codigo = -9,
                    mensaje = ex.Message
                };

            }
            return oResp;
        }

        #endregion "Cofres Urnas"

    }
}
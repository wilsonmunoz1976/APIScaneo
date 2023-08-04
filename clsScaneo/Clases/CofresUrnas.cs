using Microsoft.Data.SqlClient;
using System.Data;
using clsScaneo.Entidades;
using NLog;
using Microsoft.Extensions.Configuration;

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
        public DataTable GetBodegas(ref RespuestaEjecucion oResp)
        {
            DataTable dt = new("tb0");
            try
            {
                SqlCommand cmd = oConnection.CreateCommand();
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.CommandText = "dbo.pr_CofresUrnas";
                cmd.Parameters.Clear();
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_accion", SqlDbType = SqlDbType.VarChar, Size = 2, Value = "BO" });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.InputOutput, ParameterName = "@o_msgerror", SqlDbType = SqlDbType.VarChar, Size = 200 });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.ReturnValue, ParameterName = "@return_value", SqlDbType = SqlDbType.Int });

                dt.Load(cmd.ExecuteReader());
                oResp = new()
                {
                    Codigo = Convert.ToInt16(cmd.Parameters["@return_value"].Value),
                    Mensaje = Convert.ToString(cmd.Parameters["@o_msgerror"].Value)
                };
            }
            catch (Exception ex)
            {
                oResp = new()
                {
                    Codigo = -9,
                    Mensaje = ex.Message
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
                    Codigo = Convert.ToInt16(cmd.Parameters["@return_value"].Value),
                    Mensaje = Convert.ToString(cmd.Parameters["@o_msgerror"].Value)
                };
            }
            catch (Exception ex)
            {
                oResp = new()
                {
                    Codigo = -9,
                    Mensaje = ex.Message
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
                    Codigo = Convert.ToInt16(cmd.Parameters["@return_value"].Value),
                    Mensaje = Convert.ToString(cmd.Parameters["@o_msgerror"].Value)
                };
            }
            catch (Exception ex)
            {
                oResp = new()
                {
                    Codigo = -9,
                    Mensaje = ex.Message
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
                    Codigo = Convert.ToInt16(cmd.Parameters["@return_value"].Value),
                    Mensaje = Convert.ToString(cmd.Parameters["@o_msgerror"].Value)
                };
            }
            catch (Exception ex)
            {
                oResp = new()
                {
                    Codigo = -9,
                    Mensaje = ex.Message
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
                if (Fotografia != null)
                {
                    cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_fotografia", SqlDbType = SqlDbType.VarChar, Value = Fotografia });
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
                    Codigo = Convert.ToInt16(cmd.Parameters["@return_value"].Value),
                    Mensaje = Convert.ToString(cmd.Parameters["@o_msgerror"].Value)
                };
            }
            catch (Exception ex)
            {
                oResp = new()
                {
                    Codigo = -2,
                    Mensaje = "Error: " + ex.Message
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
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_codsolegre", SqlDbType = SqlDbType.Int, Value = reingresoCofreUrna.CodSolicitudEgreso });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_articulo", SqlDbType = SqlDbType.VarChar, Size=20, Value = reingresoCofreUrna.CodCofreUrnaNuevo });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.InputOutput, ParameterName = "@o_msgerror", SqlDbType = SqlDbType.VarChar, Size = 200 });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.ReturnValue, ParameterName = "@return_value", SqlDbType = SqlDbType.Int });

                dt.Load(cmd.ExecuteReader());

                oResp = new()
                {
                    Codigo = Convert.ToInt16(cmd.Parameters["@return_value"].Value),
                    Mensaje = Convert.ToString(cmd.Parameters["@o_msgerror"].Value)
                };
            } catch (Exception ex)
            {
                oResp = new()
                {
                    Codigo = -2,
                    Mensaje = "Error: " + ex.Message
                };
                logger.Error($"Error en la clase [{ex.GetType().Name}], metodo [{ex.GetType().FullName}" + "\r\n" + ex.StackTrace);
            }
            return dt;
        }

        #endregion "Cofres Urnas"

    }
}
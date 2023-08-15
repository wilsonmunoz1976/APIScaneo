using Microsoft.Data.SqlClient;
using System.Data;
using clsScaneo.Entidades;
using NLog;
using APIScaneo.Authorization;
using clsScaneo.Models;
using System.Runtime.InteropServices;
using Microsoft.Extensions.Options;

namespace clsScaneo.Clases
{
    public class Seguridad 
    {
        #region "Construccion"
        private readonly SqlConnection oConnection = new();
        private static readonly Logger logger = LogManager.GetCurrentClassLogger();

        public Seguridad(string myDb1ConnectionString)
        {

            try
            {
                if (!string.IsNullOrEmpty(myDb1ConnectionString))
                {
                    oConnection.ConnectionString = myDb1ConnectionString;
                    oConnection.Open();
                }
            }
            catch (Exception ex)
            {
                logger.Error("Error instanciando clase Seguridad: " + ex.Message + "\r\n" + ex.StackTrace);
            }
        }

        #endregion "Construccion"

        #region "Seguridad"
        public DataTable GetEmpresas(ref RespuestaEjecucion? oResp)
        {
            DataTable dt = new("tb0");
            try
            {
                SqlCommand cmd = oConnection.CreateCommand();
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.CommandText = "dbo.pr_Seguridad";
                cmd.Parameters.Clear();
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_accion", SqlDbType = SqlDbType.VarChar, Size = 2, Value = "EM" });
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

        public DataSet LoginApp(string? Usuario, string? Password, ref RespuestaEjecucion oResp)
        {
            DataSet ds = new();
            try
            {
                SqlCommand cmd = oConnection.CreateCommand();
                SqlDataAdapter da = new();
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.CommandText = "dbo.pr_Seguridad";
                cmd.Parameters.Clear();
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_accion", SqlDbType = SqlDbType.VarChar, Size = 2, Value = "LO" });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_usuario", SqlDbType = SqlDbType.VarChar, Size = 15, Value = Usuario });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_password", SqlDbType = SqlDbType.VarChar, Size = 15, Value = Password });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.InputOutput, ParameterName = "@o_msgerror", SqlDbType = SqlDbType.VarChar, Size = 200 });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.ReturnValue, ParameterName = "@return_value", SqlDbType = SqlDbType.Int });

                da.SelectCommand = cmd;
                da.Fill(ds);

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
            return ds;
        }

        #endregion "Seguridad"

    }
}
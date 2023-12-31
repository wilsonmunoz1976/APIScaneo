﻿using Microsoft.Data.SqlClient;
using System.Data;
using clsScaneo.Entidades;
using NLog;

namespace clsScaneo.Clases
{
    public class ActivosFijos
    {
        #region "Construccion"
        public SqlConnection oConnection = new();
        private static readonly Logger logger = LogManager.GetCurrentClassLogger();

        public ActivosFijos(string? connectionString)
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
                logger.Error("Error instanciando clase Activos Fijos: " + ex.Message + "\r\n" + ex.StackTrace);
            }
        }
        #endregion "Construccion"

        #region "Archivos Fijos"
        public DataTable GetActivosFijos(ref RespuestaEjecucion oResp)
        {
            DataTable dt = new("tb0");
            try
            {
                SqlCommand cmd = oConnection.CreateCommand();
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.CommandText = "dbo.pr_ActivosFijos";
                cmd.Parameters.Clear();
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_accion", SqlDbType = SqlDbType.VarChar, Size = 2, Value = "LI" });
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
                    codigo = -9,
                    mensaje = ex.Message
                };
                logger.Error($"Error en la clase [{ex.GetType().Name}], metodo [{ex.GetType().FullName}" + "\r\n" + ex.StackTrace);
            }
            return dt;
        }

        public DataSet GetActivosFijos(string Codigo, string Usuario, ref RespuestaEjecucion oResp)
        {
            DataSet ds = new("rs0");
            try
            {
                SqlCommand cmd = oConnection.CreateCommand();
                SqlDataAdapter da = new SqlDataAdapter();
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.CommandText = "dbo.pr_ActivosFijos";
                cmd.Parameters.Clear();
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_accion", SqlDbType = SqlDbType.VarChar, Size = 2, Value = "CO" });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_codigo", SqlDbType = SqlDbType.VarChar, Size = 50, Value = Codigo });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_usuario", SqlDbType = SqlDbType.VarChar, Size = 15, Value = Usuario });
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

        #endregion "Archivos Fijos"

    }
}
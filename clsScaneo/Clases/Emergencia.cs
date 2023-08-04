using Microsoft.Data.SqlClient;
using System.Data;
using clsScaneo.Entidades;
using NLog;

namespace clsScaneo.Clases
{
    public class Emergencia
    {
        #region "Construccion"
        public SqlConnection oConnection = new();
        private static readonly Logger logger = LogManager.GetCurrentClassLogger();
        public Emergencia(string? connectionString)
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
                logger.Error("Error instanciando clase Emergencia: " + ex.Message + "\r\n" + ex.StackTrace);
            }
        }
        #endregion "Construccion"

        #region "Emergencia"
        public RespuestaEjecucion? EnviarCorreoNotificacion(EmailMessage? oReq)
        {
            RespuestaEjecucion oResp = new();
            try
            {
                if (oReq != null)
                {

                    string sMailTo = "";
                    string sMailCC = "";
                    string sMailCCO = "";

                    if (oReq.To != null) { foreach (string? sMail in oReq.To) { if (sMail != null) { sMailTo += sMail + "; "; } } }
                    if (oReq.CC != null) { foreach (string? sMail in oReq.CC) { if (sMail != null) { sMailCC += sMail + "; "; } } }
                    if (oReq.CCO != null) { foreach (string? sMail in oReq.CCO) { if (sMail != null) { sMailCCO += sMail + "; "; } } }

                    CDO.Message oMsg = new();
                    CDO.Configuration oCfg = new();
                    ADODB.Fields oFields;
                    ADODB.Field oField;

                    oCfg = oMsg.Configuration;
                    oFields = oCfg.Fields;

                    oField = oFields["http://schemas.microsoft.com/cdo/configuration/sendusing"];
                    oField.Value = CDO.CdoSendUsing.cdoSendUsingPort;

                    oField = oFields["http://schemas.microsoft.com/cdo/configuration/smtpserverport"];
                    oField.Value = Convert.ToInt16(oReq.PortMail);

                    oField = oFields["http://schemas.microsoft.com/cdo/configuration/smtpserver"];
                    oField.Value = oReq.ServidorMail ?? "";

                    oField = oFields["http://schemas.microsoft.com/cdo/configuration/smtpconnectiontimeout"];
                    oField.Value = 1000;

                    oField = oFields["http://schemas.microsoft.com/cdo/configuration/smtpusessl"];
                    oField.Value = true;

                    oField = oFields["http://schemas.microsoft.com/cdo/configuration/smtpauthenticate"];
                    oField.Value = 1;

                    oField = oFields["http://schemas.microsoft.com/cdo/configuration/sendusername"];
                    oField.Value = oReq.UsuarioMail;

                    oField = oFields["http://schemas.microsoft.com/cdo/configuration/sendpassword"];
                    oField.Value = oReq.PasswordMail;

                    oFields.Update();
                    oMsg.Configuration = oCfg;
                    oMsg.BodyPart.Charset = "UTF-8";
                    oMsg.HTMLBody = oReq.Body;
                    oMsg.Subject = oReq.Subject;
                    oMsg.From = oReq.FromName + "<" + oReq.FromMail + ">";
                    if (sMailCC != null) { if (sMailCC != "") { oMsg.CC = sMailCC; } }
                    if (sMailCCO != null) { if (sMailCCO != "") { oMsg.BCC = sMailCCO; } }
                    oMsg.To = sMailTo;
                    oMsg.CC = sMailCC;
                    oMsg.BCC = sMailCCO;

                    oMsg.Send();

                    oResp.Codigo = 0;
                    oResp.Mensaje = "Mensaje Enviado Correctamente";
                }
                else
                {
                    oResp = new()
                    {
                        Codigo = -1,
                        Mensaje = "Llamada a metodo sin parametros de entrada"
                    };
                }
            }
            catch (Exception ex)
            {
                oResp = new()
                {
                    Codigo = -2,
                    Mensaje = ex.Message + "\r\n" + ex.StackTrace
                };
                logger.Error($"Error en la clase [{ex.GetType().Name}], metodo [{ex.GetType().FullName}" + "\r\n" + ex.StackTrace);
            }
            return oResp;
        }

        public RespuestaEjecucion? RegistrarEmergencia(RegistroEmergenciaRequest? oEmergencia, ref RegistroEmergenciaResponse respRegistro)
        {
            RespuestaEjecucion? oResp;
            try
            {
                if (oEmergencia != null)
                {
                    SqlCommand cmd = oConnection.CreateCommand();
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.CommandText = "dbo.pr_Emergencia";
                    cmd.Parameters.Clear();
                    cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_accion", SqlDbType = SqlDbType.VarChar, Size = 2, Value = "RG" });
                    cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_nombres", SqlDbType = SqlDbType.VarChar, Size = 100, Value = oEmergencia.Nombres });
                    cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_articulo", SqlDbType = SqlDbType.VarChar, Size = 20, Value = oEmergencia.Articulo });
                    cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_usuario", SqlDbType = SqlDbType.VarChar, Size = 15, Value = oEmergencia.Usuario });
                    cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.InputOutput, ParameterName = "@o_msgerror", SqlDbType = SqlDbType.VarChar, Size = 200 });
                    cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.InputOutput, ParameterName = "@o_codplanilla", SqlDbType = SqlDbType.VarChar, Size = 15 });
                    cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.InputOutput, ParameterName = "@o_codsoliegre", SqlDbType = SqlDbType.Int });
                    cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.InputOutput, ParameterName = "@o_bodega", SqlDbType = SqlDbType.VarChar, Size = 3 });
                    cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.InputOutput, ParameterName = "@o_descarticulo", SqlDbType = SqlDbType.VarChar, Size = 60 });
                    cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.ReturnValue, ParameterName = "@return_value", SqlDbType = SqlDbType.Int });

                    _ = cmd.ExecuteNonQuery();

                    respRegistro.CodigoPlanilla = Convert.ToString(cmd.Parameters["@o_codplanilla"].Value);
                    respRegistro.CodigoSolicEgre = Convert.ToInt32(cmd.Parameters["@o_codsoliegre"].Value);
                    respRegistro.Bodega = Convert.ToString(cmd.Parameters["@o_bodega"].Value);
                    respRegistro.DesArticulo = Convert.ToString(cmd.Parameters["@o_descarticulo"].Value);

                    oResp = new()
                    {
                        Codigo = Convert.ToInt16(cmd.Parameters["@return_value"].Value),
                        Mensaje = Convert.ToString(cmd.Parameters["@o_msgerror"].Value)
                    };
                }
                else
                {
                    oResp = new()
                    {
                        Codigo = -1,
                        Mensaje = "Llamada a metodo sin parametros de entrada"
                    };
                }
            }
            catch (Exception ex)
            {
                oResp = new()
                {
                    Codigo = -2,
                    Mensaje = ex.Message
                };
                logger.Error($"Error en la clase [{ex.GetType().Name}], metodo [{ex.GetType().FullName}" + "\r\n" + ex.StackTrace);
            }
            return oResp;
        }


        #endregion "Emergencia"
    }
}
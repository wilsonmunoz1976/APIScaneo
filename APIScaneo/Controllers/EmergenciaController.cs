using clsScaneo;
using clsScaneo.Clases;
using clsScaneo.Entidades;
using Microsoft.AspNetCore.Mvc;
using NLog;

namespace APIScaneo.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class EmergenciaController : ControllerBase
    {
        private static readonly Logger logger = LogManager.GetCurrentClassLogger();

        private readonly string CrLf = "\r\n";

        private readonly Emergencia? Conectividad;

        public EmergenciaController()
        {
            try
            {
                IConfigurationRoot configuration = new ConfigurationBuilder()
                .SetBasePath(AppDomain.CurrentDomain.BaseDirectory)
                .AddJsonFile("appsettings.json")
                .Build();

                string? myDb1ConnectionString = configuration.GetConnectionString("DefaultConnection");

                if (myDb1ConnectionString != null)
                {
                    Conectividad = new Emergencia(myDb1ConnectionString);
                }
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message + "\r\n" + ex.StackTrace);
            }
        }

        [HttpPost("RegistrarEmergencia")]
        public RespuestaEjecucion? RegistrarEmergencia([FromBody] RegistroEmergenciaRequest? oReq)
        {
            RegistroEmergenciaResponse respRegistro = new();
            RespuestaEjecucion? oRespEmail = new();
            RespuestaEjecucion? oResp = IsTokenValido();
            if (oResp != null)
            {
                if (oResp.codigo == 0)
                {

                    try
                    {
                        if (Conectividad != null)
                        {
                            oResp = Conectividad.RegistrarEmergencia(oReq, ref respRegistro);
                            if (oResp != null)
                            {
                                if (oResp.codigo == 0)
                                {
                                    oRespEmail = NotificacionEmail(oReq, ref respRegistro);
                                }
                                else
                                {
                                    string? sMensaje = oResp.mensaje;
                                    oResp = new()
                                    {
                                        codigo = -1,
                                        mensaje = sMensaje ?? ""
                                    };

                                }
                            }
                            else
                            {
                                oResp = new()
                                {
                                    codigo = -2,
                                    mensaje = "Hubo un error al ejecutar RegistrarEmergencia"
                                };
                                logger.Error("Hubo un error al ejecutar RegistrarEmergencia");
                            }
                        }
                        else
                        {
                            oResp = new()
                            {
                                codigo = -2,
                                mensaje = "No esta instanciada la clase de Emergencia"
                            };
                            logger.Error("No esta instanciada la clase de Emergencia");
                        }
                    }
                    catch (Exception ex)
                    {
                        oResp = new()
                        {
                            codigo = -2,
                            mensaje = ex.Message
                        };
                        logger.Error(ex.Message + "\r\n" + ex.StackTrace);
                    }
                }
            }
            return oResp;
        }

        private RespuestaEjecucion? NotificacionEmail(RegistroEmergenciaRequest? oReq, ref RegistroEmergenciaResponse respRegistro)
        {
            RespuestaEjecucion? oResp = IsTokenValido();
            if (oResp != null)
            {
                if (oResp.codigo == 0)
                {
                    IConfigurationRoot configuration = new ConfigurationBuilder()
                    .SetBasePath(AppDomain.CurrentDomain.BaseDirectory)
                    .AddJsonFile("appsettings.json")
                    .Build();

                    EmailConfig? configEmail = configuration.GetSection("ConfigEmail").Get<EmailConfig>();
                    string htmlBody = string.Empty;
                    if (configEmail != null)
                    {
                        string fileName = Environment.CurrentDirectory + "\\plantilla_mail_notificacion.html";
                        using (StreamReader reader = new(fileName))
                        {
                            string? line;
                            while ((line = reader.ReadLine()) != null)
                            {
                                htmlBody += line + CrLf;
                            }
                        }
                        if (oReq != null)
                        {
                            htmlBody = htmlBody.Replace("[CodArticulo]", oReq.articulo);
                            htmlBody = htmlBody.Replace("[DesArticulo]", respRegistro.desArticulo);
                            htmlBody = htmlBody.Replace("[Bodega]", respRegistro.bodega);
                            htmlBody = htmlBody.Replace("[NombreCompleto]", oReq.nombres);
                            htmlBody = htmlBody.Replace("[Usuario]", oReq.usuario);
                            htmlBody = htmlBody.Replace("[CodigoSoliEgre]", respRegistro.codigoSolicEgre.ToString());
                            htmlBody = htmlBody.Replace("[CodigoPlanilla]", respRegistro.codigoPlanilla);
                        }

                        EmailMessage? oMail = new()
                        {
                            ServidorMail = configEmail.MailServer,
                            PortMail = configEmail.MailPuerto,
                            UseSSL = true,
                            FromMail = configEmail.FromEmail,
                            FromName = configEmail.FromName,
                            Subject = configEmail.MailSubject,
                            UsuarioMail = configEmail.MailUsuario,
                            PasswordMail = configEmail.MailPassword,
                            To = new List<string?>(configEmail.MailTo.Split(";")),
                            CC = new List<string?>(configEmail.MailCC.Split(";")),
                            CCO = new List<string?>(configEmail.MailCCO.Split(";")),
                            Body = htmlBody
                        };

                        if (Conectividad != null)
                        {
                            oResp = Conectividad.EnviarCorreoNotificacion(oMail);
                        }
                        else
                        {
                            oResp = new()
                            {
                                codigo = -2,
                                mensaje = "Hubo un error al ejecutar RegistrarEmergencia"
                            };
                            logger.Error("Hubo un error al ejecutar RegistrarEmergencia");
                        }

                        if (oResp == null)
                        {
                            oResp = new RespuestaEjecucion()
                            {
                                codigo = -2,
                                mensaje = "No hay conectividad con la base de datos, solicite soporte"
                            };
                            logger.Error("No hay conectividad con la base de datos, solicite soporte");
                        }
                    }
                }
            }
            return oResp;
        }

        private RespuestaEjecucion? IsTokenValido()
        {
            var context = HttpContext;
            if (context.Response.Headers["token-Expired"] == "true")
            {
                return new()
                {
                    codigo = 100,
                    mensaje = "token es invalido o esta expirado"
                };
            }
            else
            {
                return new()
                {
                    codigo = 0,
                    mensaje = "token valido"
                };
            }
        }
    }
}
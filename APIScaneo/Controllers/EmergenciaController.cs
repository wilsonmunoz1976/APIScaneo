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
            RespuestaEjecucion? oResp = IsTokenValido();
            if (oResp != null)
            {
                if (oResp.Codigo == 0)
                {

                    try
                    {
                        if (Conectividad != null)
                        {
                            oResp = Conectividad.RegistrarEmergencia(oReq, ref respRegistro);
                            if (oResp != null)
                            {
                                if (oResp.Codigo == 0)
                                {
                                    oResp = NotificacionEmail(oReq, ref respRegistro);
                                }
                                else
                                {
                                    string? sMensaje = oResp.Mensaje;
                                    oResp = new()
                                    {
                                        Codigo = -1,
                                        Mensaje = sMensaje ?? ""
                                    };

                                }
                            }
                            else
                            {
                                oResp = new()
                                {
                                    Codigo = -2,
                                    Mensaje = "Hubo un error al ejecutar RegistrarEmergencia"
                                };
                                logger.Error("Hubo un error al ejecutar RegistrarEmergencia");
                            }
                        }
                        else
                        {
                            oResp = new()
                            {
                                Codigo = -2,
                                Mensaje = "No esta instanciada la clase de Emergencia"
                            };
                            logger.Error("No esta instanciada la clase de Emergencia");
                        }
                    }
                    catch (Exception ex)
                    {
                        oResp = new()
                        {
                            Codigo = -2,
                            Mensaje = ex.Message
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
                if (oResp.Codigo == 0)
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
                            htmlBody = htmlBody.Replace("[CodArticulo]", oReq.Articulo);
                            htmlBody = htmlBody.Replace("[DesArticulo]", respRegistro.DesArticulo);
                            htmlBody = htmlBody.Replace("[Bodega]", respRegistro.Bodega);
                            htmlBody = htmlBody.Replace("[NombreCompleto]", oReq.Nombres);
                            htmlBody = htmlBody.Replace("[Usuario]", oReq.Usuario);
                            htmlBody = htmlBody.Replace("[CodigoSoliEgre]", respRegistro.CodigoSolicEgre.ToString());
                            htmlBody = htmlBody.Replace("[CodigoPlanilla]", respRegistro.CodigoPlanilla);
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
                                Codigo = -2,
                                Mensaje = "Hubo un error al ejecutar RegistrarEmergencia"
                            };
                            logger.Error("Hubo un error al ejecutar RegistrarEmergencia");
                        }

                        if (oResp == null)
                        {
                            oResp = new RespuestaEjecucion()
                            {
                                Codigo = -2,
                                Mensaje = "No hay conectividad con la base de datos, solicite soporte"
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
            if (context.Response.Headers["Token-Expired"] == "true")
            {
                return new()
                {
                    Codigo = -9,
                    Mensaje = "Token es invalido o esta expirado"
                };
            }
            else
            {
                return new()
                {
                    Codigo = 0,
                    Mensaje = "Token valido"
                };
            }
        }
    }
}
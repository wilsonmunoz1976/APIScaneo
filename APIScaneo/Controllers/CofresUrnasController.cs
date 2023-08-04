using clsScaneo.Clases;
using clsScaneo.Entidades;
using Microsoft.AspNetCore.Mvc;
using NLog;
using System.Data;

namespace APIScaneo.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class CofresUrnasController : ControllerBase
    {
        private static readonly Logger logger = LogManager.GetCurrentClassLogger();
        private readonly CofresUrnas? Conectividad = null;
        private readonly Emergencia? MailAgente = null;
        private readonly string CrLf = "\r\n";

        public CofresUrnasController()
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
                    Conectividad = new CofresUrnas(myDb1ConnectionString);
                    MailAgente = new Emergencia(myDb1ConnectionString);
                }
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message + "\r\n" + ex.StackTrace);
            }
        }

        [HttpPost("GetBodegas")]
        public BodegaResponse GetBodegas()
        {
            List<BodegaResponseDetalle> oBodegas = new();
            RespuestaEjecucion oResp = new();
            try
            {
                if (Conectividad != null)
                {
                    DataTable oData = Conectividad.GetBodegas(ref oResp);
                    if (oData != null)
                    {
                        oBodegas = (from DataRow dr in oData.Rows
                                    select new BodegaResponseDetalle()
                                    {
                                        Codigobodega = dr["ci_bodega"].ToString(),
                                        Nombrebodega = dr["tx_nombrebodega"].ToString(),
                                    }
                                         ).ToList();
                    }
                }
                else
                {
                    oResp.Codigo = -2;
                    oResp.Mensaje = "No esta instanciada la clase de CofresUrnas";
                    logger.Error("No esta instanciada la clase de CofresUrnas");
                }
            } catch (Exception ex)
            {
                oResp.Codigo = -2;
                oResp.Mensaje = ex.Message;
                logger.Error(ex.Message + "\r\n" + ex.StackTrace);
            }

            return new BodegaResponse() { Respuesta = oResp, Detalle = oBodegas };
        }

        [HttpPost("GetCofresUrnas")]
        public CofreUrnaListaResponse GetCofresUrnas()
        {
            List<CofreUrnaListaResponseDetalle> oCofresUrnas = new();
            RespuestaEjecucion oResp = new();
            try
            {
                if (Conectividad != null)
                {
                    DataTable oData = Conectividad.GetCofresUrnas("009", 0, null, ref oResp);
                    if (oData != null)
                    {
                        oCofresUrnas = (from DataRow dr in oData.Rows
                                        select new CofreUrnaListaResponseDetalle()
                                        {
                                            Codigo = dr["Codigo"].ToString(),
                                            Bodega = dr["Bodega"].ToString(),
                                            Producto = dr["Producto"].ToString(),
                                            Inhumado = dr["Inhumado"].ToString(),
                                            NombreProveedor = dr["NombreProveedor"].ToString(),
                                            Estado = Convert.ToInt16(dr["Estado"])
                                        }
                                         ).ToList();
                    }
                }
                else
                {
                    oResp.Codigo = -2;
                    oResp.Mensaje = "No esta instanciada la clase de CofresUrnas";
                    logger.Error("No esta instanciada la clase de CofresUrnas");
                }
            }
            catch (Exception ex)
            {
                oResp.Codigo = -2;
                oResp.Mensaje = ex.Message;
                logger.Error(ex.Message + "\r\n" + ex.StackTrace);
            }
            return new CofreUrnaListaResponse() { Respuesta = oResp, Detalle = oCofresUrnas };
        }

        [HttpPost("GetCofresUrnas/{bodega}")]
        public CofreUrnaListaResponse GetCofresUrnas(string bodega, int? estado = 0, string? usuario = null)
        {
            List<CofreUrnaListaResponseDetalle>? oActivosFijos = new();
            RespuestaEjecucion oResp = new();
            try
            {
                if (Conectividad != null)
                {
                    DataTable oData = Conectividad.GetCofresUrnas(bodega, estado, usuario, ref oResp);
                    if (oData != null)
                    {
                        oActivosFijos = (from DataRow dr in oData.Rows
                                         select new CofreUrnaListaResponseDetalle()
                                         {
                                             Codigo = dr["Codigo"].ToString(),
                                             Bodega = dr["Bodega"].ToString(),
                                             Producto = dr["Producto"].ToString(),
                                             Inhumado = dr["Inhumado"].ToString(),
                                             NombreProveedor = dr["NombreProveedor"].ToString(),
                                             Estado = Convert.ToInt16(dr["Estado"])
                                         }
                                         ).ToList();
                    }
                }
                else
                {
                    oResp.Codigo = -2;
                    oResp.Mensaje = "No esta instanciada la clase de CofresUrnas";
                    logger.Error("No esta instanciada la clase de CofresUrnas");
                }
            }
            catch (Exception ex)
            {
                oResp.Codigo = -2;
                oResp.Mensaje = ex.Message;
                logger.Error(ex.Message + "\r\n" + ex.StackTrace);
            }
            return new CofreUrnaListaResponse() { Respuesta = oResp, Detalle = oActivosFijos };
        }

        [HttpPost("GetCofreUrna/{articulo}")]
        public CofreUrnaDatoResponse GetCofreUrna(string? articulo)
        {
            CofreUrnaDatoResponseDetalle detalle = new();
            RespuestaEjecucion oResp = new();
            try
            {
                if (Conectividad != null)
                {
                    DataTable oData = Conectividad.GetCofreUrna(articulo, ref oResp);
                    if (oData != null)
                    {
                        if (oData.Rows.Count > 0)
                        {
                            DataRow dr = oData.Rows[0];
                            detalle = new()
                            {
                                CodArticulo = dr["CodArticulo"].ToString(),
                                DesArticulo = dr["DesArticulo"].ToString(),
                                CodBodega = dr["CodBodega"].ToString(),
                                DesBodega = dr["DesBodega"].ToString(),
                                Precio = Convert.ToDecimal(dr["Precio"]),
                                Existencia = Convert.ToDecimal(dr["Existencia"])
                            };
                        }
                    }
                }
                else
                {
                    oResp.Codigo = -2;
                    oResp.Mensaje = "No esta instanciada la clase de CofresUrnas";
                    logger.Error("No esta instanciada la clase de CofresUrnas");
                }
            }
            catch (Exception ex)
            {
                oResp.Codigo = -2;
                oResp.Mensaje = ex.Message;
                logger.Error(ex.Message + "\r\n" + ex.StackTrace);
            }
            return new CofreUrnaDatoResponse() { Respuesta = oResp, Detalle = detalle };
        }

        [HttpPost("GetSolEgreCofreUrna/{solicitudEgreso}")]
        public CofreUrnaListaResponse GetSolEgreCofreUrna(int? solicitudEgreso, string? usuario = null)
        {
            List<CofreUrnaListaResponseDetalle> oCofresUrnas = new();
            RespuestaEjecucion oResp = new();
            try
            {
                if (Conectividad != null)
                {
                    DataTable oData = Conectividad.GetSolEgreCofreUrna(solicitudEgreso, usuario, ref oResp);
                    if (oData != null)
                    {
                        oCofresUrnas = (from DataRow dr in oData.Rows
                                        select new CofreUrnaListaResponseDetalle()
                                        {
                                            Codigo = dr["Codigo"].ToString(),
                                            Bodega = dr["Bodega"].ToString(),
                                            Producto = dr["Producto"].ToString(),
                                            Inhumado = dr["Inhumado"].ToString(),
                                            NombreProveedor = dr["NombreProveedor"].ToString(),
                                            Estado = Convert.ToInt16(dr["Estado"]),
                                            Comentario = dr["Comentario"].ToString(),
                                            ObservacionRetiro = dr["ObservacionRetiro"].ToString(),
                                            ObservacionEntrega = dr["ObservacionEntrega"].ToString(),
                                            ObservacionSala = dr["ObservacionSala"].ToString(),
                                            FotografiaSala = dr["FotografiaSala"].ToString()
                                        }
                                         ).ToList();
                    }
                }
                else
                {
                    oResp.Codigo = -2;
                    oResp.Mensaje = "No esta instanciada la clase de CofresUrnas";
                    logger.Error("No esta instanciada la clase de CofresUrnas");
                }
            }
            catch (Exception ex)
            {
                oResp.Codigo = -2;
                oResp.Mensaje = ex.Message;
                logger.Error(ex.Message + "\r\n" + ex.StackTrace);
            }
            return new CofreUrnaListaResponse() { Respuesta = oResp, Detalle = oCofresUrnas };
        }

        [HttpPost("CambiaEstadoCofresUrnas")]
        public RespuestaEjecucion? CambiaEstadoCofresUrnas([FromBody] CambiaEstadoCofreUrnaRequest cofresUrnasReq)
        {
            RespuestaEjecucion? oResp;
            try
            {
                if (Conectividad != null)
                {
                    oResp = Conectividad.CambiaEstadoCofresUrnas(
                            Bodega: cofresUrnasReq.Bodega,
                            Codigo: cofresUrnasReq.Codigo,
                            Estado: cofresUrnasReq.Estado,
                            Comentario: cofresUrnasReq.Comentario,
                            Fotografia: cofresUrnasReq.Fotografia,
                            Usuario: cofresUrnasReq.Usuario
                            );
                }
                else
                {
                    oResp = new()
                    {
                        Codigo = -2,
                        Mensaje = "No esta instanciada la clase de CofresUrnas"
                    };
                    logger.Error("No esta instanciada la clase de CofresUrnas");
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
            return oResp;
        }

        [HttpPost("ReingresoCofresUrnas")]
        public RespuestaEjecucion? ReingresoCofresUrnas([FromBody] ReingresoCofreUrnaRequest reingresoCofreUrna)
        {
            RespuestaEjecucion? oResp = new();

            try
            {
                if (Conectividad != null)
                {
                    DataTable dt = Conectividad.ReingresoCofresUrnas(reingresoCofreUrna, ref oResp);
                    if (oResp.Codigo == 0)
                    {
                        if (dt.Rows.Count > 0)
                        {
                            ReingresoCofreUrnaRespose? oDato = null;
                            DataRow dr = dt.Rows[0];
                            oDato = new()
                            {
                                CodArticuloOrigen = dr["CodArticuloOrigen"].ToString(),
                                DesArticuloOrigen = dr["DesArticuloOrigen"].ToString(),
                                CodArticuloDestino = dr["CodArticuloDestino"].ToString(),
                                DesArticuloDestino = dr["DesArticuloDestino"].ToString(),
                                CodSoliEgre = Convert.ToInt32(dr["CodSoliEgre"]),
                                CodPlanilla = dr["CodPlanilla"].ToString(),
                                NombreFallecido = dr["NombreFallecido"].ToString(),
                                Usuario = dr["Usuario"].ToString()
                            };
                            oResp = NotificarReingreso(oDato);
                        }
                    }
                }
                else
                {
                    oResp = new()
                    {
                        Codigo = -2,
                        Mensaje = "No esta instanciada la clase de CofresUrnas"
                    };
                    logger.Error("No esta instanciada la clase de CofresUrnas");
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
            return oResp;
        }

        private RespuestaEjecucion? NotificarReingreso(ReingresoCofreUrnaRespose? oReq)
        {
            RespuestaEjecucion? oResp = null;

            IConfigurationRoot configuration = new ConfigurationBuilder()
            .SetBasePath(AppDomain.CurrentDomain.BaseDirectory)
            .AddJsonFile("appsettings.json")
            .Build();

            EmailConfig? configEmail = configuration.GetSection("ConfigEmail").Get<EmailConfig>();
            string htmlBody = string.Empty;
            if (configEmail != null)
            {
                string fileName = Environment.CurrentDirectory + "\\plantilla_mail_reingreso.html";
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
                    htmlBody = htmlBody.Replace("[CodCofreOrig]", oReq.CodArticuloOrigen);
                    htmlBody = htmlBody.Replace("[DesCofreOrig]", oReq.DesArticuloOrigen);
                    htmlBody = htmlBody.Replace("[CodCofreDest]", oReq.CodArticuloDestino);
                    htmlBody = htmlBody.Replace("[DesCofreOrig]", oReq.DesArticuloDestino);
                    htmlBody = htmlBody.Replace("[Usuario]", oReq.Usuario);
                    htmlBody = htmlBody.Replace("[CodigoSoliEgre]", oReq.CodSoliEgre.ToString());
                    htmlBody = htmlBody.Replace("[CodigoPlanilla]", oReq.CodPlanilla);
                    htmlBody = htmlBody.Replace("[Usuario]", oReq.Usuario);
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

                if (MailAgente != null)
                {
                    oResp = MailAgente.EnviarCorreoNotificacion(oMail);
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
            return oResp;
        }
    }
}
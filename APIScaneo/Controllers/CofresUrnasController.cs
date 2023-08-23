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
            RespuestaEjecucion? oResp = IsTokenValido();
            if (oResp != null)
            {
                if (oResp.codigo == 0)
                {
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
                                                codigoBodega = dr["ci_bodega"].ToString(),
                                                nombreBodega = dr["tx_nombrebodega"].ToString(),
                                            }
                                           ).ToList();
                            }
                        }
                        else
                        {
                            oResp.codigo = -2;
                            oResp.mensaje = "No esta instanciada la clase de CofresUrnas";
                            logger.Error("No esta instanciada la clase de CofresUrnas");
                        }
                    }
                    catch (Exception ex)
                    {
                        oResp.codigo = -2;
                        oResp.mensaje = ex.Message;
                        logger.Error(ex.Message + "\r\n" + ex.StackTrace);
                    }
                }
            }

            return new BodegaResponse() { respuesta = oResp, detalle = oBodegas };
        }

        [HttpPost("GetCofresUrnas/{bodega}")]
        public CofreUrnaListaResponse GetCofresUrnas(string bodega, int? estado = 0, string? usuario = null)
        {
            List<CofreUrnaListaResponseDetalle>? oActivosFijos = new();
            RespuestaEjecucion? oResp = IsTokenValido();
            if (oResp != null)
            {
                if (oResp.codigo == 0)
                {
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
                                                     codigo = dr["codigo"]==DBNull.Value? null: dr["codigo"].ToString(),
                                                     bodega = dr["bodega"] == DBNull.Value ? null : dr["bodega"].ToString(),
                                                     codproducto = dr["codProducto"] == DBNull.Value ? null : dr["codproducto"].ToString(),
                                                     producto = dr["producto"] == DBNull.Value ? null : dr["producto"].ToString(),
                                                     inhumado = dr["inhumado"] == DBNull.Value ? null : dr["inhumado"].ToString(),
                                                     nombreProveedor = dr["nombreProveedor"] == DBNull.Value ? null : dr["nombreProveedor"].ToString(),
                                                     estado = dr["estado"] == DBNull.Value ? null : Convert.ToInt16(dr["estado"])
                                                 }
                                                 ).ToList();
                            }
                        }
                        else
                        {
                            oResp.codigo = -2;
                            oResp.mensaje = "No esta instanciada la clase de CofresUrnas";
                            logger.Error("No esta instanciada la clase de CofresUrnas");
                        }
                    }
                    catch (Exception ex)
                    {
                        oResp.codigo = -2;
                        oResp.mensaje = ex.Message;
                        logger.Error(ex.Message + "\r\n" + ex.StackTrace);
                    }
                }
            }
            return new CofreUrnaListaResponse() { respuesta = oResp, detalle = oActivosFijos };
        }

        [HttpPost("GetCofreUrna/{articulo}")]
        public CofreUrnaDatoResponse GetCofreUrna(string? articulo)
        {
            CofreUrnaDatoResponseDetalle detalle = new();
            RespuestaEjecucion? oResp = IsTokenValido();
            if (oResp != null)
            {
                if (oResp.codigo == 0)
                {
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
                                        codArticulo = dr["codArticulo"] == DBNull.Value ? null : dr["codArticulo"].ToString(),
                                        desArticulo = dr["desArticulo"] == DBNull.Value ? null : dr["desArticulo"].ToString(),
                                        codBodega = dr["codBodega"] == DBNull.Value ? null : dr["codBodega"].ToString(),
                                        desBodega = dr["desBodega"] == DBNull.Value ? null : dr["desBodega"].ToString(),
                                        precio = dr["precio"] == DBNull.Value ? null : Convert.ToDecimal(dr["precio"]),
                                        existencia = dr["existencia"] == DBNull.Value ? null : Convert.ToDecimal(dr["existencia"])
                                    };
                                }
                            }
                        }
                        else
                        {
                            oResp.codigo = -2;
                            oResp.mensaje = "No esta instanciada la clase de CofresUrnas";
                            logger.Error("No esta instanciada la clase de CofresUrnas");
                        }
                    }
                    catch (Exception ex)
                    {
                        oResp.codigo = -2;
                        oResp.mensaje = ex.Message;
                        logger.Error(ex.Message + "\r\n" + ex.StackTrace);
                    }
                }
            }
            return new CofreUrnaDatoResponse() { respuesta = oResp, detalle = detalle };
        }

        [HttpPost("GetSolEgreCofreUrna/{solicitudEgreso}")]
        public CofreUrnaListaResponse GetSolEgreCofreUrna(int? solicitudEgreso, string? usuario = null)
        {
            List<CofreUrnaListaResponseDetalle> oCofresUrnas = new();
            RespuestaEjecucion? oResp = IsTokenValido();
            if (oResp != null)
            {
                if (oResp.codigo == 0)
                {
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
                                                    codigo = dr["codigo"] == DBNull.Value ? null : dr["codigo"].ToString(),
                                                    bodega = dr["bodega"] == DBNull.Value ? null : dr["bodega"].ToString(),
                                                    producto = dr["producto"] == DBNull.Value ? null : dr["producto"].ToString(),
                                                    inhumado = dr["inhumado"] == DBNull.Value ? null : dr["inhumado"].ToString(),
                                                    nombreProveedor = dr["nombreProveedor"] == DBNull.Value ? null : dr["nombreProveedor"].ToString(),
                                                    estado = dr["estado"] == DBNull.Value ? null : Convert.ToInt16(dr["estado"]),
                                                    comentario = dr["comentario"] == DBNull.Value ? null : dr["comentario"].ToString(),
                                                    observacionRetiro = dr["observacionRetiro"] == DBNull.Value ? null : dr["observacionRetiro"].ToString(),
                                                    observacionEntrega = dr["observacionEntrega"] == DBNull.Value ? null : dr["observacionEntrega"].ToString(),
                                                    observacionSala = dr["observacionSala"] == DBNull.Value ? null : dr["observacionSala"].ToString(),
                                                    fotografiaSala = dr["fotografiaSala"] == DBNull.Value ? null : dr["fotografiaSala"].ToString()
                                                }
                                                 ).ToList();
                            }
                        }
                        else
                        {
                            oResp.codigo = -2;
                            oResp.mensaje = "No esta instanciada la clase de CofresUrnas";
                            logger.Error("No esta instanciada la clase de CofresUrnas");
                        }
                    }
                    catch (Exception ex)
                    {
                        oResp.codigo = -2;
                        oResp.mensaje = ex.Message;
                        logger.Error(ex.Message + "\r\n" + ex.StackTrace);
                    }
                }
            }
            return new CofreUrnaListaResponse() { respuesta = oResp, detalle = oCofresUrnas };
        }

        [HttpPost("CambiaEstadoCofresUrnas")]
        public RespuestaEjecucion? CambiaEstadoCofresUrnas([FromBody] CambiaEstadoCofreUrnaRequest cofresUrnasReq)
        {
            RespuestaEjecucion? oResp = IsTokenValido();
            if (oResp != null)
            {
                if (oResp.codigo == 0)
                {
                    try
                    {
                        if (Conectividad != null)
                        {
                            oResp = Conectividad.CambiaEstadoCofresUrnas(
                                    Bodega: cofresUrnasReq.bodega,
                                    Codigo: cofresUrnasReq.codigo,
                                    Estado: cofresUrnasReq.estado,
                                    Comentario: cofresUrnasReq.comentario,
                                    Fotografia: cofresUrnasReq.fotografia,
                                    Usuario: cofresUrnasReq.usuario
                                    );
                        }
                        else
                        {
                            oResp = new()
                            {
                                codigo = -2,
                                mensaje = "No esta instanciada la clase de CofresUrnas"
                            };
                            logger.Error("No esta instanciada la clase de CofresUrnas");
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

        [HttpPost("ReingresoCofresUrnas")]
        public RespuestaEjecucion? ReingresoCofresUrnas([FromBody] ReingresoCofreUrnaRequest reingresoCofreUrna)
        {
            RespuestaEjecucion? oResp = IsTokenValido();
            if (oResp != null)
            {
                if (oResp.codigo == 0)
                {
                    try
                    {
                        if (Conectividad != null)
                        {
                            DataTable dt = Conectividad.ReingresoCofresUrnas(reingresoCofreUrna, ref oResp);
                            if (oResp.codigo == 0)
                            {
                                if (dt.Rows.Count > 0)
                                {
                                    ReingresoCofreUrnaRespose? oDato = null;
                                    DataRow dr = dt.Rows[0];
                                    oDato = new()
                                    {
                                        codArticuloOrigen = dr["codArticuloOrigen"] == DBNull.Value ? null : dr["codArticuloOrigen"].ToString(),
                                        desArticuloOrigen = dr["desArticuloOrigen"] == DBNull.Value ? null : dr["desArticuloOrigen"].ToString(),
                                        codArticuloDestino = dr["codArticuloDestino"] == DBNull.Value ? null : dr["codArticuloDestino"].ToString(),
                                        desArticuloDestino = dr["desArticuloDestino"] == DBNull.Value ? null : dr["desArticuloDestino"].ToString(),
                                        codSoliEgre = dr["codSoliEgre"] == DBNull.Value ? null : Convert.ToInt32(dr["codSoliEgre"]),
                                        codPlanilla = dr["codPlanilla"] == DBNull.Value ? null : dr["codPlanilla"].ToString(),
                                        nombreFallecido = dr["nombreFallecido"] == DBNull.Value ? null : dr["nombreFallecido"].ToString(),
                                        usuario = dr["usuario"] == DBNull.Value ? null : dr["usuario"].ToString()
                                    };
                                    oResp = NotificarReingreso(oDato);
                                }
                            }
                        }
                        else
                        {
                            oResp = new()
                            {
                                codigo = -2,
                                mensaje = "No esta instanciada la clase de CofresUrnas"
                            };
                            logger.Error("No esta instanciada la clase de CofresUrnas");
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
                    htmlBody = htmlBody.Replace("[CodCofreOrig]", oReq.codArticuloOrigen);
                    htmlBody = htmlBody.Replace("[DesCofreOrig]", oReq.desArticuloOrigen);
                    htmlBody = htmlBody.Replace("[CodCofreDest]", oReq.codArticuloDestino);
                    htmlBody = htmlBody.Replace("[DesCofreDest]", oReq.desArticuloDestino);
                    htmlBody = htmlBody.Replace("[Usuario]", oReq.usuario);
                    htmlBody = htmlBody.Replace("[CodigoSoliEgre]", oReq.codSoliEgre.ToString());
                    htmlBody = htmlBody.Replace("[CodigoPlanilla]", oReq.codPlanilla);
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
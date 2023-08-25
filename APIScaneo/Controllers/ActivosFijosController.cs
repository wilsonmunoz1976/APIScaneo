using clsScaneo;
using clsScaneo.Clases;
using clsScaneo.Entidades;
using Microsoft.AspNetCore.Mvc;
using NLog;
using System.Data;

namespace APIScaneo.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ActivosFijosController : ControllerBase
    {
        private static readonly Logger logger = LogManager.GetCurrentClassLogger();

        private readonly ActivosFijos? Conectividad;

        public ActivosFijosController()
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
                    Conectividad = new ActivosFijos(myDb1ConnectionString);
                }
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message + "\r\n" + ex.StackTrace);
            }
        }

        [HttpPost("GetActivosFijos")]
        public ActivoFijoResponse GetActivosFijos()
        {
            List<ActivoFijoResponseDetalle> oActivosFijos = new();
            RespuestaEjecucion? oResp = IsTokenValido();
            if (oResp != null)
            {
                if (oResp.codigo == 0)
                {
                    try
                    {

                        if (Conectividad != null)
                        {
                            DataTable oData = Conectividad.GetActivosFijos(ref oResp);
                            if (oData != null)
                            {
                                oActivosFijos = (from DataRow dr in oData.Rows
                                                 select new ActivoFijoResponseDetalle()
                                                 {
                                                     codigo = dr["codigo"]==DBNull.Value? null: dr["codigo"].ToString(),
                                                     activo = dr["activo"] == DBNull.Value ? null : dr["activo"].ToString(),
                                                     custodio = dr["custodio"] == DBNull.Value ? null : dr["custodio"].ToString(),
                                                     costo = dr["costo"] == DBNull.Value? null: Convert.ToDecimal(dr["costo"])
                                                 }
                                                 ).ToList();
                            }
                        }
                        else
                        {
                            oResp.codigo = -2;
                            oResp.mensaje = "No esta instanciada la clase de Activos Fijos";
                            logger.Error("No esta instanciada la clase de Activos Fijos");
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
            return new ActivoFijoResponse() { respuesta = oResp, detalle=oActivosFijos };
        }

        [HttpPost("GetActivosFijos/{codigo}/{usuario}")]
        public ActivoFijoResponse GetActivosFijos(string codigo, string usuario)
        {
            List<ActivoFijoResponseDetalle> oActivosFijos = new();
            RespuestaEjecucion? oResp = IsTokenValido();
            if (oResp != null)
            {
                if (oResp.codigo == 0)
                {
                    try
                    {
                        if (Conectividad != null)
                        {
                            DataTable oData = Conectividad.GetActivosFijos(codigo, usuario, ref oResp);
                            if (oData != null)
                            {
                                oActivosFijos = (from DataRow dr in oData.Rows
                                                 select new ActivoFijoResponseDetalle()
                                                 {
                                                     codigo = dr["codigo"] == DBNull.Value ? null : dr["codigo"].ToString(),
                                                     activo = dr["activo"] == DBNull.Value ? null : dr["activo"].ToString(),
                                                     custodio = dr["custodio"] == DBNull.Value ? null : dr["custodio"].ToString(),
                                                     costo = dr["costo"] == DBNull.Value ? null : Convert.ToDecimal(dr["costo"])
                                                 }
                                                 ).ToList();
                            }
                        }
                        else
                        {
                            oResp.codigo = -2;
                            oResp.mensaje = "No esta instanciada la clase de Activos Fijos";
                            logger.Error("No esta instanciada la clase de Activos Fijos");
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
            return new ActivoFijoResponse() { respuesta = oResp, detalle = oActivosFijos };
        }

        private RespuestaEjecucion IsTokenValido()
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
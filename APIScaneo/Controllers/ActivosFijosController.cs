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
        public ActivoFijo GetActivosFijos()
        {
            List<ActivoFijoDet> oActivosFijos = new();
            RespuestaEjecucion oResp = new();
            try
            {
                if (Conectividad != null)
                {
                    DataTable oData = Conectividad.GetActivosFijos(ref oResp);
                    if (oData != null)
                    {
                        oActivosFijos = (from DataRow dr in oData.Rows
                                         select new ActivoFijoDet()
                                         {
                                             Codigo = dr["Codigo"].ToString(),
                                             Activo = dr["Activo"].ToString(),
                                             Custodio = dr["Custodio"].ToString(),
                                             Costo = Convert.ToDecimal(dr["Costo"]),
                                         }
                                         ).ToList();
                    }
                }
                else
                {
                    oResp.Codigo = -2;
                    oResp.Mensaje = "No esta instanciada la clase de Activos Fijos";
                    logger.Error("No esta instanciada la clase de Activos Fijos");
                }
            }
            catch (Exception ex)
            {
                oResp.Codigo = -2;
                oResp.Mensaje = ex.Message;
                logger.Error(ex.Message + "\r\n" + ex.StackTrace);
            }
            return new ActivoFijo() { Respuesta = oResp, Detalle=oActivosFijos };
        }

        [HttpPost("GetActivosFijos/{codigo}")]
        public ActivoFijo GetActivosFijos(string codigo)
        {
            List<ActivoFijoDet> oActivosFijos = new();
            RespuestaEjecucion oResp = new();
            try
            {
                if (Conectividad != null)
                {
                    DataTable oData = Conectividad.GetActivosFijos(codigo, ref oResp);
                    if (oData != null)
                    {
                        oActivosFijos = (from DataRow dr in oData.Rows
                                         select new ActivoFijoDet()
                                         {
                                             Codigo = dr["Codigo"].ToString(),
                                             Activo = dr["Activo"].ToString(),
                                             Custodio = dr["Custodio"].ToString(),
                                             Costo = Convert.ToDecimal(dr["Costo"]),
                                         }
                                         ).ToList();
                    }
                }
                else
                {
                    oResp.Codigo = -2;
                    oResp.Mensaje = "No esta instanciada la clase de Activos Fijos";
                    logger.Error("No esta instanciada la clase de Activos Fijos");
                }
            }
            catch (Exception ex)
            {
                oResp.Codigo = -2;
                oResp.Mensaje = ex.Message;
                logger.Error(ex.Message + "\r\n" + ex.StackTrace);
            }
            return new ActivoFijo() { Respuesta = oResp, Detalle = oActivosFijos };
        }

    }
}
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

        [HttpPost("GetActivosFijos/{codigo}/{usuario}")]
        public ActivoFijoResponse GetActivosFijos(string codigo, string usuario)
        {
            ActivoFijoResponseInfo oActivoInfo = new();
            List<ActivoFijoResponseDetalle> oActivoDetalle = new();
            RespuestaEjecucion? oResp = IsTokenValido();
            if (oResp != null)
            {
                if (oResp.codigo == 0)
                {
                    try
                    {
                        if (Conectividad != null)
                        {
                            DataSet oData = Conectividad.GetActivosFijos(codigo, usuario, ref oResp);
                            if (oData.Tables.Count > 0)
                            {
                                DataTable dtInfo = oData.Tables[0];
                                DataTable dtDetalle = oData.Tables[1];
                                if (dtInfo != null)
                                {
                                    if (dtInfo.Rows.Count > 0)
                                    {
                                        DataRow oRowInfo = dtInfo.Rows[0];
                                        oActivoInfo.codigo      = oRowInfo["Codigo"]      == DBNull.Value ? null: oRowInfo["Codigo"].ToString();
                                        oActivoInfo.descripcion = oRowInfo["Descripcion"] == DBNull.Value ? null: oRowInfo["Descripcion"].ToString();
                                        oActivoInfo.custodio    = oRowInfo["Custodio"]    == DBNull.Value ? null: oRowInfo["Custodio"].ToString();
                                        oActivoInfo.costo       = oRowInfo["Costo"]       == DBNull.Value ? null: Convert.ToDecimal(oRowInfo["Costo"]);
                                        oActivoInfo.existencia  = oRowInfo["Existencia"]  == DBNull.Value ? null: Convert.ToInt32(oRowInfo["Existencia"]);
                                    }
                                }

                                if (dtDetalle != null)
                                {
                                    oActivoDetalle = (from DataRow dr in dtDetalle.Rows
                                                     select new ActivoFijoResponseDetalle()
                                                     {
                                                         codbodega  = dr["CodBodega"]  == DBNull.Value ? null : dr["CodBodega"].ToString(),
                                                         desbodega  = dr["DesBodega"]  == DBNull.Value ? null : dr["DesBodega"].ToString(),
                                                         existencia = dr["Existencia"] == DBNull.Value ? null : Convert.ToInt32(dr["Existencia"]),
                                                     }
                                                     ).ToList();
                                }
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
            return new ActivoFijoResponse() { respuesta = oResp, info = oActivoInfo, detalle = oActivoDetalle };
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
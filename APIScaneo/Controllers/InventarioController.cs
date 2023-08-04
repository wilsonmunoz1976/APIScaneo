using clsScaneo.Clases;
using clsScaneo.Entidades;
using Microsoft.AspNetCore.Mvc;
using NLog;
using System.Data;

namespace APIScaneo.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class InventarioController : ControllerBase
    {
        private static readonly Logger logger = LogManager.GetCurrentClassLogger();

        private readonly Inventario? Conectividad = null;

        public InventarioController()
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
                    Conectividad = new Inventario(myDb1ConnectionString);
                }
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message + "\r\n" + ex.StackTrace);
            }
        }

        [HttpPost("GetBodegas")]
        public Bodega GetBodegas()
        {
            List<BodegaDet> oBodegas = new();
            RespuestaEjecucion oResp = new();
            try
            {
                if (Conectividad != null)
                {
                    if (Conectividad != null)
                    {
                        DataTable oData = Conectividad.GetBodegas(ref oResp);
                        if (oData != null)
                        {
                            oBodegas = (from DataRow dr in oData.Rows
                                        select new BodegaDet()
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
                        oResp.Mensaje = "No esta instanciada la clase de Inventario";
                        logger.Error("No esta instanciada la clase de Inventario");
                    }
                }
                else
                {
                    oResp.Codigo = -2;
                    oResp.Mensaje = "No hay conectividad con la base de datos, solicite soporte";
                    logger.Error("No hay conectividad con la base de datos, solicite soporte");
                }
            }
            catch (Exception ex)
            {
                oResp.Codigo = -2;
                oResp.Mensaje = ex.Message;
                logger.Error(ex.GetType().FullName + " - " + ex.Message + "\r\n" + ex.StackTrace);
            }

            return new Bodega() { Respuesta = oResp, Detalle = oBodegas };
        }

        [HttpPost("GetInventario/{bodega}")]
        public InventarioCab GetInventario(string bodega)
        {
            List<InventarioDet> oInventario = new();
            RespuestaEjecucion? oResp = new();
            try
            {
                if (Conectividad != null)
                {
                    DataTable oData = Conectividad.GetInventario(bodega, ref oResp);
                    if (oData != null)
                    {
                        oInventario = (from DataRow dr in oData.Rows
                                       select new InventarioDet()
                                       {
                                           Codigo = dr["Codigo"].ToString(),
                                           Articulo = dr["Articulo"].ToString(),
                                           Existencia = Convert.ToDecimal(dr["Existencia"]),
                                           TomaFisica = Convert.ToDecimal(dr["TomaFisica"]),
                                           Diferencia = Convert.ToDecimal(dr["Diferencia"])
                                       }
                                         ).ToList();
                    }
                }
                else
                {
                    oResp = new()
                    {
                        Codigo = -2,
                        Mensaje = "No esta instanciada la clase de Inventario"
                    };
                    logger.Error("No esta instanciada la clase de Inventario");
                }
            } catch (Exception ex)
            {
                oResp.Codigo = -2;
                oResp.Mensaje = ex.Message;
                logger.Error(ex.Message + "\r\n" + ex.StackTrace);
            }
            return new InventarioCab() { Respuesta = oResp, Detalle = oInventario };
        }

        [HttpPost("GetInventario/{bodega}/{Codigo}")]
        public InventarioCab GetInventario(string codigo, string bodega="1")
        {
            List<InventarioDet> oInventario = new();
            RespuestaEjecucion oResp = new();
            try
            {
                if (Conectividad != null)
                {
                    DataTable oData = Conectividad.GetInventario(bodega, codigo, ref oResp);
                    if (oData != null)
                    {
                        oInventario = (from DataRow dr in oData.Rows
                                       select new InventarioDet()
                                       {
                                           Codigo = dr["Codigo"].ToString(),
                                           Articulo = dr["Articulo"].ToString(),
                                           Existencia = Convert.ToDecimal(dr["Existencia"]),
                                           TomaFisica = Convert.ToDecimal(dr["TomaFisica"]),
                                           Diferencia = Convert.ToDecimal(dr["Diferencia"])
                                       }
                                         ).ToList();
                    }
                }
                else
                {
                    oResp = new()
                    {
                        Codigo = -2,
                        Mensaje = "No esta instanciada la clase de Inventario"
                    };
                    logger.Error("No esta instanciada la clase de Inventario");
                }
            }
            catch (Exception ex)
            {
                oResp.Codigo = -2;
                oResp.Mensaje = ex.Message;
                logger.Error(ex.Message + "\r\n" + ex.StackTrace);

            }
            return new InventarioCab() { Respuesta = oResp, Detalle = oInventario };
        }

        [HttpPost("ActualizarInventario")]
        public RespuestaEjecucion ActualizarInventario([FromBody] InventarioReq oReq)
        {
            RespuestaEjecucion oResp = new();
            try
            {
                if (Conectividad != null)
                {
                    oResp = Conectividad.ActualizarInventario(oReq);
                }
                else
                {
                    oResp = new()
                    {
                        Codigo = -2,
                        Mensaje = "No esta instanciada la clase de Inventario"
                    };
                    logger.Error("No esta instanciada la clase de Inventario");
                }
            }
            catch (Exception ex)
            {
                oResp.Codigo = -2;
                oResp.Mensaje = ex.Message;
                logger.Error(ex.Message + "\r\n" + ex.StackTrace);
            }

            return oResp;
        }

    }
}
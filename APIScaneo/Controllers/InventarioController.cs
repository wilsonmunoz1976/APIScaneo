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
        public BodegaResponse GetBodegas(string usuario)
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
                            if (Conectividad != null)
                            {
                                DataTable oData = Conectividad.GetBodegas(usuario, ref oResp);
                                if (oData != null)
                                {
                                    oBodegas = (from DataRow dr in oData.Rows
                                                select new BodegaResponseDetalle()
                                                {
                                                    codigoBodega = dr["ci_bodega"]==DBNull.Value? null: dr["ci_bodega"].ToString(),
                                                    nombreBodega = dr["tx_nombrebodega"] == DBNull.Value ? null : dr["tx_nombrebodega"].ToString(),
                                                }
                                               ).ToList();
                                }
                            }
                            else
                            {
                                oResp.codigo = -2;
                                oResp.mensaje = "No esta instanciada la clase de Inventario";
                                logger.Error("No esta instanciada la clase de Inventario");
                            }
                        }
                        else
                        {
                            oResp.codigo = -2;
                            oResp.mensaje = "No hay conectividad con la base de datos, solicite soporte";
                            logger.Error("No hay conectividad con la base de datos, solicite soporte");
                        }
                    }
                    catch (Exception ex)
                    {
                        oResp.codigo = -2;
                        oResp.mensaje = ex.Message;
                        logger.Error(ex.GetType().FullName + " - " + ex.Message + "\r\n" + ex.StackTrace);
                    }
                }
            }
            return new BodegaResponse() { respuesta = oResp, detalle = oBodegas };
        }

        [HttpPost("GetInventario/{usuario}/{bodega}")]
        public InventarioResponse GetInventario(string usuario, string bodega)
        {
            List<InventarioDetalle> oInventario = new();
            RespuestaEjecucion? oResp = IsTokenValido();
            if (oResp != null)
            {
                if (oResp.codigo == 0)
                {
                    try
                    {
                        if (Conectividad != null)
                        {
                            DataTable oData = Conectividad.GetInventario(usuario, bodega, ref oResp);
                            if (oData != null)
                            {
                                oInventario = (from DataRow dr in oData.Rows
                                               select new InventarioDetalle()
                                               {
                                                   codigo = dr["codigo"] == DBNull.Value ? null : dr["codigo"].ToString(),
                                                   bodega = dr["bodega"] == DBNull.Value ? null : dr["bodega"].ToString(),
                                                   articulo = dr["articulo"] == DBNull.Value ? null : dr["articulo"].ToString(),
                                                   existencia = dr["existencia"] == DBNull.Value ? null : Convert.ToDouble(dr["existencia"]),
                                                   enConsignacion = dr["EnConsignacion"] == null ? null :   Convert.ToDouble(dr["EnConsignacion"]),
                                                   retapizandose = dr["Retapizandose"] == DBNull.Value ? null : Convert.ToDouble(dr["Retapizandose"]),
                                                   planillaPorCerrar = dr["PlanillaPorCerrar"]==DBNull.Value ?null:Convert.ToDouble(dr["PlanillaPorCerrar"]),
                                                   tomaFisica = dr["TomaFisica"]==DBNull.Value ? null: Convert.ToDouble(dr["TomaFisica"]),
                                                   diferencia = dr["Diferencia"]==DBNull.Value ? null: Convert.ToDouble(dr["Diferencia"]),
                                                   observacion = dr["Observacion"]==DBNull.Value ? null: dr["Observacion"].ToString(),
                                                   modificar = dr["Modificar"] == DBNull.Value ? null : dr["Modificar"].ToString()
                                               }
                                                 ).ToList();
                            }
                        }
                        else
                        {
                            oResp = new()
                            {
                                codigo = -2,
                                mensaje = "No esta instanciada la clase de Inventario"
                            };
                            logger.Error("No esta instanciada la clase de Inventario");
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
            return new InventarioResponse() { respuesta = oResp, detalle = oInventario };
        }

        [HttpPost("GetInventario/{usuario}/{bodega}/{codigo}")]
        public InventarioResponse GetInventario(string usuario, string codigo, string bodega="1")
        {
            List<InventarioDetalle> oInventario = new();
            RespuestaEjecucion? oResp = IsTokenValido();
            if (oResp != null)
            {
                if (oResp.codigo == 0)
                {
                    try
                    {
                        if (Conectividad != null)
                        {
                            DataTable oData = Conectividad.GetInventario(usuario, bodega, codigo, ref oResp);
                            if (oData != null)
                            {
                                oInventario = (from DataRow dr in oData.Rows
                                               select new InventarioDetalle()
                                               {
                                                   codigo = dr["Codigo"] == DBNull.Value ? null : dr["codigo"].ToString(),
                                                   bodega = dr["bodega"] == DBNull.Value ? null : dr["bodega"].ToString(),
                                                   articulo = dr["Articulo"]== DBNull.Value ? null: dr["articulo"].ToString(),
                                                   existencia = dr["Existencia"] == DBNull.Value ? null : Convert.ToDouble(dr["existencia"]),
                                                   enConsignacion = dr["EnConsignacion"] == DBNull.Value ? null : Convert.ToDouble(dr["EnConsignacion"]),
                                                   retapizandose = dr["Retapizandose"] == DBNull.Value ? null : Convert.ToDouble(dr["Retapizandose"]),
                                                   planillaPorCerrar = dr["PlanillaPorCerrar"] == DBNull.Value ? null : Convert.ToDouble(dr["PlanillaPorCerrar"]),
                                                   tomaFisica = dr["TomaFisica"] == DBNull.Value ? null : Convert.ToDouble(dr["TomaFisica"]),
                                                   diferencia = dr["Diferencia"] == DBNull.Value ? null : Convert.ToDouble(dr["Diferencia"]),
                                                   observacion = dr["Observacion"] == DBNull.Value ? null : dr["Observacion"].ToString(),
                                                   modificar = dr["Modificar"] == DBNull.Value ? null : dr["Modificar"].ToString()
                                               }
                                              ).ToList();
                            }
                        }
                        else
                        {
                            oResp = new()
                            {
                                codigo = -2,
                                mensaje = "No esta instanciada la clase de Inventario"
                            };
                            logger.Error("No esta instanciada la clase de Inventario");
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
            return new InventarioResponse() { respuesta = oResp, detalle = oInventario };
        }

        [HttpPost("ActualizarInventario")]
        public RespuestaEjecucion? ActualizarInventario([FromBody] InventarioRequest oReq)
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
                            oResp = Conectividad.ActualizarInventario(oReq);
                        }
                        else
                        {
                            oResp = new()
                            {
                                codigo = -2,
                                mensaje = "No esta instanciada la clase de Inventario"
                            };
                            logger.Error("No esta instanciada la clase de Inventario");
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
            return oResp;
        }

        [HttpPost("ConsultarPeriodoActivo/{bodega}/{tipoconsulta}")]
        public PeriodoActivoResponse ConsultarPeriodoActivo(string bodega, string tipoconsulta) 
        {
            PeriodoActivoResponseDetalle? oDetalle = new();
            RespuestaEjecucion? oResp = IsTokenValido();
            if (oResp != null)
            {
                if (oResp.codigo == 0)
                {
                    try
                    {
                        if (Conectividad != null)
                        {
                            DataTable oData = Conectividad.ConsultarPeriodoActivo(bodega, tipoconsulta, ref oResp);
                            if (oData != null)
                            {
                                if (oData.Rows.Count > 0)
                                {
                                    DataRow dr = oData.Rows[0];
                                    oDetalle = new()
                                    {
                                        anio = dr["anio"].ToString(),
                                        mes = dr["mes"].ToString(),
                                        secuencia = Convert.ToInt32(dr["secuencia"])
                                    };
                                }
                                    
                            }
                        }
                        else
                        {
                            oResp = new()
                            {
                                codigo = -2,
                                mensaje = "No esta instanciada la clase de Inventario"
                            };
                            logger.Error("No esta instanciada la clase de Inventario");
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
            return new PeriodoActivoResponse() {  
                respuesta = oResp, 
                detalle = oDetalle 
            };

        }

        [HttpPost("ConsultarConteoInventario")]
        public ConsultarConteoInventarioResponse ConsultarConteoInventario([FromBody] ConsultarConteoInventarioRequest oReq)
        {
            double iConteo = 0;
            double iCantidad = 0;
            RespuestaEjecucion? oResp = IsTokenValido();
            if (oResp != null)
            {
                if (oResp.codigo == 0)
                {
                    try
                    {
                        if (Conectividad != null)
                        {
                            DataTable oData = Conectividad.ConsultarConteoInventario(oReq, ref oResp);
                            if (oData != null)
                            {
                                if (oData.Rows.Count > 0)
                                {
                                    DataRow dr = oData.Rows[0];
                                    iConteo = Convert.ToDouble(dr["qn_conteo"]);
                                    iCantidad = Convert.ToDouble(dr["qn_cantidad"]);
                                }

                            }
                        }
                        else
                        {
                            oResp = new()
                            {
                                codigo = -2,
                                mensaje = "No esta instanciada la clase de Inventario"
                            };
                            logger.Error("No esta instanciada la clase de Inventario");
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
            return new ConsultarConteoInventarioResponse() { respuesta = oResp, conteo = iConteo, cantidad = iCantidad };

        }

        [HttpPost("IniciarConteoInventario")]
        public RespuestaEjecucion? IniciarConteoInventario([FromBody] ConsultarConteoInventarioRequest oReq)
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
                            Conectividad.IniciarConteoInventario(oReq, ref oResp);
                        }
                        else
                        {
                            oResp = new()
                            {
                                codigo = -2,
                                mensaje = "No esta instanciada la clase de Inventario"
                            };
                            logger.Error("No esta instanciada la clase de Inventario");
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
            return oResp;
        }


        [HttpPost("CerrarConteoInventario")]
        public RespuestaEjecucion? CerrarConteoInventario([FromBody] ConsultarConteoInventarioRequest oReq)
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
                            Conectividad.CerrarConteoInventario(oReq, ref oResp);
                        }
                        else
                        {
                            oResp = new()
                            {
                                codigo = -2,
                                mensaje = "No esta instanciada la clase de Inventario"
                            };
                            logger.Error("No esta instanciada la clase de Inventario");
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
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
                    oResp.Mensaje = "No esta instanciada la clase de CofresUrnas";
                    logger.Error("No esta instanciada la clase de CofresUrnas");
                }
            } catch (Exception ex)
            {
                oResp.Codigo = -2;
                oResp.Mensaje = ex.Message;
                logger.Error(ex.Message + "\r\n" + ex.StackTrace);
            }

            return new Bodega() { Respuesta = oResp, Detalle = oBodegas };
        }

        [HttpPost("GetCofresUrnas")]
        public CofreUrnaResp GetCofresUrnas()
        {
            List<CofreUrnaDet> oCofresUrnas = new();
            RespuestaEjecucion oResp = new();
            try
            {
                if (Conectividad != null)
                {
                    DataTable oData = Conectividad.GetCofresUrnas("009", 0, null, ref oResp);
                    if (oData != null)
                    {
                        oCofresUrnas = (from DataRow dr in oData.Rows
                                        select new CofreUrnaDet()
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
            return new CofreUrnaResp() { Respuesta = oResp, Detalle = oCofresUrnas };
        }

        [HttpPost("GetCofresUrnas/{bodega}")]
        public CofreUrnaResp GetCofresUrnas(string bodega, int? estado = 0, string? usuario = null)
        {
            List<CofreUrnaDet>? oActivosFijos = new();
            RespuestaEjecucion oResp = new();
            try
            {
                if (Conectividad != null)
                {
                    DataTable oData = Conectividad.GetCofresUrnas(bodega, estado, usuario, ref oResp);
                    if (oData != null)
                    {
                        oActivosFijos = (from DataRow dr in oData.Rows
                                         select new CofreUrnaDet()
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
            return new CofreUrnaResp() { Respuesta = oResp, Detalle = oActivosFijos };
        }

        [HttpPost("GetCofreUrna/{articulo}")]
        public CofreUrnaDatoResp GetCofreUrna(string? articulo)
        {
            CofreUrnaDato detalle = new();
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
            return new CofreUrnaDatoResp() { Respuesta = oResp, Detalle = detalle };
        }

        [HttpPost("GetSolEgreCofreUrna/{solicitudEgreso}")]
        public CofreUrnaResp GetSolEgreCofreUrna(int? solicitudEgreso, string? usuario = null)
        {
            List<CofreUrnaDet> oCofresUrnas = new();
            RespuestaEjecucion oResp = new();
            try
            {
                if (Conectividad != null)
                {
                    DataTable oData = Conectividad.GetSolEgreCofreUrna(solicitudEgreso, usuario, ref oResp);
                    if (oData != null)
                    {
                        oCofresUrnas = (from DataRow dr in oData.Rows
                                        select new CofreUrnaDet()
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
            return new CofreUrnaResp() { Respuesta = oResp, Detalle = oCofresUrnas };
        }

        [HttpPost("CambiaEstadoCofresUrnas")]
        public RespuestaEjecucion? CambiaEstadoCofresUrnas([FromBody] CofreUrnaReq cofresUrnasReq)
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
        public RespuestaEjecucion ReingresoCofresUrnas([FromBody] ReingresoCofreUrna reingresoCofreUrna)
        {
            RespuestaEjecucion oResp = new();

            try
            {
                if (Conectividad != null)
                {
                    oResp = Conectividad.ReingresoCofresUrnas(reingresoCofreUrna);
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
                oResp.Codigo = -2;
                oResp.Mensaje = ex.Message;
                logger.Error(ex.Message + "\r\n" + ex.StackTrace);
            }
            return oResp;
        }

    }
}
using Microsoft.Data.SqlClient;
using System.Data;
using clsScaneo.Entidades;
using NLog;

namespace clsScaneo.Clases
{
    public class Inventario
    {
        #region "Construccion"
        public SqlConnection oConnection = new();
        private static readonly Logger logger = LogManager.GetCurrentClassLogger();
        public Inventario(string? connectionString)
        {
            try
            {
                if (!string.IsNullOrEmpty(connectionString))
                {
                    oConnection.ConnectionString = connectionString;
                    oConnection.Open();
                }
            }
            catch (Exception ex)
            {
                logger.Error("Error instanciando clase Inventario: " + ex.Message + "\r\n" + ex.StackTrace);
            }
        }
        #endregion "Construccion"

        #region "Inventario"
        public DataTable GetBodegas(string usuario, ref RespuestaEjecucion oResp)
        {
            DataTable dt = new("tb0");
            try
            {
                SqlCommand cmd = oConnection.CreateCommand();
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.CommandText = "dbo.pr_Inventario";
                cmd.Parameters.Clear();
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_accion", SqlDbType = SqlDbType.VarChar, Size = 2, Value = "BO" });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_usuario", SqlDbType = SqlDbType.VarChar, Size = 15, Value = usuario });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.InputOutput, ParameterName = "@o_msgerror", SqlDbType = SqlDbType.VarChar, Size = 200 });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.ReturnValue, ParameterName = "@return_value", SqlDbType = SqlDbType.Int });

                dt.Load(cmd.ExecuteReader());
                oResp = new()
                {
                    codigo = Convert.ToInt16(cmd.Parameters["@return_value"].Value),
                    mensaje = Convert.ToString(cmd.Parameters["@o_msgerror"].Value)
                };
            }
            catch (Exception ex)
            {
                oResp = new()
                {
                    codigo = -9,
                    mensaje = ex.Message
                };
                logger.Error($"Error en la clase [{ex.GetType().Name}], metodo [{ex.GetType().FullName}" + "\r\n" + ex.StackTrace);
            }

            return dt;
        }

        public DataTable GetInventario(string Usuario, string? Bodega, ref RespuestaEjecucion oResp)
        {
            DataTable dt = new("tb0");
            try
            {
                SqlCommand cmd = oConnection.CreateCommand();
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.CommandText = "dbo.pr_Inventario";
                cmd.Parameters.Clear();
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_accion", SqlDbType = SqlDbType.VarChar, Size = 2, Value = "LI" });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_usuario", SqlDbType = SqlDbType.VarChar, Size = 15, Value = Usuario });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_bodega", SqlDbType = SqlDbType.VarChar, Size = 3, Value = Bodega });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.InputOutput, ParameterName = "@o_msgerror", SqlDbType = SqlDbType.VarChar, Size = 200 });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.ReturnValue, ParameterName = "@return_value", SqlDbType = SqlDbType.Int });
                dt.Load(cmd.ExecuteReader());

                oResp = new()
                {
                    codigo = Convert.ToInt16(cmd.Parameters["@return_value"].Value),
                    mensaje = Convert.ToString(cmd.Parameters["@o_msgerror"].Value)
                };
            }
            catch (Exception ex)
            {
                oResp = new()
                {
                    codigo = -9,
                    mensaje = ex.Message
                };
                logger.Error($"Error en la clase [{ex.GetType().Name}], metodo [{ex.GetType().FullName}" + "\r\n" + ex.StackTrace);
            }

            return dt;
        }

        public DataTable GetInventario(string Usuario, string Bodega, string Codigo, ref RespuestaEjecucion oResp)
        {
            DataTable dt = new("tb0");
            try
            {
                SqlCommand cmd = oConnection.CreateCommand();
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.CommandText = "dbo.pr_Inventario";
                cmd.Parameters.Clear();
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_accion", SqlDbType = SqlDbType.VarChar, Size = 2, Value = "CO" });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_usuario", SqlDbType = SqlDbType.VarChar, Size = 15, Value = Usuario });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_bodega", SqlDbType = SqlDbType.VarChar, Size = 3, Value = Bodega });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_codigo", SqlDbType = SqlDbType.VarChar, Size = 50, Value = Codigo });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.InputOutput, ParameterName = "@o_msgerror", SqlDbType = SqlDbType.VarChar, Size = 200 });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.ReturnValue, ParameterName = "@return_value", SqlDbType = SqlDbType.Int });
                dt.Load(cmd.ExecuteReader());

                oResp = new()
                {
                    codigo = Convert.ToInt16(cmd.Parameters["@return_value"].Value),
                    mensaje = Convert.ToString(cmd.Parameters["@o_msgerror"].Value)
                };
            }
            catch (Exception ex)
            {
                oResp = new()
                {
                    codigo = -9,
                    mensaje = ex.Message
                };
                logger.Error($"Error en la clase [{ex.GetType().Name}], metodo [{ex.GetType().FullName}" + "\r\n" + ex.StackTrace);
            }

            return dt;
        }

        public RespuestaEjecucion ActualizarInventario(InventarioRequest oReq)
        {
            RespuestaEjecucion? oResp;
            try
            {
                SqlCommand cmd = oConnection.CreateCommand();
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.CommandText = "dbo.pr_Inventario";
                cmd.Parameters.Clear();

                /*
                 *****************************************
                 * Ejemplo de XML a enviar:              *
                 *****************************************
                 <Inventario>
                   <Cabecera>
                      <usuario>WMUNOZ</usuario>
                      <anio>2023</anio>
                      <mes>07</mes>
                   </Cabecera>
                   <detalle>
                        <Conteo>
                            <articulo>C91</articulo>
                            <existencia>5</existencia>
                            <tomafisica>5</tomafisica>
                            <diferencia>0</diferencia>
                        </Conteo>
                        <Conteo>
                            <articulo>C92</articulo>
                            <existencia>3</existencia>
                            <tomafisica>2</tomafisica>
                            <diferencia>1</diferencia>
                        </Conteo>
                        <Conteo>
                            <articulo>C98</articulo>
                            <existencia>6</existencia>
                            <tomafisica>6</tomafisica>
                            <diferencia>0</diferencia>
                        </Conteo>
                   </detalle>
                </Inventario>
                *****************************************
                 */

                string DetalleXML = "";
                DetalleXML += "<Inventario>\r\n";
                DetalleXML += "   <Cabecera>\r\n";
                DetalleXML += "      <usuario>" + oReq.usuario + "</usuario>\r\n";
                DetalleXML += "      <anio>" + oReq.anio + "</anio>\r\n";
                DetalleXML += "      <mes>" + oReq.mes + "</mes>\r\n";
                DetalleXML += "   </Cabecera>\r\n";
                DetalleXML += "   <detalle>\r\n";
                if (oReq.detalle != null)
                {
                    foreach (InventarioDetalle? oDet in oReq.detalle)
                    {
                        DetalleXML += "       <Conteo>\r\n";
                        DetalleXML += "           <articulo>" + oDet.codigo + "</articulo>\r\n";
                        DetalleXML += "           <existencia>" + Convert.ToString(oDet.existencia) + "</existencia>\r\n";
                        DetalleXML += "           <tomafisica>" + Convert.ToString(oDet.tomaFisica) + "</tomafisica>\r\n";
                        DetalleXML += "           <diferencia>" + Convert.ToString(oDet.diferencia) + "</diferencia>\r\n";
                        DetalleXML += "           <retapizando>" + Convert.ToString(oDet.retapizandose) + "</retapizando>\r\n";
                        DetalleXML += "           <consignacion>" + Convert.ToString(oDet.enConsignacion) + "</consignacion>\r\n";
                        DetalleXML += "           <planillaxcerrar>" + Convert.ToString(oDet.planillaPorCerrar) + "</planillaxcerrar>\r\n";
                        DetalleXML += "           <observacion>" + oDet.observacion + "</observacion>\r\n";
                        DetalleXML += "       </Conteo>\r\n";
                    }
                }
                DetalleXML += "    </detalle>\r\n";
                DetalleXML += "</Inventario>\r\n";

                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_accion", SqlDbType = SqlDbType.VarChar, Size = 2, Value = "UP" });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_bodega", SqlDbType = SqlDbType.VarChar, Size = 3, Value = oReq.bodega });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_dataxml", SqlDbType = SqlDbType.Xml, Value = DetalleXML });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_usuario", SqlDbType = SqlDbType.VarChar, Size = 15, Value = oReq.usuario });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.InputOutput, ParameterName = "@o_msgerror", SqlDbType = SqlDbType.VarChar, Size = 200 });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.ReturnValue, ParameterName = "@return_value", SqlDbType = SqlDbType.Int });

                _ = cmd.ExecuteNonQuery();

                oResp = new()
                {
                    codigo = Convert.ToInt16(cmd.Parameters["@return_value"].Value),
                    mensaje = Convert.ToString(cmd.Parameters["@o_msgerror"].Value)
                };
            }
            catch (Exception ex)
            {
                oResp = new()
                {
                    codigo = -9,
                    mensaje = ex.Message
                };
                logger.Error($"Error en la clase [{ex.GetType().Name}], metodo [{ex.GetType().FullName}" + "\r\n" + ex.StackTrace);
            }

            return oResp;
        }

        #endregion "Inventario"

    }
}
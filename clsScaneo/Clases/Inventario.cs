﻿using Microsoft.Data.SqlClient;
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
        public DataTable GetBodegas(ref RespuestaEjecucion oResp)
        {
            DataTable dt = new("tb0");
            try
            {
                SqlCommand cmd = oConnection.CreateCommand();
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.CommandText = "dbo.pr_Inventario";
                cmd.Parameters.Clear();
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_accion", SqlDbType = SqlDbType.VarChar, Size = 2, Value = "BO" });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.InputOutput, ParameterName = "@o_msgerror", SqlDbType = SqlDbType.VarChar, Size = 200 });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.ReturnValue, ParameterName = "@return_value", SqlDbType = SqlDbType.Int });

                dt.Load(cmd.ExecuteReader());
                oResp = new()
                {
                    Codigo = Convert.ToInt16(cmd.Parameters["@return_value"].Value),
                    Mensaje = Convert.ToString(cmd.Parameters["@o_msgerror"].Value)
                };
            }
            catch (Exception ex)
            {
                oResp = new()
                {
                    Codigo = -9,
                    Mensaje = ex.Message
                };
                logger.Error($"Error en la clase [{ex.GetType().Name}], metodo [{ex.GetType().FullName}" + "\r\n" + ex.StackTrace);
            }

            return dt;
        }

        public DataTable GetInventario(string? Bodega, ref RespuestaEjecucion oResp)
        {
            DataTable dt = new("tb0");
            try
            {
                SqlCommand cmd = oConnection.CreateCommand();
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.CommandText = "dbo.pr_Inventario";
                cmd.Parameters.Clear();
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_accion", SqlDbType = SqlDbType.VarChar, Size = 2, Value = "LI" });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_bodega", SqlDbType = SqlDbType.VarChar, Size = 3, Value = Bodega });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.InputOutput, ParameterName = "@o_msgerror", SqlDbType = SqlDbType.VarChar, Size = 200 });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.ReturnValue, ParameterName = "@return_value", SqlDbType = SqlDbType.Int });
                dt.Load(cmd.ExecuteReader());

                oResp = new()
                {
                    Codigo = Convert.ToInt16(cmd.Parameters["@return_value"].Value),
                    Mensaje = Convert.ToString(cmd.Parameters["@o_msgerror"].Value)
                };
            }
            catch (Exception ex)
            {
                oResp = new()
                {
                    Codigo = -9,
                    Mensaje = ex.Message
                };
                logger.Error($"Error en la clase [{ex.GetType().Name}], metodo [{ex.GetType().FullName}" + "\r\n" + ex.StackTrace);
            }

            return dt;
        }

        public DataTable GetInventario(string Bodega, string Codigo, ref RespuestaEjecucion oResp)
        {
            DataTable dt = new("tb0");
            try
            {
                SqlCommand cmd = oConnection.CreateCommand();
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.CommandText = "dbo.pr_Inventario";
                cmd.Parameters.Clear();
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_accion", SqlDbType = SqlDbType.VarChar, Size = 2, Value = "CO" });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_bodega", SqlDbType = SqlDbType.VarChar, Size = 3, Value = Bodega });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_codigo", SqlDbType = SqlDbType.VarChar, Size = 50, Value = Codigo });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.InputOutput, ParameterName = "@o_msgerror", SqlDbType = SqlDbType.VarChar, Size = 200 });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.ReturnValue, ParameterName = "@return_value", SqlDbType = SqlDbType.Int });
                dt.Load(cmd.ExecuteReader());

                oResp = new()
                {
                    Codigo = Convert.ToInt16(cmd.Parameters["@return_value"].Value),
                    Mensaje = Convert.ToString(cmd.Parameters["@o_msgerror"].Value)
                };
            }
            catch (Exception ex)
            {
                oResp = new()
                {
                    Codigo = -9,
                    Mensaje = ex.Message
                };
                logger.Error($"Error en la clase [{ex.GetType().Name}], metodo [{ex.GetType().FullName}" + "\r\n" + ex.StackTrace);
            }

            return dt;
        }

        public RespuestaEjecucion ActualizarInventario(InventarioReq oReq)
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
                   <Detalle>
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
                   </Detalle>
                </Inventario>
                *****************************************
                 */

                string DetalleXML = "";
                DetalleXML += "<Inventario>\r\n";
                DetalleXML += "   <Cabecera>\r\n";
                DetalleXML += "      <usuario>" + oReq.Usuario + "</usuario>\r\n";
                DetalleXML += "      <anio>" + oReq.Anio + "</anio>\r\n";
                DetalleXML += "      <mes>" + oReq.Mes + "</mes>\r\n";
                DetalleXML += "   </Cabecera>\r\n";
                DetalleXML += "   <Detalle>\r\n";
                if (oReq.Detalle != null)
                {
                    foreach (InventarioDet? oDet in oReq.Detalle)
                    {
                        DetalleXML += "       <Conteo>\r\n";
                        DetalleXML += "           <articulo>" + oDet.Articulo + "</articulo>\r\n";
                        DetalleXML += "           <existencia>" + Convert.ToString(oDet.Existencia) + "</existencia>\r\n";
                        DetalleXML += "           <tomafisica>" + Convert.ToString(oDet.TomaFisica) + "</tomafisica>\r\n";
                        DetalleXML += "           <diferencia>" + Convert.ToString(oDet.Diferencia) + "</diferencia>\r\n";
                        DetalleXML += "       </Conteo>\r\n";
                    }
                }
                DetalleXML += "    </Detalle>\r\n";
                DetalleXML += "</Inventario>\r\n";

                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_accion", SqlDbType = SqlDbType.VarChar, Size = 2, Value = "UP" });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_bodega", SqlDbType = SqlDbType.VarChar, Size = 3, Value = oReq.Bodega });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.Input, ParameterName = "@i_dataxml", SqlDbType = SqlDbType.Xml, Value = DetalleXML });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.InputOutput, ParameterName = "@o_msgerror", SqlDbType = SqlDbType.VarChar, Size = 200 });
                cmd.Parameters.Add(new SqlParameter() { Direction = ParameterDirection.ReturnValue, ParameterName = "@return_value", SqlDbType = SqlDbType.Int });

                _ = cmd.ExecuteNonQuery();

                oResp = new()
                {
                    Codigo = Convert.ToInt16(cmd.Parameters["@return_value"].Value),
                    Mensaje = Convert.ToString(cmd.Parameters["@o_msgerror"].Value)
                };
            }
            catch (Exception ex)
            {
                oResp = new()
                {
                    Codigo = -9,
                    Mensaje = ex.Message
                };
                logger.Error($"Error en la clase [{ex.GetType().Name}], metodo [{ex.GetType().FullName}" + "\r\n" + ex.StackTrace);
            }

            return oResp;
        }

        #endregion "Inventario"

    }
}
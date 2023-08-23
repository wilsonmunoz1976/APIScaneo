using APIScaneo.Authorization;
using clsScaneo.Clases;
using clsScaneo.Entidades;
using Microsoft.AspNetCore.Mvc;
using NLog;
using System.Data;
using System.Net;

namespace APIScaneo.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class LoginController : ControllerBase
    {

        private static readonly Logger logger = LogManager.GetCurrentClassLogger();
        private readonly ILoginUser? _loginUser;

        private readonly Seguridad? Conectividad = null;

        public LoginController(ILoginUser loginUser)
        {
            try
            {
                IConfigurationRoot configuration = new ConfigurationBuilder()
                .SetBasePath(AppDomain.CurrentDomain.BaseDirectory)
                .AddJsonFile("appsettings.json")
                .Build();

                _loginUser = loginUser;

                string? myDb1ConnectionString = configuration.GetConnectionString("DefaultConnection");

                if (myDb1ConnectionString != null)
                {
                    Conectividad = new Seguridad(myDb1ConnectionString);
                }
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message + "\r\n" + ex.StackTrace);
            }
        }

        [AllowAnonymous]
        [HttpPost("LoginApp")]
        public LoginResponse LoginApp([FromBody] LoginRequest oReq)
        {
            List<LoginResponsePermiso> oPermiso = new();
            List<LoginResponseParametro> oParametro = new();
            LoginResponseInfoUsuario oDato = new();
            string sToken = string.Empty;
            RespuestaEjecucion oResp = new();
            try
            {
                if (Conectividad != null)
                {
                    DataSet oData = Conectividad.LoginApp(Usuario: oReq.usuario, Password: oReq.password, ref oResp);
                    if (oData.Tables.Count > 0)
                    {
                        DataTable tbPermisos = oData.Tables[0];
                        DataTable tbParametros = oData.Tables[1];
                        DataTable tbDatos = oData.Tables[2];

                        if (tbPermisos != null)
                        {
                            oPermiso = (from DataRow dr in tbPermisos.Rows
                                        select new LoginResponsePermiso()
                                        {
                                            codigoModulo = dr["cod_modulo"]==DBNull.Value? null: dr["cod_modulo"].ToString(),
                                            descripcionModulo = dr["des_modulo"] == DBNull.Value ? null : dr["des_modulo"].ToString(),
                                            codigoOpcion = dr["cod_opcion"] == DBNull.Value ? null : dr["cod_opcion"].ToString(),
                                            numeroOpcion = dr["num_opcion"] == DBNull.Value ? null: Convert.ToUInt16(dr["num_opcion"]),
                                            descripcionOpcion = dr["des_opcion"] == DBNull.Value ? null : dr["des_opcion"].ToString(),
                                            permisos = dr["permisos"] == DBNull.Value ? null : dr["permisos"].ToString()
                                        }
                                        ).ToList();
                        }

                        if (tbParametros != null)
                        {
                            oParametro = (from DataRow dr in tbParametros.Rows
                                          select new LoginResponseParametro()
                                          {
                                              nombreParametro = dr["nom_parametro"]==DBNull.Value? null: dr["nom_parametro"].ToString(),
                                              valorParametro = dr["val_parametro"] == DBNull.Value ? null : dr["val_parametro"].ToString(),
                                              descripcionParametro = dr["des_parametro"] == DBNull.Value ? null : dr["des_parametro"].ToString()
                                          }
                                        ).ToList();
                        }

                        if (tbDatos != null)
                        {
                            DataRow dr = tbDatos.Rows[0];
                            oDato = new()
                            {
                                id = dr["id"]==DBNull.Value? 0: Convert.ToInt32(dr["id"]),
                                nombres = dr["nombres"] == DBNull.Value ? null : dr["nombres"].ToString(),
                                username = oReq.usuario,
                                password = oReq.password
                            };

                            if (_loginUser != null)
                            {
                                sToken = _loginUser.TokenLogin(Convert.ToInt32(dr["id"]), dr["nombres"].ToString(), oReq.usuario, oReq.password);
                            }

                        }

                    }
                    else
                    {
                        oResp.codigo = oResp.codigo;
                        oResp.mensaje = oResp.mensaje;
                        logger.Error(oResp.mensaje);
                    }
                }
            }
            catch (Exception ex)
            {
                oResp.codigo = -2;
                oResp.mensaje = ex.Message;
                logger.Error(ex.Message + "\r\n" + ex.StackTrace);
            }
            return new LoginResponse() { respuesta = oResp, parametro = oParametro, permiso = oPermiso, loginDato = oDato, token = sToken };
        }
    }
}
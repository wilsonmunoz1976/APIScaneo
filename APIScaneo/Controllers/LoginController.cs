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
                    DataSet oData = Conectividad.LoginApp(Usuario: oReq.Usuario, Password: oReq.Password, ref oResp);
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
                                            CodigoModulo = dr["cod_modulo"].ToString(),
                                            DescripcionModulo = dr["des_modulo"].ToString(),
                                            CodigoOpcion = dr["cod_opcion"].ToString(),
                                            NumeroOpcion = Convert.ToUInt16(dr["num_opcion"]),
                                            DescripcionOpcion = dr["des_opcion"].ToString(),
                                            Permisos = dr["permisos"].ToString()
                                        }
                                        ).ToList();
                        }

                        if (tbParametros != null)
                        {
                            oParametro = (from DataRow dr in tbParametros.Rows
                                          select new LoginResponseParametro()
                                          {
                                              NombreParametro = dr["nom_parametro"].ToString(),
                                              ValorParametro = dr["val_parametro"].ToString(),
                                              DescripcionParametro = dr["des_parametro"].ToString()
                                          }
                                        ).ToList();
                        }

                        if (tbDatos != null)
                        {
                            DataRow dr = tbDatos.Rows[0];
                            oDato = new()
                            {
                                Id = Convert.ToInt32(dr["Id"]),
                                Nombres = dr["Nombres"].ToString(),
                                Username = oReq.Usuario,
                                Password = oReq.Password
                            };

                            if (_loginUser != null)
                            {
                                sToken = _loginUser.TokenLogin(Convert.ToInt32(dr["Id"]), dr["Nombres"].ToString(), oReq.Usuario, oReq.Password);
                            }

                        }

                    }
                    else
                    {
                        oResp.Codigo = oResp.Codigo;
                        oResp.Mensaje = oResp.Mensaje;
                        logger.Error(oResp.Mensaje);
                    }
                }
            }
            catch (Exception ex)
            {
                oResp.Codigo = -2;
                oResp.Mensaje = ex.Message;
                logger.Error(ex.Message + "\r\n" + ex.StackTrace);
            }
            return new LoginResponse() { Respuesta = oResp, Parametro = oParametro, Permiso = oPermiso, LoginDato = oDato, Token = sToken };
        }
    }
}
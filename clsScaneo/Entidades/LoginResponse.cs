using Azure.Core;
using clsScaneo.Entidades;

namespace clsScaneo.Entidades
{
    public class LoginResponse
    {
        public RespuestaEjecucion? respuesta { get; set; } = null;
        public List<LoginResponseParametro>? parametro  { get; set; } = null;
        public List<LoginResponsePermiso>? permiso { get; set; } = null;
        public LoginResponseInfoUsuario? loginDato { get; set; } = null;
        public string? token { get; set; } = string.Empty;
    }
}
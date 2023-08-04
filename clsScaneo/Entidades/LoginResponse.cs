using Azure.Core;
using clsScaneo.Entidades;

namespace clsScaneo.Entidades
{
    public class LoginResponse
    {
        public RespuestaEjecucion? Respuesta { get; set; } = null;
        public List<LoginResponseParametro>? Parametro  { get; set; } = null;
        public List<LoginResponsePermiso>? Permiso { get; set; } = null;
        public LoginResponseInfoUsuario? LoginDato { get; set; } = null;
        public string? Token { get; set; } = string.Empty;
    }
}
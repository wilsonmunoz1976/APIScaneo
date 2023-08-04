using Azure.Core;
using clsScaneo.Entidades;

namespace clsScaneo.Entidades
{
    public class LoginResp
    {
        public RespuestaEjecucion? Respuesta { get; set; } = null;
        public List<LoginParam>? Parametro  { get; set; } = null;
        public List<LoginPermiso>? Permiso { get; set; } = null;
        public LoginDato? LoginDato { get; set; } = null;
        public string? Token { get; set; } = string.Empty;
    }
}
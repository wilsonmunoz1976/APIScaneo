using clsScaneo.Entidades;

namespace clsScaneo.Entidades
{
    public class Empresa
    {
        public RespuestaEjecucion? Respuesta { get; set; }
        public List<EmpresaDet>? Detalle { get; set; }
    }
}
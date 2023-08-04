using clsScaneo.Entidades;

namespace clsScaneo.Entidades
{
    public class CofreUrnaResp
    {
        public RespuestaEjecucion? Respuesta { get; set; }
        public List<CofreUrnaDet>? Detalle { get; set; }
    }
}
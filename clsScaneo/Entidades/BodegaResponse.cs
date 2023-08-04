using clsScaneo.Entidades;

namespace clsScaneo.Entidades
{
    public class BodegaResponse
    {
        public RespuestaEjecucion? Respuesta { get; set; }
        public List<BodegaResponseDetalle>? Detalle { get; set; }
    }
}
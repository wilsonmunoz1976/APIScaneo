using clsScaneo.Entidades;

namespace clsScaneo.Entidades
{
    public class BodegaResponse
    {
        public RespuestaEjecucion? respuesta { get; set; }
        public List<BodegaResponseDetalle>? detalle { get; set; }
    }
}
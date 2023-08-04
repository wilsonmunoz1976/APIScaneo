using clsScaneo.Entidades;

namespace clsScaneo.Entidades
{
    public class Bodega
    {
        public RespuestaEjecucion? Respuesta { get; set; }
        public List<BodegaDet>? Detalle { get; set; }
    }
}
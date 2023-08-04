using clsScaneo.Entidades;

namespace clsScaneo.Entidades
{
    public class ActivoFijo
    {
        public RespuestaEjecucion? Respuesta { get; set; }
        public List<ActivoFijoDet>? Detalle { get; set; }
    }
}
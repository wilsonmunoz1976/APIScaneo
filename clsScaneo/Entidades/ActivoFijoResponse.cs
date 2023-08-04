using clsScaneo.Entidades;

namespace clsScaneo.Entidades
{
    public class ActivoFijoResponse
    {
        public RespuestaEjecucion? Respuesta { get; set; }
        public List<ActivoFijoResponseDetalle>? Detalle { get; set; }
    }
}
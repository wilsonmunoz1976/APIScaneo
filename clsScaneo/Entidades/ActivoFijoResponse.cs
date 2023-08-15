using clsScaneo.Entidades;

namespace clsScaneo.Entidades
{
    public class ActivoFijoResponse
    {
        public RespuestaEjecucion? respuesta { get; set; }
        public List<ActivoFijoResponseDetalle>? detalle { get; set; }
    }
}
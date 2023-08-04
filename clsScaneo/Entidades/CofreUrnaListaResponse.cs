using clsScaneo.Entidades;

namespace clsScaneo.Entidades
{
    public class CofreUrnaListaResponse
    {
        public RespuestaEjecucion? Respuesta { get; set; }
        public List<CofreUrnaListaResponseDetalle>? Detalle { get; set; }
    }
}
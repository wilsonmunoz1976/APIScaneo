using clsScaneo.Entidades;

namespace clsScaneo.Entidades
{
    public class CofreUrnaListaResponse
    {
        public RespuestaEjecucion? respuesta { get; set; }
        public List<CofreUrnaListaResponseDetalle>? detalle { get; set; }
    }
}
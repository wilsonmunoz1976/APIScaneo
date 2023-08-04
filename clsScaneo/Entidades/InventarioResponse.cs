namespace clsScaneo.Entidades
{
    public class InventarioResponse
    {
        public RespuestaEjecucion? Respuesta { get; set; }
        public List<InventarioDetalle>? Detalle { get; set; }
    }
}
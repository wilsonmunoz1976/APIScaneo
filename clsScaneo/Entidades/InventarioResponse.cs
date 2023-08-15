namespace clsScaneo.Entidades
{
    public class InventarioResponse
    {
        public RespuestaEjecucion? respuesta { get; set; }
        public List<InventarioDetalle>? detalle { get; set; }
    }
}
namespace clsScaneo.Entidades
{
    public class ConsultarConteoInventarioResponse
    {
        public RespuestaEjecucion? respuesta { get; set; } = null;
        public double? conteo { get; set; } = 0;
        public double? cantidad { get; set; } = 0;
    }
}
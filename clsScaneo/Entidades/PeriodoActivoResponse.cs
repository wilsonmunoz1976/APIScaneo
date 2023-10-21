namespace clsScaneo.Entidades
{
    public class PeriodoActivoResponse
    {
        public RespuestaEjecucion? respuesta { get; set; } = null;
        public PeriodoActivoResponseDetalle? detalle { get; set; } = null;
    }
}
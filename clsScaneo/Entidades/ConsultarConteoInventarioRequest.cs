namespace clsScaneo.Entidades
{
    public class ConsultarConteoInventarioRequest
    {
        public string? anio { get; set; } = string.Empty;
        public string? mes { get; set; } = string.Empty;
        public string? bodega { get; set; } = string.Empty;
        public string? usuario { get; set; } = string.Empty;
        public int? secuencia { get; set; } = 0;
        public string forzar { get; set; } = string.Empty;
    }
}
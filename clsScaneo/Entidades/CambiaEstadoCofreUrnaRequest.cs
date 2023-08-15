namespace clsScaneo.Entidades
{
    public class CambiaEstadoCofreUrnaRequest
    {
        public string? bodega { get; set; } = string.Empty;
        public int? codigo { get; set; } = 0;
        public int? estado { get; set; } = 0;
        public string? comentario { get; set; } = string.Empty;
        public string? fotografia { get; set; } = string.Empty;
        public string? usuario { get; set; } = string.Empty;
    }
}
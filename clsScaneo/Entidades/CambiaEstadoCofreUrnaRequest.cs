namespace clsScaneo.Entidades
{
    public class CambiaEstadoCofreUrnaRequest
    {
        public string? Bodega { get; set; } = string.Empty;
        public int? Codigo { get; set; } = 0;
        public int? Estado { get; set; } = 0;
        public string? Comentario { get; set; } = string.Empty;
        public string? Fotografia { get; set; } = string.Empty;
        public string? Usuario { get; set; } = string.Empty;
    }
}
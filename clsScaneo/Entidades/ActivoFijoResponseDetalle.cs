namespace clsScaneo.Entidades
{
    public class ActivoFijoResponseDetalle
    {
        public string? codigo { get; set; } = string.Empty;
        public string? activo { get; set; } = string.Empty;
        public string? custodio { get; set; } = string.Empty;
        public decimal? costo { get; set; } = decimal.Zero;
        public int? existencia { get; set; } = 0;
    }
}
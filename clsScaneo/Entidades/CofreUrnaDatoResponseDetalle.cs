namespace clsScaneo.Entidades
{
    public class CofreUrnaDatoResponseDetalle
    {
        public string? codArticulo { get; set; } = string.Empty;
        public string? desArticulo { get; set; } = string.Empty;
        public string? codBodega { get; set; } = string.Empty;
        public string? desBodega { get; set; } = string.Empty;
        public decimal? precio { get; set; } = decimal.Zero;
        public decimal? existencia { get; set; } = decimal.Zero;
    }
}
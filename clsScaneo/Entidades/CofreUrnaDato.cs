namespace clsScaneo.Entidades
{
    public class CofreUrnaDato
    {
        public string? CodArticulo { get; set; } = string.Empty;
        public string? DesArticulo { get; set; } = string.Empty;
        public string? CodBodega { get; set; } = string.Empty;
        public string? DesBodega { get; set; } = string.Empty;
        public decimal? Precio { get; set; } = decimal.Zero;
        public decimal? Existencia { get; set; } = decimal.Zero;
    }
}
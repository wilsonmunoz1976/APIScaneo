namespace clsScaneo.Entidades
{
    public class CofreUrnaDatoResponseDetalle
    {
        public string? CodArticulo { get; set; } = string.Empty;
        public string? DesArticulo { get; set; } = string.Empty;
        public string? CodBodega { get; set; } = string.Empty;
        public string? DesBodega { get; set; } = string.Empty;
        public decimal? Precio { get; set; } = decimal.Zero;
        public decimal? Existencia { get; set; } = decimal.Zero;
    }
}
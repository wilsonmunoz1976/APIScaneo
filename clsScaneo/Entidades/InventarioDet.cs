namespace clsScaneo.Entidades
{
    public class InventarioDet
    {
        public string? Codigo { get; set; } = "I0000099999";
        public string? Articulo { get; set; } = "C100";
        public decimal? Existencia { get; set; } = 0;
        public decimal? TomaFisica { get; set; } = 0;
        public decimal? Diferencia { get; set; } = 0;
    }
}
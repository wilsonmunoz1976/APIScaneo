namespace clsScaneo.Entidades
{
    public class InventarioDetalle
    {
        public string? codigo { get; set; } = string.Empty;
        public string? bodega { get; set; } = string.Empty;
        public string? articulo { get; set; } = string.Empty;
        public double? existencia { get; set; } = 0;
        public double? enConsignacion { get; set; } = 0;
        public double? retapizandose { get; set; } = 0;
        public double? planillaPorCerrar { get; set; } = 0;
        public double? tomaFisica { get; set; } = 0;
        public double? diferencia { get; set; } = 0;
        public string? observacion { get; set; } = string.Empty;
        public string? modificar { get; set; } = string.Empty;
        public int anchocolumna0 { get; set; } = 0;
        public int anchocolumna9 { get; set; } = 0;

    }
}
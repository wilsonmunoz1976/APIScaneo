namespace clsScaneo.Entidades
{
    public class InventarioReq
    {
        public string? Anio { get; set; } = DateTime.Now.Year.ToString();
        public string? Mes { get; set; } = DateTime.Now.Month.ToString("00");
        public string? Bodega { get; set; } = "009";
        public string? Usuario { get; set; } = "ADMINISTRADOR";
        public List<InventarioDet>? Detalle { get; set; }
    }
}
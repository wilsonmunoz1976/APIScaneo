using System.ComponentModel.DataAnnotations;

namespace clsScaneo.Entidades
{
    public class InventarioRequest
    {
        [Required]
        public string? Anio { get; set; } = DateTime.Now.Year.ToString();
        [Required]
        public string? Mes { get; set; } = DateTime.Now.Month.ToString("00");
        [Required]
        public string? Bodega { get; set; } = string.Empty;
        public string? Usuario { get; set; } = string.Empty;
        [Required]
        public List<InventarioDetalle>? Detalle { get; set; } = null;
    }
}
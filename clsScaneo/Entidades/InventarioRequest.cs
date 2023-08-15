using System.ComponentModel.DataAnnotations;

namespace clsScaneo.Entidades
{
    public class InventarioRequest
    {
        [Required]
        public string? anio { get; set; } = DateTime.Now.Year.ToString();
        [Required]
        public string? mes { get; set; } = DateTime.Now.Month.ToString("00");
        [Required]
        public string? bodega { get; set; } = string.Empty;
        public string? usuario { get; set; } = string.Empty;
        [Required]
        public List<InventarioDetalle>? detalle { get; set; } = null;
    }
}
using System.ComponentModel.DataAnnotations;

namespace clsScaneo.Entidades
{
    public class ReasignacionRequest
    {
        [Required]
        public string? usuario { get; set; } = string.Empty;
        [Required]
        public string? usuarionuevo { get; set; } = string.Empty;
        [Required]
        public int? codigosolegre { get; set; } = 0;
    }
}
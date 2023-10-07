using System.ComponentModel.DataAnnotations;

namespace clsScaneo.Entidades
{
    public class LoginRequest
    {
        [Required]
        public string? usuario  { get; set; }
        [Required]
        public string? password { get; set; }
        public string? version { get; set; }
    }
}
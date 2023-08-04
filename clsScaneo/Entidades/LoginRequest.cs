using System.ComponentModel.DataAnnotations;

namespace clsScaneo.Entidades
{
    public class LoginRequest
    {
        [Required]
        public string? Usuario  { get; set; }
        [Required]
        public string? Password { get; set; }
    }
}
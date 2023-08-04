using clsScaneo.Entidades;
using System.Text.Json.Serialization;

namespace clsScaneo.Entidades
{
    public class LoginResponseInfoUsuario
    {
        public int Id { get; set; }
        public string? Nombres { get; set; }
        public string? Username { get; set; }

        [JsonIgnore]
        public string? Password { get; set; }
    }
}

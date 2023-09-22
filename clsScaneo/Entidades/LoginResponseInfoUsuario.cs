using clsScaneo.Entidades;
using System.Text.Json.Serialization;

namespace clsScaneo.Entidades
{
    public class LoginResponseInfoUsuario
    {
        public int id { get; set; } = 0;
        public string? nombres { get; set; }
        public string? username { get; set; }
        public string? email { get; set; }

        [JsonIgnore]
        public string? password { get; set; }
    }
}

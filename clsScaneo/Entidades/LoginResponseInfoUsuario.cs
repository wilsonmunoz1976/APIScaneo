using clsScaneo.Entidades;
using System.Text.Json.Serialization;

namespace clsScaneo.Entidades
{
    public class LoginResponseInfoUsuario
    {
        public int? id { get; set; }
        public string? nombres { get; set; }
        public string? username { get; set; }

        [JsonIgnore]
        public string? password { get; set; }
    }
}

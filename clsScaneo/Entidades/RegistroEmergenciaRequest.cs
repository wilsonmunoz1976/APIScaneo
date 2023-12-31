namespace clsScaneo.Entidades
{
    public class RegistroEmergenciaRequest
    {
        public string nombres { get; set; } = "";
        public string articulo { get; set; } = "";
        public string bodega { get; set; } = "";
        public string usuario { get; set; } = "";
        public string? email { get; set; } = "";
        public bool? tipogestion { get; set; }
        public bool? tipoingreso { get; set; }
    }
}
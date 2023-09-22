namespace clsScaneo.Entidades
{
    public class ReingresoCofreUrnaRequest
    {
        public int? codSolicitudEgreso { get; set; } = null;
        public string? codCofreUrnaNuevo { get; set; } = string.Empty;
        public string? usuario { get; set; } = string.Empty;
        public string? email { get; set; } = string.Empty;
    }
}
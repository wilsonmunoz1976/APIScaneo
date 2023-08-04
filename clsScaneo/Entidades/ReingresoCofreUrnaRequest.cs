namespace clsScaneo.Entidades
{
    public class ReingresoCofreUrnaRequest
    {
        public int? CodSolicitudEgreso { get; set; } = null;
        public string? CodCofreUrnaNuevo { get; set; } = string.Empty;
        public string? Usuario { get; set; } = string.Empty;
    }
}
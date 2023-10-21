namespace clsScaneo.Entidades
{
    public class ReingresoCofreUrnaRequest
    {
        public int? codSolicitudEgreso { get; set; } = null;
        public string? codCofreUrnaNuevo { get; set; } = string.Empty;
        public bool? retapizado { get; set; } = false;
        public string? bodega { get; set; } = string.Empty;
        public string? usuario { get; set; } = string.Empty;
        public int? estado { get; set; } = 0;
        public string? email { get; set; } = string.Empty;
        public string? factura { get; set; } = string.Empty;
        public string? nombrelimpieza { get; set; } = string.Empty;
        public string? observacion { get; set; } = string.Empty;
    }
}
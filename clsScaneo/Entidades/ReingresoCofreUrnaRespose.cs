namespace clsScaneo.Entidades
{
    public class ReingresoCofreUrnaRespose
    {
        public string? codArticuloOrigen { get; set; } = string.Empty;
        public string? desArticuloOrigen { get; set; } = string.Empty;
        public string? codArticuloDestino { get; set; } = string.Empty;
        public string? desArticuloDestino { get; set; } = string.Empty;
        public string? codPlanilla { get; set; } = string.Empty;
        public int? codSoliEgre { get; set; } = null;
        public string? nombreFallecido { get; set; } = string.Empty;
        public string? usuario { get; set; } = string.Empty;
        public string? codBodega { get; set; } = string.Empty;
        public string? desBodega { get; set; } = string.Empty;
    }
}
namespace clsScaneo.Entidades
{
    public class ReingresoCofreDato
    {
        public string? CodArticuloOrigen { get; set; } = string.Empty;
        public string? DesArticuloOrigen { get; set; } = string.Empty;
        public string? CodArticuloDestino { get; set; } = string.Empty;
        public string? DesArticuloDestino { get; set; } = string.Empty;
        public string? CodPlanilla { get; set; } = string.Empty;
        public int? CodSoliEgre { get; set; } = null;
        public string? NombreFallecido { get; set; } = string.Empty;
        public string? Usuario { get; set; } = string.Empty;
    }
}
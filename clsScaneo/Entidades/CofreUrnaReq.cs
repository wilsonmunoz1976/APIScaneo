namespace clsScaneo.Entidades
{
    public class CofreUrnaReq
    {
        public string? Bodega { get; set; } = "009";
        public int? Codigo { get; set; }
        public int? Estado { get; set; } = 0;
        public string? Comentario { get; set; }
        public string? Fotografia { get; set; }
        public string? Usuario { get; set; }
    }
}
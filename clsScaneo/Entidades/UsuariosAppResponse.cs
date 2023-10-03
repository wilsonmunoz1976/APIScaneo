namespace clsScaneo.Entidades
{
    public class UsuariosAppResponse
    {
        public RespuestaEjecucion? respuesta { get; set; }
        public List<UsuariosAppResponseDetalle>? detalle { get; set; }
    }
}
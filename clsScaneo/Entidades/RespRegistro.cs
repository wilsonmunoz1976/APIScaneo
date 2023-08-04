using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace clsScaneo.Entidades
{
    public class RespRegistro
    {
        public string? CodigoPlanilla { get; set; } = string.Empty;
        public int? CodigoSolicEgre { get; set; } = 0;
        public string? DesArticulo { get; set; } = string.Empty;
        public string? Bodega { get; set; } = string.Empty;
    }

}

using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace clsScaneo.Entidades
{
    public class RegistroEmergenciaResponse
    {
        public string? codigoPlanilla { get; set; } = string.Empty;
        public int? codigoSolicEgre { get; set; } = 0;
        public string? desArticulo { get; set; } = string.Empty;
        public string? bodega { get; set; } = string.Empty;
    }

}

namespace clsScaneo.Entidades
{
    public class EmailMessage
    {
        public string? ServidorMail { get; set; } = "mail.jardinesdeesperanza.com";
        public int? PortMail { get; set; } = 465;
        public bool? UseSSL { get; set; } = true;
        public string? UsuarioMail { get; set; }
        public string? PasswordMail { get; set; }
        public string? FromMail { get; set; }
        public string? FromName { get; set; }
        public List<string?>? To { get; set; }
        public List<string?>? CC { get; set; }
        public List<string?>? CCO { get; set; }
        public string? Subject { get; set; }
        public string? Body { get; set; }
    }
}
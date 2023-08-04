namespace clsScaneo.Entidades
{
    public class EmailConfig
    {
        public string MailServer { get; set; } = "mail.saberempresarial.com";
        public int MailPuerto { get; set; } = 465;
        public string FromName { get; set; } = "Jardines de Esperanza";
        public string FromEmail { get; set; } = "info@jardinesdeesperanza.net";
        public string MailUsuario { get; set; } = "info@jardinesdeesperanza.net";
        public string MailPassword { get; set; } = "12345";
        public string MailTo { get; set; } = "notificaciones@jardinesdeesperanza.net";
        public string MailCC { get; set; } = "notificaciones@jardinesdeesperanza.net";
        public string MailCCO { get; set; } = "notificaciones@jardinesdeesperanza.net";
        public string MailSubject { get; set; } = "Notificación de APIScaneo";
    }
}
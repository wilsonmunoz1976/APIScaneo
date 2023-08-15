using clsScaneo.Entidades;
namespace clsScaneo.Models
{

    public class AuthenticateResponse
    {
        public int? Id { get; set; }
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public string? Username { get; set; }
        public string Token { get; set; }


        public AuthenticateResponse(LoginResponseInfoUsuario user, string token)
        {
            Id = user.id;
            FirstName = user.nombres;
            Username = user.username;
            Token = token;
        }
    }
}
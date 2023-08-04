using Microsoft.Data.SqlClient;
using System.Data;
using clsScaneo.Entidades;
using NLog;
using APIScaneo.Authorization;
using clsScaneo.Models;
using System.Runtime.InteropServices;
using Microsoft.Extensions.Options;

namespace clsScaneo.Clases
{
    public interface ILoginUser
    {
        string TokenLogin(int? Id, string? Nombres, string? Usuario, string? Password);
        bool ValidaTokenLogin(string? Token);
    }

    public class LoginUser : ILoginUser
    {
        private readonly IJwtUtils? _jwtUtils;

        public LoginUser(IJwtUtils? jwtUtils)
        {
            _jwtUtils = jwtUtils;
        }

        public string TokenLogin(int? Id, string? Nombres, string? Usuario, string? Password)
        {
            string Token = string.Empty;

                if (_jwtUtils != null)
                {
                    Token = _jwtUtils.GenerateJwtToken(new LoginResponseInfoUsuario()
                    { Id = Convert.ToInt32(Id), Nombres = Nombres, Username = Usuario, Password = Password });
                }
            return Token;
        }

        public bool ValidaTokenLogin(string? Token)
        {
            int? iRet = null;
            if (_jwtUtils != null)
            {
                iRet = _jwtUtils.ValidateJwtToken(Token);
            }
            return iRet != null ;
        }

    }
}
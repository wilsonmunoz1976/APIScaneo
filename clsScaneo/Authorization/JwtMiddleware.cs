using clsScaneo.Clases;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;

namespace APIScaneo.Authorization
{

    public class JwtMiddleware
    {
        private readonly RequestDelegate _next;

        public JwtMiddleware(RequestDelegate next)
        {
            _next = next;
        }

        public async Task Invoke(HttpContext context/*, ILoginUser userService*/, IJwtUtils jwtUtils)
        {

            if (!(context.Request.Path.Value.Contains("/api/Login/")))
            {
                var token = context.Request.Headers["Authorization"].FirstOrDefault()?.Split(" ").Last();
                //int userId;
                _ = jwtUtils.ValidateJwtToken(token) ?? throw new Exception("El token suministrado no es correcto");
            }
            await _next(context);
        }
    }
}
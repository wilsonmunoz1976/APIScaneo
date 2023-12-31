﻿using Microsoft.AspNetCore.Http;
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
                int? userId = jwtUtils.ValidateJwtToken(token); 
                if (userId == null)
                {
                    context.Response.Headers.Add("token-Expired", "true");
                }

            }
            await _next(context);
        }
    }
}
namespace APIScaneo.Authorization;

using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using clsScaneo.Entidades;
using clsScaneo.Helpers;

public interface IJwtUtils
{
    public string GenerateJwtToken(LoginResponseInfoUsuario user);
    public int? ValidateJwtToken(string? token);
}

public class JwtUtils : IJwtUtils
{
    private readonly Settings _Settings;

    public JwtUtils(IOptions<Settings> settings)
    {
        _Settings = settings.Value;

        if (string.IsNullOrEmpty(_Settings.Secret))
            throw new Exception("JWT secret not configured");
    }

    public string GenerateJwtToken(LoginResponseInfoUsuario user)
    {
        // generate token that is valid for 7 days
        var tokenHandler = new JwtSecurityTokenHandler();
        var key = Encoding.ASCII.GetBytes(_Settings.Secret!);
        var tokenDescriptor = new SecurityTokenDescriptor
        {
            Subject = new ClaimsIdentity(new[] { new Claim("id", user.Id.ToString()) }),
            Expires = DateTime.UtcNow.AddMinutes(_Settings.HorasExpiracion * 60),
            SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(key), SecurityAlgorithms.HmacSha256Signature)
        };
        var token = tokenHandler.CreateToken(tokenDescriptor);
        return tokenHandler.WriteToken(token);
    }

    public int? ValidateJwtToken(string? token)
    {
        if (token == null)
            return null;

        var tokenHandler = new JwtSecurityTokenHandler();
        var key = Encoding.ASCII.GetBytes(_Settings.Secret!);
        try
        {
            tokenHandler.ValidateToken(token, new TokenValidationParameters
            {
                ValidateIssuerSigningKey = true,
                IssuerSigningKey = new SymmetricSecurityKey(key),
                ValidateIssuer = false,
                ValidateAudience = false,
                ValidateLifetime = true,
                // set clockskew to zero so tokens expire exactly at token expiration time (instead of 5 minutes later)
                ClockSkew = TimeSpan.Zero
            }, out SecurityToken validatedToken);

            var jwtToken = (JwtSecurityToken)validatedToken;
            var userId = int.Parse(jwtToken.Claims.First(x => x.Type == "id").Value);

            // return user id from JWT token if validation successful
            return userId;
        }
        catch
        {
            // return null if validation fails
            return null;
        }
    }
}
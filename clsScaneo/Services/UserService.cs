namespace APIScaneo.Services;

using APIScaneo.Authorization;
using APIScaneo.Models;
using clsScaneo.Entidades;

public interface IUserService
{
    AuthenticateResponse? Authenticate(AuthenticateRequest model);
    IEnumerable<LoginDato> GetAll();
    LoginDato? GetById(int id);
}

public class UserService : IUserService
{
    // users hardcoded for simplicity, store in a db with hashed passwords in production applications
    private readonly List<LoginDato> _users = new()
    {
        new LoginDato { Id = 1, Nombres = "Test", Username = "test", Password = "test" }
    };

    private readonly IJwtUtils _jwtUtils;

    public UserService(IJwtUtils jwtUtils)
    {
        _jwtUtils = jwtUtils;
    }

    public AuthenticateResponse? Authenticate(AuthenticateRequest model)
    {
        var user = _users.SingleOrDefault(x => x.Username == model.Username && x.Password == model.Password);

        // return null if user not found
        if (user == null) return null;

        // authentication successful so generate jwt token
        string token = _jwtUtils.GenerateJwtToken(user);

        return new AuthenticateResponse(user, token);
    }

    public IEnumerable<LoginDato> GetAll()
    {
        return _users;
    }

    public LoginDato? GetById(int id)
    {
        return _users.FirstOrDefault(x => x.Id == id);
    }
}

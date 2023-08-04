using NLog.Extensions.Logging;
using clsScaneo.Clases;
using APIScaneo.Authorization;
using clsScaneo.Helpers;

internal class Program
{
    private static void Main(string[] args)
    {

        var builder = WebApplication.CreateBuilder(args);

        builder.Services.AddCors(options =>
        {
            options.AddDefaultPolicy(
                                  policy =>
                                  {
                                      policy.WithOrigins("http://example.com",
                                                          "http://www.contoso.com")
                                                          .AllowAnyHeader()
                                                          .AllowAnyMethod();
                                  });
        });

        // Add services to the container.

        builder.Services.AddControllers();
        // Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
        builder.Services.AddEndpointsApiExplorer();
        builder.Services.AddSwaggerGen();

        // configure strongly typed settings object
        builder.Services.Configure<Settings>(builder.Configuration.GetSection("Settings"));
        // configure DI for application services
        builder.Services.AddScoped<IJwtUtils, JwtUtils>();
        builder.Services.AddScoped<ILoginUser, LoginUser>();

        var app = builder.Build();

        NLog.LogManager.Configuration = new NLogLoggingConfiguration(builder.Configuration.GetSection("Nlog"));

        // Configure the HTTP request pipeline.
        Settings? settings = builder.Configuration.GetSection("Settings").Get<Settings>();

        //if (app.Environment.IsDevelopment())
        if (settings != null)
        {
            if (settings.Showswagger == true)
            {
                app.UseSwagger();
                app.UseSwaggerUI();
            }
            if (settings.ValidarToken == true)
            {
                app.UseMiddleware<JwtMiddleware>();
            }
        }

        app.UseHttpsRedirection();

        app.UseAuthorization();

        // configure HTTP request pipeline
        {
            // global cors policy
            app.UseCors(x => x
                .AllowAnyOrigin()
                .AllowAnyMethod()
                .AllowAnyHeader());

            // custom jwt auth middleware

            app.MapControllers();
        }

        app.Run();
        IConfigurationRoot configuration = new ConfigurationBuilder()
        .SetBasePath(AppDomain.CurrentDomain.BaseDirectory)
        .AddJsonFile("appsettings.json")
        .Build();

    }
}


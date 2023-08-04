using Microsoft.AspNetCore.Mvc.Filters;
using clsScaneo.Entidades;
using Microsoft.AspNetCore.Http;

namespace APIScaneo.Authorization
{

    [AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
    public class AuthorizeAttribute : Attribute, IAuthorizationFilter
    {
        public void OnAuthorization(AuthorizationFilterContext context)
        {
            // skip authorization if action is decorated with [AllowAnonymous] attribute
            var allowAnonymous = context.ActionDescriptor.EndpointMetadata.OfType<AllowAnonymousAttribute>().Any();
            if (allowAnonymous)
                return;

            // authorization
            var user = (LoginResponseInfoUsuario?)context.HttpContext.Items["User"];
            if (user == null)
            {
                // not logged in or role not authorized
                //context.Result = new System.Web.Http.Results.JsonResult(new { message = "Unauthorized" }) { StatusCode = StatusCodes.Status401Unauthorized };
            }
        }
    }
}

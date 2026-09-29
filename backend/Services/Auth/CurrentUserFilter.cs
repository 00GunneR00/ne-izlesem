using System.Reflection;
using Microsoft.AspNetCore.Mvc.Filters;

namespace Neizlesem.Api.Services.Auth;

/// <summary>
/// Makes the signed-in user's identity come from the JWT, never from the
/// request. Endpoints historically took the acting user as a parameter
/// (<c>?userId=</c>, <c>UserId</c>/<c>SenderId</c>/… in bodies); after model
/// binding this filter overwrites every such value with the token's user id,
/// so a client can't act as someone else by sending another id.
/// </summary>
public class CurrentUserFilter : IActionFilter
{
    /// <summary>Action parameters that mean "the acting user".</summary>
    private static readonly HashSet<string> IdParameters =
        new(StringComparer.OrdinalIgnoreCase) { "userId", "excludeUserId" };

    /// <summary>Request-body properties that mean "the acting user".</summary>
    private static readonly HashSet<string> IdProperties =
        new(StringComparer.Ordinal) { "UserId", "SenderId", "RequesterId", "OwnerId" };

    public void OnActionExecuting(ActionExecutingContext context)
    {
        if (context.HttpContext.User.GetUserId() is not { } userId)
        {
            return; // anonymous endpoint (auth) — nothing to bind
        }

        foreach (var name in context.ActionArguments.Keys.ToList())
        {
            var value = context.ActionArguments[name];
            if (IdParameters.Contains(name) && value is int or null)
            {
                context.ActionArguments[name] = userId;
            }
            else if (value is not null && IsRequestModel(value.GetType()))
            {
                foreach (var property in value.GetType().GetProperties(BindingFlags.Public | BindingFlags.Instance))
                {
                    if (IdProperties.Contains(property.Name)
                        && property.PropertyType == typeof(int)
                        && property.CanWrite)
                    {
                        property.SetValue(value, userId);
                    }
                }
            }
        }
    }

    public void OnActionExecuted(ActionExecutedContext context)
    {
    }

    /// <summary>Only our own request records (…Request) — never entities or framework types.</summary>
    private static bool IsRequestModel(Type type) =>
        type.Namespace == "Neizlesem.Api.DTOs" && type.Name.EndsWith("Request", StringComparison.Ordinal);
}

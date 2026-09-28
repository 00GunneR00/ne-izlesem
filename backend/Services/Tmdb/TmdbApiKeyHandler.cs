using Microsoft.AspNetCore.WebUtilities;

namespace Neizlesem.Api.Services.Tmdb;

/// <summary>
/// Appends TMDB's v3 <c>api_key</c> and the configured <c>language</c> query
/// parameters to every outgoing request, so call sites in <see cref="TmdbService"/>
/// don't need to touch query strings. A call that sets <c>language</c> itself
/// (the English overview fallback) keeps its own value.
/// </summary>
public class TmdbApiKeyHandler(TmdbOptions options) : DelegatingHandler
{
    protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken ct)
    {
        if (request.RequestUri is not null)
        {
            var url = request.RequestUri.ToString();
            if (!string.IsNullOrEmpty(options.ApiKey))
            {
                url = QueryHelpers.AddQueryString(url, "api_key", options.ApiKey);
            }
            if (!string.IsNullOrEmpty(options.Language) &&
                !QueryHelpers.ParseQuery(request.RequestUri.Query).ContainsKey("language"))
            {
                url = QueryHelpers.AddQueryString(url, "language", options.Language);
            }
            request.RequestUri = new Uri(url);
        }

        return base.SendAsync(request, ct);
    }
}

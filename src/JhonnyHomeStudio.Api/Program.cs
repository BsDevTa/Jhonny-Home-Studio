using System.IdentityModel.Tokens.Jwt;
using System.Text;
using JhonnyHomeStudio.Application.Common.Settings;
using JhonnyHomeStudio.Infrastructure.Persistence;
using JhonnyHomeStudio.Api.Middleware;
using JhonnyHomeStudio.Infrastructure.Seeding;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Http.Features;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.Extensions.FileProviders;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;

var builder = WebApplication.CreateBuilder(args);
const long MaxUploadRequestSizeBytes = 50 * 1024 * 1024;

var allowedOrigins = new[]
{
    "https://johnny-home-studio.web.app",
    "https://johnny-home-studio.firebaseapp.com",

    "https://jhonny-home-studio.web.app",
    "https://jhonny-home-studio.firebaseapp.com",

    "http://localhost:3000",
    "http://localhost:5000",
    "http://localhost:8080",
    "http://localhost:5173"
};

builder.Services.AddCors(options =>
{
    options.AddPolicy("FlutterWeb", policy =>
    {
        policy
            .WithOrigins(allowedOrigins)
            .AllowAnyHeader()
            .AllowAnyMethod()
            .AllowCredentials();
    });
});

builder.Services.AddControllers().ConfigureApiBehaviorOptions(options =>
{
    options.InvalidModelStateResponseFactory = context =>
    {
        var errors = context.ModelState
            .Where(entry => entry.Value?.Errors.Count > 0)
            .SelectMany(entry => entry.Value!.Errors.Select(error =>
                string.IsNullOrWhiteSpace(error.ErrorMessage)
                    ? "Requisição inválida."
                    : error.ErrorMessage))
            .ToArray();

        var response = JhonnyHomeStudio.Application.Common.Responses.ApiResponse<object>.FailureResponse(
            "Não foi possível processar a requisição.",
            errors);

        return new Microsoft.AspNetCore.Mvc.JsonResult(response)
        {
            StatusCode = StatusCodes.Status400BadRequest,
            ContentType = "application/json"
        };
    };
});

builder.Services.Configure<FormOptions>(options =>
{
    options.MultipartBodyLengthLimit = MaxUploadRequestSizeBytes;
});

builder.WebHost.ConfigureKestrel(options =>
{
    options.Limits.MaxRequestBodySize = MaxUploadRequestSizeBytes;
});

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "Jhonny Home Studio API",
        Version = "v1"
    });

    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "Informe: Bearer {seu token JWT}"
    });

    options.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});
builder.Services.AddInfrastructure(builder.Configuration);

var jwtSettings = builder.Configuration.GetSection("JwtSettings").Get<JwtSettings>() ?? new JwtSettings();
var signingKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSettings.SecretKey));

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.RequireHttpsMetadata = false;
    options.SaveToken = true;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateIssuerSigningKey = true,
        ValidateLifetime = true,
        ValidIssuer = jwtSettings.Issuer,
        ValidAudience = jwtSettings.Audience,
        IssuerSigningKey = signingKey,
        ClockSkew = TimeSpan.Zero
    };

    options.Events = new JwtBearerEvents
    {
        OnMessageReceived = context =>
        {
            var logger = context.HttpContext.RequestServices
                .GetRequiredService<ILoggerFactory>()
                .CreateLogger("JwtDiagnostics");
            logger.LogInformation(
                "JWT request {Method} {Path} Authorization={Authorization}",
                context.Request.Method,
                context.Request.Path,
                MaskAuthorization(context.Request.Headers.Authorization.ToString()));

            return Task.CompletedTask;
        },
        OnAuthenticationFailed = context =>
        {
            var logger = context.HttpContext.RequestServices
                .GetRequiredService<ILoggerFactory>()
                .CreateLogger("JwtDiagnostics");
            logger.LogWarning(
                context.Exception,
                "JWT authentication failed for {Method} {Path} Authorization={Authorization}",
                context.Request.Method,
                context.Request.Path,
                MaskAuthorization(context.Request.Headers.Authorization.ToString()));

            return Task.CompletedTask;
        },
        OnChallenge = async context =>
        {
            context.HandleResponse();
            context.Response.StatusCode = StatusCodes.Status401Unauthorized;
            context.Response.ContentType = "application/json";
            await context.Response.WriteAsJsonAsync(JhonnyHomeStudio.Application.Common.Responses.ApiResponse<object>.FailureResponse(
                "Acesso não autorizado.",
                new[] { "Token inválido, ausente ou expirado." }));
        },
        OnForbidden = async context =>
        {
            context.Response.StatusCode = StatusCodes.Status403Forbidden;
            context.Response.ContentType = "application/json";
            await context.Response.WriteAsJsonAsync(JhonnyHomeStudio.Application.Common.Responses.ApiResponse<object>.FailureResponse(
                "Acesso negado.",
                new[] { "Você não tem permissão para executar esta ação." }));
        }
    };
});

builder.Services.AddAuthorization();

builder.Services.Configure<ForwardedHeadersOptions>(options =>
{
    options.ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto;
    options.KnownNetworks.Clear();
    options.KnownProxies.Clear();
});

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

var webRoot = app.Environment.WebRootPath ?? Path.Combine(app.Environment.ContentRootPath, "wwwroot");
Directory.CreateDirectory(webRoot);

var uploadsRoot = Path.Combine(webRoot, "uploads");
Directory.CreateDirectory(uploadsRoot);

app.UseForwardedHeaders();

app.UseRouting();

app.UseCors("FlutterWeb");

app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = new PhysicalFileProvider(webRoot),
    OnPrepareResponse = context => AddStaticFileCorsHeaders(context.Context, allowedOrigins)
});

app.UseMiddleware<ExceptionHandlingMiddleware>();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

await app.Services.SeedInitialDataAsync();

app.Run();

static void AddStaticFileCorsHeaders(HttpContext context, IReadOnlyCollection<string> allowedOrigins)
{
    context.Response.Headers["Cache-Control"] = "public,max-age=3600";

    var origin = context.Request.Headers.Origin.ToString();
    if (string.IsNullOrWhiteSpace(origin) || !allowedOrigins.Contains(origin, StringComparer.OrdinalIgnoreCase))
    {
        return;
    }

    context.Response.Headers["Access-Control-Allow-Origin"] = origin;
    context.Response.Headers["Access-Control-Allow-Credentials"] = "true";
    context.Response.Headers["Vary"] = "Origin";
}

static string MaskAuthorization(string? authorization)
{
    if (string.IsNullOrWhiteSpace(authorization))
    {
        return "<missing>";
    }

    const string prefix = "Bearer ";
    if (!authorization.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
    {
        return "<present non-bearer>";
    }

    var token = authorization[prefix.Length..];
    if (token.Length <= 16)
    {
        return $"Bearer {token}(len={token.Length})";
    }

    return $"Bearer {token[..12]}...{token[^8..]}(len={token.Length})";
}

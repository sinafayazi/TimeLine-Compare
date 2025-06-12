using HistoricalEvents.Services;
using Polly;
using Polly.Extensions.Http;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// HTTP client with retry policy
builder.Services.AddHttpClient<WikidataService>()
    .AddPolicyHandler(GetRetryPolicy());

// Query generator - choose based on configuration
var queryGeneratorType = builder.Configuration["QueryGenerator:Type"] ?? "Simple";

switch (queryGeneratorType.ToLower())
{
    case "ollama":
        builder.Services.AddHttpClient<OllamaQueryGeneratorService>();
        builder.Services.AddScoped<IQueryGeneratorService, OllamaQueryGeneratorService>();
        break;
    case "pattern":
        builder.Services.AddScoped<IQueryGeneratorService, PatternQueryGeneratorService>();
        break;
    default:
        builder.Services.AddScoped<IQueryGeneratorService, SimpleQueryGeneratorService>();
        break;
}

builder.Services.AddLogging(config =>
{
    config.AddConsole();
    config.AddDebug();
});

// Add CORS
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(builder =>
    {
        builder.AllowAnyOrigin()
               .AllowAnyMethod()
               .AllowAnyHeader();
    });
});

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors();
app.UseRouting();
app.MapControllers();

Console.WriteLine("Historical Events API started");
Console.WriteLine("Swagger UI: https://localhost:5001/swagger");

app.Run();

static IAsyncPolicy<HttpResponseMessage> GetRetryPolicy()
{
    return HttpPolicyExtensions
        .HandleTransientHttpError()
        .OrResult(msg => !msg.IsSuccessStatusCode)
        .WaitAndRetryAsync(
            3,
            retryAttempt => TimeSpan.FromSeconds(Math.Pow(2, retryAttempt)),
            onRetry: (outcome, timespan, retryCount, context) =>
            {
                Console.WriteLine($"Retry {retryCount} after {timespan} seconds");
            });
}

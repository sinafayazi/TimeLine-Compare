using System.Text;
using System.Text.Json;
using HistoricalEvents.Models;

namespace HistoricalEvents.Services;

public class OllamaQueryGeneratorService : IQueryGeneratorService
{
    private readonly HttpClient _http;
    private readonly ILogger<OllamaQueryGeneratorService> _logger;
    private readonly string _ollamaUrl;

    public OllamaQueryGeneratorService(HttpClient http, IConfiguration config, ILogger<OllamaQueryGeneratorService> logger)
    {
        _http = http;
        _logger = logger;
        _ollamaUrl = config["Ollama:Url"] ?? "http://localhost:11434";
        
        _http.DefaultRequestHeaders.Accept.Add(new System.Net.Http.Headers.MediaTypeWithQualityHeaderValue("application/json"));
    }

    public async Task<SparqlQuery> GenerateQuery(string userQuery, DateTime? startDate = null, DateTime? endDate = null)
    {
        var prompt = $@"You are a Wikidata SPARQL query expert. Generate a SPARQL query to find historical events and entities.

IMPORTANT: Return ONLY the SPARQL query code, no explanations or markdown.

Use this template structure:
SELECT DISTINCT ?entity ?entityLabel ?description ?date ?startDate ?endDate ?image WHERE {{
  # Search patterns for: {userQuery}
  
  # Include text search
  {{
    ?entity rdfs:label ?label .
    FILTER(CONTAINS(LCASE(?label), LCASE('{userQuery.Replace("'", "\\'")}''')))
  }} UNION {{
    ?entity schema:description ?desc .
    FILTER(CONTAINS(LCASE(?desc), LCASE('{userQuery.Replace("'", "\\'")}''')))
  }}
  
  # Universal date extraction
  OPTIONAL {{ ?entity wdt:P585 ?pointTime. }}
  OPTIONAL {{ ?entity wdt:P580 ?startTime. }}
  OPTIONAL {{ ?entity wdt:P582 ?endTime. }}
  OPTIONAL {{ ?entity wdt:P569 ?birthTime. }}
  OPTIONAL {{ ?entity wdt:P570 ?deathTime. }}
  OPTIONAL {{ ?entity wdt:P571 ?inceptionTime. }}
  OPTIONAL {{ ?entity wdt:P576 ?dissolvedTime. }}
  
  BIND(COALESCE(?pointTime, ?startTime, ?birthTime, ?inceptionTime) AS ?date)
  BIND(COALESCE(?endTime, ?deathTime, ?dissolvedTime) AS ?endDate)
  BIND(?startTime AS ?startDate)
  
  {(startDate.HasValue ? $"FILTER(!BOUND(?date) || ?date >= '{startDate:yyyy-MM-dd}'^^xsd:dateTime)" : "")}
  {(endDate.HasValue ? $"FILTER(!BOUND(?date) || ?date <= '{endDate:yyyy-MM-dd}'^^xsd:dateTime)" : "")}
  
  OPTIONAL {{ ?entity wdt:P18 ?image. }}
  OPTIONAL {{ ?entity schema:description ?description. FILTER(LANG(?description) = 'en') }}
  
  SERVICE wikibase:label {{ bd:serviceParam wikibase:language 'en'. }}
}}
LIMIT 1000

Generate an optimized SPARQL query for: '{userQuery}'";

        try
        {
            // First, check if Ollama is running
            var healthCheck = await _http.GetAsync($"{_ollamaUrl}/api/tags");
            if (!healthCheck.IsSuccessStatusCode)
            {
                _logger.LogWarning("Ollama is not responding. Falling back to pattern-based generation.");
                return GenerateFallbackQuery(userQuery, startDate, endDate);
            }

            var request = new
            {
                model = "llama3.2",
                prompt = prompt,
                stream = false,
                options = new
                {
                    temperature = 0.3,
                    top_p = 0.9,
                    num_predict = 2000
                }
            };

            var jsonContent = JsonSerializer.Serialize(request);
            var content = new StringContent(jsonContent, System.Text.Encoding.UTF8, "application/json");

            var response = await _http.PostAsync($"{_ollamaUrl}/api/generate", content);
            
            if (!response.IsSuccessStatusCode)
            {
                var errorContent = await response.Content.ReadAsStringAsync();
                _logger.LogError($"Ollama API error: {response.StatusCode} - {errorContent}");
                return GenerateFallbackQuery(userQuery, startDate, endDate);
            }

            var responseContent = await response.Content.ReadAsStringAsync();
            var result = JsonSerializer.Deserialize<OllamaResponse>(responseContent, new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            });

            if (result == null || string.IsNullOrEmpty(result.Response))
            {
                _logger.LogWarning("Empty response from Ollama");
                return GenerateFallbackQuery(userQuery, startDate, endDate);
            }

            var generatedQuery = result.Response;
            generatedQuery = CleanupSparqlQuery(generatedQuery);

            _logger.LogInformation($"Generated SPARQL for '{userQuery}' using Ollama");

            return new SparqlQuery
            {
                Query = generatedQuery,
                Explanation = $"Query generated for: {userQuery}"
            };
        }
        catch (HttpRequestException ex)
        {
            _logger.LogError(ex, "Cannot connect to Ollama. Is it running?");
            return GenerateFallbackQuery(userQuery, startDate, endDate);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating query with Ollama");
            return GenerateFallbackQuery(userQuery, startDate, endDate);
        }
    }

    private string CleanupSparqlQuery(string query)
    {
        query = System.Text.RegularExpressions.Regex.Replace(query, @"```sparql\s*", "", System.Text.RegularExpressions.RegexOptions.IgnoreCase);
        query = System.Text.RegularExpressions.Regex.Replace(query, @"```\s*", "");
        
        var selectMatch = System.Text.RegularExpressions.Regex.Match(query, @"SELECT.*?LIMIT\s+\d+", System.Text.RegularExpressions.RegexOptions.Singleline | System.Text.RegularExpressions.RegexOptions.IgnoreCase);
        if (selectMatch.Success)
        {
            return selectMatch.Value;
        }

        return query.Trim();
    }

    private SparqlQuery GenerateFallbackQuery(string userQuery, DateTime? startDate, DateTime? endDate)
    {
        var query = $@"
SELECT DISTINCT ?entity ?entityLabel ?description ?date ?startDate ?endDate ?image WHERE {{
  {{
    ?entity rdfs:label ?label .
    FILTER(CONTAINS(LCASE(?label), LCASE('{userQuery}')))
  }} UNION {{
    ?entity schema:description ?desc .
    FILTER(CONTAINS(LCASE(?desc), LCASE('{userQuery}')))
  }}
  
  # Universal date extraction
  OPTIONAL {{ ?entity wdt:P585 ?pointTime. }}
  OPTIONAL {{ ?entity wdt:P580 ?startTime. }}
  OPTIONAL {{ ?entity wdt:P582 ?endTime. }}
  OPTIONAL {{ ?entity wdt:P569 ?birthTime. }}
  OPTIONAL {{ ?entity wdt:P570 ?deathTime. }}
  OPTIONAL {{ ?entity wdt:P571 ?inceptionTime. }}
  OPTIONAL {{ ?entity wdt:P576 ?dissolvedTime. }}
  
  BIND(COALESCE(?pointTime, ?startTime, ?birthTime, ?inceptionTime) AS ?date)
  BIND(COALESCE(?endTime, ?deathTime, ?dissolvedTime) AS ?endDate)
  BIND(?startTime AS ?startDate)
  
  {(startDate.HasValue ? $"FILTER(?date >= '{startDate:yyyy-MM-dd}'^^xsd:dateTime)" : "")}
  {(endDate.HasValue ? $"FILTER(?date <= '{endDate:yyyy-MM-dd}'^^xsd:dateTime)" : "")}
  
  OPTIONAL {{ ?entity wdt:P18 ?image. }}
  OPTIONAL {{ ?entity schema:description ?description. FILTER(LANG(?description) = 'en') }}
  
  SERVICE wikibase:label {{ bd:serviceParam wikibase:language 'en'. }}
}}
LIMIT 1000";

        return new SparqlQuery
        {
            Query = query,
            Explanation = "Fallback text search query"
        };
    }

    private class OllamaResponse
    {
        public string Response { get; set; } = string.Empty;
        public bool Done { get; set; }
        public string Model { get; set; } = string.Empty;
        public long Created_at { get; set; }
    }
}

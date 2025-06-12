using System.Text.Json;
using HistoricalEvents.Models;

namespace HistoricalEvents.Services;

public class WikidataService
{
    private readonly HttpClient _http;
    private readonly ILogger<WikidataService> _logger;

    public WikidataService(HttpClient http, ILogger<WikidataService> logger)
    {
        _http = http;
        _logger = logger;
        _http.DefaultRequestHeaders.Add("User-Agent", "HistoricalEventsAPI/1.0");
        _http.Timeout = TimeSpan.FromSeconds(10); // Reduced timeout to fail faster
    }

    public async Task<List<Event>> ExecuteQuery(string sparqlQuery)
    {
        try
        {
            var url = $"https://query.wikidata.org/sparql?query={Uri.EscapeDataString(sparqlQuery)}&format=json";
            
            using var response = await _http.GetAsync(url);
            response.EnsureSuccessStatusCode();
            
            var json = await response.Content.ReadAsStringAsync();
            var data = JsonSerializer.Deserialize<JsonElement>(json);

            var events = new List<Event>();
            foreach (var binding in data.GetProperty("results").GetProperty("bindings").EnumerateArray())
            {
                var evt = ParseEvent(binding);
                if (evt != null && !string.IsNullOrEmpty(evt.Title) && evt.Title != "Unknown")
                {
                    events.Add(evt);
                }
            }

            _logger.LogInformation($"Query returned {events.Count} results");
            return events;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error executing SPARQL query");
            throw;
        }
    }

    private Event ParseEvent(JsonElement binding)
    {
        var evt = new Event
        {
            WikidataId = ExtractEntityId(GetValue(binding, "entity")) ?? string.Empty,
            Title = GetValue(binding, "entityLabel") ?? "Unknown",
            Description = GetValue(binding, "description") ?? string.Empty
        };

        if (TryParseDate(GetValue(binding, "date"), out var date))
            evt.Date = date;
        if (TryParseDate(GetValue(binding, "startDate"), out var startDate))
            evt.StartDate = startDate;
        if (TryParseDate(GetValue(binding, "endDate"), out var endDate))
            evt.EndDate = endDate;

        var imageUrl = GetValue(binding, "image");
        if (!string.IsNullOrEmpty(imageUrl))
            evt.Images.Add(imageUrl);

        foreach (var prop in binding.EnumerateObject())
        {
            if (!new[] { "entity", "entityLabel", "description", "date", "startDate", "endDate", "image" }.Contains(prop.Name))
            {
                var value = GetValue(binding, prop.Name);
                if (!string.IsNullOrEmpty(value))
                {
                    evt.Properties[prop.Name] = value;
                }
            }
        }

        return evt;
    }

    public async Task<Event?> GetEntityDetails(string wikidataId)
    {
        try
        {
            var url = $"https://www.wikidata.org/w/rest.php/wikibase/v1/entities/items/{wikidataId}";
            var response = await _http.GetStringAsync(url);
            var data = JsonSerializer.Deserialize<JsonElement>(response);

            var evt = new Event { WikidataId = wikidataId };

            if (data.TryGetProperty("labels", out var labels) && labels.TryGetProperty("en", out var enLabel))
            {
                evt.Title = enLabel.GetString() ?? string.Empty;
            }

            if (data.TryGetProperty("descriptions", out var descriptions) && descriptions.TryGetProperty("en", out var enDesc))
            {
                evt.Description = enDesc.GetString() ?? string.Empty;
            }

            evt.Summary = await GetWikipediaSummary(data) ?? string.Empty;

            return evt;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error getting details for {wikidataId}");
            return null;
        }
    }

    private async Task<string?> GetWikipediaSummary(JsonElement wikidataEntity)
    {
        try
        {
            if (wikidataEntity.TryGetProperty("sitelinks", out var sitelinks) &&
                sitelinks.TryGetProperty("enwiki", out var enwiki) &&
                enwiki.TryGetProperty("title", out var title))
            {
                var wikipediaTitle = title.GetString();
                var url = $"https://en.wikipedia.org/api/rest_v1/page/summary/{Uri.EscapeDataString(wikipediaTitle!)}";
                var response = await _http.GetStringAsync(url);
                var data = JsonSerializer.Deserialize<JsonElement>(response);
                
                return data.TryGetProperty("extract", out var extract) 
                    ? extract.GetString() 
                    : null;
            }
        }
        catch { }
        return null;
    }

    private string? GetValue(JsonElement binding, string key)
    {
        return binding.TryGetProperty(key, out var prop) && 
               prop.TryGetProperty("value", out var value) 
               ? value.GetString() : null;
    }

    private string ExtractEntityId(string? wikidataUrl)
    {
        return wikidataUrl?.Split('/').LastOrDefault() ?? string.Empty;
    }

    private bool TryParseDate(string? dateStr, out DateTime date)
    {
        date = default;
        if (string.IsNullOrEmpty(dateStr)) return false;
        
        dateStr = dateStr.Split('T')[0];
        return DateTime.TryParse(dateStr, out date);
    }
}

using System.Text;
using HistoricalEvents.Models;

namespace HistoricalEvents.Services;

public class SimpleQueryGeneratorService : IQueryGeneratorService
{
    private readonly ILogger<SimpleQueryGeneratorService> _logger;

    public SimpleQueryGeneratorService(ILogger<SimpleQueryGeneratorService> logger)
    {
        _logger = logger;
    }

    public Task<SparqlQuery> GenerateQuery(string userQuery, DateTime? startDate = null, DateTime? endDate = null)
    {
        // Very simple query that should execute quickly
        var query = $@"
SELECT DISTINCT ?entity ?entityLabel ?description WHERE {{
  ?entity rdfs:label ?entityLabel .
  FILTER(CONTAINS(LCASE(?entityLabel), LCASE('{userQuery.Replace("'", "\\'")}')))
  FILTER(LANG(?entityLabel) = 'en')
  
  OPTIONAL {{ ?entity schema:description ?description . FILTER(LANG(?description) = 'en') }}
}}
LIMIT 10";

        return Task.FromResult(new SparqlQuery
        {
            Query = query,
            Explanation = $"Simple query for: {userQuery}"
        });
    }
}

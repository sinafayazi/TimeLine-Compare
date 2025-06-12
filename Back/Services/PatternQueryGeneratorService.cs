using System.Text;
using HistoricalEvents.Models;

namespace HistoricalEvents.Services;

public class PatternQueryGeneratorService : IQueryGeneratorService
{
    private readonly ILogger<PatternQueryGeneratorService> _logger;

    public PatternQueryGeneratorService(ILogger<PatternQueryGeneratorService> logger)
    {
        _logger = logger;
    }

    public Task<SparqlQuery> GenerateQuery(string userQuery, DateTime? startDate = null, DateTime? endDate = null)
    {
        var wikidataIdPattern = @"\b[Qq]\d+\b";
        var wikidataIds = System.Text.RegularExpressions.Regex.Matches(userQuery, wikidataIdPattern)
            .Select(m => m.Value.ToUpper()).ToList();

        var queryBuilder = new StringBuilder();
        queryBuilder.AppendLine("SELECT DISTINCT ?entity ?entityLabel ?description ?date ?startDate ?endDate ?image WHERE {");

        if (wikidataIds.Any())
        {
            queryBuilder.AppendLine("  {");
            foreach (var id in wikidataIds)
            {
                queryBuilder.AppendLine($"    {{ ?entity wdt:P31/wdt:P279* wd:{id} }} UNION");
                queryBuilder.AppendLine($"    {{ ?entity wdt:P361 wd:{id} }} UNION");
                queryBuilder.AppendLine($"    {{ ?entity wdt:P710 wd:{id} }} UNION");
            }
            queryBuilder.Length -= 7; // Remove last UNION
            queryBuilder.AppendLine("  }");
        }
        else
        {
            var searchTerms = userQuery.ToLower().Split(' ', StringSplitOptions.RemoveEmptyEntries);
            
            queryBuilder.AppendLine("  {");
            queryBuilder.AppendLine("    # Text search in labels and descriptions");
            queryBuilder.AppendLine("    ?entity rdfs:label ?label .");
            
            if (searchTerms.Length == 1)
            {
                queryBuilder.AppendLine($"    FILTER(CONTAINS(LCASE(?label), '{searchTerms[0]}'))");
            }
            else
            {
                queryBuilder.Append("    FILTER(");
                foreach (var term in searchTerms)
                {
                    queryBuilder.Append($"CONTAINS(LCASE(?label), '{term}') || ");
                }
                queryBuilder.Length -= 4; // Remove last ||
                queryBuilder.AppendLine(")");
            }
            
            queryBuilder.AppendLine("  } UNION {");
            queryBuilder.AppendLine("    # Search in descriptions");
            queryBuilder.AppendLine("    ?entity schema:description ?desc .");
            queryBuilder.AppendLine($"    FILTER(CONTAINS(LCASE(?desc), LCASE('{userQuery}')))");
            queryBuilder.AppendLine("  }");
        }

        queryBuilder.AppendLine(@"
  # Universal date extraction
  OPTIONAL { ?entity wdt:P585 ?pointTime. }
  OPTIONAL { ?entity wdt:P580 ?startTime. }
  OPTIONAL { ?entity wdt:P582 ?endTime. }
  OPTIONAL { ?entity wdt:P569 ?birthTime. }
  OPTIONAL { ?entity wdt:P570 ?deathTime. }
  OPTIONAL { ?entity wdt:P571 ?inceptionTime. }
  OPTIONAL { ?entity wdt:P576 ?dissolvedTime. }
  
  BIND(COALESCE(?pointTime, ?startTime, ?birthTime, ?inceptionTime) AS ?date)
  BIND(COALESCE(?endTime, ?deathTime, ?dissolvedTime) AS ?endDate)
  BIND(?startTime AS ?startDate)");

        if (startDate.HasValue)
            queryBuilder.AppendLine($"  FILTER(!BOUND(?date) || ?date >= '{startDate:yyyy-MM-dd}'^^xsd:dateTime)");
        if (endDate.HasValue)
            queryBuilder.AppendLine($"  FILTER(!BOUND(?date) || ?date <= '{endDate:yyyy-MM-dd}'^^xsd:dateTime)");

        queryBuilder.AppendLine(@"
  OPTIONAL { ?entity wdt:P18 ?image. }
  OPTIONAL { ?entity schema:description ?description. FILTER(LANG(?description) = 'en') }
  
  SERVICE wikibase:label { bd:serviceParam wikibase:language 'en'. }
}
ORDER BY ?date
LIMIT 100");

        return Task.FromResult(new SparqlQuery
        {
            Query = queryBuilder.ToString(),
            Explanation = $"Pattern-based query for: {userQuery}"
        });
    }
}

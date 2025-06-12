using HistoricalEvents.Models;

namespace HistoricalEvents.Services;

public interface IQueryGeneratorService
{
    Task<SparqlQuery> GenerateQuery(string userQuery, DateTime? startDate = null, DateTime? endDate = null);
}

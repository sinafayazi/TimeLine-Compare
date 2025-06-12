namespace HistoricalEvents.Models;

public class Event
{
    public string WikidataId { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string Summary { get; set; } = string.Empty;
    public DateTime? Date { get; set; }
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public string EntityType { get; set; } = string.Empty;
    public List<string> Images { get; set; } = new();
    public Dictionary<string, string> Properties { get; set; } = new();
    public List<string> RelatedEntities { get; set; } = new();
    
    // Hierarchical relationships
    public string? ParentEntityId { get; set; }
    public List<Event> ChildEvents { get; set; } = new();
    public string RelationshipType { get; set; } = string.Empty; // "part_of", "ruler_of", "battle_in", etc.
}

public class SearchRequest
{
    public string Query { get; set; } = string.Empty;
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public int Limit { get; set; } = 100;
}

public class SparqlQuery
{
    public string Query { get; set; } = string.Empty;
    public string Explanation { get; set; } = string.Empty;
}

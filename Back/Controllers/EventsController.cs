using Microsoft.AspNetCore.Mvc;
using HistoricalEvents.Models;
using HistoricalEvents.Services;

namespace HistoricalEvents.Controllers;

[ApiController]
[Route("api/[controller]")]
public class EventsController : ControllerBase
{
    private readonly IQueryGeneratorService _queryGenerator;
    private readonly WikidataService _wikidata;
    private readonly ILogger<EventsController> _logger;

    public EventsController(
        IQueryGeneratorService queryGenerator, 
        WikidataService wikidata, 
        ILogger<EventsController> logger)
    {
        _queryGenerator = queryGenerator;
        _wikidata = wikidata;
        _logger = logger;
    }

    [HttpPost("search")]
    public async Task<ActionResult<List<Event>>> Search([FromBody] SearchRequest request)
    {
        try
        {
            var sparqlQuery = await _queryGenerator.GenerateQuery(
                request.Query, 
                request.StartDate, 
                request.EndDate
            );

            _logger.LogInformation($"Generated query for: {request.Query}");
            _logger.LogDebug($"SPARQL: {sparqlQuery.Query}");

            // Try Wikidata first, but fallback to demo data if it fails
            try
            {
                var events = await _wikidata.ExecuteQuery(sparqlQuery.Query);

                if (request.Limit > 0 && events.Count > request.Limit)
                {
                    events = events.Take(request.Limit).ToList();
                }

                return Ok(new
                {
                    results = events,
                    count = events.Count,
                    query = request.Query,
                    sparql = sparqlQuery.Query,
                    source = "wikidata"
                });
            }
            catch (Exception wikidataEx)
            {
                _logger.LogWarning(wikidataEx, "Wikidata query failed, falling back to demo data");
                
                // Fallback to demo data
                return await GetSearchDemoData(request, sparqlQuery.Query);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error searching for: {request.Query}");
            return StatusCode(500, new { error = "Search failed", message = ex.Message });
        }
    }

    private async Task<ActionResult<List<Event>>> GetSearchDemoData(SearchRequest request, string sparqlQuery)
    {
        var demoData = new List<Event>();

        // Add Iran/Persia related demo data if query matches
        if (request.Query.ToLower().Contains("iran") || request.Query.ToLower().Contains("persia"))
        {
            demoData.AddRange(new List<Event>
            {
                new Event
                {
                    WikidataId = "Q389688",
                    Title = "Achaemenid Empire",
                    Description = "First Persian Empire (c. 550–330 BCE)",
                    Summary = "The Achaemenid Empire, also called the First Persian Empire, was an ancient Iranian empire founded by Cyrus the Great in 550 BCE.",
                    Date = new DateTime(550, 1, 1),
                    StartDate = new DateTime(550, 1, 1),
                    EndDate = new DateTime(330, 1, 1),
                    EntityType = "empire",
                    Images = new List<string> { "https://example.com/achaemenid-empire.jpg" },
                    Properties = new Dictionary<string, string>
                    {
                        {"founder", "Cyrus the Great"},
                        {"capital", "Persepolis, Susa, Ecbatana"},
                        {"territory", "Central Asia to India to Egypt"},
                        {"religion", "Zoroastrianism"},
                        {"peak_size", "5.5 million km²"}
                    },
                    RelatedEntities = new List<string> { "Q8591", "Q868", "Q5746", "Q4551172" }
                },
                new Event
                {
                    WikidataId = "Q606076",
                    Title = "Sassanid Empire",
                    Description = "Last Persian Empire before Islamic conquest (224–651 CE)",
                    Summary = "The Sassanid Empire was the last imperial dynasty of ancient Persia before the Muslim conquest.",
                    Date = new DateTime(224, 1, 1),
                    StartDate = new DateTime(224, 1, 1),
                    EndDate = new DateTime(651, 1, 1),
                    EntityType = "empire",
                    Images = new List<string> { "https://example.com/sassanid-empire.jpg" },
                    Properties = new Dictionary<string, string>
                    {
                        {"founder", "Ardashir I"},
                        {"capital", "Ctesiphon"},
                        {"religion", "Zoroastrianism"},
                        {"rival", "Byzantine Empire"}
                    },
                    RelatedEntities = new List<string> { "Q389688", "Q12560", "Q29552" }
                },
                new Event
                {
                    WikidataId = "Q12560",
                    Title = "Safavid Empire",
                    Description = "Iranian empire (1501–1736)",
                    Summary = "The Safavid dynasty was one of the most significant ruling dynasties of Iran from 1501 to 1736.",
                    Date = new DateTime(1501, 1, 1),
                    StartDate = new DateTime(1501, 1, 1),
                    EndDate = new DateTime(1736, 1, 1),
                    EntityType = "empire",
                    Images = new List<string> { "https://example.com/safavid-empire.jpg" },
                    Properties = new Dictionary<string, string>
                    {
                        {"founder", "Shah Ismail I"},
                        {"capital", "Tabriz, Qazvin, Isfahan"},
                        {"religion", "Shia Islam"},
                        {"significance", "Established Iran as Shia Muslim state"}
                    },
                    RelatedEntities = new List<string> { "Q606076", "Q28799020" }
                },
                new Event
                {
                    WikidataId = "Q8591",
                    Title = "Cyrus the Great",
                    Description = "Founder and first king of the Achaemenid Empire (c. 600–530 BCE)",
                    Summary = "Cyrus II of Persia, commonly known as Cyrus the Great, was the founder of the Achaemenid Empire.",
                    Date = new DateTime(600, 1, 1),
                    StartDate = new DateTime(600, 1, 1),
                    EndDate = new DateTime(530, 1, 1),
                    EntityType = "person",
                    Images = new List<string> { "https://example.com/cyrus-great.jpg" },
                    Properties = new Dictionary<string, string>
                    {
                        {"title", "King of Kings, Great King"},
                        {"empire", "Achaemenid Empire"},
                        {"achievements", "Cyrus Cylinder - first charter of human rights"},
                        {"empire_extent", "From Aegean Sea to Indus River"}
                    },
                    RelatedEntities = new List<string> { "Q389688" }
                },
                new Event
                {
                    WikidataId = "Q868",
                    Title = "Darius the Great",
                    Description = "Third king of the Achaemenid Empire (550-486 BCE)",
                    Summary = "Darius I, commonly known as Darius the Great, was the third Persian King of Kings of the Achaemenid Empire.",
                    Date = new DateTime(550, 1, 1),
                    StartDate = new DateTime(522, 1, 1),
                    EndDate = new DateTime(486, 1, 1),
                    EntityType = "person",
                    Images = new List<string> { "https://example.com/darius-great.jpg" },
                    Properties = new Dictionary<string, string>
                    {
                        {"title", "King of Kings, Great King"},
                        {"empire", "Achaemenid Empire"},
                        {"achievements", "Built Persepolis, organized satrapies"},
                        {"reign_duration", "36 years"}
                    },
                    RelatedEntities = new List<string> { "Q389688", "Q8591" }
                }
            });
        }

        // Apply date filtering if specified
        if (request.StartDate.HasValue)
        {
            demoData = demoData
                .Where(e => e.Date >= request.StartDate.Value || e.StartDate >= request.StartDate.Value)
                .ToList();
        }

        if (request.EndDate.HasValue)
        {
            demoData = demoData
                .Where(e => e.Date <= request.EndDate.Value || e.EndDate <= request.EndDate.Value)
                .ToList();
        }

        // Apply limit
        if (request.Limit > 0)
        {
            demoData = demoData.Take(request.Limit).ToList();
        }

        // Sort by date
        demoData = demoData.OrderBy(e => e.Date).ToList();

        return Ok(new
        {
            results = demoData,
            count = demoData.Count,
            query = request.Query,
            sparql = sparqlQuery,
            source = "demo_fallback",
            message = "Wikidata service temporarily unavailable, showing demo data",
            note = "This demonstrates the API response structure with filtered demo data"
        });
    }

    [HttpGet("{wikidataId}")]
    public async Task<ActionResult<Event>> GetEvent(string wikidataId)
    {
        var evt = await _wikidata.GetEntityDetails(wikidataId);
        if (evt == null)
            return NotFound();

        return Ok(evt);
    }

    [HttpGet("test")]
    public ActionResult<object> Test()
    {
        return Ok(new
        {
            message = "Historical Events API is working!",
            timestamp = DateTime.UtcNow,
            version = "1.0.0"
        });
    }

    [HttpGet("wikidata-test")]
    public async Task<ActionResult<object>> WikidataTest()
    {
        try
        {
            // Test a very simple Wikidata query
            var simpleQuery = @"
SELECT ?item ?itemLabel WHERE {
  ?item wdt:P31 wd:Q5.
  SERVICE wikibase:label { bd:serviceParam wikibase:language 'en'. }
}
LIMIT 1";
            
            var events = await _wikidata.ExecuteQuery(simpleQuery);
            return Ok(new
            {
                message = "Wikidata connection successful!",
                resultsCount = events.Count,
                query = simpleQuery
            });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new 
            { 
                error = "Wikidata connection failed", 
                message = ex.Message 
            });
        }
    }

    [HttpGet("demo")]
    public ActionResult<object> Demo()
    {
        // Return sample historical events to demonstrate API structure
        var sampleEvents = new List<Event>
        {
            new Event
            {
                WikidataId = "Q362",
                Title = "World War II",
                Description = "Global war, 1939–1945",
                Summary = "World War II was a global conflict that lasted from 1939 to 1945. It involved the vast majority of the world's countries—including all of the great powers—forming two opposing military alliances.",
                Date = new DateTime(1939, 9, 1),
                StartDate = new DateTime(1939, 9, 1),
                EndDate = new DateTime(1945, 9, 2),
                EntityType = "historical event",
                Images = new List<string> { "https://example.com/wwii.jpg" },
                Properties = new Dictionary<string, string> 
                { 
                    { "participants", "Multiple nations" },
                    { "casualties", "70-85 million" }
                },
                RelatedEntities = new List<string> { "Q937", "Q352" }
            },
            new Event
            {
                WikidataId = "Q937",
                Title = "Albert Einstein",
                Description = "German-born theoretical physicist (1879–1955)",
                Summary = "Albert Einstein was a German-born theoretical physicist, widely acknowledged to be one of the greatest and most influential physicists of all time.",
                Date = new DateTime(1879, 3, 14),
                StartDate = new DateTime(1879, 3, 14),
                EndDate = new DateTime(1955, 4, 18),
                EntityType = "person",
                Images = new List<string> { "https://example.com/einstein.jpg" },
                Properties = new Dictionary<string, string> 
                { 
                    { "occupation", "theoretical physicist" },
                    { "nationality", "German-American" }
                },
                RelatedEntities = new List<string> { "Q5593", "Q41395" }
            },
            new Event
            {
                WikidataId = "Q1492",
                Title = "French Revolution",
                Description = "Revolution in France, 1789–1799",
                Summary = "The French Revolution was a period of radical political and societal change in France that began with the Estates General of 1789.",
                Date = new DateTime(1789, 7, 14),
                StartDate = new DateTime(1789, 5, 5),
                EndDate = new DateTime(1799, 11, 9),
                EntityType = "historical event",
                Images = new List<string> { "https://example.com/french-revolution.jpg" },
                Properties = new Dictionary<string, string> 
                { 
                    { "location", "France" },
                    { "type", "political revolution" }
                },
                RelatedEntities = new List<string> { "Q7732", "Q44", "Q2079" }
            }
        };

        return Ok(new
        {
            results = sampleEvents,
            count = sampleEvents.Count,
            query = "Demo data",
            message = "This is sample data demonstrating the API response structure. In production, this would be real data from Wikidata.",
            sparql = "SELECT DISTINCT ?entity ?entityLabel ?description ?date ?startDate ?endDate ?image WHERE { ... }"
        });
    }

    [HttpGet("demo/iran-empire")]
    public ActionResult<object> IranEmpireDemo()
    {
        // Main Achaemenid Empire - Parent Entity
        var achaemenidEmpire = new Event
        {
            WikidataId = "Q389688",
            Title = "Achaemenid Empire",
            Description = "First Persian Empire (c. 550–330 BCE)",
            Summary = "The Achaemenid Empire, also called the First Persian Empire, was an ancient Iranian empire founded by Cyrus the Great in 550 BCE.",
            Date = new DateTime(550, 1, 1),
            StartDate = new DateTime(550, 1, 1),
            EndDate = new DateTime(330, 1, 1),
            EntityType = "empire",
            Images = new List<string> { "https://example.com/achaemenid-empire.jpg" },
            Properties = new Dictionary<string, string>
            {
                {"founder", "Cyrus the Great"},
                {"capital", "Persepolis, Susa, Ecbatana"},
                {"territory", "Central Asia to India to Egypt"},
                {"religion", "Zoroastrianism"},
                {"peak_size", "5.5 million km²"}
            },
            RelatedEntities = new List<string> { "Q8591", "Q868", "Q5746", "Q4551172" },
            RelationshipType = "root"
        };

        // Child entities - rulers, battles, cities that belong to the empire
        var cyrusTheGreat = new Event
        {
            WikidataId = "Q8591",
            Title = "Cyrus the Great",
            Description = "Founder and first king of the Achaemenid Empire (c. 600–530 BCE)",
            Summary = "Cyrus II of Persia, commonly known as Cyrus the Great, was the founder of the Achaemenid Empire.",
            Date = new DateTime(600, 1, 1),
            StartDate = new DateTime(600, 1, 1),
            EndDate = new DateTime(530, 1, 1),
            EntityType = "person",
            Images = new List<string> { "https://example.com/cyrus-great.jpg" },
            Properties = new Dictionary<string, string>
            {
                {"title", "King of Kings, Great King"},
                {"role", "Founder and First Emperor"},
                {"achievements", "Cyrus Cylinder - first charter of human rights"},
                {"empire_extent", "From Aegean Sea to Indus River"}
            },
            RelatedEntities = new List<string> { "Q389688" },
            ParentEntityId = "Q389688", // Child of Achaemenid Empire
            RelationshipType = "ruler_of"
        };

        var dariusTheGreat = new Event
        {
            WikidataId = "Q868",
            Title = "Darius the Great",
            Description = "Third king of the Achaemenid Empire (550-486 BCE)",
            Summary = "Darius I, commonly known as Darius the Great, was the third Persian King of Kings of the Achaemenid Empire.",
            Date = new DateTime(550, 1, 1),
            StartDate = new DateTime(522, 1, 1),
            EndDate = new DateTime(486, 1, 1),
            EntityType = "person",
            Images = new List<string> { "https://example.com/darius-great.jpg" },
            Properties = new Dictionary<string, string>
            {
                {"title", "King of Kings, Great King"},
                {"role", "Third Emperor"},
                {"achievements", "Built Persepolis, organized satrapies"},
                {"reign_duration", "36 years"}
            },
            RelatedEntities = new List<string> { "Q389688", "Q8591" },
            ParentEntityId = "Q389688", // Child of Achaemenid Empire
            RelationshipType = "ruler_of"
        };

        var battleOfGaugamela = new Event
        {
            WikidataId = "Q5746",
            Title = "Battle of Gaugamela",
            Description = "Decisive battle ending the Achaemenid Empire (331 BCE)",
            Summary = "The Battle of Gaugamela was the decisive battle between Alexander the Great and Darius III of Persia, effectively ending the Achaemenid Empire.",
            Date = new DateTime(331, 10, 1),
            StartDate = new DateTime(331, 10, 1),
            EndDate = new DateTime(331, 10, 1),
            EntityType = "battle",
            Images = new List<string> { "https://example.com/gaugamela.jpg" },
            Properties = new Dictionary<string, string>
            {
                {"location", "Gaugamela, Assyria (modern Iraq)"},
                {"result", "Macedonian victory"},
                {"significance", "End of Achaemenid Empire"},
                {"participants", "Alexander the Great vs Darius III"}
            },
            RelatedEntities = new List<string> { "Q389688", "Q8409" },
            ParentEntityId = "Q389688", // Child of Achaemenid Empire
            RelationshipType = "battle_in"
        };

        var persepolis = new Event
        {
            WikidataId = "Q4551172",
            Title = "Persepolis",
            Description = "Ceremonial capital of the Achaemenid Empire",
            Summary = "Persepolis was the ceremonial capital of the Achaemenid Empire, built by Darius the Great.",
            Date = new DateTime(515, 1, 1),
            StartDate = new DateTime(515, 1, 1),
            EndDate = new DateTime(330, 1, 1),
            EntityType = "city",
            Images = new List<string> { "https://example.com/persepolis.jpg" },
            Properties = new Dictionary<string, string>
            {
                {"function", "Ceremonial capital"},
                {"builder", "Darius the Great"},
                {"location", "Fars Province, Iran"},
                {"destruction", "Burned by Alexander the Great"}
            },
            RelatedEntities = new List<string> { "Q389688", "Q868" },
            ParentEntityId = "Q389688", // Child of Achaemenid Empire
            RelationshipType = "capital_of"
        };

        // Add children to the parent empire
        achaemenidEmpire.ChildEvents.AddRange(new[] { cyrusTheGreat, dariusTheGreat, battleOfGaugamela, persepolis });

        // Other Persian empires as separate root entities
        var sassanidEmpire = new Event
        {
            WikidataId = "Q606076",
            Title = "Sassanid Empire",
            Description = "Last Persian Empire before Islamic conquest (224–651 CE)",
            Summary = "The Sassanid Empire was the last imperial dynasty of ancient Persia before the Muslim conquest.",
            Date = new DateTime(224, 1, 1),
            StartDate = new DateTime(224, 1, 1),
            EndDate = new DateTime(651, 1, 1),
            EntityType = "empire", 
            Images = new List<string> { "https://example.com/sassanid-empire.jpg" },
            Properties = new Dictionary<string, string>
            {
                {"founder", "Ardashir I"},
                {"capital", "Ctesiphon"},
                {"religion", "Zoroastrianism"},
                {"rival", "Byzantine Empire"}
            },
            RelatedEntities = new List<string> { "Q389688", "Q12560", "Q29552" },
            RelationshipType = "successor"
        };

        var results = new List<Event> { achaemenidEmpire, sassanidEmpire };

        return Ok(new
        {
            results = results,
            count = results.Count,
            totalEntities = results.Count + achaemenidEmpire.ChildEvents.Count,
            query = "Iran Empire - Hierarchical Structure",
            message = "Proper hierarchical data: Achaemenid Empire contains its rulers, battles, and cities as children",
            timespan = "550 BCE - 651 CE",
            structure = new
            {
                empires = results.Select(e => new 
                { 
                    e.WikidataId, 
                    e.Title, 
                    e.EntityType,
                    childCount = e.ChildEvents.Count,
                    children = e.ChildEvents.Select(c => new { c.WikidataId, c.Title, c.EntityType, c.RelationshipType })
                }),
                note = "Cyrus the Great is now correctly shown as a child/ruler OF the Achaemenid Empire, not a sibling"
            },
            sparql = "SELECT ?empire ?ruler WHERE { ?ruler wdt:P27|wdt:P108 ?empire . ?empire wdt:P31/wdt:P279* wd:Q389688 }"
        });
    }

    [HttpGet("test/ollama")]
    public async Task<ActionResult<object>> TestOllama()
    {
        try
        {
            var queryGeneratorType = _queryGenerator.GetType().Name;
            
            if (queryGeneratorType != "OllamaQueryGeneratorService")
            {
                return Ok(new
                {
                    message = "Not using Ollama",
                    currentGenerator = queryGeneratorType,
                    isOllama = false,
                    recommendation = "Set QueryGenerator:Type to 'Ollama' in appsettings.json and restart"
                });
            }

            // Test Ollama with a simple query
            var testQuery = await _queryGenerator.GenerateQuery("test Persian empire");
            
            return Ok(new
            {
                message = "Ollama is working!",
                currentGenerator = queryGeneratorType,
                isOllama = true,
                testQuery = testQuery.Query.Length > 100 ? testQuery.Query.Substring(0, 200) + "..." : testQuery.Query,
                explanation = testQuery.Explanation
            });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new
            {
                error = "Ollama test failed",
                message = ex.Message,
                currentGenerator = _queryGenerator.GetType().Name
            });
        }
    }

    [HttpPost("query/preview")]
    public async Task<ActionResult<SparqlQuery>> PreviewQuery([FromBody] SearchRequest request)
    {
        var sparqlQuery = await _queryGenerator.GenerateQuery(
            request.Query, 
            request.StartDate, 
            request.EndDate
        );

        return Ok(sparqlQuery);
    }

    [HttpPost("search/demo")]
    public ActionResult<object> SearchDemo([FromBody] SearchRequest request)
    {
        // Return filtered demo data based on the search query
        var iranRelatedEvents = new List<Event>();

        if (request.Query.ToLower().Contains("iran") || request.Query.ToLower().Contains("persia"))
        {
            iranRelatedEvents.AddRange(new List<Event>
            {
                new Event
                {
                    WikidataId = "Q389688",
                    Title = "Achaemenid Empire",
                    Description = "First Persian Empire (c. 550–330 BCE)",
                    Summary = "The Achaemenid Empire, also called the First Persian Empire, was an ancient Iranian empire founded by Cyrus the Great in 550 BCE.",
                    Date = new DateTime(550, 1, 1),
                    StartDate = new DateTime(550, 1, 1),
                    EndDate = new DateTime(330, 1, 1),
                    EntityType = "empire",
                    Images = new List<string> { "https://example.com/achaemenid-empire.jpg" },
                    Properties = new Dictionary<string, string>
                    {
                        {"founder", "Cyrus the Great"},
                        {"capital", "Persepolis, Susa, Ecbatana"},
                        {"territory", "Central Asia to India to Egypt"},
                        {"religion", "Zoroastrianism"},
                        {"peak_size", "5.5 million km²"}
                    },
                    RelatedEntities = new List<string> { "Q8591", "Q868", "Q5746", "Q4551172" }
                },
                new Event
                {
                    WikidataId = "Q606076",
                    Title = "Sassanid Empire",
                    Description = "Last Persian Empire before Islamic conquest (224–651 CE)",
                    Summary = "The Sassanid Empire was the last imperial dynasty of ancient Persia before the Muslim conquest.",
                    Date = new DateTime(224, 1, 1),
                    StartDate = new DateTime(224, 1, 1),
                    EndDate = new DateTime(651, 1, 1),
                    EntityType = "empire",
                    Images = new List<string> { "https://example.com/sassanid-empire.jpg" },
                    Properties = new Dictionary<string, string>
                    {
                        {"founder", "Ardashir I"},
                        {"capital", "Ctesiphon"},
                        {"religion", "Zoroastrianism"},
                        {"rival", "Byzantine Empire"}
                    },
                    RelatedEntities = new List<string> { "Q389688", "Q12560", "Q29552" }
                },
                new Event
                {
                    WikidataId = "Q12560",
                    Title = "Safavid Empire",
                    Description = "Iranian empire (1501–1736)",
                    Summary = "The Safavid dynasty was one of the most significant ruling dynasties of Iran from 1501 to 1736.",
                    Date = new DateTime(1501, 1, 1),
                    StartDate = new DateTime(1501, 1, 1),
                    EndDate = new DateTime(1736, 1, 1),
                    EntityType = "empire",
                    Images = new List<string> { "https://example.com/safavid-empire.jpg" },
                    Properties = new Dictionary<string, string>
                    {
                        {"founder", "Shah Ismail I"},
                        {"capital", "Tabriz, Qazvin, Isfahan"},
                        {"religion", "Shia Islam"},
                        {"significance", "Established Iran as Shia Muslim state"}
                    },
                    RelatedEntities = new List<string> { "Q606076", "Q28799020" }
                },
                new Event
                {
                    WikidataId = "Q8591",
                    Title = "Cyrus the Great",
                    Description = "Founder and first king of the Achaemenid Empire (c. 600–530 BCE)",
                    Summary = "Cyrus II of Persia, commonly known as Cyrus the Great, was the founder of the Achaemenid Empire.",
                    Date = new DateTime(600, 1, 1),
                    StartDate = new DateTime(600, 1, 1),
                    EndDate = new DateTime(530, 1, 1),
                    EntityType = "person",
                    Images = new List<string> { "https://example.com/cyrus-great.jpg" },
                    Properties = new Dictionary<string, string>
                    {
                        {"title", "King of Kings, Great King"},
                        {"empire", "Achaemenid Empire"},
                        {"achievements", "Cyrus Cylinder - first charter of human rights"},
                        {"empire_extent", "From Aegean Sea to Indus River"}
                    },
                    RelatedEntities = new List<string> { "Q389688" }
                },
                new Event
                {
                    WikidataId = "Q868",
                    Title = "Darius the Great",
                    Description = "Third king of the Achaemenid Empire (550-486 BCE)",
                    Summary = "Darius I, commonly known as Darius the Great, was the third Persian King of Kings of the Achaemenid Empire.",
                    Date = new DateTime(550, 1, 1),
                    StartDate = new DateTime(522, 1, 1),
                    EndDate = new DateTime(486, 1, 1),
                    EntityType = "person",
                    Images = new List<string> { "https://example.com/darius-great.jpg" },
                    Properties = new Dictionary<string, string>
                    {
                        {"title", "King of Kings, Great King"},
                        {"empire", "Achaemenid Empire"},
                        {"achievements", "Built Persepolis, organized satrapies"},
                        {"reign_duration", "36 years"}
                    },
                    RelatedEntities = new List<string> { "Q389688", "Q8591" }
                }
            });
        }

        // Apply date filtering if specified
        if (request.StartDate.HasValue)
        {
            iranRelatedEvents = iranRelatedEvents
                .Where(e => e.Date >= request.StartDate.Value || e.StartDate >= request.StartDate.Value)
                .ToList();
        }

        if (request.EndDate.HasValue)
        {
            iranRelatedEvents = iranRelatedEvents
                .Where(e => e.Date <= request.EndDate.Value || e.EndDate <= request.EndDate.Value)
                .ToList();
        }

        // Apply limit
        if (request.Limit > 0)
        {
            iranRelatedEvents = iranRelatedEvents.Take(request.Limit).ToList();
        }

        // Sort by date
        iranRelatedEvents = iranRelatedEvents.OrderBy(e => e.Date).ToList();

        return Ok(new
        {
            results = iranRelatedEvents,
            count = iranRelatedEvents.Count,
            query = request.Query,
            startDate = request.StartDate,
            endDate = request.EndDate,
            limit = request.Limit,
            message = "Demo data filtered by your search criteria (Wikidata endpoint currently experiencing timeouts)",
            note = "This demonstrates the API response structure with Iranian historical data matching your query parameters"
        });
    }
}

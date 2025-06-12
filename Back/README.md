# Historical Events API

A backend service for querying historical events and entities from Wikidata using natural language queries. The API supports multiple query generation strategies including pattern-based queries, LLM-powered queries via Ollama, and fallback mechanisms.

## Features

- **Multiple Query Generators**: Pattern-based, Ollama-powered, and simple query generators
- **SPARQL Query Generation**: Automatic generation of optimized SPARQL queries for Wikidata
- **Flexible Search**: Natural language queries with date range filtering
- **Robust Error Handling**: Comprehensive error handling and logging
- **API Documentation**: Swagger/OpenAPI documentation included
- **CORS Support**: Enabled for frontend integration

## Project Structure

```
/
├── Controllers/
│   └── EventsController.cs        # API endpoints
├── Models/
│   └── Event.cs                   # Data models
├── Services/
│   ├── IQueryGeneratorService.cs  # Query generator interface
│   ├── OllamaQueryGeneratorService.cs    # LLM-powered query generation
│   ├── PatternQueryGeneratorService.cs   # Pattern-based query generation
│   ├── SimpleQueryGeneratorService.cs    # Simple query generation
│   └── WikidataService.cs         # Wikidata SPARQL execution
├── Program.cs                     # Application startup
├── appsettings.json              # Configuration
└── HistoricalEvents.csproj       # Project file
```

## API Endpoints

### GET `/api/events/test`
Test endpoint to verify API functionality.

**Response:**
```json
{
  "message": "Historical Events API is working!",
  "timestamp": "2025-06-11T15:36:50.119082Z",
  "version": "1.0.0"
}
```

### POST `/api/events/search`
Search for historical events using natural language queries.

**Request Body:**
```json
{
  "query": "World War II",
  "startDate": "1939-01-01",
  "endDate": "1945-12-31",
  "limit": 50
}
```

**Response:**
```json
{
  "results": [
    {
      "wikidataId": "Q362",
      "title": "World War II",
      "description": "Global war from 1939 to 1945",
      "summary": "...",
      "date": "1939-09-01T00:00:00",
      "startDate": "1939-09-01T00:00:00",
      "endDate": "1945-09-02T00:00:00",
      "entityType": "war",
      "images": ["https://commons.wikimedia.org/..."],
      "properties": {},
      "relatedEntities": []
    }
  ],
  "count": 1,
  "query": "World War II",
  "sparql": "SELECT DISTINCT ?entity ?entityLabel..."
}
```

### POST `/api/events/query/preview`
Preview the generated SPARQL query without executing it.

**Request Body:**
```json
{
  "query": "Einstein",
  "startDate": "1900-01-01",
  "endDate": "2000-12-31"
}
```

**Response:**
```json
{
  "query": "SELECT DISTINCT ?entity ?entityLabel ?description...",
  "explanation": "Pattern-based query for: Einstein"
}
```

### GET `/api/events/{wikidataId}`
Get detailed information about a specific Wikidata entity.

**Response:**
```json
{
  "wikidataId": "Q937",
  "title": "Albert Einstein",
  "description": "German-born theoretical physicist",
  "summary": "Albert Einstein was a German-born theoretical physicist...",
  "date": "1879-03-14T00:00:00",
  "endDate": "1955-04-18T00:00:00",
  "images": ["https://commons.wikimedia.org/..."],
  "properties": {},
  "relatedEntities": []
}
```

## Configuration

The API supports different query generation strategies configured in `appsettings.json`:

```json
{
  "QueryGenerator": {
    "Type": "Pattern"  // Options: "Simple", "Pattern", "Ollama"
  },
  "Ollama": {
    "Url": "http://localhost:11434"
  }
}
```

### Query Generator Types

1. **Simple**: Basic text search in Wikidata labels
2. **Pattern**: Advanced pattern-based query generation with date filtering
3. **Ollama**: LLM-powered query generation using local Ollama instance

## Installation & Setup

### Prerequisites
- .NET 8.0 SDK
- (Optional) Ollama for LLM-powered query generation

### Installation

1. **Clone and navigate to the project:**
   ```bash
   cd /Users/sina/dev/timeline-compare/TimeLine-Front/Back
   ```

2. **Restore dependencies:**
   ```bash
   dotnet restore
   ```

3. **Build the project:**
   ```bash
   dotnet build
   ```

4. **Run the application:**
   ```bash
   dotnet run
   ```

   The API will start on:
   - HTTP: http://localhost:5000
   - HTTPS: https://localhost:5001
   - Swagger UI: https://localhost:5001/swagger

### Running with Custom Port

```bash
dotnet run --urls "http://localhost:5002"
```

## Usage Examples

### Basic Search
```bash
curl -X POST "http://localhost:5000/api/events/search" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "American Civil War",
    "limit": 10
  }'
```

### Date-Filtered Search
```bash
curl -X POST "http://localhost:5000/api/events/search" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Renaissance",
    "startDate": "1400-01-01",
    "endDate": "1600-12-31",
    "limit": 20
  }'
```

### Query Preview
```bash
curl -X POST "http://localhost:5000/api/events/query/preview" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Napoleon Bonaparte"
  }'
```

## Development

### Adding New Query Generators

1. Implement the `IQueryGeneratorService` interface
2. Register the service in `Program.cs`
3. Add configuration option in `appsettings.json`

### Testing

The API includes several test endpoints:
- `/api/events/test` - Basic functionality test
- `/api/events/wikidata-test` - Wikidata connectivity test

## Performance Considerations

- **Timeout Settings**: Default HTTP timeout is 30 seconds
- **Query Limits**: SPARQL queries are limited to 100 results by default
- **Retry Policy**: HTTP requests include exponential backoff retry policy
- **Error Handling**: Graceful fallback to simpler queries when complex queries fail

## Dependencies

- **Microsoft.AspNetCore.OpenApi** - OpenAPI support
- **Swashbuckle.AspNetCore** - Swagger documentation
- **Microsoft.Extensions.Http.Polly** - HTTP retry policies
- **Polly.Extensions.Http** - Resilience patterns
- **System.Text.Json** - JSON serialization

## Troubleshooting

### Common Issues

1. **Port Already in Use**: Use `lsof -ti:5000 | xargs kill -9` to kill processes
2. **Wikidata Timeouts**: Try using "Simple" query generator for faster responses
3. **SPARQL Errors**: Check query syntax in the preview endpoint

### Logs

The application provides detailed logging:
- Info level: General application flow
- Debug level: Detailed SPARQL queries and responses
- Error level: Exceptions and failures

## Future Enhancements

- **OpenAI Integration**: GPT-powered query generation
- **Caching**: Redis-based query result caching
- **Rate Limiting**: API rate limiting and throttling
- **Authentication**: JWT-based authentication
- **Database Storage**: Local storage of frequently accessed entities
- **Batch Processing**: Bulk query processing capabilities

## License

This project is part of the Timeline Compare application.

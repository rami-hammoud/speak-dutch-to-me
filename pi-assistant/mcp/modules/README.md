# MCP Modules

Modular capabilities for the Pi Assistant, following the Model Context Protocol (MCP) architecture.

## Available Modules

### 1. Dutch Learning Module (`dutch_learning.py`)
Comprehensive Dutch language learning system with:
- **Vocabulary Management**: Add, search, and review Dutch words with spaced repetition
- **Grammar Exercises**: Interactive exercises for articles, verb conjugation, and word order
- **Translation**: Multi-provider translation service (LibreTranslate, Ollama, Dictionary fallback)
- **Pronunciation Scoring**: Speech recognition-based pronunciation assessment
- **Visual Learning**: Camera-based object identification with Dutch vocabulary
- **Progress Tracking**: Daily stats, streaks, and mastery levels
- **Conversation Practice**: AI-powered Dutch conversation sessions

**Database**: SQLite database for vocabulary, progress, and practice sessions

**Tools**: 14 MCP tools for vocabulary, grammar, translation, pronunciation, and progress tracking

### 2. Personal Assistant Module (`personal_assistant.py`)
Personal productivity and organization features:
- Calendar management (Google Calendar integration)
- Task management (Todoist/Things integration)
- Email search and management
- Reminders and notifications

**Status**: Scaffolded, API integrations pending

**Tools**: 5 MCP tools for calendar, tasks, and email

### 3. E-Commerce Module (`ecommerce.py`)
Shopping and commerce capabilities:
- Product search across multiple platforms
- Price comparison
- Shopping cart management
- Purchase execution
- Order tracking

**Status**: Scaffolded, API integrations pending

**Tools**: 6 MCP tools for shopping and order management

### 4. Smart Home Module (Coming Soon)
Home automation and IoT device control.

### 5. Knowledge Base Module (Coming Soon)
Web search, Wikipedia, and knowledge retrieval.

## Architecture

Each module follows the MCP protocol:

```python
class ModuleName:
    def __init__(self):
        self.tools = []
        self._initialized = False
    
    async def initialize(self):
        # Initialize services and register tools
        pass
    
    def get_tools(self) -> List[MCPTool]:
        return self.tools
    
    async def cleanup(self):
        # Cleanup resources
        pass
```

## Adding a New Module

1. Create `mcp/modules/your_module.py`
2. Implement the module class with `initialize()`, `get_tools()`, and `cleanup()`
3. Register tools using `MCPTool` with name, description, schema, and handler
4. Add module to `mcp/modules/__init__.py`
5. Initialize in `mcp/server.py`

## Tool Schema

Tools use JSON Schema for input validation:

```python
MCPTool(
    name="tool_name",
    description="What this tool does",
    input_schema={
        "type": "object",
        "properties": {
            "param1": {"type": "string"},
            "param2": {"type": "integer", "default": 10}
        },
        "required": ["param1"]
    },
    handler=self._tool_handler
)
```

## Services

Shared services are in `services/`:
- `translation_service.py`: Multi-provider translation
- `pronunciation_service.py`: Speech recognition and scoring

## Database

Each module can use its own database or shared database:
- Dutch Learning: `data/dutch_learning.db` (SQLite)
- Add your own in `data/` directory

## Configuration

Module configuration via environment variables in `.env`:

```env
# Dutch Learning
DUTCH_VOCABULARY_DB=./data/dutch_vocab.db
PROGRESS_TRACKING=true

# Personal Assistant
GOOGLE_CALENDAR_ENABLED=false
TODOIST_API_KEY=

# E-Commerce
AMAZON_API_KEY=
STRIPE_API_KEY=
```

## Testing

Test individual modules:

```bash
cd pi-assistant
source venv/bin/activate
python -m pytest tests/test_dutch_learning.py
```

## Future Modules

Planned modules:
- **Health & Fitness**: Exercise tracking, nutrition, wellness
- **Entertainment**: Music, podcasts, media control
- **Travel**: Trip planning, booking, navigation
- **Learning**: Multi-language support beyond Dutch
- **Social**: Social media integration, messaging

## Contributing

When adding new modules:
1. Follow the MCP protocol structure
2. Add comprehensive docstrings
3. Implement error handling
4. Add tests
5. Update this README

# Augmented LLM Pattern

This directory demonstrates the Augmented LLM pattern, which enhances a base LLM with additional capabilities like tools and memory.

## Components

### Core Components

- `augmented.py`: The main implementation of the Augmented LLM pattern
  - `Tool`: Abstract base class for implementing tools
  - `AugmentedLLM`: Main class that combines LLM with tools and memory

### Tools

Located in `tools/basic_tools.py`:

- `WebSearchTool`: Mock implementation of web search
- `CalculatorTool`: Basic calculator functionality
- `WeatherTool`: Mock weather information retrieval

### Examples

Located in `examples/basic_usage.py`:

- Demonstrates how to initialize and use the Augmented LLM
- Shows tool usage and memory capabilities
- Includes sample conversation flow

## Usage

1. Set up environment variables:

```bash
ANTHROPIC_API_KEY=your_key_here  # For Claude
OPENAI_API_KEY=your_key_here     # For GPT-4
```

2. Install dependencies:

```bash
pip install -r requirements.txt
```

3. Run the example:

```bash
python -m examples.basic_usage
```

## Key Features

1. **Multiple LLM Provider Support**

   - Anthropic Claude
   - OpenAI GPT-4
   - Extensible for other providers

2. **Tool Integration**

   - Abstract tool interface
   - Easy to add new tools
   - Tool description formatting for prompts

3. **Memory Support**
   - Optional conversation history
   - Contextual awareness in responses
   - Memory formatting for prompts

## Implementation Details

### Tool Integration

Tools are implemented as classes inheriting from the `Tool` base class:

```python
class Tool:
    def __init__(self, name: str, description: str):
        self.name = name
        self.description = description

    @abstractmethod
    async def execute(self, **kwargs) -> str:
        pass
```

### Memory Management

Memory is implemented as a list of conversation turns:

```python
self.memory = [] if enable_memory else None
```

### Provider-Specific Processing

Each provider has its own processing method:

- `_process_anthropic`: For Claude
- `_process_openai`: For GPT-4

## Best Practices

1. **Tool Development**

   - Keep tools focused and single-purpose
   - Provide clear descriptions
   - Handle errors gracefully
   - Mock external services in examples

2. **Memory Usage**

   - Enable only when needed
   - Consider memory limitations
   - Clear memory when appropriate

3. **Error Handling**
   - Graceful API error handling
   - Tool execution error handling
   - Clear error messages

## Extensions

Consider extending this pattern with:

1. Tool result caching
2. Parallel tool execution
3. Tool chain orchestration
4. Structured memory management
5. Result validation

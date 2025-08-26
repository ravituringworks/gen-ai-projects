# Example Collection

A comprehensive collection of examples demonstrating the implementation and usage of each pattern.

## Building Blocks

### Augmented LLM

- [Basic Usage](../building-block/augmented-llm/examples/basic_usage.py)
  - Simple tool integration
  - Memory usage
  - Basic LLM interaction

## Workflows

### Prompt Chaining

- [Text Analysis](../workflows/prompt-chaining/examples/text_analysis.py)
  - Multi-step text processing
  - Context management
  - Result aggregation

### Routing

- [Support Routing](../workflows/routing/examples/support_routing.py)
  - Ticket classification
  - Handler selection
  - Fallback management

### Parallelization

- [Content Moderation](../workflows/parallelization/examples/content_moderation.py)
  - Parallel content checks
  - Result voting
  - Consensus building

### Orchestrator-Workers

- [Document Processing](../workflows/orchestrator-workers/examples/document_processing.py)
  - Task decomposition
  - Worker coordination
  - Result aggregation

### Evaluator-Optimizer

- [Code Optimization](../workflows/evaluator-optimizer/examples/code_optimization.py)
  - Code improvement
  - Multiple strategies
  - Progress tracking

## Agents

### Autonomous Agent

- [Research Assistant](../agents/autonomous-agent/examples/research_assistant.py)
  - Dynamic planning
  - Tool utilization
  - Goal achievement

### Domain-Specific Agent

- [Medical Assistant](../agents/domain-specific/examples/medical_assistant.py)
  - Domain knowledge
  - Constraint handling
  - Specialized behaviors

## Running Examples

### Prerequisites

1. Python 3.8+
2. Required API keys (see .env.example)
3. Dependencies installed:
   ```bash
   pip install -r requirements.txt
   ```

### Environment Setup

1. Copy environment template:

   ```bash
   cp .env.example .env
   ```

2. Edit .env with your API keys:
   ```
   ANTHROPIC_API_KEY=your_key_here
   # ... other keys as needed
   ```

### Running Individual Examples

Each example can be run directly using Python:

```bash
# Format:
python -m path.to.example

# Examples:
python -m building-block.augmented-llm.examples.basic_usage
python -m workflows.prompt-chaining.examples.text_analysis
python -m agents.autonomous-agent.examples.research_assistant
```

### Example Output

Each example provides clear output showing:

- Input processing
- Intermediate steps
- Final results
- Any errors or issues

## Contributing Examples

1. Follow the existing structure
2. Include clear documentation
3. Handle errors gracefully
4. Add meaningful output
5. Update this index

## Example Categories

### By Complexity

- **Basic**

  - Augmented LLM basic usage
  - Simple prompt chaining
  - Basic routing

- **Intermediate**

  - Content moderation
  - Document processing
  - Research assistant

- **Advanced**
  - Code optimization
  - Medical diagnosis
  - Multi-agent coordination

### By Feature

- **Tool Integration**

  - Web search
  - Calculator
  - Weather info

- **Memory Usage**

  - Conversation history
  - Context management
  - State tracking

- **Error Handling**
  - Input validation
  - API errors
  - Fallback strategies

### By Domain

- **Text Processing**

  - Analysis
  - Summarization
  - Classification

- **Code**

  - Optimization
  - Review
  - Generation

- **Healthcare**
  - Diagnosis
  - Treatment planning
  - Drug interaction

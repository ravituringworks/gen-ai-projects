# Building With LLMs

A practical guide and reference implementation of architecture patterns for building with Large Language Models (LLMs). This repository focuses on native implementations without relying on frameworks, demonstrating how to build both simple workflows and complex autonomous agents.

## Overview

This repository provides:

- 🏗️ Reference architectures for common LLM patterns
- 💻 Example implementations using native LLM APIs
- 📚 Practical guides and best practices
- 🛠️ Templates for quick starts

## Architecture Patterns

### Building Blocks

- ✅ **Augmented LLM**: Basic LLM integration with retrieval, tools, and memory
  - Web search, calculator, and weather tools
  - Memory management
  - Tool integration framework

### Workflows

- ✅ **Prompt Chaining**: Sequential LLM calls with intermediate processing

  - Text analysis example
  - Chain building and execution
  - Context management

- ✅ **Routing**: Input classification and specialized handling

  - Support ticket routing example
  - Dynamic route selection
  - Fallback handling

- ✅ **Parallelization**: Concurrent LLM processing with sectioning and voting

  - Content moderation example
  - Multiple voting strategies
  - Result combination

- ✅ **Orchestrator-Workers**: Dynamic task decomposition and delegation

  - Document processing example
  - Task distribution
  - Worker management

- ✅ **Evaluator-Optimizer**: Iterative improvement through feedback loops
  - Code optimization example
  - Multiple optimization strategies
  - Progress tracking

### Agents

- ✅ **Autonomous Agents**: Self-directed systems with planning and execution

  - Research assistant example
  - Dynamic planning
  - Tool utilization

- ✅ **Domain-Specific Agents**: Implementations for specialized domains
  - Medical diagnosis example
  - Domain knowledge integration
  - Constraint enforcement

## Getting Started

### Prerequisites

- Python 3.8+
- API keys for the LLM provider(s) you want to use
- Git for version control

### Installation

1. Clone the repository:

```bash
git clone https://github.com/coderplex-tech/building-with-llms.git
cd building-with-llms
```

2. Create and activate a virtual environment:

```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

3. Install dependencies:

```bash
pip install -r requirements.txt
```

4. Set up environment variables:

```bash
cp .env.example .env
# Edit .env with your API keys and configuration
```

### Running Examples

Each pattern includes standalone examples that demonstrate its usage. Here's how to run them:

1. **Building Blocks**:

```bash
# Augmented LLM example
python -m building-block.augmented-llm.examples.basic_usage
```

2. **Workflows**:

```bash
# Prompt Chaining
python -m workflows.prompt-chaining.examples.text_analysis

# Routing
python -m workflows.routing.examples.support_routing

# Parallelization
python -m workflows.parallelization.examples.content_moderation

# Orchestrator-Workers
python -m workflows.orchestrator-workers.examples.document_processing

# Evaluator-Optimizer
python -m workflows.evaluator-optimizer.examples.code_optimization
```

3. **Agents**:

```bash
# Autonomous Agent
python -m agents.autonomous-agent.examples.research_assistant

# Domain-Specific Agent
python -m agents.domain-specific.examples.medical_assistant
```

### Directory Structure

```
├── building-block/
│   └── augmented-llm/          # Basic LLM integration
├── workflows/
│   ├── prompt-chaining/        # Sequential processing
│   ├── routing/                # Input classification
│   ├── parallelization/        # Concurrent processing
│   ├── orchestrator-workers/   # Task decomposition
│   └── evaluator-optimizer/    # Iterative improvement
├── agents/
│   ├── autonomous-agent/       # Self-directed systems
│   └── domain-specific/        # Specialized agents
├── requirements.txt            # Project dependencies
├── .env.example               # Example environment variables
└── README.md                  # This file
```

## Implementation Details

Each pattern is implemented with:

- Core classes and interfaces
- Example implementations
- Comprehensive documentation
- Unit tests (coming soon)
- Best practices and usage guidelines

### Current Features

- Multiple LLM provider support (Anthropic, OpenAI, etc.)
- Async/await for efficient processing
- Type hints and Pydantic models
- Error handling and retries
- Detailed logging
- Configuration management

### Coming Soon

- Additional examples for each pattern
- Integration tests
- Performance benchmarks
- CI/CD pipeline
- Docker containerization
- API documentation

## Contributing

We welcome contributions! Here's how you can help:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

Please ensure your code follows our style guide and includes appropriate tests and documentation.

## Why Native Implementations?

While frameworks like LangChain can be useful, we believe building directly with LLM APIs provides:

- Better understanding of core concepts
- More control over implementation details
- Easier debugging and maintenance
- Lower overhead and dependencies

## Resources

- 📚 [Pattern Documentation](./docs)
- 🔧 [Implementation Guides](./guides)
- 📊 [Architecture Decision Records](./adr)
- 🧪 [Example Collection](./examples)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Thanks to all contributors
- Inspired by software architecture patterns and LLM best practices
- Built with modern Python async/await patterns

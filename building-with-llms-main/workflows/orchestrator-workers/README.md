# Orchestrator-Workers Pattern

This pattern demonstrates how to implement dynamic task decomposition and parallel execution using an orchestrator and specialized workers.

## Overview

The orchestrator-workers pattern is useful when:

- Complex tasks need to be broken down dynamically
- Different subtasks require specialized handling
- Tasks have dependencies and execution order constraints
- Parallel execution can improve performance

## Components

### Core Classes

1. **Task**

   - Represents a unit of work
   - Tracks status and dependencies
   - Stores execution results
   - Manages task metadata

2. **Worker**

   - Handles specific task types
   - Executes task logic
   - Manages concurrency
   - Reports task results

3. **Orchestrator**

   - Decomposes complex tasks
   - Manages task dependencies
   - Delegates to workers
   - Coordinates execution

4. **OrchestratorBuilder**
   - Configures worker pool
   - Sets up task routing
   - Manages concurrency limits
   - Simplifies orchestrator creation

## Example Implementation

The `examples/document_processing.py` demonstrates document analysis:

1. Worker Types:

   - Text Extraction
   - Language Detection
   - Summarization
   - Topic Extraction
   - Sentiment Analysis
   - Report Formatting

2. Features:
   - Dynamic task decomposition
   - Parallel processing
   - Dependency management
   - Result aggregation

## Usage

1. Set up environment:

```bash
pip install -r requirements.txt
```

2. Configure API keys:

```bash
export ANTHROPIC_API_KEY=your_key_here
# or
export OPENAI_API_KEY=your_key_here
```

3. Run the example:

```bash
python -m examples.document_processing
```

## Implementation Details

### Task Definition

```python
Task(
    id="task-id",
    type="task-type",
    input_data={},
    dependencies=["dep-1", "dep-2"]
)
```

### Worker Configuration

```python
Worker(
    name="worker-name",
    task_types=["type-1", "type-2"],
    handler=async_handler_function,
    concurrency_limit=2
)
```

### Orchestrator Building

```python
orchestrator = (
    OrchestratorBuilder()
    .add_worker(...)
    .add_worker(...)
    .build(llm_caller)
)
```

### Execution

```python
results = await orchestrator.execute(input_data)
```

## Best Practices

1. **Task Design**

   - Keep tasks focused
   - Define clear interfaces
   - Handle errors gracefully
   - Document dependencies

2. **Worker Implementation**

   - Manage resources efficiently
   - Set appropriate concurrency
   - Handle timeouts
   - Validate inputs/outputs

3. **Dependency Management**

   - Avoid circular dependencies
   - Handle missing dependencies
   - Track task status
   - Clean up resources

4. **Error Handling**
   - Handle worker failures
   - Manage task timeouts
   - Provide fallback options
   - Log execution details

## Extensions

Consider extending this pattern with:

1. **Advanced Orchestration**

   - Dynamic worker allocation
   - Load balancing
   - Priority queues
   - Task scheduling

2. **Monitoring**

   - Task progress tracking
   - Worker performance metrics
   - Resource utilization
   - Error reporting

3. **Resilience**

   - Task retries
   - Circuit breaking
   - Fallback strategies
   - State recovery

4. **Optimization**

   - Task batching
   - Resource pooling
   - Result caching
   - Parallel execution

5. **Integration**
   - External services
   - Message queues
   - Storage systems
   - Monitoring tools

# Parallelization Pattern

This pattern demonstrates how to execute multiple LLM tasks in parallel and combine their results using various voting strategies.

## Overview

The parallelization pattern is useful when:

- Multiple perspectives or analyses are needed
- Tasks can be executed independently
- Results need to be combined systematically
- Performance optimization is important

## Components

### Core Classes

1. **ParallelTask**

   - Defines a task to run in parallel
   - Includes prompt template and weight
   - Supports context variables

2. **Parallelizer**

   - Manages parallel task execution
   - Implements voting strategies
   - Handles result combination

3. **ParallelizerBuilder**
   - Fluent interface for configuration
   - Supports task and strategy setup
   - Enables custom result combining

## Example Implementation

The `examples/content_moderation.py` demonstrates parallel content moderation:

1. Parallel Checks:

   - Toxicity detection
   - Adult content detection
   - Spam detection

2. Features:
   - Weighted voting
   - Custom result combination
   - Detailed explanations
   - Fail-safe design

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
python -m examples.content_moderation
```

## Implementation Details

### Task Definition

```python
ParallelTask(
    name="task_name",
    prompt_template="Your prompt with {variables}",
    weight=1.0
)
```

### Parallelizer Building

```python
parallelizer = (
    ParallelizerBuilder()
    .add_task(...)
    .add_task(...)
    .set_voting_strategy(strategy, custom_combiner)
    .build(llm_caller)
)
```

### Execution

```python
result = await parallelizer.execute(context)
```

## Voting Strategies

1. **Majority Voting**

   - Most common response wins
   - Supports weighted votes
   - Default strategy

2. **Unanimous Voting**

   - Requires all tasks to agree
   - Returns all responses if no consensus
   - Good for critical decisions

3. **Weighted Averaging**

   - For numeric responses
   - Considers task weights
   - Falls back to majority if non-numeric

4. **Custom Combining**
   - User-defined combination logic
   - Access to all task results
   - Maximum flexibility

## Best Practices

1. **Task Design**

   - Keep tasks independent
   - Use clear prompt templates
   - Assign appropriate weights
   - Handle edge cases

2. **Performance**

   - Optimize number of tasks
   - Balance task complexity
   - Monitor execution times
   - Handle timeouts

3. **Result Combination**

   - Choose appropriate strategy
   - Handle conflicting results
   - Provide clear explanations
   - Consider confidence levels

4. **Error Handling**
   - Handle task failures
   - Implement timeouts
   - Provide fallbacks
   - Log issues

## Extensions

Consider extending this pattern with:

1. **Advanced Execution**

   - Dynamic task creation
   - Conditional execution
   - Task prioritization
   - Resource management

2. **Result Processing**

   - Confidence scoring
   - Result filtering
   - Anomaly detection
   - Quality metrics

3. **Performance**

   - Result caching
   - Task batching
   - Rate limiting
   - Load balancing

4. **Monitoring**

   - Task timing
   - Error rates
   - Result distribution
   - Resource usage

5. **Integration**
   - Multiple LLM providers
   - External services
   - Custom task types
   - Result persistence

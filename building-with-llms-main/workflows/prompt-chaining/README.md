# Prompt Chaining Pattern

This pattern demonstrates how to create sequential chains of prompts where each step builds upon the results of previous steps.

## Overview

Prompt chaining is a fundamental pattern for complex LLM workflows where:

- Tasks can be broken down into smaller, focused steps
- Later steps depend on the output of earlier steps
- Results need to be combined in a specific sequence

## Components

### Core Classes

1. **ChainStep**

   - Represents a single step in the chain
   - Defines input/output relationships
   - Handles prompt templating

2. **PromptChain**

   - Manages the execution of steps
   - Validates dependencies
   - Maintains context between steps

3. **ChainBuilder**
   - Fluent interface for chain construction
   - Simplifies chain creation
   - Enables step-by-step definition

## Example Implementation

The `examples/text_analysis.py` demonstrates a three-step chain for text analysis:

1. Topic Extraction

   - Identifies main topics in the text
   - Outputs a comma-separated list

2. Sentiment Analysis

   - Analyzes positive and negative elements
   - Provides detailed sentiment breakdown

3. Summary Generation
   - Combines topics and sentiment
   - Produces a comprehensive summary

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
python -m examples.text_analysis
```

## Implementation Details

### Chain Step Definition

```python
ChainStep(
    name="step_name",
    prompt_template="Your prompt with {variables}",
    output_key="result_key",
    input_keys=["required_input_keys"]
)
```

### Chain Building

```python
chain = (
    ChainBuilder()
    .add_step(...)
    .add_step(...)
    .build(llm_caller, initial_context)
)
```

### Execution

```python
results = await chain.execute()
```

## Best Practices

1. **Step Design**

   - Keep steps focused and single-purpose
   - Use clear, descriptive names
   - Document input/output relationships

2. **Prompt Templates**

   - Use clear, consistent formatting
   - Include necessary context
   - Handle edge cases

3. **Error Handling**

   - Validate inputs at each step
   - Provide clear error messages
   - Handle API failures gracefully

4. **Context Management**
   - Pass only necessary context
   - Use descriptive key names
   - Clean up temporary data

## Extensions

Consider extending this pattern with:

1. **Parallel Execution**

   - Run independent steps concurrently
   - Merge results at synchronization points

2. **Conditional Branching**

   - Skip steps based on conditions
   - Take different paths based on results

3. **Error Recovery**

   - Retry failed steps
   - Provide fallback options

4. **Result Validation**

   - Validate step outputs
   - Ensure data quality

5. **Monitoring**
   - Track step performance
   - Log execution details
   - Measure success rates

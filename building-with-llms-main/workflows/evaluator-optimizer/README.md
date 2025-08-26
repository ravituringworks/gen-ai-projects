# Evaluator-Optimizer Pattern

This pattern demonstrates how to implement iterative improvement through evaluation and optimization feedback loops.

## Overview

The evaluator-optimizer pattern is useful when:

- Solutions need iterative refinement
- Quality can be evaluated systematically
- Multiple optimization strategies may be applicable
- Progress can be measured quantitatively

## Components

### Core Classes

1. **Candidate**

   - Represents a potential solution
   - Tracks evaluation metrics
   - Maintains iteration history
   - Stores feedback data

2. **Optimizer**

   - Manages optimization process
   - Implements multiple strategies
   - Evaluates candidates
   - Generates improvements

3. **OptimizerBuilder**
   - Configures optimization process
   - Sets strategy parameters
   - Defines evaluation criteria
   - Manages optimization limits

## Example Implementation

The `examples/code_optimization.py` demonstrates code improvement:

1. Optimization Strategies:

   - Iterative Improvement
   - Parallel Variations
   - Tournament Selection

2. Evaluation Criteria:

   - Performance
   - Readability
   - Maintainability
   - Error Handling

3. Features:
   - Multiple optimization strategies
   - Weighted evaluation criteria
   - Progress tracking
   - Detailed feedback

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
python -m examples.code_optimization
```

## Implementation Details

### Candidate Definition

```python
Candidate(
    id="candidate-id",
    content="solution content",
    score=0.85,
    feedback="evaluation feedback"
)
```

### Optimizer Configuration

```python
optimizer = (
    OptimizerBuilder()
    .set_strategy(strategy)
    .set_max_iterations(5)
    .set_score_threshold(0.95)
    .build(llm_caller)
)
```

### Optimization

```python
best, history = await optimizer.optimize(
    initial_solution,
    evaluation_criteria
)
```

## Optimization Strategies

1. **Iterative**

   - Sequential improvements
   - Direct feedback incorporation
   - Step-by-step refinement
   - Linear progression

2. **Parallel**

   - Multiple variations
   - Concurrent evaluation
   - Best candidate selection
   - Broader exploration

3. **Tournament**
   - Population-based
   - Competitive selection
   - Genetic-style evolution
   - Diverse solutions

## Best Practices

1. **Evaluation Design**

   - Define clear criteria
   - Use quantitative metrics
   - Weight importance factors
   - Consider trade-offs

2. **Strategy Selection**

   - Match problem characteristics
   - Consider resource constraints
   - Balance exploration/exploitation
   - Adapt to feedback

3. **Termination Conditions**

   - Set realistic thresholds
   - Limit iteration count
   - Monitor improvement rate
   - Handle convergence

4. **Result Analysis**
   - Track improvement history
   - Analyze feedback patterns
   - Document optimizations
   - Validate improvements

## Extensions

Consider extending this pattern with:

1. **Advanced Strategies**

   - Hybrid approaches
   - Adaptive methods
   - Multi-objective optimization
   - Constraint handling

2. **Evaluation Enhancement**

   - Automated testing
   - Performance profiling
   - Quality metrics
   - Validation suites

3. **Learning**

   - Strategy adaptation
   - Pattern recognition
   - Historical learning
   - Meta-optimization

4. **Visualization**

   - Progress tracking
   - Strategy comparison
   - Result analysis
   - Performance metrics

5. **Integration**
   - CI/CD pipelines
   - Version control
   - Issue tracking
   - Documentation generation

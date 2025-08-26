# Routing Pattern

This pattern demonstrates how to use LLMs for intelligent routing of inputs to appropriate handlers based on content classification.

## Overview

The routing pattern is useful when:

- Inputs need to be classified and handled differently
- Multiple specialized handlers exist
- Classification rules are complex or fuzzy
- Routing logic needs to be flexible and maintainable

## Components

### Core Classes

1. **Route**

   - Defines a possible routing destination
   - Specifies handler function and requirements
   - Includes description for LLM classification

2. **Router**

   - Manages route collection and classification
   - Validates input requirements
   - Handles routing to appropriate handlers

3. **RouterBuilder**
   - Fluent interface for router construction
   - Simplifies route configuration
   - Supports fallback handler setup

## Example Implementation

The `examples/support_routing.py` demonstrates a support ticket routing system:

1. Route Types:

   - Technical Support
   - Billing Queries
   - Account Management
   - Feature Requests

2. Features:
   - Automatic ticket classification
   - Required field validation
   - Fallback handling
   - Priority support

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
python -m examples.support_routing
```

## Implementation Details

### Route Definition

```python
Route(
    name="route_name",
    description="Route description for LLM",
    handler=async_handler_function,
    required_fields=["field1", "field2"]
)
```

### Router Building

```python
router = (
    RouterBuilder()
    .add_route(...)
    .add_route(...)
    .set_fallback(fallback_handler)
    .build(llm_caller)
)
```

### Input Processing

```python
response = await router.route(input_data)
```

## Best Practices

1. **Route Design**

   - Use clear, distinct route names
   - Provide detailed route descriptions
   - Define appropriate required fields
   - Implement focused handlers

2. **Classification**

   - Write clear route descriptions
   - Consider overlapping cases
   - Handle ambiguous inputs
   - Use fallback routes

3. **Error Handling**

   - Validate inputs thoroughly
   - Provide clear error messages
   - Implement fallback logic
   - Log routing decisions

4. **Performance**
   - Cache similar classifications
   - Batch similar requests
   - Monitor response times
   - Optimize prompt length

## Extensions

Consider extending this pattern with:

1. **Advanced Classification**

   - Multi-label routing
   - Confidence scores
   - Route priorities
   - Dynamic routes

2. **Performance Optimization**

   - Classification caching
   - Batch processing
   - Parallel routing
   - Rate limiting

3. **Monitoring**

   - Route analytics
   - Classification accuracy
   - Handler performance
   - Error tracking

4. **Dynamic Routing**

   - Runtime route updates
   - A/B testing support
   - Load balancing
   - Circuit breaking

5. **Integration**
   - Queue systems
   - External services
   - Metrics systems
   - Logging services

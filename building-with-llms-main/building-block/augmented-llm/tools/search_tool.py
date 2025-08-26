from augmented_llm import AugmentedLLM
from tools import SearchTool, CalculatorTool

# Initialize with desired capabilities
llm = AugmentedLLM(
    provider="anthropic",
    tools=[SearchTool(), CalculatorTool()],
    enable_memory=True
)

# Use the augmented LLM
response = await llm.process(
    "What was the population of New York in 2020 multiplied by 2?"
)
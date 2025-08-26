import asyncio
import os
from dotenv import load_dotenv
from augmented import AugmentedLLM
from tools import SearchTool, CalculatorTool

async def main():
    # Load environment variables
    load_dotenv()
    
    # Initialize the augmented LLM with Anthropic
    llm = AugmentedLLM(
        provider="anthropic",
        tools=[SearchTool(), CalculatorTool()],
        enable_memory=True
    )
    
    # Example 1: Simple calculation
    print("\nExample 1: Calculation")
    response = await llm.process(
        "What is 1234 multiplied by 5678? Use the calculator tool."
    )
    print(f"Response: {response}")
    
    # Example 2: Chained reasoning with memory
    print("\nExample 2: Chained reasoning")
    response = await llm.process(
        "If I have half of that number in dollars, how many euros would that be? Search for the current exchange rate."
    )
    print(f"Response: {response}")
    
    # Example 3: Combined tools usage
    print("\nExample 3: Combined tools")
    response = await llm.process(
        "What is the population of Tokyo? Multiply that number by 2 and tell me the result."
    )
    print(f"Response: {response}")

if __name__ == "__main__":
    asyncio.run(main())
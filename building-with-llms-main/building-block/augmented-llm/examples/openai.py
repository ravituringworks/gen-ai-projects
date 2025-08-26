import asyncio
import os
from dotenv import load_dotenv
from augmented import AugmentedLLM
from tools import SearchTool, CalculatorTool

async def main():
    # Load environment variables
    load_dotenv()
    
    # Initialize the augmented LLM with OpenAI
    llm = AugmentedLLM(
        provider="openai",
        tools=[SearchTool(), CalculatorTool()],
        enable_memory=True
    )
    
    # Example 1: Using search tool
    print("\nExample 1: Search")
    response = await llm.process(
        "What is the capital of France and what's its population? Use the search tool."
    )
    print(f"Response: {response}")
    
    # Example 2: Using calculator with memory
    print("\nExample 2: Calculator with memory")
    response = await llm.process(
        "If the population were to increase by 15%, what would be the new population? Use the calculator."
    )
    print(f"Response: {response}")
    
    # Example 3: Multiple tool interaction
    print("\nExample 3: Multiple tools")
    response = await llm.process(
        "What is the GDP of Germany? Calculate 5% of that number."
    )
    print(f"Response: {response}")

if __name__ == "__main__":
    asyncio.run(main())
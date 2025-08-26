import asyncio
import os
from dotenv import load_dotenv
from ..augmented import AugmentedLLM
from ..tools.basic_tools import WebSearchTool, CalculatorTool, WeatherTool

async def main():
    # Load environment variables
    load_dotenv()
    
    # Initialize tools
    tools = [
        WebSearchTool(),
        CalculatorTool(),
        WeatherTool()
    ]
    
    # Initialize augmented LLM with tools and memory
    llm = AugmentedLLM(
        provider="anthropic",  # or "openai"
        tools=tools,
        enable_memory=True
    )
    
    # Example conversation
    queries = [
        "What's 234 * 456?",
        "What's the weather like in London?",
        "Can you search for information about quantum computing?",
        "What did I ask about earlier regarding calculations?"
    ]
    
    for query in queries:
        print(f"\nUser: {query}")
        response = await llm.process(query)
        print(f"Assistant: {response}")

if __name__ == "__main__":
    asyncio.run(main()) 
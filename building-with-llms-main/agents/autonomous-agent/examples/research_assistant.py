import asyncio
import os
from typing import Dict, Any
from dotenv import load_dotenv
import anthropic
from ..agent import AgentBuilder, Memory

async def llm_call(prompt: str) -> str:
    """Call Anthropic's Claude API"""
    client = anthropic.Anthropic()
    response = await client.messages.create(
        model="claude-3-opus-20240229",
        max_tokens=1000,
        temperature=0.7,
        system="You are a helpful research assistant.",
        messages=[{"role": "user", "content": prompt}]
    )
    return response.content[0].text

# Tool handlers for research tasks
async def handle_web_search(params: Dict[str, Any]) -> Dict[str, Any]:
    """Search the web for information (mock implementation)"""
    query = params["query"]
    return {
        "results": [
            {
                "title": f"Search result 1 for: {query}",
                "snippet": "This is a mock search result...",
                "url": "https://example.com/1"
            },
            {
                "title": f"Search result 2 for: {query}",
                "snippet": "Another mock search result...",
                "url": "https://example.com/2"
            }
        ]
    }

async def handle_read_webpage(params: Dict[str, Any]) -> Dict[str, Any]:
    """Extract content from a webpage (mock implementation)"""
    url = params["url"]
    return {
        "title": "Mock webpage title",
        "content": f"Mock content extracted from {url}...",
        "metadata": {
            "author": "John Doe",
            "date": "2024-02-15"
        }
    }

async def handle_summarize_text(params: Dict[str, Any]) -> Dict[str, Any]:
    """Summarize text content"""
    text = params["text"]
    return {
        "summary": f"Summary of: {text}",
        "key_points": [
            "Key point 1",
            "Key point 2",
            "Key point 3"
        ]
    }

async def handle_extract_facts(params: Dict[str, Any]) -> Dict[str, Any]:
    """Extract factual information from text"""
    text = params["text"]
    return {
        "facts": [
            "Fact 1 extracted from text",
            "Fact 2 extracted from text",
            "Fact 3 extracted from text"
        ],
        "confidence_scores": [0.9, 0.8, 0.7]
    }

async def handle_save_notes(params: Dict[str, Any]) -> Dict[str, Any]:
    """Save research notes (mock implementation)"""
    notes = params["notes"]
    return {
        "saved": True,
        "location": "research_notes.md",
        "timestamp": "2024-02-15T12:00:00Z"
    }

async def main():
    # Load environment variables
    load_dotenv()
    
    # Initialize memory
    memory = Memory(
        context={
            "research_topic": "artificial intelligence",
            "focus_areas": [
                "machine learning",
                "neural networks",
                "deep learning"
            ]
        }
    )
    
    # Build the research assistant
    assistant = (
        AgentBuilder()
        .add_tool(
            name="web_search",
            description="Search the web for information",
            parameters={
                "query": "search query string"
            },
            handler=handle_web_search
        )
        .add_tool(
            name="read_webpage",
            description="Extract content from a webpage",
            parameters={
                "url": "webpage URL"
            },
            handler=handle_read_webpage
        )
        .add_tool(
            name="summarize_text",
            description="Generate a summary of text content",
            parameters={
                "text": "text to summarize"
            },
            handler=handle_summarize_text
        )
        .add_tool(
            name="extract_facts",
            description="Extract factual information from text",
            parameters={
                "text": "text to analyze"
            },
            handler=handle_extract_facts
        )
        .add_tool(
            name="save_notes",
            description="Save research notes",
            parameters={
                "notes": "notes to save"
            },
            handler=handle_save_notes
        )
        .with_memory(memory)
        .build(llm_caller=llm_call)
    )
    
    # Research goals to accomplish
    goals = [
        "Research recent advancements in neural networks and summarize key findings",
        "Investigate applications of deep learning in healthcare and compile examples",
        "Analyze trends in machine learning research and identify emerging areas"
    ]
    
    # Execute research tasks
    for goal in goals:
        print(f"\n{'-' * 50}")
        print(f"Executing Goal: {goal}")
        print(f"{'-' * 50}")
        
        try:
            # Execute goal
            actions = await assistant.execute(goal)
            
            # Print results
            print("\nCompleted Actions:")
            for action in actions:
                print(f"\n{action.description}:")
                print(f"Tool: {action.name}")
                print(f"Result: {action.result}")
                
        except Exception as e:
            print(f"Error executing goal: {str(e)}")

if __name__ == "__main__":
    asyncio.run(main()) 
import asyncio
import os
from typing import Dict, Any
from dotenv import load_dotenv
import anthropic
from ..chain import ChainBuilder

async def llm_call(prompt: str) -> str:
    """Call Anthropic's Claude API"""
    client = anthropic.Anthropic()
    response = await client.messages.create(
        model="claude-3-opus-20240229",
        max_tokens=1000,
        temperature=0.7,
        system="You are a helpful text analysis assistant.",
        messages=[{"role": "user", "content": prompt}]
    )
    return response.content[0].text

async def main():
    # Load environment variables
    load_dotenv()
    
    # Example text to analyze
    text = """
    Climate change poses one of the greatest challenges to our planet. 
    Rising temperatures, extreme weather events, and sea level rise threaten 
    communities worldwide. However, renewable energy adoption, conservation 
    efforts, and technological innovation offer hope for addressing this crisis.
    """
    
    # Build the analysis chain
    chain = (
        ChainBuilder()
        .add_step(
            name="extract_topics",
            prompt_template=(
                "Extract the main topics from this text. "
                "Format the response as a comma-separated list:\n\n{text}"
            ),
            output_key="topics",
            input_keys=["text"]
        )
        .add_step(
            name="sentiment_analysis",
            prompt_template=(
                "Analyze the sentiment of this text. Consider both positive "
                "and negative elements. Be specific about what contributes to "
                "each:\n\n{text}"
            ),
            output_key="sentiment",
            input_keys=["text"]
        )
        .add_step(
            name="generate_summary",
            prompt_template=(
                "Generate a concise summary of the text, incorporating the "
                "main topics ({topics}) and the sentiment analysis:\n\n"
                "Sentiment Analysis: {sentiment}\n"
                "Original Text: {text}"
            ),
            output_key="summary",
            input_keys=["text", "topics", "sentiment"]
        )
        .build(
            llm_caller=llm_call,
            initial_context={"text": text}
        )
    )
    
    # Execute the chain
    try:
        results = await chain.execute()
        
        # Print results
        print("\nText Analysis Results:")
        print("\nTopics:")
        print(results["topics"])
        print("\nSentiment Analysis:")
        print(results["sentiment"])
        print("\nFinal Summary:")
        print(results["summary"])
        
    except Exception as e:
        print(f"Error executing chain: {str(e)}")

if __name__ == "__main__":
    asyncio.run(main()) 
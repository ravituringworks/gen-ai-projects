import asyncio
import os
from typing import Dict, Any, List
from dotenv import load_dotenv
import anthropic
from ..parallel import ParallelizerBuilder, VotingStrategy, ParallelResult

async def llm_call(prompt: str) -> str:
    """Call Anthropic's Claude API"""
    client = anthropic.Anthropic()
    response = await client.messages.create(
        model="claude-3-opus-20240229",
        max_tokens=1000,
        temperature=0.7,
        system="You are a helpful content moderation assistant.",
        messages=[{"role": "user", "content": prompt}]
    )
    return response.content[0].text

def custom_moderation_combiner(results: List[ParallelResult]) -> str:
    """Custom combiner for moderation results"""
    # Count votes for each category
    votes = {"safe": 0, "unsafe": 0}
    reasons = []
    
    for result in results:
        response = result.response.strip().lower()
        if "unsafe" in response:
            votes["unsafe"] += result.weight
            reasons.append(f"{result.task_name}: {response}")
        else:
            votes["safe"] += result.weight
    
    # If any moderator flags as unsafe, content is unsafe
    if votes["unsafe"] > 0:
        return f"UNSAFE - Reasons:\n" + "\n".join(reasons)
    return "SAFE - All moderators approved the content"

async def main():
    # Load environment variables
    load_dotenv()
    
    # Build the content moderator
    moderator = (
        ParallelizerBuilder()
        .add_task(
            name="toxicity",
            prompt_template=(
                "Analyze this content for toxic language or hate speech. "
                "Respond with SAFE if no issues found, or UNSAFE with explanation "
                "if problems detected:\n\n{content}"
            ),
            weight=1.0
        )
        .add_task(
            name="adult",
            prompt_template=(
                "Check if this content contains adult themes or explicit material. "
                "Respond with SAFE if appropriate for general audience, or UNSAFE "
                "with explanation if adult content detected:\n\n{content}"
            ),
            weight=1.0
        )
        .add_task(
            name="spam",
            prompt_template=(
                "Evaluate if this content is spam or promotional material. "
                "Respond with SAFE if legitimate content, or UNSAFE with "
                "explanation if spam detected:\n\n{content}"
            ),
            weight=0.5  # Lower weight for spam detection
        )
        .set_voting_strategy(
            VotingStrategy.CUSTOM,
            custom_combiner=custom_moderation_combiner
        )
        .build(llm_caller=llm_call)
    )
    
    # Example content to moderate
    content_examples = [
        {
            "content": """
            Check out our amazing weight loss solution! 
            Lose 20 pounds in just 1 week with this miracle pill.
            Limited time offer - 80% off! Click now to order!
            """
        },
        {
            "content": """
            The new movie was fantastic! Great performances by the entire cast,
            and the special effects were incredible. Highly recommend watching
            it in theaters. Family-friendly and entertaining throughout.
            """
        },
        {
            "content": """
            I completely disagree with your political views! Only an idiot would
            think that way. You're what's wrong with this country, and you
            should be ashamed of yourself!
            """
        }
    ]
    
    # Process content
    for i, example in enumerate(content_examples, 1):
        print(f"\nModerating Content Example {i}:")
        print("-" * 50)
        print(example["content"].strip())
        print("-" * 50)
        
        try:
            result = await moderator.execute(example)
            print(f"Moderation Result: {result}")
        except Exception as e:
            print(f"Error moderating content: {str(e)}")

if __name__ == "__main__":
    asyncio.run(main()) 
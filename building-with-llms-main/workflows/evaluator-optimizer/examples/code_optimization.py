import asyncio
import os
from typing import Dict, Any
from dotenv import load_dotenv
import anthropic
from ..optimizer import OptimizerBuilder, OptimizationStrategy

async def llm_call(prompt: str) -> str:
    """Call Anthropic's Claude API"""
    client = anthropic.Anthropic()
    response = await client.messages.create(
        model="claude-3-opus-20240229",
        max_tokens=1000,
        temperature=0.7,
        system="You are a helpful code optimization assistant.",
        messages=[{"role": "user", "content": prompt}]
    )
    return response.content[0].text

async def main():
    # Load environment variables
    load_dotenv()
    
    # Initial code to optimize
    initial_code = """
    def fibonacci(n):
        if n <= 0:
            return []
        elif n == 1:
            return [0]
        
        sequence = [0, 1]
        while len(sequence) < n:
            sequence.append(sequence[-1] + sequence[-2])
        return sequence
    
    def find_fibonacci_sum(n):
        sequence = fibonacci(n)
        return sum(sequence)
    """
    
    # Evaluation criteria
    criteria = {
        "performance": {
            "description": "Code should be efficient in terms of time and space complexity",
            "weight": 0.4
        },
        "readability": {
            "description": "Code should be clear, well-documented, and follow Python best practices",
            "weight": 0.3
        },
        "maintainability": {
            "description": "Code should be easy to modify and extend",
            "weight": 0.2
        },
        "error_handling": {
            "description": "Code should handle edge cases and invalid inputs gracefully",
            "weight": 0.1
        }
    }
    
    # Create optimizer with different strategies
    strategies = [
        ("Iterative Optimization", OptimizationStrategy.ITERATIVE),
        ("Parallel Optimization", OptimizationStrategy.PARALLEL),
        ("Tournament Optimization", OptimizationStrategy.TOURNAMENT)
    ]
    
    for strategy_name, strategy in strategies:
        print(f"\n{'-' * 50}")
        print(f"Running {strategy_name}")
        print(f"{'-' * 50}")
        
        optimizer = (
            OptimizerBuilder()
            .set_strategy(strategy)
            .set_max_iterations(3)
            .set_score_threshold(0.95)
            .set_population_size(3)
            .build(llm_caller=llm_call)
        )
        
        try:
            # Optimize code
            best, history = await optimizer.optimize(initial_code, criteria)
            
            print(f"\nOptimization completed after {len(history)} iterations")
            print(f"Final score: {best.score}")
            print("\nOptimized Code:")
            print(best.content)
            print("\nFeedback:")
            print(best.feedback)
            
        except Exception as e:
            print(f"Error during optimization: {str(e)}")

if __name__ == "__main__":
    asyncio.run(main()) 
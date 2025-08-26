from typing import List, Dict, Any, Callable, Optional, Union, Tuple
from abc import ABC, abstractmethod
from pydantic import BaseModel
import asyncio
from enum import Enum

class OptimizationStrategy(str, Enum):
    """Strategies for optimization"""
    ITERATIVE = "iterative"
    PARALLEL = "parallel"
    TOURNAMENT = "tournament"

class Candidate(BaseModel):
    """A candidate solution"""
    id: str
    content: str
    score: Optional[float] = None
    feedback: Optional[str] = None
    iteration: int = 0

class EvaluationResult(BaseModel):
    """Result of evaluating a candidate"""
    score: float
    feedback: str
    improvements: List[str]

class OptimizerConfig(BaseModel):
    """Configuration for the optimizer"""
    max_iterations: int = 5
    score_threshold: float = 0.9
    optimization_strategy: OptimizationStrategy = OptimizationStrategy.ITERATIVE
    population_size: int = 3
    tournament_size: int = 2

class Optimizer:
    """Improves solutions through evaluation and optimization"""
    
    def __init__(
        self,
        llm_caller: Callable[[str], str],
        config: Optional[OptimizerConfig] = None
    ):
        self.llm_caller = llm_caller
        self.config = config or OptimizerConfig()
        self.candidates: List[Candidate] = []
    
    async def _evaluate_candidate(
        self,
        candidate: Candidate,
        evaluation_criteria: Dict[str, Any]
    ) -> EvaluationResult:
        """Evaluate a candidate solution"""
        prompt = (
            "Evaluate this solution based on the given criteria. Provide:\n"
            "1. A score between 0 and 1\n"
            "2. Specific feedback\n"
            "3. Suggested improvements\n\n"
            f"Solution:\n{candidate.content}\n\n"
            f"Criteria:\n{evaluation_criteria}\n\n"
            "Respond in JSON format:\n"
            "{\n"
            '  "score": 0.8,\n'
            '  "feedback": "Detailed feedback here",\n'
            '  "improvements": ["improvement 1", "improvement 2"]\n'
            "}"
        )
        
        try:
            response = await self.llm_caller(prompt)
            return EvaluationResult.parse_raw(response)
        except Exception as e:
            raise Exception(f"Error evaluating candidate: {str(e)}")
    
    async def _optimize_candidate(
        self,
        candidate: Candidate,
        evaluation_result: EvaluationResult
    ) -> Candidate:
        """Generate an improved version of the candidate"""
        prompt = (
            "Improve this solution based on the evaluation feedback and "
            "suggested improvements. Maintain the same format and structure, "
            "but address the identified issues.\n\n"
            f"Original Solution:\n{candidate.content}\n\n"
            f"Feedback:\n{evaluation_result.feedback}\n\n"
            "Suggested Improvements:\n" +
            "\n".join(f"- {imp}" for imp in evaluation_result.improvements) +
            "\n\nImproved Solution:"
        )
        
        try:
            improved_content = await self.llm_caller(prompt)
            return Candidate(
                id=f"{candidate.id}-v{candidate.iteration + 1}",
                content=improved_content,
                iteration=candidate.iteration + 1
            )
        except Exception as e:
            raise Exception(f"Error optimizing candidate: {str(e)}")
    
    async def _generate_variations(
        self,
        candidate: Candidate,
        num_variations: int
    ) -> List[Candidate]:
        """Generate multiple variations of a candidate"""
        prompt = (
            f"Generate {num_variations} different variations of this solution. "
            "Each variation should maintain the same basic structure but vary in "
            "approach or implementation details.\n\n"
            f"Original Solution:\n{candidate.content}\n\n"
            "Respond with each variation separated by '---'\n"
        )
        
        try:
            response = await self.llm_caller(prompt)
            variations = [v.strip() for v in response.split("---")]
            return [
                Candidate(
                    id=f"{candidate.id}-var{i}",
                    content=content,
                    iteration=candidate.iteration
                )
                for i, content in enumerate(variations[:num_variations], 1)
            ]
        except Exception as e:
            raise Exception(f"Error generating variations: {str(e)}")
    
    async def _run_tournament(
        self,
        candidates: List[Candidate],
        evaluation_criteria: Dict[str, Any]
    ) -> List[Candidate]:
        """Run a tournament to select the best candidates"""
        # Randomly pair candidates for tournament rounds
        import random
        tournament_pairs = []
        available = candidates.copy()
        while len(available) >= 2:
            pair = random.sample(available, 2)
            tournament_pairs.append(pair)
            for p in pair:
                available.remove(p)
        
        # If odd number, add last one to winners
        winners = available
        
        # Evaluate pairs and select winners
        for pair in tournament_pairs:
            results = await asyncio.gather(*[
                self._evaluate_candidate(c, evaluation_criteria)
                for c in pair
            ])
            # Add winner to next round
            winner = pair[0] if results[0].score > results[1].score else pair[1]
            winners.append(winner)
        
        return winners
    
    async def optimize(
        self,
        initial_solution: str,
        evaluation_criteria: Dict[str, Any]
    ) -> Tuple[Candidate, List[Candidate]]:
        """Optimize a solution through iterative improvement"""
        # Initialize first candidate
        current = Candidate(
            id="solution-v0",
            content=initial_solution,
            iteration=0
        )
        
        history = [current]
        
        if self.config.optimization_strategy == OptimizationStrategy.ITERATIVE:
            # Iterative improvement
            for i in range(self.config.max_iterations):
                # Evaluate current candidate
                eval_result = await self._evaluate_candidate(
                    current,
                    evaluation_criteria
                )
                
                # Update candidate with evaluation results
                current.score = eval_result.score
                current.feedback = eval_result.feedback
                
                # Check if good enough
                if current.score >= self.config.score_threshold:
                    break
                
                # Generate improved version
                current = await self._optimize_candidate(current, eval_result)
                history.append(current)
                
        elif self.config.optimization_strategy == OptimizationStrategy.PARALLEL:
            # Parallel variations and improvement
            for i in range(self.config.max_iterations):
                # Generate variations
                variations = await self._generate_variations(
                    current,
                    self.config.population_size
                )
                
                # Evaluate all variations
                eval_results = await asyncio.gather(*[
                    self._evaluate_candidate(v, evaluation_criteria)
                    for v in variations
                ])
                
                # Update variations with scores
                for var, result in zip(variations, eval_results):
                    var.score = result.score
                    var.feedback = result.feedback
                
                # Select best variation
                best = max(variations, key=lambda x: x.score)
                if best.score >= self.config.score_threshold:
                    current = best
                    history.extend(variations)
                    break
                
                # Improve best variation
                current = await self._optimize_candidate(
                    best,
                    eval_results[variations.index(best)]
                )
                history.extend(variations + [current])
                
        else:  # TOURNAMENT
            # Tournament-based optimization
            current_population = [current]
            
            for i in range(self.config.max_iterations):
                # Generate variations for tournament
                variations = await self._generate_variations(
                    current,
                    self.config.population_size - 1
                )
                current_population.extend(variations)
                
                # Run tournament
                winners = await self._run_tournament(
                    current_population,
                    evaluation_criteria
                )
                
                # Select best winner
                best = winners[0]
                for w in winners[1:]:
                    eval_result = await self._evaluate_candidate(
                        w,
                        evaluation_criteria
                    )
                    w.score = eval_result.score
                    w.feedback = eval_result.feedback
                    if w.score > (best.score or 0):
                        best = w
                
                if best.score >= self.config.score_threshold:
                    current = best
                    history.extend(current_population)
                    break
                
                # Use best as seed for next generation
                current = best
                current_population = [current]
                history.extend(current_population)
        
        return current, history

class OptimizerBuilder:
    """Helper class to build optimizers"""
    
    def __init__(self):
        self.config = OptimizerConfig()
    
    def set_max_iterations(self, max_iterations: int) -> 'OptimizerBuilder':
        """Set maximum number of optimization iterations"""
        self.config.max_iterations = max_iterations
        return self
    
    def set_score_threshold(self, threshold: float) -> 'OptimizerBuilder':
        """Set score threshold for early stopping"""
        self.config.score_threshold = threshold
        return self
    
    def set_strategy(
        self,
        strategy: OptimizationStrategy
    ) -> 'OptimizerBuilder':
        """Set optimization strategy"""
        self.config.optimization_strategy = strategy
        return self
    
    def set_population_size(self, size: int) -> 'OptimizerBuilder':
        """Set population size for parallel/tournament strategies"""
        self.config.population_size = size
        return self
    
    def set_tournament_size(self, size: int) -> 'OptimizerBuilder':
        """Set tournament size for tournament strategy"""
        self.config.tournament_size = size
        return self
    
    def build(
        self,
        llm_caller: Callable[[str], str]
    ) -> Optimizer:
        """Build the optimizer"""
        return Optimizer(
            llm_caller=llm_caller,
            config=self.config
        ) 
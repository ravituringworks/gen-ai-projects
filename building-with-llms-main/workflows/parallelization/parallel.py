from typing import List, Dict, Any, Callable, Optional, Union
from abc import ABC, abstractmethod
from pydantic import BaseModel
import asyncio
from enum import Enum

class VotingStrategy(str, Enum):
    """Strategies for combining parallel results"""
    MAJORITY = "majority"
    UNANIMOUS = "unanimous"
    WEIGHTED = "weighted"
    CUSTOM = "custom"

class ParallelTask(BaseModel):
    """A task to be executed in parallel"""
    name: str
    prompt_template: str
    weight: float = 1.0

class ParallelResult(BaseModel):
    """Result from a parallel task execution"""
    task_name: str
    response: str
    weight: float

class Parallelizer:
    """Executes multiple LLM tasks in parallel and combines results"""
    
    def __init__(
        self,
        tasks: List[ParallelTask],
        llm_caller: Callable[[str], str],
        voting_strategy: VotingStrategy = VotingStrategy.MAJORITY,
        custom_combiner: Optional[Callable[[List[ParallelResult]], str]] = None
    ):
        self.tasks = tasks
        self.llm_caller = llm_caller
        self.voting_strategy = voting_strategy
        self.custom_combiner = custom_combiner
        self._validate_config()
    
    def _validate_config(self):
        """Validate parallelizer configuration"""
        if self.voting_strategy == VotingStrategy.CUSTOM and not self.custom_combiner:
            raise ValueError(
                "Custom voting strategy requires a custom_combiner function"
            )
        
        names = set()
        for task in self.tasks:
            if task.name in names:
                raise ValueError(f"Duplicate task name: {task.name}")
            names.add(task.name)
    
    async def _execute_task(
        self,
        task: ParallelTask,
        context: Dict[str, Any]
    ) -> ParallelResult:
        """Execute a single task"""
        try:
            # Format prompt with context
            prompt = task.prompt_template.format(**context)
            
            # Call LLM
            response = await self.llm_caller(prompt)
            
            return ParallelResult(
                task_name=task.name,
                response=response,
                weight=task.weight
            )
            
        except Exception as e:
            raise Exception(f"Error executing task '{task.name}': {str(e)}")
    
    def _combine_majority(self, results: List[ParallelResult]) -> str:
        """Combine results using majority voting"""
        # Count occurrences of each response
        response_counts: Dict[str, float] = {}
        for result in results:
            response = result.response.strip().lower()
            response_counts[response] = (
                response_counts.get(response, 0) + result.weight
            )
        
        # Find response with highest weighted count
        max_count = 0
        majority_response = None
        for response, count in response_counts.items():
            if count > max_count:
                max_count = count
                majority_response = response
        
        return majority_response or results[0].response
    
    def _combine_unanimous(self, results: List[ParallelResult]) -> str:
        """Combine results requiring unanimity"""
        # Check if all responses are the same
        first_response = results[0].response.strip().lower()
        if all(r.response.strip().lower() == first_response for r in results):
            return first_response
        
        # If no unanimity, return all responses
        return "No unanimous agreement. Responses: " + ", ".join(
            f"{r.task_name}: {r.response}" for r in results
        )
    
    def _combine_weighted(self, results: List[ParallelResult]) -> str:
        """Combine results using weighted averaging"""
        # This is a simple implementation that works with numeric responses
        try:
            total_weight = sum(r.weight for r in results)
            weighted_sum = sum(
                float(r.response) * r.weight for r in results
            )
            return str(weighted_sum / total_weight)
        except ValueError:
            # If responses aren't numeric, fall back to majority
            return self._combine_majority(results)
    
    def _combine_results(self, results: List[ParallelResult]) -> str:
        """Combine results using the specified strategy"""
        if self.voting_strategy == VotingStrategy.CUSTOM:
            return self.custom_combiner(results)
        elif self.voting_strategy == VotingStrategy.UNANIMOUS:
            return self._combine_unanimous(results)
        elif self.voting_strategy == VotingStrategy.WEIGHTED:
            return self._combine_weighted(results)
        else:  # MAJORITY
            return self._combine_majority(results)
    
    async def execute(self, context: Dict[str, Any]) -> str:
        """Execute all tasks in parallel and combine results"""
        # Create tasks
        tasks = [
            self._execute_task(task, context)
            for task in self.tasks
        ]
        
        # Execute all tasks in parallel
        results = await asyncio.gather(*tasks)
        
        # Combine results
        return self._combine_results(results)

class ParallelizerBuilder:
    """Helper class to build parallelizers"""
    
    def __init__(self):
        self.tasks: List[ParallelTask] = []
        self.voting_strategy = VotingStrategy.MAJORITY
        self.custom_combiner = None
    
    def add_task(
        self,
        name: str,
        prompt_template: str,
        weight: float = 1.0
    ) -> 'ParallelizerBuilder':
        """Add a task to the parallelizer"""
        self.tasks.append(
            ParallelTask(
                name=name,
                prompt_template=prompt_template,
                weight=weight
            )
        )
        return self
    
    def set_voting_strategy(
        self,
        strategy: VotingStrategy,
        custom_combiner: Optional[Callable] = None
    ) -> 'ParallelizerBuilder':
        """Set the voting strategy"""
        self.voting_strategy = strategy
        self.custom_combiner = custom_combiner
        return self
    
    def build(
        self,
        llm_caller: Callable[[str], str]
    ) -> Parallelizer:
        """Build the parallelizer"""
        return Parallelizer(
            tasks=self.tasks,
            llm_caller=llm_caller,
            voting_strategy=self.voting_strategy,
            custom_combiner=self.custom_combiner
        ) 
from typing import List, Dict, Any, Callable, Optional, Union
from abc import ABC, abstractmethod
from pydantic import BaseModel
import asyncio
import json

class Task(BaseModel):
    """A task to be executed by a worker"""
    id: str
    type: str
    input_data: Dict[str, Any]
    dependencies: List[str] = []
    status: str = "pending"
    result: Optional[Dict[str, Any]] = None

class Worker(BaseModel):
    """A worker that can execute specific types of tasks"""
    name: str
    task_types: List[str]
    handler: Callable[[Dict[str, Any]], Any]
    concurrency_limit: int = 1

class Orchestrator:
    """Manages task decomposition, delegation, and execution"""
    
    def __init__(
        self,
        workers: List[Worker],
        llm_caller: Callable[[str], str]
    ):
        self.workers = workers
        self.llm_caller = llm_caller
        self.tasks: Dict[str, Task] = {}
        self.worker_queues: Dict[str, asyncio.Queue] = {}
        self._validate_config()
        self._setup_queues()
    
    def _validate_config(self):
        """Validate orchestrator configuration"""
        # Check for duplicate worker names
        names = set()
        for worker in self.workers:
            if worker.name in names:
                raise ValueError(f"Duplicate worker name: {worker.name}")
            names.add(worker.name)
        
        # Check that all task types have handlers
        task_types = set()
        for worker in self.workers:
            task_types.update(worker.task_types)
    
    def _setup_queues(self):
        """Set up task queues for each worker"""
        for worker in self.workers:
            self.worker_queues[worker.name] = asyncio.Queue()
    
    async def _decompose_task(
        self,
        input_data: Dict[str, Any]
    ) -> List[Task]:
        """Use LLM to decompose input into subtasks"""
        prompt = (
            "Decompose this task into smaller subtasks. For each subtask, specify:\n"
            "1. A unique ID\n"
            "2. The task type (one of: " + 
            ", ".join(self._get_all_task_types()) + ")\n"
            "3. Input data\n"
            "4. Dependencies (other task IDs)\n\n"
            "Respond in JSON format:\n"
            "{\n"
            '  "tasks": [\n'
            "    {\n"
            '      "id": "task-1",\n'
            '      "type": "task_type",\n'
            '      "input_data": {},\n'
            '      "dependencies": []\n'
            "    }\n"
            "  ]\n"
            "}\n\n"
            f"Task to decompose:\n{json.dumps(input_data, indent=2)}"
        )
        
        try:
            response = await self.llm_caller(prompt)
            task_data = json.loads(response)
            return [Task(**task) for task in task_data["tasks"]]
        except Exception as e:
            raise Exception(f"Error decomposing task: {str(e)}")
    
    def _get_all_task_types(self) -> List[str]:
        """Get all supported task types"""
        task_types = set()
        for worker in self.workers:
            task_types.update(worker.task_types)
        return sorted(list(task_types))
    
    def _get_workers_for_task(self, task_type: str) -> List[Worker]:
        """Get workers that can handle a specific task type"""
        return [
            worker for worker in self.workers
            if task_type in worker.task_types
        ]
    
    async def _execute_worker(self, worker: Worker):
        """Execute tasks for a specific worker"""
        queue = self.worker_queues[worker.name]
        while True:
            task = await queue.get()
            try:
                # Execute task
                result = await worker.handler(task.input_data)
                
                # Update task status and result
                task.status = "completed"
                task.result = result
                
                # Check if any dependent tasks can now run
                await self._check_dependencies()
                
            except Exception as e:
                task.status = "failed"
                task.result = {"error": str(e)}
            
            finally:
                queue.task_done()
    
    async def _check_dependencies(self):
        """Check and queue tasks whose dependencies are met"""
        for task in self.tasks.values():
            if task.status == "pending":
                # Check if all dependencies are completed
                deps_completed = all(
                    self.tasks[dep].status == "completed"
                    for dep in task.dependencies
                )
                
                if deps_completed:
                    # Find suitable worker and queue task
                    workers = self._get_workers_for_task(task.type)
                    if workers:
                        # Simple round-robin for now
                        worker = workers[0]
                        await self.worker_queues[worker.name].put(task)
                        task.status = "queued"
    
    async def execute(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """Execute a complex task using orchestration"""
        try:
            # Decompose task
            tasks = await self._decompose_task(input_data)
            
            # Store tasks
            for task in tasks:
                self.tasks[task.id] = task
            
            # Start worker coroutines
            worker_tasks = []
            for worker in self.workers:
                for _ in range(worker.concurrency_limit):
                    worker_tasks.append(
                        asyncio.create_task(self._execute_worker(worker))
                    )
            
            # Queue initial tasks (those with no dependencies)
            for task in tasks:
                if not task.dependencies:
                    workers = self._get_workers_for_task(task.type)
                    if workers:
                        worker = workers[0]  # Simple round-robin
                        await self.worker_queues[worker.name].put(task)
                        task.status = "queued"
            
            # Wait for all tasks to complete
            for queue in self.worker_queues.values():
                await queue.join()
            
            # Cancel worker tasks
            for task in worker_tasks:
                task.cancel()
            
            # Combine results
            return {
                task.id: task.result
                for task in self.tasks.values()
                if task.status == "completed"
            }
            
        except Exception as e:
            raise Exception(f"Error in orchestration: {str(e)}")

class OrchestratorBuilder:
    """Helper class to build orchestrators"""
    
    def __init__(self):
        self.workers: List[Worker] = []
    
    def add_worker(
        self,
        name: str,
        task_types: List[str],
        handler: Callable[[Dict[str, Any]], Any],
        concurrency_limit: int = 1
    ) -> 'OrchestratorBuilder':
        """Add a worker to the orchestrator"""
        self.workers.append(
            Worker(
                name=name,
                task_types=task_types,
                handler=handler,
                concurrency_limit=concurrency_limit
            )
        )
        return self
    
    def build(
        self,
        llm_caller: Callable[[str], str]
    ) -> Orchestrator:
        """Build the orchestrator"""
        return Orchestrator(
            workers=self.workers,
            llm_caller=llm_caller
        ) 
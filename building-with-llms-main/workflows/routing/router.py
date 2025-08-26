from typing import Dict, Any, List, Callable, Optional, Union
from abc import ABC, abstractmethod
from pydantic import BaseModel
import json

class Route(BaseModel):
    """Represents a possible routing destination"""
    name: str
    description: str
    handler: Callable[[Dict[str, Any]], Any]
    required_fields: List[str] = []

class Router:
    """Routes inputs to appropriate handlers based on LLM classification"""
    
    def __init__(
        self,
        routes: List[Route],
        llm_caller: Callable[[str], str],
        fallback_handler: Optional[Callable[[Dict[str, Any]], Any]] = None
    ):
        self.routes = routes
        self.llm_caller = llm_caller
        self.fallback_handler = fallback_handler
        self._validate_routes()
    
    def _validate_routes(self):
        """Validate route configuration"""
        names = set()
        for route in self.routes:
            if route.name in names:
                raise ValueError(f"Duplicate route name: {route.name}")
            names.add(route.name)
    
    def _build_classification_prompt(self, input_data: Dict[str, Any]) -> str:
        """Build prompt for route classification"""
        routes_desc = "\n".join([
            f"- {route.name}: {route.description}"
            for route in self.routes
        ])
        
        return (
            "Given the following input and possible routes, determine the best "
            "route to handle this input. Respond with ONLY the route name, or "
            "'UNKNOWN' if no route is suitable.\n\n"
            f"Input:\n{json.dumps(input_data, indent=2)}\n\n"
            f"Available Routes:\n{routes_desc}"
        )
    
    def _validate_required_fields(
        self,
        route: Route,
        input_data: Dict[str, Any]
    ) -> None:
        """Validate that input contains all required fields for the route"""
        missing_fields = [
            field for field in route.required_fields
            if field not in input_data
        ]
        if missing_fields:
            raise ValueError(
                f"Missing required fields for route '{route.name}': "
                f"{missing_fields}"
            )
    
    async def route(self, input_data: Dict[str, Any]) -> Any:
        """Route input to appropriate handler"""
        try:
            # Get classification from LLM
            prompt = self._build_classification_prompt(input_data)
            route_name = (await self.llm_caller(prompt)).strip()
            
            # Find matching route
            matching_route = next(
                (r for r in self.routes if r.name == route_name),
                None
            )
            
            if matching_route:
                # Validate required fields
                self._validate_required_fields(matching_route, input_data)
                # Execute handler
                return await matching_route.handler(input_data)
            
            # Use fallback if available
            if self.fallback_handler:
                return await self.fallback_handler(input_data)
            
            raise ValueError(f"No route found for classification: {route_name}")
            
        except Exception as e:
            if self.fallback_handler:
                return await self.fallback_handler(input_data)
            raise e

class RouterBuilder:
    """Helper class to build routers"""
    
    def __init__(self):
        self.routes: List[Route] = []
        self.fallback_handler: Optional[Callable] = None
    
    def add_route(
        self,
        name: str,
        description: str,
        handler: Callable[[Dict[str, Any]], Any],
        required_fields: Optional[List[str]] = None
    ) -> 'RouterBuilder':
        """Add a route to the router"""
        self.routes.append(
            Route(
                name=name,
                description=description,
                handler=handler,
                required_fields=required_fields or []
            )
        )
        return self
    
    def set_fallback(
        self,
        handler: Callable[[Dict[str, Any]], Any]
    ) -> 'RouterBuilder':
        """Set the fallback handler"""
        self.fallback_handler = handler
        return self
    
    def build(
        self,
        llm_caller: Callable[[str], str]
    ) -> Router:
        """Build the router"""
        return Router(
            routes=self.routes,
            llm_caller=llm_caller,
            fallback_handler=self.fallback_handler
        ) 
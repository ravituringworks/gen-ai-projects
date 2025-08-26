from typing import Optional
import ast
import operator

class CalculatorTool:
    def __init__(self):
        self.name = "calculator"
        self.description = "Performs basic mathematical calculations. Supports addition, subtraction, multiplication, division, and exponents."
        
        # Supported operators
        self.operators = {
            ast.Add: operator.add,
            ast.Sub: operator.sub,
            ast.Mult: operator.mul,
            ast.Div: operator.truediv,
            ast.Pow: operator.pow,
        }

    async def execute(self, expression: str) -> str:
        """
        Safely evaluates a mathematical expression.
        
        Args:
            expression (str): Mathematical expression as string (e.g., "2 + 2")
            
        Returns:
            str: Result of the calculation
            
        Raises:
            ValueError: If expression is invalid or contains unsafe operations
        """
        try:
            # Parse the expression into an AST
            tree = ast.parse(expression, mode='eval')
            
            # Verify it only contains safe operations
            if not self._is_safe_expression(tree.body):
                raise ValueError("Expression contains unsafe operations")
                
            # Evaluate the expression
            result = self._eval_expr(tree.body)
            return str(result)
            
        except Exception as e:
            return f"Error calculating result: {str(e)}"

    def _is_safe_expression(self, node) -> bool:
        """
        Verifies that the expression only contains safe operations.
        """
        if isinstance(node, ast.Num):
            return True
        elif isinstance(node, ast.BinOp):
            return (type(node.op) in self.operators and
                    self._is_safe_expression(node.left) and
                    self._is_safe_expression(node.right))
        elif isinstance(node, ast.UnaryOp) and isinstance(node.op, ast.USub):
            return self._is_safe_expression(node.operand)
        return False

    def _eval_expr(self, node):
        """
        Recursively evaluates an AST expression.
        """
        if isinstance(node, ast.Num):
            return node.n
        elif isinstance(node, ast.BinOp):
            return self.operators[type(node.op)](
                self._eval_expr(node.left),
                self._eval_expr(node.right)
            )
        elif isinstance(node, ast.UnaryOp) and isinstance(node.op, ast.USub):
            return -self._eval_expr(node.operand)
        raise ValueError("Invalid expression")
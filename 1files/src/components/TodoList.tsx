import React from 'react';
import { TodoItem } from './TodoItem';
export function TodoList({
  todos,
  toggleTodo,
  deleteTodo
}) {
  if (todos.length === 0) {
    return <div className="mt-8 text-center text-gray-500">
        <p>No tasks yet. Add one above!</p>
      </div>;
  }
  return <ul className="mt-4 space-y-2">
      {todos.map(todo => <TodoItem key={todo.id} todo={todo} toggleTodo={toggleTodo} deleteTodo={deleteTodo} />)}
    </ul>;
}
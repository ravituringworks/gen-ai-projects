import React, { useEffect, useState } from 'react';
import { TodoList } from './components/TodoList';
import { AddTodoForm } from './components/AddTodoForm';
export function App() {
  const [todos, setTodos] = useState(() => {
    const savedTodos = localStorage.getItem('todos');
    if (savedTodos) {
      return JSON.parse(savedTodos);
    } else {
      return [];
    }
  });
  useEffect(() => {
    localStorage.setItem('todos', JSON.stringify(todos));
  }, [todos]);
  const addTodo = text => {
    const newTodo = {
      id: Date.now(),
      text,
      completed: false
    };
    setTodos([...todos, newTodo]);
  };
  const toggleTodo = id => {
    setTodos(todos.map(todo => todo.id === id ? {
      ...todo,
      completed: !todo.completed
    } : todo));
  };
  const deleteTodo = id => {
    setTodos(todos.filter(todo => todo.id !== id));
  };
  return <div className="flex flex-col min-h-screen bg-gray-100">
      <header className="bg-blue-500 text-white p-4 shadow-md">
        <h1 className="text-xl font-bold text-center">Todo App</h1>
      </header>
      <main className="flex-1 p-4 max-w-md mx-auto w-full">
        <AddTodoForm addTodo={addTodo} />
        <TodoList todos={todos} toggleTodo={toggleTodo} deleteTodo={deleteTodo} />
      </main>
      <footer className="bg-white p-4 border-t text-center text-gray-500 text-sm">
        Your tasks are saved locally
      </footer>
    </div>;
}
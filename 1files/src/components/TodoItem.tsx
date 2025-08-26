import React from 'react';
import { CheckIcon, TrashIcon } from 'lucide-react';
export function TodoItem({
  todo,
  toggleTodo,
  deleteTodo
}) {
  return <li className="bg-white rounded-lg shadow p-4 flex items-center justify-between">
      <div className="flex items-center flex-1">
        <button onClick={() => toggleTodo(todo.id)} className={`w-6 h-6 rounded-full border flex items-center justify-center mr-3 ${todo.completed ? 'bg-green-500 border-green-500 text-white' : 'border-gray-300'}`}>
          {todo.completed && <CheckIcon size={14} />}
        </button>
        <span className={`${todo.completed ? 'line-through text-gray-400' : ''}`}>
          {todo.text}
        </span>
      </div>
      <button onClick={() => deleteTodo(todo.id)} className="text-red-500 ml-2">
        <TrashIcon size={18} />
      </button>
    </li>;
}
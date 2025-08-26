import React, { useState } from 'react';
import { PlusIcon } from 'lucide-react';
export function AddTodoForm({
  addTodo
}) {
  const [text, setText] = useState('');
  const handleSubmit = e => {
    e.preventDefault();
    if (text.trim()) {
      addTodo(text);
      setText('');
    }
  };
  return <form onSubmit={handleSubmit} className="mt-4">
      <div className="flex rounded-lg overflow-hidden shadow">
        <input type="text" value={text} onChange={e => setText(e.target.value)} placeholder="Add a new task..." className="flex-1 p-3 outline-none" />
        <button type="submit" className="bg-blue-500 text-white px-4 flex items-center justify-center" disabled={!text.trim()}>
          <PlusIcon size={20} />
        </button>
      </div>
    </form>;
}
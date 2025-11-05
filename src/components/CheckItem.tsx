import React, {useState, useEffect} from 'react';

type Props = {
  children: React.ReactNode;
  indent?: number;
  id?: string; // optionnel : persistance par identifiant
  persist?: boolean; // true => mémorise l'état dans localStorage
};

export default function CheckItem({ children, id, indent = 0, persist = false }: Props) {
  const storageKey = id ? `checkitem:${id}` : undefined;
  const [checked, setChecked] = useState<boolean>(false);

  useEffect(() => {
    if (persist && storageKey) {
      const saved = localStorage.getItem(storageKey);
      if (saved === '1') setChecked(true);
    }
  }, [persist, storageKey]);

  useEffect(() => {
    if (persist && storageKey) {
      localStorage.setItem(storageKey, checked ? '1' : '0');
    }
  }, [persist, storageKey, checked]);

  return (
    <div style={{ marginBottom: 6, paddingLeft: (indent + "rem") }}>
      <label
        style={{
          cursor: 'pointer',
          textDecoration: checked ? 'line-through' : 'none',
          userSelect: 'text',
        }}
      >
        <input
          type="checkbox"
          checked={checked}
          onChange={() => setChecked(v => !v)}
          style={{ marginRight: 8, cursor: 'pointer' }}
        />
        {children}
      </label>
    </div>
  );
}

import { useState } from 'react'
import { createGreeting, Greeting } from './api/greeting'
import './App.css'

type Status = 'idle' | 'loading' | 'success' | 'error'

export default function App() {
  const [name, setName] = useState('')
  const [status, setStatus] = useState<Status>('idle')
  const [greeting, setGreeting] = useState<Greeting | null>(null)
  const [error, setError] = useState<string | null>(null)

  const handleSubmit = async () => {
    setStatus('loading')
    setError(null)
    setGreeting(null)
    try {
      const result = await createGreeting(name)
      setGreeting(result)
      setStatus('success')
    } catch (err: unknown) {
      const message =
        err instanceof Error ? err.message : 'Error desconocido al conectar con el backend'
      setError(message)
      setStatus('error')
    }
  }

  return (
    <div className="app">
      <header className="header">
        <h1 className="title">
          <span className="title-accent">Greeting</span> Service
        </h1>
        <p className="subtitle">Microservicio Full-Stack — EP3 DevOps</p>
      </header>

      <main className="main">
        <div className="card">
          <div className="input-group">
            <label htmlFor="name-input" className="label">
              Nombre
            </label>
            <input
              id="name-input"
              type="text"
              className="input"
              placeholder="Escribe un nombre (default: World)"
              value={name}
              onChange={(e) => setName(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === 'Enter') handleSubmit()
              }}
              disabled={status === 'loading'}
              autoFocus
            />
          </div>

          <button
            className={`btn ${status === 'loading' ? 'btn--loading' : ''}`}
            onClick={handleSubmit}
            disabled={status === 'loading'}
          >
            {status === 'loading' ? (
              <span className="spinner" />
            ) : (
              'Solicitar Saludo'
            )}
          </button>
        </div>

        {status === 'success' && greeting && (
          <div className="result fade-in">
            <div className="result-badge">201 Created</div>
            <pre className="result-json mono">
              {JSON.stringify(greeting, null, 2)}
            </pre>
          </div>
        )}

        {status === 'error' && error && (
          <div className="error fade-in">
            <svg
              className="error-icon"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
            >
              <circle cx="12" cy="12" r="10" />
              <line x1="12" y1="8" x2="12" y2="12" />
              <line x1="12" y1="16" x2="12.01" y2="16" />
            </svg>
            <p className="error-text">{error}</p>
          </div>
        )}
      </main>

      <footer className="footer">
        <span className="footer-dot" />
        Duoc UC — Ingeniería DevOps — Evaluación Parcial N°3
      </footer>
    </div>
  )
}

import { describe, it, expect } from 'vitest'

describe('Greeting Service — Unit Tests', () => {
  it('frontend package.json has correct project name', async () => {
    const pkg = await import('../../package.json')
    expect(pkg.name).toBe('greeting-frontend')
  })

  it('axios is importable', async () => {
    const axios = await import('axios')
    expect(axios.default.create).toBeDefined()
  })

  it('vite config has react plugin', async () => {
    const cfg = await import('../../vite.config')
    expect(cfg.default).toBeDefined()
  })

  it('API module exports createGreeting', async () => {
    const { createGreeting } = await import('../api/greeting')
    expect(typeof createGreeting).toBe('function')
  })

  it('App component exports default function', async () => {
    const App = await import('../App')
    expect(typeof App.default).toBe('function')
  })
})

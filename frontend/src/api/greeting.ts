import axios from 'axios'

const api = axios.create({
  baseURL: '/api/v1',
  headers: { 'Content-Type': 'application/json' },
  timeout: 10000,
})

export interface Greeting {
  id: number
  name: string
  message: string
  timestamp: string
}

export async function createGreeting(name: string): Promise<Greeting> {
  const { data } = await api.post<Greeting>('/greetings', null, {
    params: { name },
  })
  return data
}

import { useEffect, useState } from 'react'
import { createRoot } from 'react-dom/client'

const fallback = {
  title: 'My site',
  body: 'Served from a box I own.',
}

function Page() {
  const [page, setPage] = useState(fallback)

  useEffect(() => {
    fetch('/api/pages')
      .then((response) => (response.ok ? response.json() : null))
      .then((json) => {
        const first = json?.data?.[0]
        if (first?.title) {
          setPage({ title: first.title, body: first.body ?? '' })
        }
      })
      .catch(() => {})
  }, [])

  return (
    <main>
      <h1>{page.title}</h1>
      <p>{page.body}</p>
    </main>
  )
}

createRoot(document.getElementById('root')).render(<Page />)

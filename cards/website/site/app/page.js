async function loadPage() {
  const response = await fetch(`${process.env.STRAPI_URL}/api/pages`, {
    cache: 'no-store',
  });
  if (!response.ok) {
    return null;
  }
  const json = await response.json();
  return json.data?.[0] ?? null;
}

export default async function Home() {
  const page = await loadPage();
  return (
    <main>
      <h1>{page?.title ?? 'My site'}</h1>
      <p>{page?.body ?? ''}</p>
    </main>
  );
}

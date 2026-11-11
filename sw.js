/* BM Nava · copia de la aplicación para abrirla sin red (v547)

   SIEMPRE se intenta la red primero. Con conexión, este archivo no cambia
   nada: cada petición sale a la red como antes y la respuesta, además, se
   guarda. La copia sólo se sirve cuando la red falla o no contesta.

   Qué se guarda: la propia página, las fotos, el escudo y las tres librerías
   y las fuentes que la página carga de fuera. Qué NO pasa por aquí: las hojas
   de Google y Supabase. Las hojas las guarda la página, que es quien tiene
   que saber —y decir— que está enseñando datos de otro día.

   Si algo de aquí falla, la petición sale a la red como si este archivo no
   existiera: nunca se queda nada sin contestar por culpa de la copia.

   Para retirar esto del todo: borrar este archivo y la línea que lo registra
   en index.html; el navegador deja de usarlo en la siguiente carga. */
const COPIA = 'bmnava-app-v1';
const FUERA = /(^|\.)cdnjs\.cloudflare\.com$|(^|\.)fonts\.googleapis\.com$|(^|\.)fonts\.gstatic\.com$/;
const TOPE_PAGINA = 8000;

self.addEventListener('install', () => { self.skipWaiting(); });

self.addEventListener('activate', e => {
  e.waitUntil((async () => {
    try {
      const ks = await caches.keys();
      await Promise.all(ks.filter(k => k.indexOf('bmnava-app-') === 0 && k !== COPIA).map(k => caches.delete(k)));
    } catch (_) {}
    await self.clients.claim();
  })());
});

async function responder(r, u, pagina) {
  let cache = null;
  try { cache = await caches.open(COPIA); } catch (_) {}
  if (!cache) return fetch(r);
  /* La página se guarda bajo UNA clave, sin lo que venga detrás del «?»: si
     no, cada dirección distinta dejaría otra copia de tres megas. */
  const clave = pagina ? (u.origin + u.pathname) : r;
  const guardada = async () => { try { return await cache.match(clave); } catch (_) { return undefined; } };
  const red = fetch(r).then(resp => {
    try { if (resp && (resp.ok || resp.type === 'opaque')) cache.put(clave, resp.clone()).catch(() => {}); } catch (_) {}
    return resp;
  });
  if (!pagina) {
    try { return await red; }
    catch (err) { const c = await guardada(); if (c) return c; throw err; }
  }
  /* La página: si la red no contesta en 8 s y hay copia, se abre la copia. */
  let tope;
  const espera = new Promise(ok => { tope = setTimeout(() => ok(null), TOPE_PAGINA); });
  try {
    const resp = await Promise.race([red, espera]);
    clearTimeout(tope);
    if (resp) return resp;
    const c = await guardada();
    return c || await red;
  } catch (err) {
    clearTimeout(tope);
    const c = await guardada();
    if (c) return c;
    throw err;
  }
}

self.addEventListener('fetch', e => {
  const r = e.request;
  if (r.method !== 'GET' || r.headers.get('range')) return;
  let u;
  try { u = new URL(r.url); } catch (_) { return; }
  const propio = u.origin === self.location.origin;
  if (!propio && !FUERA.test(u.hostname)) return;
  e.respondWith(responder(r, u, r.mode === 'navigate'));
});

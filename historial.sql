-- ═══════════════════════════════════════════════════════════════════
-- BM Nava · Historial de la sincronización
--
-- Qué resuelve: hoy la tabla bmnava_state guarda SOLO el estado actual.
-- Cada subida machaca la fila anterior y lo que había se pierde para
-- siempre. Si algo llega mal —un navegador que sube un bloque a medias,
-- un borrado sin querer, un error de la app— no hay a dónde volver.
--
-- Esto añade una tabla que solo crece: antes de que una fila cambie, se
-- archiva como estaba. No modifica bmnava_state ni cómo funciona la app;
-- se limita a guardar copias por detrás.
--
-- Cómo se aplica: Supabase → SQL Editor → pegar todo → Run. Una vez.
-- ═══════════════════════════════════════════════════════════════════

-- 1 · La tabla de historial
create table if not exists public.bmnava_state_hist (
  id          bigserial primary key,
  k           text        not null,
  v           jsonb,
  updated_at  timestamptz,
  updated_by  text,
  archived_at timestamptz not null default now()
);

create index if not exists bmnava_hist_k_idx
  on public.bmnava_state_hist (k, archived_at desc);

-- 2 · El disparador: antes de pisar una fila, se archiva la versión vieja.
--     Si el contenido no cambia no se archiva nada, para no llenar la tabla
--     de copias idénticas cada vez que alguien pulsa Actualizar.
create or replace function public.bmnava_archivar()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if (tg_op = 'UPDATE') then
    if old.v is distinct from new.v then
      insert into public.bmnava_state_hist (k, v, updated_at, updated_by)
      values (old.k, old.v, old.updated_at, old.updated_by);
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists bmnava_archivar_trg on public.bmnava_state;
create trigger bmnava_archivar_trg
  before update on public.bmnava_state
  for each row execute function public.bmnava_archivar();

-- 3 · Permisos: el staff puede LEER el historial (para recuperar), pero
--     nadie puede escribirlo ni borrarlo desde la app. Solo lo escribe el
--     disparador, que va con permisos propios.
alter table public.bmnava_state_hist enable row level security;

drop policy if exists "staff lee historial" on public.bmnava_state_hist;
create policy "staff lee historial"
  on public.bmnava_state_hist
  for select
  to authenticated
  using (true);

-- ═══════════════════════════════════════════════════════════════════
-- CÓMO RECUPERAR ALGO (en el SQL Editor)
--
-- Ver qué versiones hay de un bloque:
--   select id, updated_by, updated_at, archived_at,
--          pg_column_size(v) as bytes
--   from public.bmnava_state_hist
--   where k = 'bmnava_meddb'
--   order by archived_at desc
--   limit 20;
--
-- Mirar una versión concreta antes de tocar nada:
--   select v from public.bmnava_state_hist where id = 123;
--
-- Devolver esa versión al estado actual:
--   update public.bmnava_state
--   set v = (select v from public.bmnava_state_hist where id = 123),
--       updated_at = now(),
--       updated_by = 'restaurado'
--   where k = 'bmnava_meddb';
--   -- (la versión que había se archiva sola por el disparador)
--
-- Limpiar historial de más de un año, si algún día ocupa demasiado:
--   delete from public.bmnava_state_hist
--   where archived_at < now() - interval '1 year';
-- ═══════════════════════════════════════════════════════════════════

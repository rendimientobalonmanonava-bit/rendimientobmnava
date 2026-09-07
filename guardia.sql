-- ═══════════════════════════════════════════════════════════════════
-- BM Nava · Guardia del servidor
--
-- Hasta ahora todas las protecciones vivían dentro de la app: fusionar antes
-- de subir, bloquear la escritura si la app va atrasada… Sirven solo si el
-- dispositivo lleva esa versión. Una app de julio no las tiene y sube su
-- bloque entero pisando lo de todos, y desde el lado bueno no hay forma de
-- impedirlo. Esta guardia vive en el servidor y se aplica a TODO el que
-- escriba, lleve la versión que lleve:
--
--   1) Un bloque vacío nunca sustituye a uno con contenido.
--   2) Solo escriben apps que fusionan bien: la app firma cada escritura con
--      su versión ("correo · v2026-09-06.1"); una firma sin versión, o con una
--      anterior a la mínima, se rechaza con un mensaje claro. Lo escrito se
--      queda en el navegador de quien lo escribió y sube cuando actualice.
--
-- Lo que se ejecuta a mano desde el SQL Editor (restaurar una versión del
-- historial, corregir algo) NO pasa por la guardia: solo vigila lo que llega
-- por la API de la app.
--
-- Cómo se aplica: Supabase → SQL Editor → pegar todo → Run. Una vez.
-- ═══════════════════════════════════════════════════════════════════

-- 1 · Ajustes del servidor. Aquí vive la versión mínima admitida.
create table if not exists public.bmnava_cfg (
  k text primary key,
  v text
);
insert into public.bmnava_cfg (k, v) values ('min_app_ver', '2026-09-06.1')
  on conflict (k) do nothing;

alter table public.bmnava_cfg enable row level security;
drop policy if exists "staff lee ajustes" on public.bmnava_cfg;
create policy "staff lee ajustes" on public.bmnava_cfg
  for select to authenticated using (true);

-- 2 · Comparar versiones "AAAA-MM-DD.N": la fecha como texto ordena bien; el
--     número, como número (para que .10 no quede por debajo de .9).
create or replace function public.bmnava_ver_menor(a text, b text)
returns boolean language sql immutable as $$
  select case
    when split_part(a,'.',1) <> split_part(b,'.',1)
      then split_part(a,'.',1) < split_part(b,'.',1)
    else nullif(split_part(a,'.',2),'')::int < nullif(split_part(b,'.',2),'')::int
  end
$$;

-- 3 · La guardia.
create or replace function public.bmnava_guardia()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  via_api boolean;
  min_v   text;
  ver     text;
  vacio   constant text[] := array['{}','[]','null','""'];
begin
  -- Solo lo que llega por la API lleva claims. El SQL Editor, no: pasa libre.
  via_api := coalesce(current_setting('request.jwt.claims', true), '') <> '';
  if not via_api then
    return new;
  end if;

  -- 1) Vacío sobre contenido: no.
  if tg_op = 'UPDATE'
     and (new.v is null or new.v::text = any(vacio))
     and old.v is not null and not (old.v::text = any(vacio)) then
    raise exception 'BMNAVA_VACIO: rechazado un bloque vacío sobre % con contenido', new.k;
  end if;

  -- 2) Versión mínima.
  select c.v into min_v from public.bmnava_cfg c where c.k = 'min_app_ver';
  if min_v is null then
    return new;
  end if;
  ver := substring(coalesce(new.updated_by, '') from 'v(\d{4}-\d{2}-\d{2}\.\d+)');
  if ver is null or public.bmnava_ver_menor(ver, min_v) then
    raise exception 'BMNAVA_VERSION: la app que escribe (%) es anterior a la mínima admitida (%)',
      coalesce(ver, 'sin versión'), min_v;
  end if;

  return new;
end;
$$;

-- El nombre empieza por "bmnava_a_" para que corra ANTES que el archivado
-- (los disparadores del mismo momento van por orden alfabético): si la guardia
-- rechaza, no se archiva nada.
drop trigger if exists bmnava_a_guardia_trg on public.bmnava_state;
create trigger bmnava_a_guardia_trg
  before insert or update on public.bmnava_state
  for each row execute function public.bmnava_guardia();

-- ═══════════════════════════════════════════════════════════════════
-- SUBIR LA VERSIÓN MÍNIMA (solo cuando yo te lo diga):
--   update public.bmnava_cfg set v = '2026-09-06.1' where k = 'min_app_ver';
-- ═══════════════════════════════════════════════════════════════════

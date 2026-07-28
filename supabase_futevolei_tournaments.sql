set lock_timeout = '5s';

create table if not exists public.futevolei_tournaments (
  id text primary key,
  payload jsonb not null,
  updated_at timestamptz default now()
);

alter table public.futevolei_tournaments enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'futevolei_tournaments'
      and policyname = 'futevolei_select'
  ) then
    create policy "futevolei_select"
    on public.futevolei_tournaments
    for select
    to anon
    using (true);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'futevolei_tournaments'
      and policyname = 'futevolei_insert'
  ) then
    create policy "futevolei_insert"
    on public.futevolei_tournaments
    for insert
    to anon
    with check (true);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'futevolei_tournaments'
      and policyname = 'futevolei_update'
  ) then
    create policy "futevolei_update"
    on public.futevolei_tournaments
    for update
    to anon
    using (true)
    with check (true);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'futevolei_tournaments'
      and policyname = 'futevolei_delete'
  ) then
    create policy "futevolei_delete"
    on public.futevolei_tournaments
    for delete
    to anon
    using (true);
  end if;
end $$;

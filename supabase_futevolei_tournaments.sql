create table if not exists public.futevolei_tournaments (
  id text primary key,
  payload jsonb not null,
  updated_at timestamptz default now()
);

alter table public.futevolei_tournaments enable row level security;

create policy "futevolei_select"
on public.futevolei_tournaments
for select
to anon
using (true);

create policy "futevolei_insert"
on public.futevolei_tournaments
for insert
to anon
with check (true);

create policy "futevolei_update"
on public.futevolei_tournaments
for update
to anon
using (true)
with check (true);

create policy "futevolei_delete"
on public.futevolei_tournaments
for delete
to anon
using (true);

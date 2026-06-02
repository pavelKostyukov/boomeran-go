-- ================================================================
-- BOOMERANGO — Supabase Setup
-- Вставь в SQL Editor: https://supabase.com/dashboard/project/vvnqqwsdvyxobohoefqx/sql
-- ================================================================

-- 1. PROFILES (пользователи через Яндекс)
create table if not exists profiles (
  id          uuid primary key default gen_random_uuid(),
  yandex_id   text unique not null,
  yandex_login text,
  name        text,
  email       text,
  phone       text,
  avatar_url  text,
  city        text,
  rating      numeric(3,2) default 5.0,
  created_at  timestamptz default now()
);

-- 2. ITEMS (объявления)
create table if not exists items (
  id             uuid primary key default gen_random_uuid(),
  owner_id       uuid references profiles(id) on delete cascade,
  title          text not null,
  description    text,
  category       text not null,
  city           text,
  price_per_day  int not null,
  price_per_week int,
  deposit        int default 0,
  cover_url      text,
  images         text[] default '{}',   -- массив доп. фото из storage
  status         text default 'active', -- active | paused | deleted
  is_available   bool default true,
  rating         numeric(3,2),
  reviews_count  int default 0,
  created_at     timestamptz default now()
);

-- 3. BOOKINGS (заявки на аренду)
create table if not exists bookings (
  id          uuid primary key default gen_random_uuid(),
  item_id     uuid references items(id) on delete cascade,
  renter_id   uuid references profiles(id) on delete cascade,
  date_from   date not null,
  date_to     date not null,
  comment     text,
  status      text default 'pending', -- pending | approved | declined | cancelled
  created_at  timestamptz default now()
);

-- ================================================================
-- RLS (Row Level Security)
-- ================================================================

alter table profiles  enable row level security;
alter table items     enable row level security;
alter table bookings  enable row level security;

-- PROFILES: читают все, пишут только свою
create policy "profiles_select" on profiles for select using (true);
create policy "profiles_insert" on profiles for insert with check (true);
create policy "profiles_update" on profiles for update using (true);

-- ITEMS: читают все, пишут только авторизованные
create policy "items_select"    on items for select using (status = 'active' or status = 'paused');
create policy "items_insert"    on items for insert with check (true);
create policy "items_update"    on items for update using (true);
create policy "items_delete"    on items for delete using (true);

-- BOOKINGS: читают участники, пишут авторизованные
create policy "bookings_select" on bookings for select using (true);
create policy "bookings_insert" on bookings for insert with check (true);
create policy "bookings_update" on bookings for update using (true);

-- ================================================================
-- STORAGE BUCKET (создай вручную или через SQL ниже)
-- Dashboard → Storage → New bucket → "item-photos", Public = ON
-- ================================================================

-- Если хочешь через SQL:
insert into storage.buckets (id, name, public)
values ('item-photos', 'item-photos', true)
on conflict (id) do nothing;

-- Storage policy — все читают, авторизованные загружают
create policy "storage_select" on storage.objects
  for select using (bucket_id = 'item-photos');

create policy "storage_insert" on storage.objects
  for insert with check (bucket_id = 'item-photos');

create policy "storage_delete" on storage.objects
  for delete using (bucket_id = 'item-photos');

-- ================================================================
-- ПРОВЕРЬ что всё создалось:
-- select table_name from information_schema.tables where table_schema='public';
-- ================================================================

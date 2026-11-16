-- Career Connect reel metadata. Media files stay on Cloudinary.
-- Run once in the Supabase SQL Editor. Only the server secret key has access.
begin;
create table public.career_reels (
  id uuid primary key,
  owner_uid text not null check (length(owner_uid) between 1 and 128),
  author text not null,
  caption text not null default '' check (length(caption) <= 500),
  type text not null check (type in ('image', 'video')),
  url text not null check (url like 'https://%'),
  public_id text not null unique,
  thumbnail_url text not null check (thumbnail_url like 'https://%'),
  duration double precision,
  created_at timestamptz not null default now(),
  constraint career_reels_duration check (
    (type = 'image' and duration is null) or
    (type = 'video' and duration > 0 and duration <= 60 and duration is not null)
  )
);
create index career_reels_feed_idx on public.career_reels(created_at desc, id desc);
alter table public.career_reels enable row level security;
revoke all on public.career_reels from anon, authenticated;
grant select, insert on public.career_reels to service_role;
commit;

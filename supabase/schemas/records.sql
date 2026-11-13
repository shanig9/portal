-- Career Connect: apply in the project's SQL editor for first-time setup.
-- Firebase UIDs are text, not Supabase Auth UUIDs. Only the trusted API accesses these tables.
begin;

create table public.career_documents (
  id uuid primary key default gen_random_uuid(),
  owner_uid text not null check (length(owner_uid) between 1 and 128),
  filename text not null check (length(filename) between 1 and 200),
  storage_path text not null unique,
  mime_type text not null check (mime_type = 'application/pdf'),
  size_bytes integer not null check (size_bytes between 1 and 10485760),
  created_at timestamptz not null default now()
);
create index career_documents_owner_created_idx on public.career_documents(owner_uid, created_at desc);
-- Supports the composite FK below: an application may attach only its owner's document.
alter table public.career_documents add constraint career_documents_owner_id_unique unique(owner_uid, id);

create table public.career_applications (
  id uuid primary key default gen_random_uuid(),
  applicant_uid text not null check (length(applicant_uid) between 1 and 128),
  job_key text not null check (length(job_key) between 1 and 200),
  job_title text not null check (length(job_title) between 1 and 200),
  company text not null check (length(company) between 1 and 200),
  location text not null check (length(location) between 1 and 200),
  document_id uuid not null,
  status text not null default 'submitted' check (status in ('submitted','under_review','shortlisted','interview','rejected','closed')),
  created_at timestamptz not null default now(),
  constraint career_applications_owner_document_fk foreign key(applicant_uid, document_id)
    references public.career_documents(owner_uid, id) on delete restrict,
  constraint career_applications_one_per_job unique(applicant_uid, job_key)
);
create index career_applications_owner_created_idx on public.career_applications(applicant_uid, created_at desc);
create index career_applications_owner_document_idx on public.career_applications(applicant_uid, document_id);

alter table public.career_documents enable row level security;
alter table public.career_applications enable row level security;
-- Intentionally no client policies: all access passes through Firebase-verified API routes.
revoke all on public.career_documents, public.career_applications from anon, authenticated;
grant select, insert on public.career_documents, public.career_applications to service_role;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('career-documents', 'career-documents', false, 10485760, array['application/pdf']);
commit;

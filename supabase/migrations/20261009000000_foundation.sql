-- Phase 1: identity, catalog, curriculum, and free enrollment foundation.
-- Teacher signup is open, the published catalog is public, and paid checkout is deferred.

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null check (length(trim(display_name)) > 0),
  role text not null check (role in ('student', 'teacher')),
  avatar_path text,
  subject text,
  qualification text,
  bio text,
  phone text,
  location text,
  target_exam text,
  locale text not null default 'en',
  time_zone text not null default 'Asia/Karachi',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.user_notification_preferences (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  push_enabled boolean not null default true,
  email_enabled boolean not null default true,
  sms_enabled boolean not null default false,
  updated_at timestamptz not null default now()
);

create table public.categories (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  name text not null check (length(trim(name)) > 0),
  icon_key text not null default 'school',
  is_active boolean not null default true,
  display_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table public.courses (
  id uuid primary key default gen_random_uuid(),
  instructor_id uuid not null references public.profiles (id),
  category_id uuid not null references public.categories (id),
  title text not null check (length(trim(title)) > 0),
  description text not null default '',
  image_path text,
  price_amount integer not null default 0 check (price_amount >= 0),
  currency char(3) not null default 'PKR' check (currency = 'PKR'),
  status text not null default 'draft' check (status in ('draft', 'published')),
  is_featured boolean not null default false,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint published_course_has_timestamp check (
    (status = 'published' and published_at is not null) or
    (status = 'draft' and published_at is null)
  )
);

create table public.course_modules (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses (id) on delete cascade,
  title text not null check (length(trim(title)) > 0),
  display_order integer not null check (display_order >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (course_id, display_order)
);

create table public.lessons (
  id uuid primary key default gen_random_uuid(),
  module_id uuid not null references public.course_modules (id) on delete cascade,
  title text not null check (length(trim(title)) > 0),
  duration_seconds integer not null default 0 check (duration_seconds >= 0),
  video_path text,
  external_video_url text,
  notes text not null default '',
  is_preview boolean not null default false,
  status text not null default 'draft' check (status in ('draft', 'published')),
  display_order integer not null check (display_order >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (module_id, display_order),
  check (video_path is null or external_video_url is null)
);

create table public.enrollments (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles (id) on delete cascade,
  course_id uuid not null references public.courses (id) on delete cascade,
  status text not null default 'active' check (status in ('active', 'completed', 'cancelled')),
  source text not null default 'free' check (source in ('free', 'manual', 'paid')),
  enrolled_at timestamptz not null default now(),
  completed_at timestamptz,
  unique (student_id, course_id)
);

create table public.lesson_progress (
  id uuid primary key default gen_random_uuid(),
  enrollment_id uuid not null references public.enrollments (id) on delete cascade,
  lesson_id uuid not null references public.lessons (id) on delete cascade,
  resume_seconds integer not null default 0 check (resume_seconds >= 0),
  watched_seconds integer not null default 0 check (watched_seconds >= 0),
  completed_at timestamptz,
  last_viewed_at timestamptz not null default now(),
  unique (enrollment_id, lesson_id)
);

create index courses_instructor_status_idx on public.courses (instructor_id, status);
create index courses_category_status_idx on public.courses (category_id, status, created_at desc);
create index courses_public_idx on public.courses (published_at desc) where status = 'published';
create index modules_course_idx on public.course_modules (course_id, display_order);
create index lessons_module_idx on public.lessons (module_id, display_order);
create index enrollments_course_idx on public.enrollments (course_id, status);
create index lesson_progress_lesson_idx on public.lesson_progress (lesson_id);

create function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_updated_at before update on public.profiles
for each row execute function public.set_updated_at();
create trigger preferences_updated_at before update on public.user_notification_preferences
for each row execute function public.set_updated_at();
create trigger courses_updated_at before update on public.courses
for each row execute function public.set_updated_at();
create trigger modules_updated_at before update on public.course_modules
for each row execute function public.set_updated_at();
create trigger lessons_updated_at before update on public.lessons
for each row execute function public.set_updated_at();

create function public.set_course_publication_time()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.status = 'draft' then
    new.published_at = null;
  elsif tg_op = 'INSERT' then
    new.published_at = now();
  elsif old.status = 'draft' then
    new.published_at = now();
  end if;
  return new;
end;
$$;

create trigger courses_publication_time before insert or update on public.courses
for each row execute function public.set_course_publication_time();

-- Requested role is read only at signup. Editing user metadata later cannot promote a profile.
create function public.create_profile_for_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name, role, subject, qualification, bio)
  values (
    new.id,
    coalesce(nullif(trim(new.raw_user_meta_data ->> 'display_name'), ''), split_part(new.email, '@', 1)),
    case when new.raw_user_meta_data ->> 'requested_role' = 'teacher' then 'teacher' else 'student' end,
    new.raw_user_meta_data ->> 'subject',
    new.raw_user_meta_data ->> 'qualification',
    new.raw_user_meta_data ->> 'bio'
  );
  insert into public.user_notification_preferences (user_id) values (new.id);
  return new;
end;
$$;

revoke all on function public.create_profile_for_new_user() from public, anon, authenticated;
create trigger on_auth_user_created after insert on auth.users
for each row execute function public.create_profile_for_new_user();

-- The view intentionally contains public teacher fields only; the profiles table stays private.
create view public.public_teacher_profiles as
select id, display_name, avatar_path, subject, qualification, bio
from public.profiles
where role = 'teacher';

alter table public.profiles enable row level security;
alter table public.user_notification_preferences enable row level security;
alter table public.categories enable row level security;
alter table public.courses enable row level security;
alter table public.course_modules enable row level security;
alter table public.lessons enable row level security;
alter table public.enrollments enable row level security;
alter table public.lesson_progress enable row level security;

revoke all on public.profiles, public.user_notification_preferences,
  public.categories, public.courses, public.course_modules, public.lessons,
  public.enrollments, public.lesson_progress from anon, authenticated;
revoke all on public.public_teacher_profiles from anon, authenticated;

grant select on public.profiles to authenticated;
grant update (display_name, avatar_path, subject, qualification, bio, phone,
  location, target_exam, locale, time_zone) on public.profiles to authenticated;
grant select, update (push_enabled, email_enabled, sms_enabled)
  on public.user_notification_preferences to authenticated;
grant select on public.categories, public.courses, public.course_modules,
  public.lessons, public.public_teacher_profiles to anon, authenticated;
grant insert (instructor_id, category_id, title, description, image_path,
  price_amount, currency, status) on public.courses to authenticated;
grant update (category_id, title, description, image_path, price_amount,
  currency, status) on public.courses to authenticated;
grant delete on public.courses to authenticated;
grant insert (course_id, title, display_order),
  update (title, display_order), delete on public.course_modules to authenticated;
grant insert (module_id, title, duration_seconds, video_path,
  external_video_url, notes, is_preview, status, display_order),
  update (title, duration_seconds, video_path, external_video_url, notes,
  is_preview, status, display_order), delete on public.lessons to authenticated;
grant select on public.enrollments to authenticated;
grant insert (student_id, course_id) on public.enrollments to authenticated;

create policy profiles_self_select on public.profiles for select to authenticated
using (id = (select auth.uid()));
create policy profiles_self_update on public.profiles for update to authenticated
using (id = (select auth.uid())) with check (id = (select auth.uid()));
create policy preferences_self_select on public.user_notification_preferences
for select to authenticated using (user_id = (select auth.uid()));
create policy preferences_self_update on public.user_notification_preferences
for update to authenticated using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

create policy categories_public_read on public.categories for select to anon, authenticated
using (is_active);
create policy courses_read on public.courses for select to anon, authenticated
using (status = 'published' or instructor_id = (select auth.uid()));
create policy courses_teacher_insert on public.courses for insert to authenticated
with check (
  instructor_id = (select auth.uid()) and
  exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role = 'teacher')
);
create policy courses_teacher_update on public.courses for update to authenticated
using (instructor_id = (select auth.uid()))
with check (instructor_id = (select auth.uid()));
create policy courses_teacher_delete on public.courses for delete to authenticated
using (instructor_id = (select auth.uid()));

create policy modules_read on public.course_modules for select to anon, authenticated
using (exists (
  select 1 from public.courses c where c.id = course_id and
    (c.status = 'published' or c.instructor_id = (select auth.uid()))
));
create policy modules_teacher_insert on public.course_modules for insert to authenticated
with check (exists (
  select 1 from public.courses c where c.id = course_id and c.instructor_id = (select auth.uid())
));
create policy modules_teacher_update on public.course_modules for update to authenticated
using (exists (
  select 1 from public.courses c where c.id = course_id and c.instructor_id = (select auth.uid())
)) with check (exists (
  select 1 from public.courses c where c.id = course_id and c.instructor_id = (select auth.uid())
));
create policy modules_teacher_delete on public.course_modules for delete to authenticated
using (exists (
  select 1 from public.courses c where c.id = course_id and c.instructor_id = (select auth.uid())
));

create policy lessons_read on public.lessons for select to anon, authenticated
using (exists (
  select 1 from public.course_modules m join public.courses c on c.id = m.course_id
  where m.id = module_id and (
    c.instructor_id = (select auth.uid()) or
    (c.status = 'published' and public.lessons.status = 'published' and (
      public.lessons.is_preview or exists (
        select 1 from public.enrollments e
        where e.course_id = c.id and e.student_id = (select auth.uid()) and e.status = 'active'
      )
    ))
  )
));
create policy lessons_teacher_insert on public.lessons for insert to authenticated
with check (exists (
  select 1 from public.course_modules m join public.courses c on c.id = m.course_id
  where m.id = module_id and c.instructor_id = (select auth.uid())
));
create policy lessons_teacher_update on public.lessons for update to authenticated
using (exists (
  select 1 from public.course_modules m join public.courses c on c.id = m.course_id
  where m.id = module_id and c.instructor_id = (select auth.uid())
)) with check (exists (
  select 1 from public.course_modules m join public.courses c on c.id = m.course_id
  where m.id = module_id and c.instructor_id = (select auth.uid())
));
create policy lessons_teacher_delete on public.lessons for delete to authenticated
using (exists (
  select 1 from public.course_modules m join public.courses c on c.id = m.course_id
  where m.id = module_id and c.instructor_id = (select auth.uid())
));

create policy enrollments_read on public.enrollments for select to authenticated
using (
  student_id = (select auth.uid()) or
  exists (select 1 from public.courses c where c.id = course_id and c.instructor_id = (select auth.uid()))
);
create policy enrollments_free_insert on public.enrollments for insert to authenticated
with check (
  student_id = (select auth.uid()) and
  exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role = 'student') and
  exists (select 1 from public.courses c where c.id = course_id and c.status = 'published' and c.price_amount = 0)
);

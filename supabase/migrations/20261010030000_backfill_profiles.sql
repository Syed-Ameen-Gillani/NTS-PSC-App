insert into public.profiles (
  id, display_name, role, subject, qualification, bio
)
select
  u.id,
  coalesce(
    nullif(trim(u.raw_user_meta_data ->> 'display_name'), ''),
    nullif(split_part(u.email, '@', 1), ''),
    'User'
  ),
  case when u.raw_user_meta_data ->> 'requested_role' = 'teacher'
    then 'teacher' else 'student' end,
  u.raw_user_meta_data ->> 'subject',
  u.raw_user_meta_data ->> 'qualification',
  u.raw_user_meta_data ->> 'bio'
from auth.users u
where not exists (select 1 from public.profiles p where p.id = u.id)
on conflict (id) do nothing;

insert into public.user_notification_preferences (user_id)
select p.id
from public.profiles p
where not exists (
  select 1 from public.user_notification_preferences pref
  where pref.user_id = p.id
)
on conflict (user_id) do nothing;

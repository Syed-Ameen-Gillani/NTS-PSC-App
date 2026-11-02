-- Public avatar delivery with owner-only upload and deletion.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'profile-avatars',
  'profile-avatars',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set public = true,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

create policy profile_avatar_owner_insert
on storage.objects for insert to authenticated
with check (
  bucket_id = 'profile-avatars'
  and split_part(name, '/', 1) = (select auth.uid())::text
);

create policy profile_avatar_owner_update
on storage.objects for update to authenticated
using (
  bucket_id = 'profile-avatars'
  and split_part(name, '/', 1) = (select auth.uid())::text
)
with check (
  bucket_id = 'profile-avatars'
  and split_part(name, '/', 1) = (select auth.uid())::text
);

create policy profile_avatar_owner_delete
on storage.objects for delete to authenticated
using (
  bucket_id = 'profile-avatars'
  and split_part(name, '/', 1) = (select auth.uid())::text
);

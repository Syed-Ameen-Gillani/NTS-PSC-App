insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
  values('course-certificates','course-certificates',false,5242880,array['application/pdf'])
  on conflict(id) do nothing;
-- Only the authenticated Edge Function may create/read artifacts through its
-- service client after checking the caller's durable completion record.

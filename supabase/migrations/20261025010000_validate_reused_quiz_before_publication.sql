-- A cross-course quiz copy must enter as a draft so its questions and answer
-- keys can be copied before the existing publication guard validates it.
create or replace function public.enforce_quiz_link_status()
returns trigger language plpgsql set search_path = '' as $$
begin
  if tg_op='INSERT' and new.source_quiz_id is not null then
    new.status := 'draft';
  else
    new.status := case when new.course_id is null then 'draft' else 'published' end;
  end if;
  return new;
end;
$$;

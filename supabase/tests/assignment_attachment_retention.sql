do $$
declare
  v_submission uuid;
  v_revisions integer;
  v_attachments integer;
begin
  select s.id into v_submission
  from public.assignment_submissions s
  join public.assignments a on a.id = s.assignment_id
  where a.title = 'ATTACHMENT TEST submission'
  order by s.created_at desc limit 1;
  if v_submission is null then raise exception 'Retained attachment test submission is missing'; end if;
  select count(*) into v_revisions from public.assignment_submission_revisions
    where submission_id = v_submission;
  select count(*) into v_attachments from public.assignment_submission_attachments att
    join public.assignment_submission_revisions r on r.id = att.revision_id
    where r.submission_id = v_submission;
  if v_revisions <> 2 or v_attachments <> 2 then
    raise exception 'Retained revisions/attachments: %/%', v_revisions, v_attachments;
  end if;
  raise notice 'Retained revisions and attachments: %/%', v_revisions, v_attachments;
end;
$$;

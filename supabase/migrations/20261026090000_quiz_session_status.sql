create function public.get_quiz_session_status(p_session_id uuid)
returns jsonb language plpgsql security definer set search_path='' as $$
declare s public.quiz_sessions;
begin
  select * into s from public.quiz_sessions where id=p_session_id and student_id=auth.uid();
  if not found then raise exception 'Attempt unavailable' using errcode='42501'; end if;
  return jsonb_build_object('id',s.id,'expires_at',s.expires_at,'server_now',now(),'attempt_id',s.attempt_id);
end;
$$;
revoke all on function public.get_quiz_session_status(uuid) from public,anon;
grant execute on function public.get_quiz_session_status(uuid) to authenticated;

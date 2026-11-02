create function public.validate_curriculum_source_scope()
returns trigger language plpgsql security definer set search_path='' as $$
begin
  perform 1 from public.courses where id=new.course_id for update;
  if (new.module_id is not null and not exists(select 1 from public.course_modules m
    where m.id=new.module_id and m.course_id=new.course_id))
    or (new.lesson_id is not null and not exists(select 1 from public.lessons l
      where l.id=new.lesson_id and l.module_id=new.module_id)) then
    raise exception 'Resource scope does not match its lesson' using errcode='23514';
  end if;
  if tg_table_name='curriculum_assessment_links' then
    if (new.quiz_id is not null and not exists(select 1 from public.quizzes q
      where q.id=new.quiz_id and q.course_id=new.course_id))
      or (new.assignment_id is not null and not exists(select 1 from public.assignments a
        where a.id=new.assignment_id and a.course_id=new.course_id)) then
      raise exception 'Assessment must belong to the course' using errcode='23514';
    end if;
  end if;
  return new;
end;
$$;
create trigger curriculum_material_scope before insert or update on public.curriculum_materials
for each row execute function public.validate_curriculum_source_scope();
create trigger curriculum_assessment_scope before insert or update on public.curriculum_assessment_links
for each row execute function public.validate_curriculum_source_scope();

create or replace function public.guard_assessment_history_delete()
returns trigger language plpgsql security definer set search_path='' as $$
begin
  if tg_table_name='assignments' then
    if exists(select 1 from public.assignment_submissions s where s.assignment_id=old.id)
      or exists(select 1 from public.curriculum_assessment_links x where x.assignment_id=old.id
        and public.course_source_is_released('assessment_link',x.id)) then
      raise exception 'Released assignments and submission history must be retained' using errcode='23503';
    end if;
  elsif exists(select 1 from public.quiz_attempts a where a.quiz_id=old.id)
    or exists(select 1 from public.quiz_sessions s where s.quiz_id=old.id)
    or exists(select 1 from public.curriculum_assessment_links x where x.quiz_id=old.id
      and public.course_source_is_released('assessment_link',x.id)) then
    raise exception 'Released quizzes and learning history must be retained' using errcode='23503';
  end if;
  return old;
end;
$$;

create function public.guard_course_release_immutability()
returns trigger language plpgsql set search_path='' as $$
begin
  raise exception 'Published release history is immutable' using errcode='23514';
end;
$$;
create trigger course_release_immutable before update or delete on public.course_releases
for each row execute function public.guard_course_release_immutability();
create trigger course_release_sources_immutable before update or delete on public.course_release_sources
for each row execute function public.guard_course_release_immutability();
revoke all on function public.validate_curriculum_source_scope(),
  public.guard_course_release_immutability() from public,anon,authenticated;

create function public.get_teacher_lesson_activity_drafts(p_course_ids uuid[])
returns table(lesson_id uuid,activities jsonb)
language plpgsql stable security definer set search_path='' as $$
begin
  if coalesce(cardinality(p_course_ids),0)>200 then raise exception 'Request at most 200 courses'; end if;
  return query select l.id,coalesce(jsonb_agg(jsonb_build_object(
    'id',p.id,'kind',p.kind,'display_order',p.display_order,'required',p.is_required,
    'title',case p.kind when 'video' then 'Video' when 'reading' then 'Reading'
      when 'material' then r.title when 'quiz' then q.title else a.title end)
    order by p.display_order,p.id) filter(where p.id is not null),'[]'::jsonb)
  from public.lessons l join public.course_modules m on m.id=l.module_id
  join public.courses c on c.id=m.course_id
  left join public.lesson_activity_placements p on p.lesson_id=l.id and not p.is_retired
  left join public.curriculum_materials r on r.id=p.material_id
  left join public.curriculum_assessment_links x on x.id=p.assessment_link_id
  left join public.quizzes q on q.id=x.quiz_id left join public.assignments a on a.id=x.assignment_id
  where c.id=any(coalesce(p_course_ids,'{}'::uuid[])) and c.instructor_id=auth.uid()
  group by l.id;
end;
$$;
revoke all on function public.get_teacher_lesson_activity_drafts(uuid[]) from public,anon;
grant execute on function public.get_teacher_lesson_activity_drafts(uuid[]) to authenticated;

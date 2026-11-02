create function public.get_teacher_lesson_activities(p_lesson_id uuid)
returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
  if not public.can_access_lesson_media(p_lesson_id,true) then
    raise exception 'Teacher access required' using errcode='42501'; end if;
  return coalesce((select jsonb_agg(jsonb_build_object('id',p.id,'kind',p.kind,
    'title',case p.kind when 'video' then 'Lesson video' when 'reading' then 'Lesson reading'
      when 'material' then r.title when 'quiz' then q.title else a.title end,
    'display_order',p.display_order,'required',p.is_required,'material_id',p.material_id,
    'warning',case when p.kind='material' and r.mime_type not in ('application/pdf','text/plain')
      then 'Supplemental file. Use PDF or text for a required reading.'
      when p.kind='quiz' and not exists(select 1 from public.quiz_questions z where z.quiz_id=q.id)
      then 'Add questions before publishing.' end) order by p.display_order,p.id)
    from public.lesson_activity_placements p left join public.curriculum_materials r on r.id=p.material_id
    left join public.curriculum_assessment_links x on x.id=p.assessment_link_id
    left join public.quizzes q on q.id=x.quiz_id left join public.assignments a on a.id=x.assignment_id
    where p.lesson_id=p_lesson_id and not p.is_retired),'[]');
end;
$$;
alter function public.configure_lesson_activities(uuid,jsonb) rename to configure_lesson_activities_before_validation;
revoke all on function public.configure_lesson_activities_before_validation(uuid,jsonb) from public,anon,authenticated;
create function public.configure_lesson_activities(p_lesson_id uuid,p_items jsonb)
returns void language plpgsql security definer set search_path='' as $$
begin
  perform public.configure_lesson_activities_before_validation(p_lesson_id,p_items);
  if exists(select 1 from public.lesson_activity_placements p join public.curriculum_materials m on m.id=p.material_id
      where p.lesson_id=p_lesson_id and not p.is_retired and p.is_required and m.mime_type not in ('application/pdf','text/plain')) then
    raise exception 'Required readings must be PDF or text. Keep other files optional' using errcode='22023'; end if;
  if not exists(select 1 from public.lesson_activity_placements where lesson_id=p_lesson_id and not is_retired and is_required) then
    raise exception 'Keep at least one required activity in this lesson' using errcode='22023'; end if;
end;
$$;
-- Changes to placements are drafts: students only consume active-release JSON.
revoke all on function public.get_teacher_lesson_activities(uuid),public.configure_lesson_activities(uuid,jsonb) from public,anon;
grant execute on function public.get_teacher_lesson_activities(uuid),public.configure_lesson_activities(uuid,jsonb) to authenticated;

alter function public.publish_course_changes(uuid) rename to publish_course_changes_before_reading_validation;
revoke all on function public.publish_course_changes_before_reading_validation(uuid) from public,anon,authenticated;
create function public.publish_course_changes(p_course_id uuid)
returns boolean language plpgsql security definer set search_path='' as $$
declare changed boolean;
begin
  changed:=public.publish_course_changes_before_reading_validation(p_course_id);
  if exists(select 1 from public.released_course_lessons(p_course_id) l
    cross join lateral jsonb_array_elements(l.activities) a
    join public.curriculum_materials m on m.id=(a->>'material_id')::uuid
    where (a->>'required')::boolean and m.mime_type not in ('application/pdf','text/plain')) then
    raise exception 'Required readings must be PDF or text. Set other documents to optional before publishing' using errcode='22023'; end if;
  return changed;
end;
$$;
revoke all on function public.publish_course_changes(uuid) from public,anon;
grant execute on function public.publish_course_changes(uuid) to authenticated;

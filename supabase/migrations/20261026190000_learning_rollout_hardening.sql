-- Bind telemetry to the source actually playing, including during release swaps.
alter function public.learning_activity_descriptor(uuid,uuid) rename to learning_activity_descriptor_before_source;
revoke all on function public.learning_activity_descriptor_before_source(uuid,uuid) from public,anon,authenticated;
create function public.learning_activity_descriptor(p_lesson uuid,p_activity uuid)
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare spec jsonb;source text;
begin
 spec:=public.learning_activity_descriptor_before_source(p_lesson,p_activity);
 if spec->>'kind'='video' then
   select coalesce(nullif(l->>'video_path',''),l->>'external_video_url') into source
     from public.courses c join public.course_releases r on r.id=c.active_release_id
     cross join lateral jsonb_array_elements(r.manifest->'modules') m
     cross join lateral jsonb_array_elements(m->'lessons') l where l->>'id'=p_lesson::text;
 end if;
 return spec||jsonb_build_object('source',source);
end;
$$;
revoke all on function public.learning_activity_descriptor(uuid,uuid) from public,anon,authenticated;

create index learning_evidence_expiry on public.learning_evidence_sessions(student_id,expires_at);
alter function public.begin_learning_evidence(uuid,uuid) rename to begin_learning_evidence_before_source;
revoke all on function public.begin_learning_evidence_before_source(uuid,uuid) from public,anon,authenticated;
create function public.begin_learning_evidence(p_lesson_id uuid,p_activity_id uuid)
returns jsonb language plpgsql security definer set search_path='' as $$
declare ticket jsonb;
begin
 ticket:=public.begin_learning_evidence_before_source(p_lesson_id,p_activity_id);
 delete from public.learning_evidence_receipts r using public.learning_evidence_sessions s
   where r.session_id=s.id and s.student_id=auth.uid() and s.expires_at<now()-interval '1 day';
 delete from public.learning_evidence_sessions where student_id=auth.uid() and expires_at<now()-interval '1 day';
 return ticket||jsonb_build_object('source',public.learning_activity_descriptor(p_lesson_id,p_activity_id)->>'source');
end;
$$;
revoke all on function public.begin_learning_evidence(uuid,uuid) from public,anon;
grant execute on function public.begin_learning_evidence(uuid,uuid) to authenticated;

alter function public.get_learning_outcome(uuid) rename to get_learning_outcome_before_state;
revoke all on function public.get_learning_outcome_before_state(uuid) from public,anon,authenticated;
create function public.get_learning_outcome(p_lesson_id uuid)
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare result jsonb;item jsonb;items jsonb:='[]';link public.curriculum_assessment_links;v_state text;
begin
 result:=public.get_learning_outcome_before_state(p_lesson_id);
 for item in select value from jsonb_array_elements(result->'activities') loop
   v_state:='available';
   if item->>'completed'='true' then v_state:='completed';
   elsif item->>'kind' in ('quiz','assignment') then
     select * into link from public.curriculum_assessment_links where id=(item->>'assessment_link_id')::uuid;
     if item->>'kind'='quiz' and exists(select 1 from public.quiz_attempts where quiz_id=link.quiz_id and student_id=auth.uid()) then
       v_state:='failed';
     elsif item->>'kind'='assignment' then
       select case status when 'pending' then 'submitted' when 'disapproved' then 'rejected' else 'completed' end
         into v_state from public.assignment_submissions where assignment_id=link.assignment_id and student_id=auth.uid()
         order by submitted_at desc,id desc limit 1;
       v_state:=coalesce(v_state,'available');
     end if;
   elsif exists(select 1 from public.learning_activity_progress p join public.enrollments e on e.id=p.enrollment_id
     where p.activity_id=(item->>'id')::uuid and e.student_id=auth.uid() and p.content_version=item->>'version') then v_state:='in_progress';
   end if;
   items:=items||jsonb_build_array(item||jsonb_build_object('state',v_state));
 end loop;
 return result||jsonb_build_object('activities',items);
end;
$$;
revoke all on function public.get_learning_outcome(uuid) from public,anon;
grant execute on function public.get_learning_outcome(uuid) to authenticated;
create or replace function public.sync_lesson_activity_placements(p_lesson uuid)
returns void language plpgsql security definer set search_path='' as $$
declare v_lesson public.lessons; v_source record; v_order integer; v_draft jsonb;
begin
  select * into v_lesson from public.lessons where id=p_lesson for update;
  if not found then return; end if;
  select changes into v_draft from public.curriculum_draft_changes where lesson_id=p_lesson;
  if v_draft ? 'notes' then v_lesson.notes:=v_draft->>'notes'; end if;
  if v_draft ? 'external_video_url' then
    v_lesson.external_video_url:=nullif(trim(v_draft->>'external_video_url'),'');
    v_lesson.video_path:=null;
  end if;
  -- Existing IDs/order/required choices survive source refresh and backfill reruns.
  for v_source in
    select 'video'::text kind,'video'::text source_key,null::uuid material_id,
      null::uuid assessment_link_id,true required,0 rank
    where (v_lesson.video_path is not null and not v_lesson.pending_video_removal)
      or nullif(trim(v_lesson.external_video_url),'') is not null
      or exists(select 1 from public.lesson_media lm where lm.lesson_id=p_lesson
        and lm.status='ready' and not (v_lesson.pending_video_removal
          and lm.object_path=v_lesson.video_path))
    union all select 'reading','reading',null,null,true,1
      where nullif(trim(v_lesson.notes),'') is not null
    union all select 'material','material:'||r.id,r.id,null,
      v_lesson.video_path is null and nullif(trim(v_lesson.external_video_url),'') is null
        and nullif(trim(v_lesson.notes),'') is null and not exists(
          select 1 from public.curriculum_assessment_links x where x.lesson_id=p_lesson
            and not x.is_retired and not x.pending_removal),2
      from public.curriculum_materials r where r.lesson_id=p_lesson
        and r.status='ready' and not r.is_retired and not r.pending_removal
    union all select case when a.quiz_id is not null then 'quiz' else 'assignment' end,
      'assessment:'||a.id,null,a.id,true,3
      from public.curriculum_assessment_links a where a.lesson_id=p_lesson
        and not a.is_retired and not a.pending_removal
    order by rank,source_key
  loop
    select coalesce(max(display_order),-1)+1 into v_order
      from public.lesson_activity_placements where lesson_id=p_lesson;
    insert into public.lesson_activity_placements(lesson_id,kind,source_key,
      material_id,assessment_link_id,display_order,is_required)
    values(p_lesson,v_source.kind,v_source.source_key,v_source.material_id,
      v_source.assessment_link_id,v_order,v_source.required)
    on conflict(lesson_id,source_key) do update set is_retired=false;
  end loop;
  update public.lesson_activity_placements p set is_retired=true
  where p.lesson_id=p_lesson and (
    (p.kind='video' and not ((v_lesson.video_path is not null and not v_lesson.pending_video_removal)
      or nullif(trim(v_lesson.external_video_url),'') is not null
      or exists(select 1 from public.lesson_media lm where lm.lesson_id=p_lesson
        and lm.status='ready' and not (v_lesson.pending_video_removal and lm.object_path=v_lesson.video_path))))
    or (p.kind='reading' and nullif(trim(v_lesson.notes),'') is null)
    or (p.kind='material' and not exists(select 1 from public.curriculum_materials r
      where r.id=p.material_id and r.status='ready' and not r.pending_removal and not r.is_retired))
    or (p.kind in ('quiz','assignment') and not exists(select 1 from public.curriculum_assessment_links a
      where a.id=p.assessment_link_id and not a.pending_removal and not a.is_retired))
  );
end;
$$;


create trigger staged_lesson_activity_refresh after insert or update on public.curriculum_draft_changes
for each row execute function public.refresh_lesson_activity_placements();
alter table public.lessons add constraint bounded_lesson_reading check(length(notes)<=500000) not valid;

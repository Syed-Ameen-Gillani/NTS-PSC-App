-- A placement in another course receives its own assessment instance. Student
-- attempts, submissions, notifications, and RLS remain scoped to that course.
alter table public.quizzes add column source_quiz_id uuid
  references public.quizzes(id) on delete set null;
alter table public.assignments add column source_assignment_id uuid
  references public.assignments(id) on delete set null;
create unique index quizzes_source_course_unique
  on public.quizzes(source_quiz_id, course_id) where source_quiz_id is not null;
create unique index assignments_source_course_unique
  on public.assignments(source_assignment_id, course_id)
  where source_assignment_id is not null;

-- Published brief files are immutable, so course copies can refer to the same
-- private object. Read access is still checked through each assessment row.
alter table public.assignment_brief_attachments
  drop constraint assignment_brief_attachments_object_path_key;
create unique index assignment_briefs_per_assignment_path
  on public.assignment_brief_attachments(assignment_id, object_path);

create or replace function public.link_curriculum_assessment(
  p_course_id uuid,p_module_id uuid,p_lesson_id uuid,p_kind text,p_assessment_id uuid
) returns void language plpgsql security definer set search_path='' as $$
declare
  v_quiz public.quizzes;
  v_assignment public.assignments;
  v_target uuid;
  v_source uuid;
  v_question record;
  v_new_question uuid;
begin
  if not public.can_access_curriculum(p_course_id,p_module_id,p_lesson_id,true) then
    raise exception 'Teacher access required' using errcode='42501';
  end if;
  if p_kind='quiz' then
    select * into v_quiz from public.quizzes where id=p_assessment_id for update;
    if not found or v_quiz.teacher_id is distinct from auth.uid() then
      raise exception 'Quiz unavailable' using errcode='42501';
    end if;
    if v_quiz.course_id is null then
      update public.quizzes set course_id=p_course_id,status='published'
      where id=v_quiz.id;
      v_target := v_quiz.id;
    elsif v_quiz.course_id=p_course_id then
      v_target := v_quiz.id;
    else
      if v_quiz.status<>'published' then
        raise exception 'Publish the quiz before reusing it';
      end if;
      v_source := coalesce(v_quiz.source_quiz_id,v_quiz.id);
      select id into v_target from public.quizzes
        where id=v_source and course_id=p_course_id;
      if v_target is null then
        select id into v_target from public.quizzes
          where source_quiz_id=v_source and course_id=p_course_id;
      end if;
      if v_target is null then
        insert into public.quizzes(teacher_id,course_id,title,category,difficulty,
          duration_minutes,passing_score,is_ai_generated,source_quiz_id)
        values(v_quiz.teacher_id,p_course_id,v_quiz.title,v_quiz.category,
          v_quiz.difficulty,v_quiz.duration_minutes,v_quiz.passing_score,
          v_quiz.is_ai_generated,v_source) returning id into v_target;
        for v_question in select q.*,k.correct_option_index,k.explanation
          from public.quiz_questions q join public.quiz_answer_keys k
            on k.question_id=q.id where q.quiz_id=v_quiz.id
          order by q.display_order loop
          insert into public.quiz_questions(quiz_id,display_order,question_text,options)
            values(v_target,v_question.display_order,v_question.question_text,
              v_question.options) returning id into v_new_question;
          insert into public.quiz_answer_keys(question_id,correct_option_index,explanation)
            values(v_new_question,v_question.correct_option_index,v_question.explanation);
        end loop;
        update public.quizzes set status='published' where id=v_target;
      end if;
    end if;
    insert into public.curriculum_assessment_links(course_id,module_id,lesson_id,quiz_id)
      values(p_course_id,p_module_id,p_lesson_id,v_target) on conflict do nothing;
  elsif p_kind='assignment' then
    select * into v_assignment from public.assignments where id=p_assessment_id for update;
    if not found or not exists(select 1 from public.courses c
      where c.id=v_assignment.course_id and c.instructor_id=auth.uid()) then
      raise exception 'Assignment unavailable' using errcode='42501';
    end if;
    if v_assignment.course_id=p_course_id then
      v_target := v_assignment.id;
    else
      if v_assignment.status<>'published' then
        raise exception 'Publish the assignment before reusing it';
      end if;
      v_source := coalesce(v_assignment.source_assignment_id,v_assignment.id);
      select id into v_target from public.assignments
        where id=v_source and course_id=p_course_id;
      if v_target is null then
        select id into v_target from public.assignments
          where source_assignment_id=v_source and course_id=p_course_id;
      end if;
      if v_target is null then
        if v_assignment.due_at<=now() then
          raise exception 'Set a future due date before linking this assignment';
        end if;
        insert into public.assignments(course_id,title,instructions,due_at,external_url,
          source_assignment_id)
          values(p_course_id,v_assignment.title,v_assignment.instructions,
            v_assignment.due_at,v_assignment.external_url,v_source)
          returning id into v_target;
        insert into public.assignment_brief_attachments(assignment_id,uploader_id,
          object_path,original_name,mime_type,size_bytes,status)
          select v_target,uploader_id,object_path,original_name,mime_type,
            size_bytes,status from public.assignment_brief_attachments
          where assignment_id=v_assignment.id and status='ready';
      end if;
    end if;
    insert into public.curriculum_assessment_links(course_id,module_id,lesson_id,assignment_id)
      values(p_course_id,p_module_id,p_lesson_id,v_target) on conflict do nothing;
    update public.assignments set status='published'
      where id=v_target and status='draft';
  else
    raise exception 'Unknown assessment type';
  end if;
end;
$$;

create or replace function public.curriculum_assessment_candidates(p_course_id uuid)
returns table(id uuid,title text,kind text,status text)
language plpgsql stable security definer set search_path='' as $$
begin
  if not public.can_access_curriculum(p_course_id,null,null,true) then
    raise exception 'Teacher access required' using errcode='42501';
  end if;
  return query select q.id,q.title,'quiz'::text,q.status from public.quizzes q
    where q.teacher_id=auth.uid()
      and (q.source_quiz_id is null or q.course_id=p_course_id)
      and (q.course_id is null or q.course_id=p_course_id or q.status='published')
  union all select a.id,a.title,'assignment'::text,a.status
    from public.assignments a join public.courses c on c.id=a.course_id
    where c.instructor_id=auth.uid()
      and (a.source_assignment_id is null or a.course_id=p_course_id)
      and (a.course_id=p_course_id or a.status='published');
end;
$$;

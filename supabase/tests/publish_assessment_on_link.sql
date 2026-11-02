do $$
declare
  teacher uuid;
  course uuid;
  assignment uuid;
  expired uuid;
  quiz uuid;
  questions jsonb := '[{"question_text":"Test question","options":["A","B"],"correct_option_index":1,"explanation":"B"}]';
begin
  begin
    select c.id,c.instructor_id into course,teacher from public.courses c
      join public.profiles p on p.id=c.instructor_id
      where p.role='teacher' and p.display_name like '%TEST%' limit 1;
    if teacher is null then raise exception 'Retained test teacher course required'; end if;
    perform set_config('request.jwt.claim.sub',teacher::text,true);
    execute 'set local role authenticated';

    insert into public.assignments(course_id,title,instructions,due_at)
      values(course,'LINK PUBLISH TEST','Test instructions',now()+interval '2 days')
      returning id into assignment;
    perform public.link_curriculum_assessment(course,null,null,'assignment',assignment);
    if not exists(select 1 from public.assignments where id=assignment and status='published') or
      not exists(select 1 from public.curriculum_assessment_links
        where assignment_id=assignment and course_id=course) then
      raise exception 'Assignment placement did not publish';
    end if;

    insert into public.assignments(course_id,title,instructions,due_at)
      values(course,'EXPIRED LINK TEST','Test instructions',now()-interval '1 day')
      returning id into expired;
    begin
      perform public.link_curriculum_assessment(course,null,null,'assignment',expired);
      raise exception 'Expired assignment was published';
    exception when raise_exception then
      if sqlerrm <> 'Assignment due date must be in the future' then raise; end if;
    end;
    if exists(select 1 from public.curriculum_assessment_links where assignment_id=expired) or
      not exists(select 1 from public.assignments where id=expired and status='draft') then
      raise exception 'Failed publication left a curriculum link';
    end if;

    quiz := public.save_teacher_quiz(null,'LINK PUBLISH TEST','General','Medium',15,60,false,false,questions);
    perform public.link_curriculum_assessment(course,null,null,'quiz',quiz);
    if not exists(select 1 from public.quizzes where id=quiz and status='published' and course_id=course) or
      not exists(select 1 from public.curriculum_assessment_links
        where quiz_id=quiz and course_id=course) then
      raise exception 'Quiz placement did not publish';
    end if;
    raise exception 'Rollback assessment publication tests';
  exception when raise_exception then
    if sqlerrm <> 'Rollback assessment publication tests' then raise; end if;
  end;
end;
$$;

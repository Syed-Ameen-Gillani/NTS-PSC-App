begin;

alter table public.student_learning_preferences
  drop constraint student_learning_preferences_categories_check,
  drop constraint student_learning_preferences_categories_check1,
  add constraint student_learning_preferences_categories_check
    check (categories <@ array['Education','Competitions','Competitive Exams','Pedagogy']::text[]),
  add constraint student_learning_preferences_categories_check1
    check (cardinality(categories) <= 4);

create or replace function public.validate_learning_preferences() returns trigger
language plpgsql set search_path = '' as $$
declare allowed text[] := '{}';
begin
  if 'Pedagogy' = any(new.categories) then
    allowed := allowed || array['Learning Theories','Teaching Methods','Educational Psychology','Classroom Management','Assessment & Evaluation'];
  end if;
  if 'Education' = any(new.categories) then
    allowed := allowed || array['Teaching','English','Mathematics','Science','Kashmir Studies','History','Computer Science'];
  end if;
  if 'Competitions' = any(new.categories) then
    allowed := allowed || array['General Knowledge','Current Affairs','Debating','Writing','Problem Solving'];
  end if;
  if 'Competitive Exams' = any(new.categories) then
    allowed := allowed || array['CSS','PMS','FPSC','NTS','AJK PSC','PPSC','SPSC','KPPSC','BPSC'];
  end if;
  if cardinality(new.categories) = 0 or cardinality(new.interests) = 0
      or not (new.interests <@ allowed) or array_position(new.interests, null) is not null
      or array_position(new.categories, null) is not null then
    raise exception 'Choose a category and at least one matching interest.' using errcode = '22023';
  end if;
  if exists(select 1 from unnest(new.skills) as skill where skill is null or length(trim(skill)) = 0 or length(skill) > 60) then
    raise exception 'Skills must contain between 1 and 60 characters.' using errcode = '22023';
  end if;
  if tg_op = 'UPDATE' then
    new.completed_at := coalesce(old.completed_at, now());
  else
    new.completed_at := now();
  end if;
  new.updated_at := now();
  return new;
end;
$$;

create or replace function public.recommended_course_ids(p_limit integer default 20, p_offset integer default 0)
returns table(course_id uuid)
language plpgsql stable security invoker set search_path = '' as $$
begin
  if p_limit < 1 or p_limit > 100 or p_offset < 0 or p_limit is null or p_offset is null then
    raise exception 'Invalid course page.' using errcode = '22023';
  end if;
  if auth.uid() is null then
    return query select c.id from public.courses c where c.status = 'published'
      order by c.created_at desc, c.id limit p_limit offset p_offset;
    return;
  end if;
  return query
  with preferences as (
    select * from public.student_learning_preferences where user_id = auth.uid()
  ), terms as (
    select distinct lower(regexp_replace(term, '[^[:alnum:]]+', ' ', 'g')) as term, weight
    from (
      select unnest(interests) as term, 4 as weight from preferences
      union all select unnest(skills), 2 from preferences
      union all select unnest(case category
        when 'Pedagogy' then array['pedagogy','teaching','education','classroom','assessment','learning theories']
        when 'Education' then array['teaching','education','english','mathematics','science','history']
        when 'Competitions' then array['competition','general knowledge','current affairs','debating','writing']
        when 'Competitive Exams' then array['css','pms','fpsc','nts','ajk psc','ppsc','spsc','kppsc','bpsc','competitive exams']
        else '{}'::text[] end), 1
      from preferences, unnest(categories) category
    ) all_terms where length(trim(term)) > 0
  )
  select c.id from public.courses c join public.categories category on category.id = c.category_id
  where c.status = 'published'
  order by (
    select coalesce(sum(terms.weight), 0) from terms
    where strpos(' ' || lower(regexp_replace(category.name || ' ' || c.title || ' ' || c.description,
      '[^[:alnum:]]+', ' ', 'g')) || ' ', ' ' || terms.term || ' ') > 0
  ) desc, c.created_at desc, c.id
  limit p_limit offset p_offset;
end;
$$;

commit;

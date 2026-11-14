begin;

create table public.student_learning_preferences (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  categories text[] not null default '{}',
  interests text[] not null default '{}',
  skills text[] not null default '{}',
  completed_at timestamptz,
  updated_at timestamptz not null default now(),
  check (categories <@ array['Education', 'Competitions', 'Competitive Exams']::text[]),
  check (cardinality(categories) <= 3),
  check (cardinality(interests) <= 30),
  check (cardinality(skills) <= 30)
);

-- Existing students retain their login flow and can opt into personalization
-- from Profile. A missing row on a new account requires the survey.
insert into public.student_learning_preferences(user_id, completed_at)
select id, now() from public.profiles where role = 'student';

alter table public.student_learning_preferences enable row level security;
revoke all on public.student_learning_preferences from anon, authenticated;
grant select, insert, update on public.student_learning_preferences to authenticated;
create policy preferences_owner_read on public.student_learning_preferences
for select to authenticated using (user_id = (select auth.uid()));
create policy preferences_student_insert on public.student_learning_preferences
for insert to authenticated with check (
  user_id = (select auth.uid()) and exists (
    select 1 from public.profiles where id = (select auth.uid()) and role = 'student'
  )
);
create policy preferences_student_update on public.student_learning_preferences
for update to authenticated using (user_id = (select auth.uid())) with check (
  user_id = (select auth.uid()) and exists (
    select 1 from public.profiles where id = (select auth.uid()) and role = 'student'
  )
);

create function public.validate_learning_preferences() returns trigger
language plpgsql set search_path = '' as $$
declare allowed text[] := '{}';
begin
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
create trigger validate_learning_preferences before insert or update
on public.student_learning_preferences for each row execute function public.validate_learning_preferences();
revoke all on function public.validate_learning_preferences() from public;

-- Rank before pagination so See All follows the same ordering as the preview.
-- Security invoker keeps catalog RLS and the current user's preference RLS.
create function public.recommended_course_ids(p_limit integer default 20, p_offset integer default 0)
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
revoke all on function public.recommended_course_ids(integer, integer) from public;
grant execute on function public.recommended_course_ids(integer, integer) to anon, authenticated;

commit;

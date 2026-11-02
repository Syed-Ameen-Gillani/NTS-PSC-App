create table public.course_reviews (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete cascade,
  rating integer not null check(rating between 1 and 5),
  body text not null check(length(trim(body)) between 3 and 2000),
  created_at timestamptz not null default now(),updated_at timestamptz not null default now(),
  unique(course_id,student_id)
);
create index course_reviews_course_order on public.course_reviews(course_id,created_at desc,id);
create index course_reviews_course_rating on public.course_reviews(course_id,rating);
alter table public.course_reviews enable row level security;
revoke all on public.course_reviews from anon,authenticated;
create policy course_review_owner_read on public.course_reviews for select to authenticated using(student_id=auth.uid());
-- No direct client writes: identity, entitlement and progress are checked by RPC.
create function public.can_review_course(p_course_id uuid)
returns boolean language sql stable security definer set search_path='' as $$
 select public.has_course_entitlement(p_course_id) and exists(
  select 1 from public.enrollments e join public.lesson_progress p on p.enrollment_id=e.id
  join public.profiles u on u.id=e.student_id join public.courses c on c.id=e.course_id
  where e.course_id=p_course_id and e.student_id=auth.uid() and u.role='student'
    and c.instructor_id<>auth.uid() and p.completed_at is not null);
$$;
create function public.save_course_review(p_course_id uuid,p_rating integer,p_body text)
returns uuid language plpgsql security definer set search_path='' as $$
declare v_id uuid;
begin
 if not public.can_review_course(p_course_id) then
   raise exception 'Complete a lesson in this course before reviewing it' using errcode='42501'; end if;
 if p_rating is null or p_rating not between 1 and 5 or p_body is null or length(trim(p_body)) not between 3 and 2000 then
   raise exception 'Choose a rating and write 3 to 2,000 characters' using errcode='22023'; end if;
 insert into public.course_reviews(course_id,student_id,rating,body) values(p_course_id,auth.uid(),p_rating,trim(p_body))
   on conflict(course_id,student_id) do update set rating=excluded.rating,body=excluded.body,updated_at=now()
   returning id into v_id;
 return v_id;
end;
$$;
create function public.get_course_reviews(p_course_id uuid,p_offset integer default 0,p_rating integer default null)
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare v_items jsonb;v_own jsonb;v_count bigint;v_average numeric;v_distribution jsonb;
begin
 if p_offset is null or p_offset<0 or p_offset>100000 or (p_rating is not null and p_rating not between 1 and 5) then
   raise exception 'Invalid review page' using errcode='22023'; end if;
 if not exists(select 1 from public.courses where id=p_course_id and (status='published' or instructor_id=auth.uid())) then
   raise exception 'Course unavailable' using errcode='42501'; end if;
 select count(*),coalesce(round(avg(rating),1),0) into v_count,v_average from public.course_reviews where course_id=p_course_id;
 select jsonb_agg((select count(*) from public.course_reviews where course_id=p_course_id and rating=star) order by star)
   into v_distribution from generate_series(1,5) star;
 select coalesce(jsonb_agg(to_jsonb(r) order by r.created_at desc,r.id),'[]') into v_items from (
   select r.id,r.rating,r.body,r.created_at,r.updated_at,p.display_name student_name
   from public.course_reviews r join public.profiles p on p.id=r.student_id
   where r.course_id=p_course_id and (p_rating is null or r.rating=p_rating)
   order by r.created_at desc,r.id offset p_offset limit 20) r;
 select jsonb_build_object('id',id,'rating',rating,'body',body) into v_own
   from public.course_reviews where course_id=p_course_id and student_id=auth.uid();
 return jsonb_build_object('items',v_items,'count',v_count,'average',v_average,'distribution',v_distribution,
   'can_review',public.can_review_course(p_course_id),'own_review',v_own);
end;
$$;
create function public.get_public_course_ratings(p_course_ids uuid[])
returns table(course_id uuid,rating numeric,review_count bigint)
language plpgsql stable security definer set search_path='' as $$
begin
 if coalesce(cardinality(p_course_ids),0)>200 then raise exception 'Request at most 200 courses'; end if;
 return query select c.id,coalesce(round(avg(r.rating),1),0),count(r.id)
   from public.courses c left join public.course_reviews r on r.course_id=c.id
   where c.id=any(p_course_ids) and c.status='published' group by c.id;
end;
$$;
revoke all on function public.can_review_course(uuid) from public,anon,authenticated;
revoke all on function public.save_course_review(uuid,integer,text) from public,anon;
grant execute on function public.save_course_review(uuid,integer,text) to authenticated;
revoke all on function public.get_course_reviews(uuid,integer,integer),public.get_public_course_ratings(uuid[]) from public;
grant execute on function public.get_course_reviews(uuid,integer,integer),public.get_public_course_ratings(uuid[]) to anon,authenticated;

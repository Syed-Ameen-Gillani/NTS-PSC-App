begin;
set local role anon;
do $$
declare
  terms jsonb := '[{"term":"english","weight":4},{"term":"grammar","weight":4}]';
  target_term text;
  first_course uuid;
  category_row record;
begin
  assert public.catalog_interest_score('English grammar course',terms)=8, 'Interest scoring diverged';
  assert public.catalog_interest_score('Processing methods','[{"term":"css","weight":4}]')=0, 'Partial word matched';
  assert (select count(*) from public.personalized_course_ids(terms,'new',null,100,0)) =
    least(100,(select count(*) from public.courses where status='published')), 'Nonmatching published courses were excluded';
  assert (select count(*) from public.personalized_course_ids(terms,'featured',null,100,0)) =
    least(100,(select count(*) from public.courses where status='published' and is_featured)), 'Featured list excluded nonmatching featured courses';
  assert not exists(select 1 from public.personalized_course_ids(terms,'new',null,100,0) r
    join public.courses c on c.id=r.course_id where c.status <> 'published'), 'Draft course exposed';
  assert (select count(*) from public.personalized_course_categories(terms)) =
    (select count(*) from public.categories), 'Categories were excluded';
  assert not exists(select 1 from public.personalized_course_categories(terms) category
    where category.course_count <> (select count(*) from public.courses c where c.category_id=category.id and c.status='published')), 'Category count mismatch';
  assert not exists(
    select 1 from public.personalized_course_ids(terms,'new',null,1,0) a
    join public.personalized_course_ids(terms,'new',null,1,1) b on a.course_id=b.course_id
  ), 'Pagination duplicated a course';
  for category_row in select id,name from public.categories loop
    assert (select count(*) from public.personalized_course_ids(terms,'available',
      array[trim(lower(regexp_replace(category_row.name,'[^[:alnum:]]+',' ','g'))),'course'],100,0)) =
      least(100,(select count(*) from public.courses c where c.category_id=category_row.id and c.status='published')),
      'Explicit category navigation included courses from another category';
  end loop;
  -- Select an older real course title so recency alone cannot pass this check.
  select trim(lower(regexp_replace(c.title,'[^[:alnum:]]+',' ','g'))) into target_term
  from public.courses c where c.status='published' order by c.created_at, c.id limit 1;
  if length(target_term) > 0 then
    terms := jsonb_build_array(jsonb_build_object('term',target_term,'weight',4));
    select course_id into first_course from public.personalized_course_ids(terms,'new',null,1,0);
    assert (select public.catalog_interest_score(c.title,terms) >= 4 from public.courses c where c.id=first_course), 'Relevant older course did not precede nonmatching new courses';
  end if;
  begin
    perform * from public.personalized_course_ids(terms,'new',null,101,0);
    raise exception 'Unbounded page allowed';
  exception when invalid_parameter_value then null;
  end;
end;
$$;
rollback;

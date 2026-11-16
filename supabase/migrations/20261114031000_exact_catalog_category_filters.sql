begin;

-- Keep explicit catalog category navigation within that category.
create or replace function public.personalized_course_ids(
  p_terms jsonb default '[]', p_section text default 'recommended',
  p_topic_terms text[] default null, p_limit integer default 20, p_offset integer default 0
) returns table(course_id uuid)
language plpgsql stable security invoker set search_path = '' as $$
begin
  if p_limit is null or p_limit < 1 or p_limit > 100 or p_offset is null or p_offset < 0
    or p_terms is null or jsonb_typeof(p_terms) <> 'array' or jsonb_array_length(p_terms) > 512
    or p_section is null or p_section not in ('recommended','new','featured','available')
    or cardinality(p_topic_terms) > 100 then
    raise exception 'Invalid catalog page.' using errcode = '22023';
  end if;
  return query
  with exact_categories as (
    select candidate.id from public.categories candidate
    where trim(lower(regexp_replace(candidate.name,'[^[:alnum:]]+',' ','g'))) = p_topic_terms[1]
  )
  select c.id from public.courses c join public.categories category on category.id=c.category_id
  where c.status='published' and (p_section <> 'featured' or c.is_featured)
    and (p_topic_terms is null or case when exists(select 1 from exact_categories)
      then category.id in (select id from exact_categories)
      else exists(
      select 1 from unnest(p_topic_terms) topic
      where length(trim(topic)) > 0 and strpos(
        ' ' || trim(lower(regexp_replace(category.name || ' ' || c.title || ' ' || c.description,'[^[:alnum:]]+',' ','g'))) || ' ',
        ' ' || topic || ' ') > 0
    ) end)
  order by public.catalog_interest_score(category.name || ' ' || c.title || ' ' || c.description,p_terms) desc,
    c.created_at desc, c.id
  limit p_limit offset p_offset;
end;
$$;


commit;

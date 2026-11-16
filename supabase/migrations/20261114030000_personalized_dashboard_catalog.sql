begin;

-- Terms come from the saved survey. They influence public catalog ordering only.
create function public.catalog_interest_score(p_text text, p_terms jsonb)
returns integer language sql immutable parallel safe set search_path = '' as $$
  select coalesce(sum(term.weight),0)::integer
  from jsonb_to_recordset(p_terms) as term(term text, weight integer)
  where length(trim(term.term)) > 0 and term.weight between 1 and 4
    and strpos(' ' || trim(lower(regexp_replace(coalesce(p_text,''),'[^[:alnum:]]+',' ','g'))) || ' ',
      ' ' || term.term || ' ') > 0;
$$;

create function public.personalized_course_ids(
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
  select c.id from public.courses c join public.categories category on category.id=c.category_id
  where c.status='published' and (p_section <> 'featured' or c.is_featured)
    and (p_topic_terms is null or exists(
      select 1 from unnest(p_topic_terms) topic
      where length(trim(topic)) > 0 and strpos(
        ' ' || trim(lower(regexp_replace(category.name || ' ' || c.title || ' ' || c.description,'[^[:alnum:]]+',' ','g'))) || ' ',
        ' ' || topic || ' ') > 0
    ))
  order by public.catalog_interest_score(category.name || ' ' || c.title || ' ' || c.description,p_terms) desc,
    c.created_at desc, c.id
  limit p_limit offset p_offset;
end;
$$;

create function public.personalized_course_categories(p_terms jsonb default '[]')
returns table(id uuid, name text, slug text, course_count bigint)
language plpgsql stable security invoker set search_path = '' as $$
begin
  if p_terms is null or jsonb_typeof(p_terms) <> 'array' or jsonb_array_length(p_terms) > 512 then
    raise exception 'Invalid survey terms.' using errcode = '22023';
  end if;
  return query
  select category.id, category.name, category.slug, count(c.id)
  from public.categories category left join public.courses c
    on c.category_id=category.id and c.status='published'
  group by category.id
  order by public.catalog_interest_score(category.name,p_terms) +
    coalesce(max(public.catalog_interest_score(category.name || ' ' || c.title || ' ' || c.description,p_terms)),0) desc,
    category.display_order, category.id;
end;
$$;

revoke all on function public.catalog_interest_score(text,jsonb) from public;
revoke all on function public.personalized_course_ids(jsonb,text,text[],integer,integer) from public;
revoke all on function public.personalized_course_categories(jsonb) from public;
grant execute on function public.catalog_interest_score(text,jsonb) to anon, authenticated;
grant execute on function public.personalized_course_ids(jsonb,text,text[],integer,integer) to anon, authenticated;
grant execute on function public.personalized_course_categories(jsonb) to anon, authenticated;
commit;

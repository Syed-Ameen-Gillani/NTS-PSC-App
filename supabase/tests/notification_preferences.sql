do $$
declare
  v_owner uuid;
  v_other uuid;
  v_count integer;
begin
  select user_id into v_owner from public.user_notification_preferences
  order by user_id limit 1;
  select user_id into v_other from public.user_notification_preferences
  where user_id <> v_owner order by user_id limit 1;
  if v_owner is null or v_other is null then
    raise exception 'Two retained test profiles are required';
  end if;

  perform set_config('request.jwt.claim.sub', v_owner::text, true);
  execute 'set local role authenticated';
  select count(*) into v_count from public.user_notification_preferences;
  if v_count <> 1 then
    raise exception 'Preference read policy exposed another user';
  end if;
  begin
    update public.user_notification_preferences
    set promotions_enabled = not promotions_enabled where user_id = v_owner;
    get diagnostics v_count = row_count;
    if v_count <> 1 then
      raise exception 'Owner could not update preferences';
    end if;
    update public.user_notification_preferences
    set promotions_enabled = not promotions_enabled where user_id = v_other;
    get diagnostics v_count = row_count;
    if v_count <> 0 then
      raise exception 'Another user preference was updated';
    end if;
    raise exception 'Rollback preference test write';
  exception when raise_exception then
    if sqlerrm <> 'Rollback preference test write' then
      raise;
    end if;
  end;
end;
$$;

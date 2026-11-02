insert into public.categories (slug, name, icon_key, display_order)
values
  ('css-pms', 'CSS / PMS', 'menu_book', 45),
  ('general', 'General', 'school', 80)
on conflict (slug) do update
set name = excluded.name,
    icon_key = excluded.icon_key,
    display_order = excluded.display_order;

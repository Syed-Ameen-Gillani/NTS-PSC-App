-- Public catalog categories only. Test users and courses are created by fixtures.
insert into public.categories (slug, name, icon_key, display_order)
values
  ('ajk-psc', 'AJK PSC', 'account_balance', 10),
  ('fpsc', 'FPSC', 'account_balance', 20),
  ('nts', 'NTS', 'school', 30),
  ('css', 'CSS', 'menu_book', 40),
  ('css-pms', 'CSS / PMS', 'menu_book', 45),
  ('current-affairs', 'Current Affairs', 'public', 50),
  ('pakistan-affairs', 'Pakistan Affairs', 'flag', 60),
  ('english', 'English', 'translate', 70),
  ('general', 'General', 'school', 80)
on conflict (slug) do update
set name = excluded.name,
    icon_key = excluded.icon_key,
    display_order = excluded.display_order;

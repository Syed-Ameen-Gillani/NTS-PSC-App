alter table public.user_notification_preferences
  add column course_updates_enabled boolean not null default true,
  add column messages_discussions_enabled boolean not null default true,
  add column exam_results_enabled boolean not null default true,
  add column promotions_enabled boolean not null default false;

grant update (course_updates_enabled, messages_discussions_enabled,
  exam_results_enabled, promotions_enabled)
  on public.user_notification_preferences to authenticated;

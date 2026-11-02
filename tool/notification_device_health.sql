select
  count(*) as registered_device_count,
  count(*) filter (where platform = 'android') as android_device_count,
  max(last_seen_at) as latest_device_seen_at
from public.push_devices;

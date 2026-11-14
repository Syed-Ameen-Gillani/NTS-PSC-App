"""Read-only Storage delivery probe. Prints metrics, never keys or signed URLs."""
import json
import os
import argparse
from pathlib import Path
import struct
import time
from urllib.error import HTTPError, URLError
from urllib.parse import quote
from urllib.request import Request, urlopen


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--profile-config', action='store_true',
                        help='Write a temporary signed URL to ignored build/ for a device profile run.')
    args = parser.parse_args()
    env = dict(os.environ)
    config = Path(__file__).resolve().parent.parent / '.env'
    if config.exists():
        for line in config.read_text(encoding='utf-8-sig').splitlines():
            if '=' in line and not line.lstrip().startswith('#'):
                key, value = line.split('=', 1)
                env.setdefault(key.strip(), value.strip().strip('\"\''))
    base = env.get('SUPABASE_URL', '').rstrip('/')
    key = env.get('SUPABASE_SERVICE_ROLE_KEY') or env.get('SUPABASE_SECRET_KEY')
    url = env.get('VIDEO_PROBE_URL')
    if not url:
        if not base or not key:
            raise ValueError('Provide VIDEO_PROBE_URL or local Supabase admin credentials.')
        headers = {'apikey': key, 'Authorization': 'Bearer ' + key}
        request = Request(base + '/rest/v1/lesson_media?select=object_path&status=eq.ready&order=byte_size.desc&limit=1', headers=headers)
        with urlopen(request, timeout=20) as response:
            rows = json.load(response)
        if not rows:
            raise ValueError('No ready media available to probe.')
        path = quote(rows[0]['object_path'], safe='/')
        request = Request(base + '/storage/v1/object/sign/lesson-videos/' + path,
                          data=json.dumps({'expiresIn': 1800 if args.profile_config else 300}).encode(),
                          headers={**headers, 'Content-Type': 'application/json'})
        with urlopen(request, timeout=20) as response:
            signed = json.load(response)['signedURL']
        url = signed if signed.startswith('https://') else base + '/storage/v1' + signed
    started = time.perf_counter()
    request = Request(url, headers={'Range': 'bytes=0-65535'})
    with urlopen(request, timeout=30) as response:
        first_byte_ms = round((time.perf_counter() - started) * 1000)
        # Bound consumption even if the origin ignores Range.
        payload = response.read(65536)
        result = {
            'status': response.status,
            'range_supported': response.status == 206,
            'content_type': response.headers.get('Content-Type'),
            'content_range': response.headers.get('Content-Range'),
            'cache_control': response.headers.get('Cache-Control'),
            'first_response_ms': first_byte_ms,
            'sample_bytes': len(payload),
            'sample_transfer_ms': round((time.perf_counter() - started) * 1000),
        }
    offset = 0
    faststart = None
    while offset + 8 <= len(payload):
        size, kind = struct.unpack_from('>I4s', payload, offset)
        if kind == b'moov':
            faststart = True
            break
        if kind == b'mdat':
            faststart = False
            break
        if size == 1:
            if offset + 16 > len(payload):
                break
            size = struct.unpack_from('>Q', payload, offset + 8)[0]
        if size < 8:
            break
        offset += size
    result['mp4_moov_before_mdat'] = faststart
    if args.profile_config:
        target = Path(__file__).resolve().parent.parent / 'build' / 'video_profile_config.json'
        target.parent.mkdir(exist_ok=True)
        target.write_text(json.dumps({'VIDEO_PROFILE_URL': url}), encoding='utf-8')
        result['profile_config_written'] = True
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    try:
        main()
    except HTTPError as error:
        print(json.dumps({'error': 'HTTP request failed', 'status': error.code}))
        raise SystemExit(1)
    except (URLError, OSError, ValueError, KeyError) as error:
        # Exception text can include credentials or signed URLs; expose type only.
        print(json.dumps({'error': type(error).__name__, 'message': 'Delivery probe could not complete.'}))
        raise SystemExit(1)

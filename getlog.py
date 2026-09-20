import urllib.request, zipfile, io, re, sys

run_id = sys.argv[1] if len(sys.argv) > 1 else '35522599380'
url = f'https://api.github.com/repos/Didiyee/Dikrapp/actions/runs/{run_id}/logs'
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0', 'Accept': 'application/vnd.github+json'})
try:
    with urllib.request.urlopen(req, timeout=60) as r:
        data = r.read()
    print('downloaded bytes:', len(data))
    z = zipfile.ZipFile(io.BytesIO(data))
    for name in z.namelist():
        print('LOG FILE:', name)
    # find the build-apk job log (usually "0_build-apk.txt" etc.)
    for name in z.namelist():
        txt = z.read(name).decode('utf-8', errors='replace')
        if 'cap:sync' in txt or 'error' in txt.lower():
            lines = txt.splitlines()
            # print tail around failures
            for i, ln in enumerate(lines):
                if '##[error]' in ln or 'Error:' in ln or 'error ' in ln.lower() and ('npm' in ln.lower() or 'vite' in ln.lower() or 'cap' in ln.lower()):
                    start = max(0, i - 3)
                    print('=' * 80)
                    print('\n'.join(lines[start:i + 12]))
            # also print last 30 lines
            print('=' * 80)
            print(f'--- TAIL of {name} ---')
            print('\n'.join(lines[-30:]))
except Exception as e:
    print('ERR:', e)

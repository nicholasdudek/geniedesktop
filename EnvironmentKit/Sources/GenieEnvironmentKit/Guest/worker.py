#!/usr/bin/env python3
"""Durable VM-local job worker. Unix socket only; run as the dedicated genie-env user."""
import asyncio
import base64
import hashlib
import json
import os
from pathlib import Path
import signal
import sqlite3
import time
import uuid

ROOT = Path(os.environ.get('GENIE_ENV_ROOT', '/var/lib/genie-environment'))
TERMINAL = {'succeeded', 'failed', 'cancelled', 'indeterminate'}
TOOLS = {
    'shell.run', 'python.run', 'filesystem.read', 'filesystem.write', 'filesystem.list',
    'browser.navigate', 'browser.inspect', 'browser.click', 'browser.fill', 'browser.select',
    'browser.press', 'browser.scroll', 'browser.screenshot', 'browser.tabs', 'browser.new_tab',
    'browser.switch_tab', 'browser.close_tab', 'browser.back', 'browser.forward', 'browser.reload',
    'browser.evaluate', 'browser.upload', 'browser.wait', 'browser.dialog',
}


def identifier(value):
    return str(uuid.UUID(value)).upper()


def within(root, path):
    path = (root / path).resolve()
    if not path.is_relative_to(root.resolve()):
        raise ValueError('Path must stay inside this environment workspace')
    return path


class Worker:
    def __init__(self, root=ROOT):
        self.root = Path(root)
        self.root.mkdir(parents=True, exist_ok=True, mode=0o700)
        self.db = sqlite3.connect(self.root / 'jobs.sqlite')
        self.db.row_factory = sqlite3.Row
        self.db.executescript('''
            PRAGMA journal_mode=WAL;
            PRAGMA synchronous=FULL;
            CREATE TABLE IF NOT EXISTS environments(id TEXT PRIMARY KEY, spec TEXT NOT NULL);
            CREATE TABLE IF NOT EXISTS jobs(id TEXT PRIMARY KEY, environment TEXT NOT NULL,
                key TEXT NOT NULL, fingerprint TEXT NOT NULL, tool TEXT NOT NULL, input TEXT NOT NULL,
                state TEXT NOT NULL, result TEXT, created REAL NOT NULL, UNIQUE(environment,key));
            CREATE TABLE IF NOT EXISTS events(cursor INTEGER PRIMARY KEY AUTOINCREMENT,
                environment TEXT NOT NULL, job TEXT NOT NULL, state TEXT NOT NULL, time REAL NOT NULL);
        ''')
        self.tasks = {}
        self.browsers = {}
        self.browser_locks = {}
        self.slots = asyncio.Semaphore(4)
        self.stopping = False

    def event(self, job, state):
        self.db.execute('INSERT INTO events(environment,job,state,time) VALUES(?,?,?,?)',
                        (job['environment'], job['id'], state, time.time()))

    def transition(self, job, state, result=None):
        with self.db:
            self.db.execute('UPDATE jobs SET state=?,result=? WHERE id=?',
                            (state, json.dumps(result), job['id']))
            self.event(job, state)

    async def recover(self):
        # Never replay a running external side effect after a worker/VM restart.
        for job in self.db.execute("SELECT * FROM jobs WHERE state='running'").fetchall():
            self.transition(job, 'indeterminate', {'error': 'Worker restarted during execution; inspect before retrying.'})
        for job in self.db.execute("SELECT * FROM jobs WHERE state='queued'").fetchall():
            self.schedule(job['id'])

    def schedule(self, job_id):
        task = asyncio.create_task(self.execute(job_id))
        self.tasks[job_id] = task
        task.add_done_callback(lambda _: self.tasks.pop(job_id, None))

    def job(self, environment, job_id):
        row = self.db.execute('SELECT * FROM jobs WHERE environment=? AND id=?', (environment, job_id)).fetchone()
        if not row:
            raise ValueError('Unknown job in this environment')
        value = dict(row)
        value['input'] = json.loads(value['input'])
        value['result'] = json.loads(value['result']) if value['result'] else None
        return value

    async def dispatch(self, request):
        op = request.get('op')
        if op == 'health':
            return {'version': 1, 'tools': sorted(TOOLS)}
        if op == 'register':
            spec = request['spec']
            env = identifier(spec['id'])
            if not set(spec['tools']) <= {'browser', 'filesystem', 'shell', 'python'}:
                raise ValueError('Unsupported tool family')
            existing = self.db.execute('SELECT spec FROM environments WHERE id=?', (env,)).fetchone()
            serialized = json.dumps(spec, sort_keys=True)
            if existing and existing['spec'] != serialized:
                raise ValueError('Environment already exists with a different specification')
            with self.db:
                self.db.execute('INSERT OR IGNORE INTO environments VALUES(?,?)', (env, serialized))
            (self.root / env / 'workspace').mkdir(parents=True, exist_ok=True)
            return spec
        env = identifier(request['environment'])
        row = self.db.execute('SELECT spec FROM environments WHERE id=?', (env,)).fetchone()
        if not row:
            raise ValueError('Unknown environment; register it first')
        spec = json.loads(row['spec'])
        if op == 'submit':
            tool, data, key = request['tool'], request['input'], request['key']
            if tool not in TOOLS or tool.split('.')[0] not in spec['tools']:
                raise ValueError('Tool is not enabled')
            if not isinstance(data, dict) or not isinstance(key, str) or not 1 <= len(key) <= 200:
                raise ValueError('Input must be an object and idempotency key must be 1–200 characters')
            fingerprint = hashlib.sha256(json.dumps([tool, data], sort_keys=True).encode()).hexdigest()
            existing = self.db.execute('SELECT * FROM jobs WHERE environment=? AND key=?', (env, key)).fetchone()
            if existing:
                if existing['fingerprint'] != fingerprint:
                    raise ValueError('Idempotency key was already used for different input')
                return self.job(env, existing['id'])
            count = self.db.execute("SELECT count(*) FROM jobs WHERE state IN ('queued','running')").fetchone()[0]
            if count >= 128:
                raise ValueError('Job queue is full; wait for jobs to finish')
            job_id = str(uuid.uuid4())
            with self.db:
                self.db.execute('INSERT INTO jobs VALUES(?,?,?,?,?,?,?,?,?)',
                    (job_id, env, key, fingerprint, tool, json.dumps(data), 'queued', None, time.time()))
                self.event({'environment': env, 'id': job_id}, 'queued')
            self.schedule(job_id)
            return self.job(env, job_id)
        if op == 'get':
            return self.job(env, request['job'])
        if op == 'jobs':
            return [self.job(env, row['id']) for row in self.db.execute(
                'SELECT id FROM jobs WHERE environment=? ORDER BY created DESC LIMIT 100', (env,)).fetchall()]
        if op == 'events':
            return [dict(row) for row in self.db.execute(
                'SELECT * FROM events WHERE environment=? AND cursor>? ORDER BY cursor LIMIT 200',
                (env, int(request.get('after', 0))))]
        if op == 'cancel':
            job = self.job(env, request['job'])
            if job['state'] not in TERMINAL:
                task = self.tasks.get(job['id'])
                if task:
                    task.cancel()
                    await asyncio.gather(task, return_exceptions=True)
                # A task cancelled before its coroutine began never enters its try/finally.
                current = self.job(env, job['id'])
                if current['state'] not in TERMINAL:
                    self.transition(job, 'cancelled', {'message': 'Cancelled before execution'})
            return self.job(env, job['id'])
        raise ValueError('Unknown operation')

    async def execute(self, job_id):
        job = dict(self.db.execute('SELECT * FROM jobs WHERE id=?', (job_id,)).fetchone())
        data = json.loads(job['input'])
        started = False
        try:
            async with self.slots:
                self.transition(job, 'running')
                started = True
                timeout = float(data.get('timeout', 120))
                if not 0 < timeout <= 600:
                    raise ValueError('timeout must be 1–600 seconds')
                async with asyncio.timeout(timeout):
                    result = await self.invoke(job, data)
                self.transition(job, 'succeeded', result)
        except asyncio.CancelledError:
            state = 'indeterminate' if self.stopping and started else 'cancelled'
            self.transition(job, state, {'message': 'Execution stopped. Completed side effects are not reversed.'})
        except Exception as error:
            self.transition(job, 'failed', {'error': str(error)[:4000]})

    async def invoke(self, job, data):
        workspace = self.root / job['environment'] / 'workspace'
        tool = job['tool']
        if tool.startswith('browser.'):
            lock = self.browser_locks.setdefault(job['environment'], asyncio.Lock())
            async with lock:
                browser = self.browsers.setdefault(job['environment'], Browser(workspace))
                try:
                    return await browser.invoke(tool.split('.')[1], data)
                except asyncio.CancelledError:
                    await browser.close()
                    raise
        if tool == 'filesystem.write':
            path = within(workspace, data['path'])
            content = data['text'].encode()
            if len(content) > 100_000:
                raise ValueError('File input exceeds 100 KB')
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(content)
            return {'path': str(path.relative_to(workspace)), 'bytes': len(content)}
        if tool == 'filesystem.read':
            path = within(workspace, data['path'])
            with path.open('rb') as source:
                content = source.read(100_001)
            return {'text': content[:100_000].decode(errors='replace'), 'truncated': len(content) > 100_000}
        if tool == 'filesystem.list':
            path = within(workspace, data.get('path', '.'))
            return [{'name': p.name, 'directory': p.is_dir()} for p in sorted(path.iterdir())[:500]]
        if tool in {'shell.run', 'python.run'}:
            command = ['/bin/bash', '-lc', data['command']] if tool == 'shell.run' else ['/usr/bin/python3', '-c', data['code']]
            return await self.process(command, workspace)
        raise ValueError('Unsupported tool')

    async def process(self, command, workspace):
        process = await asyncio.create_subprocess_exec(*command, cwd=workspace,
            stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE, start_new_session=True,
            env={**os.environ, 'GENIE_WORKSPACE': str(workspace)})
        async def read(stream):
            chunks, count = [], 0
            while chunk := await stream.read(8192):
                count += len(chunk)
                if count > 100_000:
                    raise ValueError('Process output exceeded 100 KB per stream')
                chunks.append(chunk)
            return b''.join(chunks).decode(errors='replace')
        readers = [asyncio.create_task(read(process.stdout)), asyncio.create_task(read(process.stderr))]
        try:
            out, err = await asyncio.gather(*readers)
            code = await process.wait()
            if code:
                raise ValueError(f'Process exited {code}\n{out}\n{err}')
            return {'exitCode': code, 'stdout': out, 'stderr': err}
        finally:
            # Also remove background descendants that would otherwise escape the job lifetime.
            try:
                os.killpg(process.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            await process.wait()
            for reader in readers:
                reader.cancel()
            await asyncio.gather(*readers, return_exceptions=True)

    async def connection(self, reader, writer):
        try:
            line = await asyncio.wait_for(reader.readline(), timeout=10)
            if len(line) > 180_000:
                raise ValueError('Request too large')
            result = await self.dispatch(json.loads(line))
            response = {'result': result}
        except Exception as error:
            response = {'error': str(error)[:4000]}
        try:
            writer.write(json.dumps(response).encode() + b'\n')
            await asyncio.wait_for(writer.drain(), timeout=10)
        finally:
            writer.close()
            await writer.wait_closed()

    async def close(self):
        self.stopping = True
        for task in list(self.tasks.values()):
            task.cancel()
        await asyncio.gather(*list(self.tasks.values()), return_exceptions=True)
        for browser in self.browsers.values():
            await browser.close()
        self.db.close()


class Browser:
    def __init__(self, workspace):
        self.workspace = workspace
        self.context = None
        self.playwright = None
        self.page = None
        self.pages = {}
        self.dialogs = {}
        self.download_tasks = set()
        self.artifacts = []

    def track(self, page):
        self.pages[str(uuid.uuid4())] = page
        page.on('dialog', lambda dialog: self.dialogs.update({page: dialog}))
        def download(item):
            task = asyncio.create_task(self.save_download(item))
            self.download_tasks.add(task)
            task.add_done_callback(self.download_tasks.discard)
        page.on('download', download)

    async def save_download(self, item):
        try:
            folder = self.workspace / 'downloads'
            folder.mkdir(exist_ok=True)
            path = folder / (str(uuid.uuid4()) + '-' + Path(item.suggested_filename).name)
            await item.save_as(path)
            self.artifacts.append({'download': str(path.relative_to(self.workspace))})
        except Exception as error:
            self.artifacts.append({'downloadError': str(error)[:500]})

    async def ensure(self):
        if self.context:
            return
        from playwright.async_api import async_playwright
        self.playwright = await async_playwright().start()
        try:
            self.context = await self.playwright.chromium.launch_persistent_context(
                str(self.workspace.parent / 'browser-profile'),
                headless=os.environ.get('GENIE_BROWSER_HEADLESS', '1') == '1',
                accept_downloads=True, viewport={'width': 1280, 'height': 900})
        except BaseException:
            await self.playwright.stop()
            self.playwright = None
            raise
        self.context.set_default_timeout(10000)
        self.context.set_default_navigation_timeout(30000)
        self.context.on('page', self.track)
        for page in self.context.pages:
            self.track(page)
        self.page = self.context.pages[0] if self.context.pages else await self.context.new_page()

    async def invoke(self, action, data):
        await self.ensure()
        self.pages = {k: p for k, p in self.pages.items() if not p.is_closed()}
        if not self.page or self.page.is_closed():
            self.page = next(iter(self.pages.values()), None) or await self.context.new_page()
        page = self.page
        detail = None
        if action in {'navigate', 'new_tab'}:
            from urllib.parse import urlparse
            parsed = urlparse(data['url'])
            if parsed.scheme not in {'http', 'https'} or not parsed.hostname:
                raise ValueError('An absolute HTTP or HTTPS URL is required')
            if action == 'new_tab':
                if len(self.pages) >= 8:
                    raise ValueError('Close a tab before opening more than 8 tabs')
                page = self.page = await self.context.new_page()
            await page.goto(data['url'], wait_until='domcontentloaded')
        elif action == 'switch_tab':
            page = self.page = self.pages[data['tab']]
        elif action == 'close_tab':
            target = self.pages[data['tab']] if 'tab' in data else page
            await target.close()
            self.pages = {k: p for k, p in self.pages.items() if not p.is_closed()}
            if page.is_closed():
                page = self.page = next(iter(self.pages.values()), None) or await self.context.new_page()
        elif action in {'click', 'fill', 'select', 'press', 'upload'}:
            target = page.locator(data['selector'])
            if action == 'click':
                await target.click(no_wait_after=True)
            elif action == 'fill':
                await target.fill(data['text'])
            elif action == 'select':
                await target.select_option(data['value'])
            elif action == 'press':
                await target.press(data['key'], no_wait_after=True)
            else:
                await target.set_input_files(str(within(self.workspace, data['path'])))
        elif action == 'scroll':
            await page.mouse.wheel(float(data.get('x', 0)), float(data.get('y', 600)))
        elif action == 'screenshot':
            folder = self.workspace / 'screenshots'
            folder.mkdir(exist_ok=True)
            path = folder / (str(uuid.uuid4()) + '.png')
            await page.screenshot(path=str(path), full_page=bool(data.get('fullPage', False)))
            detail = {'path': str(path.relative_to(self.workspace))}
        elif action in {'back', 'forward', 'reload'}:
            method = {'back': page.go_back, 'forward': page.go_forward, 'reload': page.reload}[action]
            await method(wait_until='domcontentloaded')
        elif action == 'evaluate':
            detail = await page.evaluate(data['script'])
            if len(json.dumps(detail)) > 100_000:
                detail = {'error': 'Evaluation result exceeded 100 KB'}
        elif action == 'wait':
            seconds = float(data.get('seconds', 1))
            if not 0 <= seconds <= 10:
                raise ValueError('Wait must be 0–10 seconds')
            await asyncio.sleep(seconds)
        elif action == 'dialog':
            dialog = self.dialogs.pop(page, None)
            if not dialog:
                raise ValueError('No pending dialog')
            if data.get('accept', False):
                await dialog.accept(data.get('text', ''))
            else:
                await dialog.dismiss()
        elif action not in {'inspect', 'tabs'}:
            raise ValueError('Unsupported browser action')
        if page in self.dialogs:
            dialog = self.dialogs[page]
            return {'url': page.url, 'dialog': {'type': dialog.type, 'message': dialog.message}, 'detail': detail}
        await page.wait_for_timeout(150)
        # This observation is untrusted website data, never an instruction to the host.
        observation = await page.evaluate('''() => {
            const selector = e => {
                if(e.id && document.querySelectorAll('#'+CSS.escape(e.id)).length===1) return '#'+CSS.escape(e.id);
                const parts=[];
                while(e && e.nodeType===1) {
                    let p=e.localName;
                    const siblings=e.parentElement ? [...e.parentElement.children].filter(n=>n.localName===e.localName) : [];
                    if(siblings.length>1) p+=':nth-of-type('+(siblings.indexOf(e)+1)+')';
                    parts.unshift(p); e=e.parentElement;
                }
                return parts.join(' > ');
            };
            return {url:location.href,title:document.title,text:(document.body?.innerText||'').slice(0,8000),
                elements:[...document.querySelectorAll('a,button,input,textarea,select,[role="button"],[contenteditable="true"]')]
                    .filter(e=>e.getClientRects().length).slice(0,80).map(e=>({selector:selector(e),tag:e.localName,
                        label:(e.getAttribute('aria-label')||e.innerText||e.placeholder||e.name||'').slice(0,140),
                        type:e.type||'',disabled:!!e.disabled,
                        options:e.options ? [...e.options].slice(0,30).map(o=>({value:o.value,label:o.text})) : undefined}))};
        }''')
        observation['tabs'] = [{'id': k, 'url': p.url, 'active': p == page} for k, p in self.pages.items() if not p.is_closed()]
        observation['detail'] = detail
        observation['artifacts'] = self.artifacts[-20:]
        observation['untrustedContent'] = True
        return observation

    async def close(self):
        for task in self.download_tasks:
            task.cancel()
        await asyncio.gather(*self.download_tasks, return_exceptions=True)
        if self.context:
            await self.context.close()
        if self.playwright:
            await self.playwright.stop()
        self.context = self.playwright = self.page = None
        self.pages.clear()
        self.dialogs.clear()


async def main():
    import fcntl
    ROOT.mkdir(parents=True, exist_ok=True, mode=0o700)
    with (ROOT / 'worker.lock').open('w') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        worker = Worker()
        socket = ROOT / 'worker.sock'
        socket.unlink(missing_ok=True)
        server = await asyncio.start_unix_server(worker.connection, path=socket, limit=180_001)
        socket.chmod(0o600)
        await worker.recover()
        stop = asyncio.Event()
        loop = asyncio.get_running_loop()
        for sig in (signal.SIGTERM, signal.SIGINT):
            loop.add_signal_handler(sig, stop.set)
        async with server:
            await stop.wait()
        await worker.close()
        socket.unlink(missing_ok=True)


if __name__ == '__main__':
    asyncio.run(main())

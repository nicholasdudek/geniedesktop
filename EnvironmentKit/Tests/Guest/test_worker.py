import asyncio
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
import uuid

source = Path(__file__).parents[2] / 'Sources/GenieEnvironmentKit/Guest/worker.py'
spec = importlib.util.spec_from_file_location('worker', source)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class WorkerTests(unittest.IsolatedAsyncioTestCase):
    async def asyncSetUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.worker = module.Worker(self.temp.name)
        self.env = str(uuid.uuid4()).upper()
        await self.worker.dispatch({'op': 'register', 'spec': {'id': self.env, 'name': 'test', 'tools': ['shell', 'filesystem', 'python', 'browser']}})

    async def asyncTearDown(self):
        await self.worker.close()
        self.temp.cleanup()

    async def submit(self, tool, data, key=None):
        return await self.worker.dispatch({'op': 'submit', 'environment': self.env, 'tool': tool, 'input': data, 'key': key or str(uuid.uuid4())})

    async def finish(self, job):
        if task := self.worker.tasks.get(job['id']):
            await task
        return self.worker.job(self.env, job['id'])

    async def test_shell_and_files(self):
        job = await self.finish(await self.submit('shell.run', {'command': 'printf hello > greeting.txt; printf done'}))
        self.assertEqual(job['result']['stdout'], 'done')
        read = await self.finish(await self.submit('filesystem.read', {'path': 'greeting.txt'}))
        self.assertEqual(read['result']['text'], 'hello')

    async def test_idempotency_and_conflicting_reuse(self):
        first = await self.submit('shell.run', {'command': 'echo once >> count.txt'}, 'key')
        second = await self.submit('shell.run', {'command': 'echo once >> count.txt'}, 'key')
        self.assertEqual(first['id'], second['id'])
        await self.finish(first)
        with self.assertRaisesRegex(ValueError, 'different input'):
            await self.submit('shell.run', {'command': 'echo twice'}, 'key')
        read = await self.finish(await self.submit('filesystem.read', {'path': 'count.txt'}))
        self.assertEqual(read['result']['text'], 'once\n')

    async def test_cancellation_terminates_shell(self):
        job = await self.submit('shell.run', {'command': 'sleep 30'})
        await asyncio.sleep(.1)
        result = await asyncio.wait_for(self.worker.dispatch({'op': 'cancel', 'environment': self.env, 'job': job['id']}), 3)
        self.assertEqual(result['state'], 'cancelled')

    async def test_cancel_before_scheduling(self):
        job = await self.submit('shell.run', {'command': 'echo should-not-run'})
        result = await self.worker.dispatch({'op': 'cancel', 'environment': self.env, 'job': job['id']})
        self.assertEqual(result['state'], 'cancelled')

    async def test_restart_preserves_results_and_marks_running_indeterminate(self):
        done = await self.finish(await self.submit('python.run', {'code': 'print(2+2)'}))
        with self.worker.db:
            self.worker.db.execute("UPDATE jobs SET state='running' WHERE id=?", (done['id'],))
        await self.worker.close()
        self.worker = module.Worker(self.temp.name)
        await self.worker.recover()
        recovered = self.worker.job(self.env, done['id'])
        self.assertEqual(recovered['state'], 'indeterminate')
        events = await self.worker.dispatch({'op': 'events', 'environment': self.env, 'after': 0})
        self.assertEqual(events[-1]['state'], 'indeterminate')
        later = await self.worker.dispatch({'op': 'events', 'environment': self.env, 'after': events[-2]['cursor']})
        self.assertEqual(len(later), 1)

    async def test_timeout_and_path_escape(self):
        timed = await self.finish(await self.submit('shell.run', {'command': 'sleep 30', 'timeout': .1}))
        self.assertEqual(timed['state'], 'failed')
        escaped = await self.finish(await self.submit('filesystem.write', {'path': '../../escaped', 'text': 'x'}))
        self.assertEqual(escaped['state'], 'failed')
        self.assertFalse((Path(self.temp.name) / 'escaped').exists())

    async def test_unknown_tool_and_wrong_environment(self):
        with self.assertRaisesRegex(ValueError, 'not enabled'):
            await self.submit('host.shell', {'command': 'whoami'})
        job = await self.submit('filesystem.list', {})
        with self.assertRaisesRegex(ValueError, 'Unknown job'):
            self.worker.job(str(uuid.uuid4()).upper(), job['id'])
        await self.finish(job)

    async def test_bounded_output(self):
        job = await self.finish(await self.submit('python.run', {'code': 'print("x" * 200000)'}))
        self.assertEqual(job['state'], 'failed')
        self.assertIn('exceeded', job['result']['error'])


if __name__ == '__main__':
    unittest.main()

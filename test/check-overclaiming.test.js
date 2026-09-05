import { test } from 'node:test';
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { writeFileSync, mkdtempSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';

const SCRIPT = new URL('../scripts/check-overclaiming.sh', import.meta.url).pathname;

function run(payload) {
  try {
    execFileSync(SCRIPT, [], { input: JSON.stringify(payload), stdio: ['pipe', 'pipe', 'pipe'] });
    return { code: 0 };
  } catch (err) {
    return { code: err.status, stderr: err.stderr?.toString() ?? '' };
  }
}

function transcriptWith(content) {
  const dir = mkdtempSync(join(tmpdir(), 'vf-test-'));
  const path = join(dir, 'transcript.jsonl');
  writeFileSync(path, content);
  return path;
}

test('blocks (exit 2) when a red-flag phrase appears with no verification evidence nearby', () => {
  const result = run({
    last_assistant_message: 'I checked and nobody has done this before, so this is genuinely unique.',
    transcript_path: transcriptWith(''),
  });
  assert.equal(result.code, 2);
  assert.match(result.stderr, /nobody has done this/);
});

test('allows (exit 0) the same red-flag phrase when search evidence is present nearby', () => {
  const result = run({
    last_assistant_message: 'I checked and nobody has done this before, so this is genuinely unique.',
    transcript_path: transcriptWith('...earlier in this session a WebSearch tool call happened...'),
  });
  assert.equal(result.code, 0);
});

test('allows (exit 0) a message with no red-flag phrase at all', () => {
  const result = run({
    last_assistant_message: 'Here is a summary of the changes I made.',
    transcript_path: transcriptWith(''),
  });
  assert.equal(result.code, 0);
});

test('fails open (exit 0) on malformed JSON input rather than crashing or blocking', () => {
  try {
    execFileSync(SCRIPT, [], { input: 'not even json', stdio: ['pipe', 'pipe', 'pipe'] });
  } catch (err) {
    assert.fail(`expected exit 0, got exit ${err.status}`);
  }
});

test('fails open (exit 0) on completely empty stdin', () => {
  try {
    execFileSync(SCRIPT, [], { input: '', stdio: ['pipe', 'pipe', 'pipe'] });
  } catch (err) {
    assert.fail(`expected exit 0, got exit ${err.status}`);
  }
});

test('fails open (exit 0) when transcript_path points to a nonexistent file', () => {
  const result = run({
    last_assistant_message: 'This has never been done before.',
    transcript_path: '/nonexistent/path/transcript.jsonl',
  });
  // No transcript to check for evidence in -> can't confirm verification happened,
  // but a missing file is an environment issue, not grounds to block the user.
  assert.equal(result.code, 0);
});

test('registry-check evidence (npm/gh) also counts as verification, not just WebSearch', () => {
  const result = run({
    last_assistant_message: 'No prior art exists for this approach.',
    transcript_path: transcriptWith('ran `gh search repos "..."` and `npm view ...` earlier'),
  });
  assert.equal(result.code, 0);
});

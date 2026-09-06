import { test } from 'node:test';
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { writeFileSync, mkdtempSync, mkdirSync } from 'node:fs';
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

// The real shape a tool invocation actually takes in a Claude Code
// transcript JSONL line, as verified against a real session transcript.
function realToolUse(name) {
  return `{"type":"tool_use","name":"${name}","id":"toolu_test","input":{}}`;
}

test('blocks (exit 2) when a red-flag phrase appears with no verification evidence nearby', () => {
  const result = run({
    last_assistant_message: 'I checked and nobody has done this before, so this is genuinely unique.',
    transcript_path: transcriptWith(''),
  });
  assert.equal(result.code, 2);
  assert.match(result.stderr, /nobody has done this/);
});

test('allows (exit 0) the same red-flag phrase when a real WebSearch tool call is present nearby', () => {
  const result = run({
    last_assistant_message: 'I checked and nobody has done this before, so this is genuinely unique.',
    transcript_path: transcriptWith(realToolUse('WebSearch')),
  });
  assert.equal(result.code, 0);
});

test('blocks (exit 2) when the transcript only contains a TEXT MENTION of WebSearch, not a real tool call', () => {
  // Regression test for a real loophole: the evidence check used to be a
  // bare substring match, so an assistant narrating "I did a WebSearch and
  // confirmed this" without ever actually invoking the tool would count as
  // verification -- exactly the unverified-claim failure mode this hook
  // exists to catch, being used to defeat the hook itself.
  const result = run({
    last_assistant_message: 'I checked and nobody has done this before, so this is genuinely unique.',
    transcript_path: transcriptWith('{"type":"text","text":"Let me think. I did a WebSearch just now and confirmed nothing similar exists."}'),
  });
  assert.equal(result.code, 2);
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

test('resolves a literal leading "~" in transcript_path against $HOME, matching the docs\' own example format', () => {
  // The official Stop-hook docs show transcript_path as
  // "~/.claude/projects/.../thread.jsonl" in their example JSON. A shell
  // variable's contents are never tilde-expanded by `[ -f ... ]` the way a
  // literal `~` in source code would be, so if that were ever the real
  // runtime value, the file-exists check would always fail and the
  // evidence check would silently never run. If the tilde isn't resolved,
  // the file is never found, the script fails open (exit 0), and that's
  // indistinguishable from "evidence found" -- so blocking here (exit 2,
  // no evidence in the real empty file) proves the path was actually
  // resolved and checked, not just skipped.
  const home = mkdtempSync(join(tmpdir(), 'vf-home-'));
  mkdirSync(join(home, 'sub'), { recursive: true });
  writeFileSync(join(home, 'sub', 'transcript.jsonl'), '');
  let result;
  try {
    execFileSync(SCRIPT, [], {
      input: JSON.stringify({
        last_assistant_message: 'This has never been done before.',
        transcript_path: '~/sub/transcript.jsonl',
      }),
      stdio: ['pipe', 'pipe', 'pipe'],
      env: { ...process.env, HOME: home },
    });
    result = { code: 0 };
  } catch (err) {
    result = { code: err.status, stderr: err.stderr?.toString() ?? '' };
  }
  assert.equal(result.code, 2);
});

test('registry-check evidence (npm/gh) also counts as verification, not just WebSearch', () => {
  const result = run({
    last_assistant_message: 'No prior art exists for this approach.',
    transcript_path: transcriptWith('ran `gh search repos "..."` and `npm view ...` earlier'),
  });
  assert.equal(result.code, 0);
});

test('blocks (exit 2) on a Chinese overclaiming phrase with no verification evidence nearby', () => {
  const result = run({
    last_assistant_message: '目前沒有人做過完全一樣的開源專案,這是全新的概念。',
    transcript_path: transcriptWith(''),
  });
  assert.equal(result.code, 2);
  assert.match(result.stderr, /沒有人做過/);
});

test('blocks (exit 2) on a fully-simplified-Chinese overclaiming phrase, not just the traditional form', () => {
  // Regression test: three ZH sub-patterns mixed a traditional character in
  // one part with no simplified counterpart elsewhere in the same
  // sub-pattern, so a fully simplified phrase silently failed to match even
  // though the mostly-traditional form did: "没有人开发过" (ended in
  // simplified 过, pattern only checked traditional 過), "保证绝对可行"
  // (pattern only had traditional 保證, not 保证), "查无前例" (pattern only
  // had traditional 查無, not 查无).
  const result = run({
    last_assistant_message: '没有人开发过这个功能,保证绝对可行,查无前例。',
    transcript_path: transcriptWith(''),
  });
  assert.equal(result.code, 2);
});

test('allows (exit 0) the same Chinese phrase when a real WebSearch tool call is present nearby', () => {
  const result = run({
    last_assistant_message: '目前沒有人做過完全一樣的開源專案。',
    transcript_path: transcriptWith(realToolUse('WebSearch')),
  });
  assert.equal(result.code, 0);
});

test('blocks (exit 2) on a citation-shaped claim (fabrication trap) with no verification evidence nearby', () => {
  const result = run({
    last_assistant_message: 'According to Smith (1998), generating functions were applied to inventory models with strong results.',
    transcript_path: transcriptWith(''),
  });
  assert.equal(result.code, 2);
  assert.match(result.stderr, /Smith \(1998\)/);
});

test('allows (exit 0) an ordinary "ProperNoun (Year)" sentence with no citation involved at all', () => {
  // Regression test for a real false-positive: an earlier version of the
  // citation-shaped pattern matched ANY capitalized word followed by a
  // parenthetical year, so completely unrelated claims about products or
  // companies would get blocked as if they were fabricated citations.
  const result = run({
    last_assistant_message: 'Tesla (2020) delivered record production numbers that quarter, and our team shipped Project Phoenix (2024) ahead of schedule.',
    transcript_path: transcriptWith(''),
  });
  assert.equal(result.code, 0);
});

test('allows (exit 0) a Chinese sentence with an unrelated year and an unrelated research-word far apart in the same message', () => {
  // Regression test: the Chinese citation pattern used an unbounded `.*`
  // between the year and the research-related word, so any message that
  // happened to mention both anywhere -- even about unrelated things --
  // would be flagged as a fabricated-citation shape.
  const result = run({
    last_assistant_message: '公司在2020年成立,後來團隊做的市場研究顯示成長穩定。',
    transcript_path: transcriptWith(''),
  });
  assert.equal(result.code, 0);
});

test('allows (exit 0) a citation-shaped claim once a scholarly-source evidence pattern is present', () => {
  const result = run({
    last_assistant_message: 'According to Smith (1998), generating functions were applied to inventory models.',
    transcript_path: transcriptWith('fetched https://scholar.google.com/... and confirmed the citation'),
  });
  assert.equal(result.code, 0);
});

test('allows (exit 0) when real search evidence is followed by enough tool output to have been truncated by a fixed-size tail window', () => {
  // Regression test: an earlier version only scanned `tail -c 20000` of the
  // transcript, so a WebSearch call followed by >20000 bytes of verbose
  // tool output in the same turn got pushed out of the checked window,
  // producing a false block on a claim that had actually been verified.
  const padding = 'x'.repeat(25000);
  const result = run({
    last_assistant_message: 'nobody has done this before',
    transcript_path: transcriptWith(`${realToolUse('WebSearch')}\n${padding}`),
  });
  assert.equal(result.code, 0);
});

test('allows (exit 0) and does not re-block when stop_hook_active is true, to avoid an infinite block/rewrite loop', () => {
  // stop_hook_active is true when Claude Code is already continuing because
  // a previous Stop hook blocked the turn. If a claim genuinely can't be
  // verified in this environment (e.g. no network access), blocking again
  // here would trap the session in an endless block-rewrite-block cycle.
  const result = run({
    last_assistant_message: 'This has never been done before and is genuinely unique.',
    stop_hook_active: true,
    transcript_path: transcriptWith(''),
  });
  assert.equal(result.code, 0);
});

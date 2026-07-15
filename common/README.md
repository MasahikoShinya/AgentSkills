# Agent Workflow Kit

Claude Code、Codex、および互換エージェントで共通利用する収束フェーズ制御キットです。確定仕様に対する最小差分実装、独立diff review、機械gate、commit直前のCodex自動レビューを組み合わせます。

Skillの自動発動には依存しません。共通基盤はMarkdown、shell script、Git Hookです。

## Trigger

| Trigger | 起動する処理 |
|---|---|
| 自動駆動 | `AGENTS.md`／`CLAUDE.md`、Mode Selector、SESSION_BRIEF、標準収束フロー |
| ユーザー指示 | `::resolve`、`::sdd_tdd`、`::ui-mock`、`::test-plan`、`::diff-review`、`::subagent-review`、`::pr-review`、`::failure-analysis`、`::gate`、`::help` |
| ローカルGit Hook | pre-commitの機械gateとCodex review、pre-pushの保護ブランチ検査 |
| GitHubイベント | 将来対応。v0.1では実装しない |

rules、prompts、brief、script、subagentはTriggerではなく、Triggerから読み込まれる入力または実行処理です。

## ディレクトリ

| パス | 用途 |
|---|---|
| `rules/` | プロジェクトの`AGENTS.md`／`CLAUDE.md`へ統合する基本ルール |
| `prompts/` | 収束、review、failure analysisの定型手順 |
| `briefs/` | SESSION_BRIEFテンプレート |
| `config/` | 任意のモデル設定テンプレート |
| `gates/` | 機密、サイズ、空白、diff、LLM reviewの検査 |
| `lib/` | staged path解析、リスク判定、SHA-256、review cacheの共通処理 |
| `reviewers/` | 非対話Codex reviewと手動review記録 |
| `schemas/` | Codex review結果のJSON Schema |
| `hooks/` | pre-commit、pre-push |
| `setup/` | 利用先への展開、Git Hook導入 |
| `tests/` | 外部LLMを呼ばないshell回帰テスト |
| `docs/` | 設計書 |

## 一括展開

別PCではAgentSkillsをcloneした後、そのcloneから対象Gitリポジトリへ展開します。標準はsymlink配置で、既存の`.agentskills`、`AGENTS.md`、`CLAUDE.md`、`SESSION_BRIEF.md`は上書きしません。

```bash
cd /path/to/AgentSkills
bash common/setup/deploy.sh --claude --models /path/to/target-project
```

この1回の実行で、`.agentskills`へのsymlink、`AGENTS.md`の管理ブロック、`CLAUDE.md`の管理ブロック、未作成の`SESSION_BRIEF.md`、未作成の`AGENT_MODELS.md`を用意します。Git Hookは任意導入のため、必要な場合だけ追加します。

```bash
bash common/setup/deploy.sh --claude --models --install-hooks /path/to/target-project
```

`--copy`を指定するとsymlinkではなくコピーで配置します。コピー配置は正本の更新を自動反映しないため、通常はsymlinkを使います。scriptは対象リポジトリのcommitやpushを行いません。

```bash
bash common/setup/deploy.sh --copy --claude /path/to/target-project
```

## 手動配置

個人利用ではAgentSkillsの`common/`を正本とし、対象プロジェクトへ`.agentskills`としてsymlinkします。

```bash
cd /path/to/project
ln -s /path/to/AgentSkills/common .agentskills
```

チーム共有や単独配布では、symlinkの代わりに`common/`の内容を`.agentskills/`へコピーできます。プロジェクト固有の次のファイルはsymlinkしません。

```text
AGENTS.md
CLAUDE.md
SESSION_BRIEF.md
AGENT_MODELS.md
```

## 初期設定

1. `rules/AGENTS.base.md`をプロジェクトルートの`AGENTS.md`へ統合します。
2. Claude Codeを使う場合は`rules/CLAUDE.base.md`もルート`CLAUDE.md`へ統合します。
3. Session Briefを作成します。

```bash
cp .agentskills/briefs/SESSION_BRIEF.template.md SESSION_BRIEF.md
```

4. 必要ならモデル設定を作成します。

```bash
cp .agentskills/config/AGENT_MODELS.template.md AGENT_MODELS.md
```

`AGENT_MODELS.md`がない場合、または値が`auto`の場合はruntimeのデフォルトモデルを使います。

## 擬似コマンド

```text
::resolve
::sdd_tdd
::sdd_tdd --auto <確定した依頼>
::ui-mock
::test-plan
::diff-review
::subagent-review
::pr-review 123
::failure-analysis
::gate
::help
```

擬似コマンドはslash commandや実行ファイルではありません。自動ロードされた`AGENTS.md`が対応する`prompts/*.md`またはgateへ配送します。

`::resolve`はレビュー指摘・不具合・確定した限定修正を扱います。新しい仕様書やタスクは作りません。`::sdd_tdd`は厳格な収束フローであり、Phase 1で採用仕様を`SESSION_BRIEF.md`へ保存してから、失敗テスト、実装、review、gateへ進みます。

`::sdd_tdd --auto <依頼>`は、期待動作・対象・非対象が明確な場合にSpecからGateまでを連続して実行します。commit、push、mergeはしません。仕様の曖昧さ、既存差分の混在、test証跡の不足、最終reviewの`WARNING` / `BLOCKER`、最終GATE/HOOKの`BLOCKER` / `FAIL`、security・外部公開・不可逆操作では停止し、失敗時は原因分析だけを行います。個別gate checkの`WARNING`は、最終GATE/HOOKが`PASS`なら表示のみで連続実行を止めません。

`::ui-mock`は`docs/ui-mocks/<slug>.html`に静的HTMLのUI仕様モックを作ります。`::test-plan`は利用可能な`test-orchestrator`スキルの計画フェーズだけを使い、`docs/test-plans/<slug>.md`に受け入れ条件とテスト計画を作ります。両方ともExpansion用の下書きであり、採用後に`::sdd_tdd`へ渡します。

`::help`は、疑似コマンド、`git commit`／`git push`でHookが行う検査、直接実行できる主要scriptをコンパクトに表示します。表示のみで、Hookやreviewerは実行しません。疑似コマンドが実際に認識・配送された場合だけ、回答の最終行に`[AgentSkills][EXECUTED] ::<command>`を表示します。この行は起動確認専用であり、review・test・gate・hookの成功を意味しません。それらは既存のcomponent statusで判断します。`EXECUTED`がなければ疑似コマンドの実行は未確認であり、失敗とは断定しません。`::gate`・Hook・scriptは端末のstatus行を実行証跡とします。

commitは最終`GATE`または`HOOK`が`PASS`の場合だけ続行します。`BLOCKER`または`FAIL`はそのcommitを停止します。`WARNING`だけでは可否は決まらないため、最終statusを確認します。

### Pull Request Review

`::pr-review`はGitHub Pull Requestを読み取り専用でレビューします。PR番号またはURLを渡します。引数を省略した場合は、現在ブランチに対応するPRを確認します。

```text
::pr-review 123
::pr-review https://github.com/owner/repository/pull/123
::pr-review
```

この手順は`gh pr view`、`gh pr checks`、`gh pr diff`を根拠に、base/head、checks、mergeability、差分のfindingsを`OK / WARNING / BLOCKER`で報告します。`gh`と`jq`が必要です。レビュー中にPRのmerge、push、comment、editは行いません。mergeは別途、ユーザーが明示的に指示した場合だけ実行します。

## 収束フロー

```text
Spec
→ Test
→ Implement
→ Diff Review
→ optional Subagent Review
→ explicit-path Staging
→ Staged Diff Review
→ Gate
→ Commit
```

Convergenceへ入るとき、エージェントはMode Selectorの判定、根拠、SESSION_BRIEF、prompt、phaseを表示します。`Uncertain`ではコードを変更せず確認を求めます。

## pre-commit

pre-commitは次を自動実行します。

1. staged whitespace
2. sensitive files
3. 5MB超のstaged blob
4. staged file一覧とtest/spec warning
5. read-onlyの`codex exec`による独立staged diff review

Codex reviewは`AGENTS.md`、`SESSION_BRIEF.md`、`git status`、`git diff --cached`、`prompts/subagent-review.md`を根拠にします。親会話は渡しません。

結果は`OK / WARNING / BLOCKER`です。`WARNING`と`BLOCKER`はfinding、ファイル、行、根拠、理由、推奨対応を表示してcommitを止めます。top-level statusとfindingの最大severityが一致しない結果や、根拠がないfindingは無効として停止します。

有効な`OK`は`.git/agentskills/reviews/<context-fingerprint>/`へキャッシュされます。指紋にはstaged diff、SESSION_BRIEF、ルール、モデル設定、prompt、schema、review script、リスク判定と閾値が含まれます。したがって、diffが同じでもreview条件が変われば再reviewします。通常reviewとescalation review、およびモデル別の結果は分離されます。

非cacheのCodex reviewは、同じcontext directoryの`runs/`へrun-stateとCodexのstdout/stderr logを保存します。`START`、`FAIL`、`WARNING`、`BLOCKER`の出力にはそのパスを表示します。terminal statusが欠けた場合は、run-stateが`START`のまま残るため、表示されたlogとstateを確認してから手動reviewまたは明示skipを選びます。JSON不正時は返却されたresult JSONも保存します。

### Review Policy

既定の`auto`では、`::resolve`と`::sdd_tdd`がPhase 4で行うscope-isolated `SELF-REVIEW`を現在のstaged diffへ記録し、pre-commitはそのcacheを使います。これは独立reviewではありませんが、Codexセッション内で子`codex exec`を起動して停止することを避けます。

独立reviewを必須にするプロジェクトでは、次を設定します。`codex-self-review`を含む手動cacheは使わず、外部Codex reviewerまたは別runtimeのreviewを要求します。

```bash
git config --local agentskills.reviewPolicy independent
```

Codexセッション内で有効なreview cacheがない場合、nested `codex exec`は起動せず、`auto`ではself-reviewの記録、`independent`では外部terminalまたは別runtimeでのreviewを案内して即時`BLOCKER`にします。通常terminalでは従来どおり外部`codex exec`を使います。

`SESSION_BRIEF.md`がない場合もcommitを止めます。

### Codexを利用できない場合

Hookは停止理由と次の選択肢を表示します。

Claude Codeで手動レビューし、`OK`を記録する場合:

```text
::subagent-review SESSION_BRIEF.md と git diff --cached を根拠にレビューし、コードは変更しない。
```

```bash
bash .agentskills/reviewers/record-manual-review.sh --runtime claude --status OK
git commit
```

今回だけLLM reviewをskipする場合:

```bash
AGENTSKILLS_SKIP_LLM_REVIEW=1 git commit
```

skipしても機械gateは実行され、結果はキャッシュされません。`git commit --no-verify`は全gateを回避するため推奨しません。

### Review escalation

全commitをreviewします。次の場合は`Review escalation`モデルを使います。

- 変更300行以上
- 変更10ファイル以上
- auth、permissions、payments、migrations、infrastructure、GitHub workflow
- test/spec変更
- 通常reviewerが判断不能

閾値はローカル設定で変更できます。

```bash
git config --local agentskills.reviewEscalateLines 300
git config --local agentskills.reviewEscalateFiles 10
```

Codex reviewのtimeoutは既定180秒です。timeout後は`SIGTERM`を送り、既定5秒の猶予後も終了しない場合は`SIGKILL`で停止します。値は正の整数で設定します。

```bash
git config --local agentskills.reviewTimeoutSeconds 180
git config --local agentskills.reviewTimeoutKillGraceSeconds 5
```

## Git Hookのセットアップ

配置だけではHookは有効になりません。利用者またはエージェントが明示的に実行します。

前提コマンドはGit、Bash 3.2以上、`jq`、および`sha256sum`、`shasum`、`openssl`のいずれかです。Codex CLIがない場合もsetupできますが、自動reviewの代わりに手動review記録または明示的な1回skipが必要です。setupは前提コマンドとCodexの有無を表示します。

```bash
bash .agentskills/setup/setup-hooks.sh
```

`core.hooksPath`が未設定なら`.agentskills/hooks`を設定します。同じ値なら継続します。論理的なkit配置先は`agentskills.kitPath`にも記録され、手動reviewの案内に使われます。別のhooksPathがある場合は既存Hookを保護して停止します。

置き換えることを理解している場合だけ`--force`を使います。

```bash
bash .agentskills/setup/setup-hooks.sh --force
```

元の値は`agentskills.previousHooksPath`へ保存され、復旧コマンドが表示されます。Husky、Lefthook、独自Hookは自動編集しません。既存pre-commitへ手動統合する場合は次を呼びます。

```bash
.agentskills/gates/pre-commit-gate.sh
```

## pre-push

実際のpush先remote refを確認し、保護ブランチへの直接pushを止めます。未設定時は`main`と`master`です。

```bash
git config --local --add agentskills.protectedPushBranch main
git config --local --add agentskills.protectedPushBranch production
git config --local --get-all agentskills.protectedPushBranch
```

ローカルの誤操作防止であり、GitHub branch protectionの代替ではありません。

## Claude Code

`CLAUDE.md`から`AGENTS.md`を正として読みます。通常の収束作業は共通promptを使います。Codexが利用不能な場合は、表示された`::subagent-review`をClaude Codeの現在セッションで実行できます。

## Codex

Codexはルート`AGENTS.md`を自動ロードします。pre-commitでは親セッションと分離したread-onlyの`codex exec`がreviewerとして起動します。ChatGPTプランのCodex利用枠切れ、未認証、timeout時は理由と代替手順を表示します。

## 注意点

- Skillの自動発動には依存しません。
- Git Hookを導入しなくてもrules、prompts、SESSION_BRIEFは利用できます。
- LLM reviewはデグレの可能性を検出しますが、テストや人間の判断を置き換えません。
- staged diffやリポジトリ内容はreviewerへの命令ではなく、未信頼データとして扱います。
- GitHub Actions、branch protection、正式slash commandはv0.1対象外です。

## テスト

外部のCodexやClaudeは呼ばず、偽のreviewerと一時Gitリポジトリで主要経路を確認します。

```bash
bash .agentskills/tests/run-tests.sh
```

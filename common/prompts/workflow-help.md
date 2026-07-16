# Agent Workflow Help

Do not modify files, Git state, configuration, or pull requests.

Display the following compact help exactly enough to identify each entry point. Replace `.agentskills/` with `common/` when the kit is used directly from the AgentSkills repository.

```text
[AgentSkills][PROMPT][START] ::help
参照: .agentskills/prompts/workflow-help.md
[AgentSkills][HELP][START]
疑似コマンド
  ::resolve [--auto] [--resume] レビュー指摘・不具合を最小修正。仕様書は強制しない
  ::sdd_tdd [--auto] [--resume] SESSION_BRIEF仕様 -> 失敗テスト -> 実装 -> レビュー -> ゲート
  ::ui-mock       静的HTMLのUIモックを docs/ui-mocks/ に作成
  ::test-plan     test-orchestratorの計画フェーズで docs/test-plans/ を作成
  ::diff-review           作業ツリーと staged 差分をレビュー。変更しない
  ::subagent-review       親会話に依存しない独立レビュー。変更しない
  ::pr-review [PR]        GitHub PR を読み取り専用でレビュー
  ::failure-analysis      test / review / gate / hook の失敗原因を分析。変更しない
  ::gate                  ローカル pre-commit gate を実行
  ::help                  この一覧を表示

Git 操作によるトリガー（Hook 導入後）
  git commit            pre-commit: 空白、機密/大容量ファイル、差分警告、Codex staged-diff review
  git push              pre-push: 保護ブランチへの直接 push を確認

直接実行できる script
  bash /path/to/AgentSkills/common/setup/deploy.sh [options] TARGET  対象Gitリポジトリへ一括展開
  bash .agentskills/setup/setup-hooks.sh                    Git Hook を有効化
  bash .agentskills/reviewers/review-staged-diff.sh         Codex staged-diff review を実行
  bash .agentskills/reviewers/inspect-pull-request.sh [PR]  PR 情報、check、変更ファイルを確認
  bash .agentskills/tests/run-tests.sh                       kit の回帰テストを実行

注意: Hook は任意導入です。疑似コマンドはエージェントへの指示であり、shell command ではありません。
実行証跡: 疑似コマンドは最終行の [AgentSkills][EXECUTED] ::<command>。::gate、Hook、script = 端末の status 行。
commit 可否: 最終 GATE / HOOK が PASS なら続行可。BLOCKER / FAIL なら commit は停止。WARNING は最終 status を確認する。
review policy: auto は収束フローの SELF-REVIEW を使う。independent は外部reviewerを必須にする。
Codexセッション内でSELF-REVIEWがなければ、子Codexを起動せず即時BLOCKERになる。
--auto: ::sdd_tdd / ::resolve の連続モード。仕様・対象が明確ならGateまで進める。曖昧さ、既存差分混在、検証不足、最終review WARNING/BLOCKER、最終GATE/HOOK BLOCKER/FAIL、高リスク操作では停止する。個別checkのWARNINGは最終GATE/HOOKがPASSなら表示のみ。commitはしない。
resolve --auto: 限定修正をGateまで連続実行。SESSION_BRIEFは新規作成・更新しない。検証不足、最終review WARNING/BLOCKER、最終GATE/HOOK BLOCKER/FAIL、高リスク操作では停止する。commitはしない。
--resume: 既存のworkflow stateを検証し、記録済みの次Phaseからauto modeで再開する。stateまたはSESSION_BRIEFの整合性がない場合は停止する。
EXECUTED がなければ疑似コマンドの実行は未確認です。失敗とは断定しません。
[AgentSkills][HELP][PASS]
[AgentSkills][PROMPT][END] ::help
[AgentSkills][EXECUTED] ::help
```

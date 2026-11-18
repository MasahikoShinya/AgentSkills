# SDD + TDDからPublish Loopまで

読了後に `[AgentSkills][PROMPT][START] ::sdd_publish` と `Source: .agentskills/prompts/sdd_publish.md` を表示する。

形式: `::sdd_publish <request>`。依頼本文は必須。`--step` 等のオプションは受け付けず `PROMPT BLOCKER` とする。

この起動は連続モードの `::sdd_tdd <request>` と、正常完了後の `::publish --loop` の許可を含む。仕様記録、対象内のtest・実装・review・明示pathのstage・Gate、commit、push、draft PR作成、同じPRへの完了までの修正・再公開・再reviewを許可する。phase境界やpublish開始時に会話上の再確認や追加の実行文言を要求しない。OS・sandboxの承認は引き続き守る。

1. `Convergence` を選択する。`.agentskills/prompts/sdd_tdd.md` を読み、依頼本文を変更せず通常の連続モードを実行する。plan採用、継続略記、request照合、未完了stateからの再開、仕様・安全性・対象混在の停止条件は元の手順に従う。SDD段階ではcommit・pushしない。
2. SDD全phaseの完了、必要な検証・reviewの成功、最終Gateの `PASS`、workflow stateの `complete` を確認する。`PROMPT END` だけを成功証拠にしない。中断、`BLOCKER`、`SKIP`、未完了stateではpublishへ進まず、`[AgentSkills][PROMPT][BLOCKER] ::sdd_publish` と理由を報告する。
3. `.agentskills/prompts/publish.md` を読み、`::publish --loop` の全手順を実行する。このコマンドの起動をpublishの明示許可として扱う。scope・証拠確認、公開内容の事前表示、既存PR再利用、PR記録、完了までの修正サイクル、停止条件を省略しない。merge、draft解除、PRコメント、同一ブランチの2本目のPR作成は行わない。
4. PR review `OK` でloopが完了した場合だけ、`[AgentSkills][PROMPT][END] ::sdd_publish` と検証・review・Gate結果、commit SHA、PR URL、修正回数を報告する。未完了なら `PROMPT BLOCKER` と最後に完了した段階・理由・次の行動を報告する。

このリポジトリ内では `.agentskills/` の代わりに `common/` を参照する。独自stateは作らず、SDDのstateとpublishのPR記録を使用する。SDD完了後にpublishだけが中断した場合は `::publish --loop` での再開を案内する。`::sdd_publish` の再起動はSDD自身の新規開始・再開ルールに従い、完了済みSDDを無条件に省略しない。`::resume` はSDDだけを再開し、publishの許可を自動継承しない。

最終応答の最終行は `[AgentSkills][EXECUTED] ::sdd_publish`。これはdispatchの証拠であり、成功判定は各componentのstatusによる。

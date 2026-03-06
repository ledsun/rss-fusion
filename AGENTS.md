# AIエージェント向け指示（AGENTS.md）

## コード変更タスク完了前の確認

コード変更タスクを完了する前に、必ず以下を実行すること。

1. `bundle exec rubocop` を実行する
2. `bundle exec ruby -Itest test/all.rb` を実行する

## RuboCop対応

* `rubocop` が違反（offense）を報告した場合は修正すること。
* `bundle exec rubocop` が成功するまで、修正と再実行を繰り返すこと。

## テスト対応

* テストが失敗した場合は修正すること。
* `bundle exec ruby -Itest test/all.rb` がすべて成功するまで、修正と再実行を繰り返すこと。

## 回答言語

* 回答は日本語で行うこと。

## コーディング規約

* 名前付き引数よりも順序引数を優先して使用すること。
* private メソッドのテストは書かないこと。

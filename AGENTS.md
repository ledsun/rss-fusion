# AI Agent Instructions

- Before concluding any code change task, run `bundle exec rubocop` and confirm it passes.
- Before concluding any code change task, run `bundle exec ruby -Itest test/all.rb` and confirm all tests pass.
- If `rubocop` reports offenses, fix them and rerun `bundle exec rubocop` until it passes.
- If tests fail, fix the failures and rerun `bundle exec ruby -Itest test/all.rb` until all tests pass.

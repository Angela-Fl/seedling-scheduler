# Run using bin/ci
#
# Mirrors .github/workflows/ci.yml, so a green run here should mean a green run
# there. Keep the two in step when either changes -- the drift is what lets a
# clean local run push a red build.

CI.run do
  step "Setup", "bin/setup --skip-server"
  # bin/setup only handles bundler and the database; the workflow installs the
  # JavaScript dependencies separately, and the audit and asset build below both
  # need them present.
  step "Setup: JavaScript", "npm ci"

  step "Style: Ruby", "bin/rubocop"

  step "Security: Gem audit", "bin/bundler-audit"
  step "Security: JavaScript audit", "npm audit --audit-level=high"
  step "Security: Brakeman code analysis", "bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error"

  # The workflow rebuilds assets ahead of both test jobs. Without this the suite
  # runs against whatever happens to be sitting in public/vite-test, so a stale
  # bundle can hide a frontend change or fail on one already fixed.
  step "Assets: Build for test", "bin/vite build --mode=test"

  step "Tests: Rails", "bin/rails db:test:prepare test"
  step "Tests: System", "bin/rails db:test:prepare test:system"
  # Local-only: the workflow has no equivalent, but it is cheap and catches seed
  # data that no longer loads against the current schema.
  step "Tests: Seeds", "env RAILS_ENV=test bin/rails db:seed:replant"

  # Optional: set a green GitHub commit status to unblock PR merge.
  # Requires the `gh` CLI and `gh extension install basecamp/gh-signoff`.
  # if success?
  #   step "Signoff: All systems go. Ready for merge and deploy.", "gh signoff"
  # else
  #   failure "Signoff: CI failed. Do not merge or deploy.", "Fix the issues and try again."
  # end
end

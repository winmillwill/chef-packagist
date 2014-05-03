#!/usr/bin/env bats

@test "site is up" {
  run "curl http://packagist.dev | grep 'Fatal error'"
  [ $status -ne 0 ]
}

@test "search is working" {
  curl http://packagist.dev/search/\?q=d -X GET -I 2>/dev/null | head -n1 | grep 200
}

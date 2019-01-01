workflow "New workflow" {
  on = "push"
  resolves = ["piranna/jekyll-social"]
}

action "piranna/jekyll-social" {
  uses = "piranna/jekyll-social"
  secrets = ["GITHUB_TOKEN", "social"]
  env = {
    user = "piranna"
    repo = "piranna.github.io"
  }
}

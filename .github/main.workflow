workflow "New workflow" {
  on = "push"
  resolves = ["piranna/jekyll-social"]
}

action "piranna/jekyll-social" {
  uses = "piranna/jekyll-social@master"
  secrets = ["GITHUB_TOKEN", "social"]
}

---
categories:
  - AI
lang: en
layout: note
tags:
  - watermark
---

What ChatGPT shows:

```sh
git add caree​​ros scripts reports tests
git commit -m "Complete ChatGPT export inspection"
```

What actually gets copied in the clipboard and executed in the terminal:

```console
piranna@Rawr CareerOS % git add caree<200b><200b>ros scripts reports tests
git commit -m "Complete ChatGPT export inspection"
```

[U+200B](https://unicode-explorer.com/c/200B), `ZERO WIDTH SPACE`... something
looks phishy. Is ChatGPT also adding watermarks to its generated output?

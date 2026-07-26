# VR Avatar Viewer 公式サイト

VR Avatar Viewer の紹介、開発日記、更新情報を公開する GitHub Pages 用リポジトリです。

## 公開構成

- `docs/index.html` — トップページ
- `docs/devlog/` — 開発日記
- `docs/assets/` — 画像・スタイル
- `.github/workflows/pages.yml` — GitHub Pages 配信ワークフロー

## 開発日記

毎日の開発日記は [`DEVLOG_WORKFLOW.md`](DEVLOG_WORKFLOW.md) を正本として作成します。
公開前は `Tools\Validate-Devlog.bat -Date YYYY-MM-DD` で記事・画像・一覧・トップページ・Git差分を検証します。

## 公開方法

`main` ブランチへ push すると、GitHub Actions が `docs/` を GitHub Pages へ配信します。

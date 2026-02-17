# 💪 FitApp - 筋トレ管理PWAアプリ

Nuxt 3とSupabaseを使用した筋トレ記録・管理アプリケーション

## ✨ 機能

- 🔐 **ユーザー認証** - Supabase Authによる安全なログイン/登録
- 📝 **ワークアウト記録** - 種目、重量、セット数、回数、メモの記録
- 📊 **統計ダッシュボード** - 総記録数、種目数、総負荷量の表示
- 📱 **PWA対応** - モバイルデバイスにインストール可能
- 🎨 **モダンUI** - レスポンシブでユーザーフレンドリーなデザイン

## 🚀 クイックスタート

### 前提条件

- Node.js 18以上
- Supabaseアカウント

### インストール

```bash
# 依存関係のインストール
npm install

# 環境変数の設定
# .envファイルに以下を追加:
SUPABASE_URL=あなたのSupabaseプロジェクトURL
SUPABASE_KEY=あなたのSupabase Anon Key

# 開発サーバーの起動
npm run dev
```

アプリケーションは http://localhost:3000 で起動します。

### Supabaseセットアップ

1. Supabaseプロジェクトを作成
2. SQL Editorで `docs/fitapp_setup/schema.sql` の内容を実行
3. URLとAnon Keyを `.env` に設定

## 📁 プロジェクト構成

```
fitapp/
├── pages/              # ページコンポーネント
├── layouts/            # レイアウトコンポーネント  
├── middleware/         # 認証ミドルウェア
├── types/              # TypeScript型定義
├── public/             # 静的ファイル
├── docs/               # ドキュメント
└── nuxt.config.ts      # Nuxt設定
```

## 🛠️ 技術スタック

- **フレームワーク**: Nuxt 3
- **言語**: TypeScript
- **バックエンド**: Supabase
- **PWA**: @vite-pwa/nuxt
- **認証**: @nuxtjs/supabase

## 📖 詳細ドキュメント

- [実装計画](docs/fitapp_setup/implementation_plan.md)
- [データベーススキーマ](docs/fitapp_setup/schema.sql)
- [Walkthrough](../../.gemini/antigravity/brain/9ff89487-6b6c-44ec-911c-79558bdea453/walkthrough.md)

## 🎯 主要機能

### 認証
- メールアドレスとパスワードでログイン・登録
- 保護されたルート（認証必須）
- ログアウト機能

### ワークアウト管理
- 新規記録の作成
- 記録一覧の表示
- 記録の削除
- 統計情報の表示

### PWA
- オフライン対応
- ホーム画面への追加
- アプリライクな体験

## 🚀 デプロイ

### ビルド

```bash
npm run build
```

### プレビュー

```bash
npm run preview
```

### デプロイ先の例

- Vercel
- Netlify
- Cloudflare Pages

## 📝 ライセンス

MIT

## 🤝 貢献

プルリクエストを歓迎します。大きな変更の場合は、まずissueを開いて変更内容を議論してください。

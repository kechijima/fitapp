# デザイン刷新とログインリダイレクト実装計画

ログイン後のユーザー体験向上（自動リダイレクト）と、アプリ全体をオレンジ・ブラックを基調としたマテリアルデザインへ刷新します。

## ユーザー確認事項
- [ ] ログイン後の遷移先を `/workouts` とすることの承認
- [ ] オレンジと黒をメインカラー、マテリアルデザインの方向性の確認

## 変更内容

### [Core]
#### [MODIFY] [nuxt.config.ts](file:///c:/Users/allja/Desktop/Workspace/fitapp/nuxt.config.ts)
- MDI (Material Design Icons) フォントの CDN リンクを `head` に追加します。

### [Style]
#### [MODIFY] [layouts/default.vue](file:///c:/Users/allja/Desktop/Workspace/fitapp/layouts/default.vue)
- CSS変数を更新し、背景色をホワイト (#FFFFFF)、テキストをダークグレー (#1E1E1E) に変更します。
- オレンジ (#FF9800) とブラック (#000000) をアクセントおよびメインカラーとして維持します。

### [UI Adjustment]
#### [MODIFY] [index.vue](file:///c:/Users/allja/Desktop/Workspace/fitapp/pages/index.vue)
#### [MODIFY] [login.vue](file:///c:/Users/allja/Desktop/Workspace/fitapp/pages/login.vue)
#### [MODIFY] [signup.vue](file:///c:/Users/allja/Desktop/Workspace/fitapp/pages/signup.vue)
#### [MODIFY] [workouts/index.vue](file:///c:/Users/allja/Desktop/Workspace/fitapp/pages/workouts/index.vue)
- 各カードの背景、ボーダー、テキストカラーをライトテーマに合わせて調整します。
- ワークアウト一覧の `workouts/index.vue` で発生しているタグの不整合も合わせて修正します。

## 検証計画

### 自動テスト
- なし

### 手動検証
- ログイン後に `/workouts` へ自動遷移することを確認。
- 未ログイン時に LP からログイン/新規登録へ遷移できることを確認。
- 各画面がオレンジと黒を基調としたデザインになっていることを確認。
- MDI アイコンが正しく表示されていることを確認。

# ワークアウト履歴の初期表示変更（当日分のみ表示）

ワークアウト履歴の一覧が膨大になるのを防ぐため、初期ロード時に「当日の履歴」のみを表示するように変更します。また、カレンダー上でどの日付が選択されているかを視覚的に分かりやすく改善します。

## Proposed Changes

### [Component Name] Workouts Page / Calendar Component

---

#### [MODIFY] [index.vue](file:///c:/Users/allja/Desktop/Workspace/fitapp/pages/workouts/index.vue)

- `selectedDate` の初期値を `new Date()` に基づく今日の日付（YYYY-MM-DD）に設定します。
- `WorkoutCalendar` コンポーネントに `selectedDate` プロップを渡し、現在選択されている日付を共有します。

#### [MODIFY] [WorkoutCalendar.vue](file:///c:/Users/allja/Desktop/Workspace/fitapp/components/WorkoutCalendar.vue)

- `selected-date` (string) プロップを追加します。
- 選択された日付に `.selected` クラスを適用し、CSSで強調表示（枠線や色の変更）を行います。

## Verification Plan

### Manual Verification
- `yarn dev` でアプリケーションを起動し、`/workouts` にアクセスする。
- **初期表示の確認**:
    - タイトルが「2026/2/22」（当日の日付）になっていること。
    - リストに当日のワークアウトのみが表示されていること（記録がない場合は「該当する記録がありません」と表示されること）。
    - カレンダー上の今日の日付がハイライト（選択状態）になっていること。
- **フィルタ操作の確認**:
    - カレンダーの他の日付（ワークアウトがある日）をクリックし、表示が切り替わること。
    - 「すべて表示」ボタンをクリックして、全履歴が表示されること。
- **新規追加との連動**:
    - 「記録する」ボタンを押した際、選択中の日付がクエリパラメータ（`?date=...`）として引き継がれること。

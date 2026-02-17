<script setup lang="ts">
const client = useSupabaseClient()
const router = useRouter()
const route = useRoute()

// クエリパラメータから日付を取得（連動用）
const targetDate = ref(route.query.date as string || null)

// 種目マスタの取得
const { data: exercises } = await useAsyncData('exercises', async () => {
  const { data } = await client.from('exercises').select('*').order('name')
  return data || []
})

const exerciseName = ref('')
const sets = ref([{ weight: null, reps: null }])
const note = ref('')
const submitting = ref(false)
const showSuccessOverlay = ref(false)

// タイマー設定用のデフォルト値
const defaultRestTime = ref(60)
const defaultWorkTime = ref(0)
const currentSetIndex = ref(0)

const resetFormForNext = () => {
  exerciseName.value = ''
  sets.value = [{ weight: null, reps: null }]
  note.value = ''
  currentSetIndex.value = 0
  showSuccessOverlay.value = false
}

// 種目選択時のデフォルト値反映
const onExerciseChange = () => {
  const ex = exercises.value?.find(e => e.name === exerciseName.value)
  if (ex) {
    if (ex.default_rest_time) defaultRestTime.value = ex.default_rest_time
    if (ex.default_work_time !== undefined) defaultWorkTime.value = ex.default_work_time
    
    // セット情報が未入力の場合のみ、デフォルトを流し込む
    const isEmpty = sets.value.length === 1 && sets.value[0].weight === null && sets.value[0].reps === null
    if (isEmpty && ex.default_sets) {
      sets.value = Array.from({ length: ex.default_sets }, () => ({
        weight: ex.default_weight || null,
        reps: ex.default_reps || null
      }))
    }
  }
}

const addSet = () => {
  const lastSet = sets.value[sets.value.length - 1]
  sets.value.push({ weight: lastSet.weight, reps: lastSet.reps })
}

const copyLastSet = (index: number) => {
  if (index > 0) {
    sets.value[index].weight = sets.value[index - 1].weight
    sets.value[index].reps = sets.value[index - 1].reps
  }
}

const removeSet = (index: number) => {
  if (sets.value.length > 1) {
    sets.value.splice(index, 1)
  }
}

const submitWorkout = async () => {
  const { data: { user: currentUser } } = await client.auth.getUser()
  if (!currentUser) {
    alert('ログインセッションが切れている可能性があります。再度ログインしてください。')
    return
  }
  
  if (!exerciseName.value) {
    alert('種目を選択してください')
    return
  }
  
  submitting.value = true
  
  try {
    const { data: workout, error: wError } = await client
      .from('workouts')
      .insert({
        user_id: currentUser.id,
        exercise_name: exerciseName.value,
        note: note.value || null,
        weight: sets.value[0].weight,
        reps: sets.value[0].reps,
        sets: sets.value.length,
        date: targetDate.value || undefined // 指定があればその日で保存
      })
      .select()
      .single()

    if (wError) throw new Error('保存に失敗しました: ' + wError.message)

    const setRecords = sets.value.map((s, i) => ({
      workout_id: workout.id,
      set_number: i + 1,
      weight: s.weight,
      reps: s.reps
    }))

    const { error: sError } = await client.from('workout_sets').insert(setRecords)
    if (sError) throw new Error('セット情報の保存に失敗しました: ' + sError.message)

    showSuccessOverlay.value = true
  } catch (error: any) {
    alert(error.message)
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <div class="add-container">
    <div class="header">
      <h1>📝 ワークアウト記録</h1>
      <p class="subtitle">
        {{ targetDate ? targetDate + ' の記録' : '今日のトレーニングを詳細に記録しましょう' }}
      </p>
    </div>

    <div class="main-layout">
      <div class="form-section">
        <div class="form-card">
          <!-- 種目選択 -->
          <div class="form-group">
            <label for="exercise">種目を選択 *</label>
            <div class="select-wrapper">
              <select 
                id="exercise"
                v-model="exerciseName" 
                required
                class="select-input"
                @change="onExerciseChange"
              >
                <option value="" disabled>種目を選択してください</option>
                <option v-for="ex in exercises" :key="(ex as any).id" :value="(ex as any).name">
                  {{ (ex as any).name }}
                </option>
              </select>
            </div>
          </div>
          
          <div class="sets-header">
            <span class="label-set">SET</span>
            <span class="label-weight">WEIGHT (kg)</span>
            <span class="label-reps">REPS</span>
            <span class="label-action"></span>
          </div>

          <div class="sets-list">
            <div 
              v-for="(set, index) in sets" 
              :key="index" 
              class="set-row"
              :class="{ 'current-focus': currentSetIndex === index }"
              @click="currentSetIndex = index"
            >
              <div class="set-number">{{ index + 1 }}</div>
              <div class="set-input">
                <input type="number" step="0.5" min="0" v-model="set.weight" placeholder="0.0" />
              </div>
              <div class="set-input">
                <input type="number" min="0" v-model="set.reps" placeholder="0" />
              </div>
              <div class="set-actions">
                <button v-if="index > 0" type="button" @click.stop="copyLastSet(index)" class="btn-icon" title="前セットをコピー">📋</button>
                <button v-if="sets.length > 1" type="button" @click.stop="removeSet(index)" class="btn-icon btn-delete" title="削除">×</button>
              </div>
            </div>
          </div>

          <button type="button" @click="addSet" class="btn btn-add-set">
            ＋ セットを追加
          </button>

          <!-- メモ欄のデザイン修正 -->
          <div class="form-group note-area">
            <label for="note" class="note-label">
              <span class="icon">✍️</span> メモ
            </label>
            <div class="textarea-wrapper">
              <textarea 
                id="note" 
                v-model="note" 
                rows="3" 
                placeholder="気づいたこと、フォームの感覚など..."
              ></textarea>
            </div>
          </div>

          <div class="actions">
            <button @click="submitWorkout" class="btn btn-submit" :disabled="submitting">
              {{ submitting ? '保存中...' : '📊 記録を完了する' }}
            </button>
            <NuxtLink to="/workouts" class="btn btn-cancel">キャンセル</NuxtLink>
          </div>
        </div>
      </div>

      <div class="timer-section">
        <WorkoutTimer 
          :default-rest-time="defaultRestTime" 
          :default-work-time="defaultWorkTime"
          :current-set="currentSetIndex + 1"
          :total-sets="sets.length"
        />
      </div>
    </div>

    <!-- 保存完了後のアクション選択オーバーレイ -->
    <Transition name="fade">
      <div v-if="showSuccessOverlay" class="success-overlay">
        <div class="success-modal">
          <div class="success-icon">✅</div>
          <h2>記録完了！</h2>
          <p>お疲れ様でした。次のアクションを選択してください。</p>
          <div class="modal-actions">
            <button @click="resetFormForNext" class="btn btn-primary">別の種目を続けて登録</button>
            <button @click="router.push('/workouts')" class="btn btn-outline">履歴一覧へ戻る</button>
          </div>
        </div>
      </div>
    </Transition>
  </div>
</template>

<style scoped>
.add-container {
  max-width: 1100px;
  margin: 0 auto;
  padding: 1rem;
}
.header { margin-bottom: 2rem; }
.header h1 { font-size: 1.75rem; color: #0f172a; font-weight: 800; letter-spacing: -0.025em; }
.subtitle { color: #64748b; font-weight: 500; }

.main-layout {
  display: grid;
  grid-template-columns: 1fr 340px;
  gap: 2.5rem;
}

@media (max-width: 950px) {
  .main-layout { grid-template-columns: 1fr; }
  .timer-section { order: -1; margin-bottom: 2rem; }
}

.form-card {
  background: white;
  border-radius: 20px;
  padding: 2rem;
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
  border: 1px solid #f1f5f9;
}

.select-wrapper {
  position: relative;
}
.select-input {
  width: 100%;
  padding: 0.875rem 1rem;
  border: 2px solid #e2e8f0;
  border-radius: 12px;
  font-size: 1rem;
  font-weight: 600;
  background-color: #f8fafc;
  cursor: pointer;
  appearance: none;
  transition: all 0.2s;
}
.select-input:focus {
  border-color: #00dc82;
  background-color: white;
  outline: none;
  box-shadow: 0 0 0 4px rgba(0, 220, 130, 0.1);
}

.form-group { margin-bottom: 2rem; }
label { display: block; margin-bottom: 0.75rem; font-weight: 800; color: #1e293b; font-size: 0.875rem; letter-spacing: 0.025em; }

.sets-header {
  display: grid;
  grid-template-columns: 40px 1fr 1fr 80px;
  gap: 0.5rem;
  padding: 0 0.75rem;
  font-size: 0.65rem;
  font-weight: 900;
  color: #94a3b8;
  margin-bottom: 0.5rem;
  letter-spacing: 0.05em;
}

.sets-list { margin-bottom: 1.5rem; }
.set-row {
  display: grid;
  grid-template-columns: 40px 1fr 1fr 80px;
  gap: 0.5rem;
  align-items: center;
  margin-bottom: 0.5rem;
  background: #f8fafc;
  padding: 0.5rem 0.75rem;
  border-radius: 12px;
  border: 2px solid transparent;
  cursor: pointer;
  transition: all 0.2s;
}
.set-row:hover { background: #f1f5f9; }
.set-row.current-focus {
  border-color: #00dc82;
  background: white;
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);
}

.set-number { font-weight: 900; color: #94a3b8; text-align: center; font-size: 1rem; }
input { 
  width: 100%; 
  padding: 0.625rem 0.25rem; 
  border: 2px solid #e2e8f0; 
  border-radius: 8px; 
  font-size: 0.9375rem; 
  font-weight: 700;
  text-align: center;
  transition: all 0.2s;
  min-width: 0; /* 防止溢出 */
}
input:focus { border-color: #00dc82; outline: none; background: #f0fff4; }

.set-actions { display: flex; gap: 0.5rem; }
.btn-icon {
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  width: 36px;
  height: 36px;
  cursor: pointer;
  transition: all 0.2s;
}
.btn-icon:hover { border-color: #00dc82; transform: translateY(-2px); }
.btn-delete:hover { border-color: #ef4444; color: #ef4444; }

.btn-add-set {
  width: 100%;
  padding: 1rem;
  background: #f8fafc;
  border: 2px dashed #cbd5e1;
  border-radius: 14px;
  color: #64748b;
  font-weight: 800;
  margin-bottom: 2.5rem;
  cursor: pointer;
  transition: all 0.2s;
}
.btn-add-set:hover { background: white; border-color: #00dc82; color: #00dc82; }

/* メモ欄のプレミアムデザイン */
.note-area {
  background: #f8fafc;
  padding: 1.25rem;
  border-radius: 16px;
  border: 1px solid #e2e8f0;
}
.note-label {
  display: flex !important;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: 1rem !important;
  color: #475569 !important;
}
.textarea-wrapper textarea {
  width: 100%;
  padding: 1rem;
  border: 2px solid #e2e8f0;
  border-radius: 12px;
  font-size: 0.9375rem;
  font-weight: 500;
  resize: vertical;
  min-height: 100px;
  transition: all 0.2s;
  background: white;
}
.textarea-wrapper textarea:focus {
  border-color: #00dc82;
  outline: none;
  box-shadow: 0 4px 12px rgba(0, 220, 130, 0.1);
}

.actions { display: flex; gap: 1rem; margin-top: 2.5rem; }
.btn { flex: 1; padding: 1.125rem; border-radius: 14px; font-weight: 800; cursor: pointer; text-align: center; text-decoration: none; font-size: 1rem; border: none; transition: all 0.2s; }
.btn-submit { background: #00dc82; color: #064e3b; box-shadow: 0 4px 6px -1px rgba(0, 220, 130, 0.2); }
.btn-submit:hover { transform: translateY(-2px); box-shadow: 0 10px 15px -3px rgba(0, 220, 130, 0.3); }
.btn-cancel { background: #f1f5f9; color: #475569; }
.btn:active { transform: scale(0.98); }

/* 保存成功オーバーレイ */
.success-overlay {
  position: fixed;
  inset: 0;
  background: rgba(15, 23, 42, 0.8);
  backdrop-filter: blur(8px);
  z-index: 1000;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 1.5rem;
}
.success-modal {
  background: white;
  border-radius: 24px;
  padding: 2.5rem;
  max-width: 440px;
  width: 100%;
  text-align: center;
  box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5);
  animation: modalIn 0.4s cubic-bezier(0.34, 1.56, 0.64, 1);
}
@keyframes modalIn {
  from { opacity: 0; transform: scale(0.9) translateY(20px); }
  to { opacity: 1; transform: scale(1) translateY(0); }
}
.success-icon { font-size: 4rem; margin-bottom: 1.5rem; }
.success-modal h2 { font-size: 1.75rem; font-weight: 800; color: #0f172a; margin-bottom: 0.75rem; }
.success-modal p { color: #64748b; margin-bottom: 2rem; font-weight: 500; }
.modal-actions { display: flex; flex-direction: column; gap: 0.75rem; }
.btn-outline { background: white; border: 2px solid #e2e8f0; color: #64748b; }
.btn-outline:hover { background: #f8fafc; border-color: #cbd5e1; }

.fade-enter-active, .fade-leave-active { transition: opacity 0.3s ease; }
.fade-enter-from, .fade-leave-to { opacity: 0; }
</style>


<script setup lang="ts">
const route = useRoute()
const router = useRouter()
const client = useSupabaseClient()
const workoutId = route.params.id as string

// マスタと既存データの取得
const { data: exercises } = await useAsyncData('exercises', async () => {
  const { data } = await client.from('exercises').select('*').order('name')
  return data || []
})

const exerciseName = ref('')
const sets = ref([{ weight: null, reps: null }])
const note = ref('')
const submitting = ref(false)

// タイマー設定用のデフォルト値
const defaultRestTime = ref(60)
const defaultWorkTime = ref(0)
const currentSetIndex = ref(0)

// 既存データの読み込み
onMounted(async () => {
  const { data: workout, error: wError } = await client
    .from('workouts')
    .select('*, workout_sets(*)')
    .eq('id', workoutId)
    .single()

  if (workout) {
    exerciseName.value = workout.exercise_name
    note.value = workout.note || ''
    if (workout.workout_sets && workout.workout_sets.length > 0) {
      sets.value = workout.workout_sets
        .sort((a: any, b: any) => a.set_number - b.set_number)
        .map((s: any) => ({ weight: s.weight, reps: s.reps }))
    }
    
    // 種目マスタから設定を同期
    onExerciseChange()
  } else if (wError) {
    alert('データの読み込みに失敗しました: ' + wError.message)
    router.push('/workouts')
  }
})

const onExerciseChange = () => {
  const ex = exercises.value?.find(e => e.name === exerciseName.value)
  if (ex) {
    if (ex.default_rest_time) defaultRestTime.value = ex.default_rest_time
    if (ex.default_work_time !== undefined) defaultWorkTime.value = ex.default_work_time
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
  if (sets.value.length > 1) sets.value.splice(index, 1)
}

const updateWorkout = async () => {
  const { data: { user: currentUser } } = await client.auth.getUser()
  if (!currentUser) return
  
  submitting.value = true
  try {
    // 1. workoutsの更新
    const { error: wError } = await client
      .from('workouts')
      .update({
        exercise_name: exerciseName.value,
        note: note.value || null,
        weight: sets.value[0].weight,
        reps: sets.value[0].reps,
        sets: sets.value.length
      })
      .eq('id', workoutId)

    if (wError) throw wError

    // 2. workout_setsの更新 (一度削除して再作成)
    await client.from('workout_sets').delete().eq('workout_id', workoutId)
    
    const setRecords = sets.value.map((s, i) => ({
      workout_id: workoutId,
      set_number: i + 1,
      weight: s.weight,
      reps: s.reps
    }))

    const { error: sError } = await client.from('workout_sets').insert(setRecords)
    if (sError) throw sError

    router.push('/workouts')
  } catch (error: any) {
    alert('更新に失敗しました: ' + error.message)
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <div class="add-container">
    <div class="header">
      <h1>✏️ 記録を編集</h1>
      <p class="subtitle">トレーニング内容を修正します</p>
    </div>

    <div class="main-layout">
      <div class="form-section">
        <div class="form-card">
          <div class="form-group">
            <label for="exercise">種目を選択 *</label>
            <div class="select-wrapper">
              <select id="exercise" v-model="exerciseName" required class="select-input" @change="onExerciseChange">
                <option v-for="ex in exercises" :key="(ex as any).id" :value="(ex as any).name">{{ (ex as any).name }}</option>
              </select>
            </div>
          </div>
          
          <div class="sets-header">
            <span>SET</span><span>WEIGHT (kg)</span><span>REPS</span><span></span>
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
              <input type="number" step="0.5" min="0" v-model="set.weight" />
              <input type="number" min="0" v-model="set.reps" />
              <div class="set-actions">
                <button type="button" @click.stop="copyLastSet(index)" class="btn-icon">📋</button>
                <button v-if="sets.length > 1" type="button" @click.stop="removeSet(index)" class="btn-icon btn-delete">×</button>
              </div>
            </div>
          </div>

          <button type="button" @click="addSet" class="btn btn-add-set">＋ セットを追加</button>

          <div class="form-group note-area">
            <label for="note" class="note-label">✍️ メモ</label>
            <div class="textarea-wrapper">
              <textarea id="note" v-model="note" rows="3"></textarea>
            </div>
          </div>

          <div class="actions">
            <button @click="updateWorkout" class="btn btn-submit" :disabled="submitting">更新を保存</button>
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
  </div>
</template>

<style scoped>
.add-container { max-width: 1100px; margin: 0 auto; padding: 1rem; }
.header { margin-bottom: 2rem; }
.header h1 { font-size: 1.75rem; color: #0f172a; font-weight: 800; }
.main-layout { display: grid; grid-template-columns: 1fr 340px; gap: 2.5rem; }
@media (max-width: 950px) { .main-layout { grid-template-columns: 1fr; } .timer-section { order: -1; margin-bottom: 2rem; } }
.form-card { background: white; border-radius: 20px; padding: 2rem; box-shadow: 0 10px 15px -3px rgba(0,0,0,0.05); border: 1px solid #f1f5f9; }
.select-input { width: 100%; padding: 0.875rem; border: 2px solid #e2e8f0; border-radius: 12px; font-weight: 600; background: #f8fafc; appearance: none; }
.sets-header { 
  display: grid; 
  grid-template-columns: 40px 1fr 1fr 80px; 
  gap: 0.5rem; 
  padding: 0 0.75rem; 
  font-size: 0.65rem; 
  font-weight: 900; 
  color: #94a3b8; 
  margin-bottom: 0.5rem; 
}
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
}
.set-row.current-focus { border-color: #00dc82; background: white; }
.set-number { font-weight: 900; color: #94a3b8; text-align: center; font-size: 1rem; }
input { 
  width: 100%; 
  padding: 0.625rem 0.25rem; 
  border: 2px solid #e2e8f0; 
  border-radius: 8px; 
  font-weight: 700; 
  text-align: center; 
  min-width: 0; 
}
.set-actions { display: flex; gap: 0.5rem; }
.btn-icon { background: white; border: 1px solid #e2e8f0; border-radius: 8px; width: 36px; height: 36px; cursor: pointer; }
.btn-delete { color: #ef4444; }
.btn-add-set { width: 100%; padding: 1rem; background: #f8fafc; border: 2px dashed #cbd5e1; border-radius: 14px; color: #64748b; font-weight: 800; margin-bottom: 2.5rem; }
.note-area { background: #f8fafc; padding: 1.25rem; border-radius: 16px; border: 1px solid #e2e8f0; }
.textarea-wrapper textarea { width: 100%; padding: 1rem; border: 2px solid #e2e8f0; border-radius: 12px; min-height: 100px; }
.actions { display: flex; gap: 1rem; margin-top: 2.5rem; }
.btn { flex: 1; padding: 1.125rem; border-radius: 14px; font-weight: 800; cursor: pointer; text-align: center; text-decoration: none; border: none; }
.btn-submit { background: #00dc82; color: #064e3b; }
.btn-cancel { background: #f1f5f9; color: #475569; }
</style>

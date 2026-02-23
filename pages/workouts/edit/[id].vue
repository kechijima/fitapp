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
const showTimer = ref(false)

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
      <h1><span class="mdi mdi-pencil-outline"></span> 記録を編集</h1>
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
                <button type="button" @click.stop="copyLastSet(index)" class="btn-icon">
                  <span class="mdi mdi-content-copy"></span>
                </button>
                <button v-if="sets.length > 1" type="button" @click.stop="removeSet(index)" class="btn-icon btn-delete">
                  <span class="mdi mdi-close"></span>
                </button>
              </div>
            </div>
          </div>

          <button type="button" @click="addSet" class="btn btn-add-set">＋ セットを追加</button>

          <div class="form-group note-area">
            <label for="note" class="note-label">
              <span class="mdi mdi-note-edit-outline icon"></span> メモ
            </label>
            <div class="textarea-wrapper">
              <textarea id="note" v-model="note" rows="3"></textarea>
            </div>
          </div>

          <div class="actions">
            <button @click="updateWorkout" class="btn btn-submit" :disabled="submitting">
              <span class="mdi mdi-check"></span> {{ submitting ? '保存中...' : '更新を保存' }}
            </button>
            <NuxtLink to="/workouts" class="btn btn-cancel">キャンセル</NuxtLink>
          </div>

          <div class="timer-toggle-area">
            <button type="button" @click="showTimer = !showTimer" class="btn-timer-toggle">
              <span class="mdi" :class="showTimer ? 'mdi-timer-off-outline' : 'mdi-timer-outline'"></span>
              {{ showTimer ? 'タイマーを隠す' : 'タイマーを表示する' }}
            </button>
          </div>

          <Transition name="slide-fade">
            <div v-if="showTimer" class="inline-timer-section">
              <WorkoutTimer 
                :default-rest-time="defaultRestTime" 
                :default-work-time="defaultWorkTime"
                :current-set="currentSetIndex + 1" 
                :total-sets="sets.length" 
              />
            </div>
          </Transition>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.add-container { max-width: 1100px; margin: 0 auto; padding: 1rem; }
.header { margin-bottom: 2rem; }
.header h1 { 
  font-size: 2rem; 
  color: #000; 
  font-weight: 800; 
  display: flex;
  align-items: center;
  gap: 0.75rem;
}
.header h1 .mdi { color: var(--primary-color); }
.subtitle { color: #666; font-weight: 500; }

.main-layout { display: block; max-width: 700px; margin: 0 auto; }

.form-card { 
  background: white; 
  border-radius: 20px; 
  padding: 2rem; 
  box-shadow: 0 10px 30px rgba(0,0,0,0.05); 
  border: 1px solid #eee; 
}

.select-input { 
  width: 100%; 
  padding: 0.875rem; 
  border: 1px solid #dee2e6; 
  border-radius: 12px; 
  font-weight: 600; 
  background: #f8f9fa; 
  appearance: none;
  color: #000;
  transition: all 0.2s;
}
.select-input:focus {
  border-color: var(--primary-color);
  background-color: white;
  outline: none;
  box-shadow: 0 0 0 4px rgba(255, 152, 0, 0.1);
}

label { display: block; margin-bottom: 0.75rem; font-weight: 800; color: #000; font-size: 0.875rem; }

.sets-header { 
  display: grid; 
  grid-template-columns: 40px 1fr 1fr 100px; 
  gap: 0.5rem; 
  padding: 0 0.75rem; 
  font-size: 0.65rem; 
  font-weight: 900; 
  color: #adb5bd; 
  margin-bottom: 0.5rem; 
}
.set-row { 
  display: grid; 
  grid-template-columns: 40px 1fr 1fr 100px; 
  gap: 0.5rem; 
  align-items: center; 
  margin-bottom: 0.5rem; 
  background: #f8f9fa; 
  padding: 0.5rem 0.75rem; 
  border-radius: 12px; 
  border: 1px solid transparent; 
  cursor: pointer; 
  transition: all 0.2s;
}
.set-row:hover { background: #f1f3f5; }
.set-row.current-focus { border-color: var(--primary-color); background: white; box-shadow: 0 4px 6px rgba(0,0,0,0.05); }

.set-number { font-weight: 900; color: #adb5bd; text-align: center; font-size: 1rem; }
input { 
  width: 100%; 
  padding: 0.625rem 0.25rem; 
  border: 1px solid #dee2e6; 
  border-radius: 8px; 
  font-weight: 700; 
  text-align: center; 
  min-width: 0; 
  background: #fff;
  color: #000;
  transition: all 0.2s;
}
input:focus { border-color: var(--primary-color); outline: none; background: #fffcf8; }

.set-actions { display: flex; gap: 0.4rem; }
.btn-icon { 
  background: white; 
  border: 1px solid #dee2e6; 
  border-radius: 8px; 
  width: 36px; 
  height: 36px; 
  cursor: pointer; 
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.1rem;
  color: #666;
  transition: all 0.2s;
}
.btn-icon:hover { border-color: var(--primary-color); color: var(--primary-color); transform: translateY(-2px); }
.btn-delete:hover { border-color: var(--error-color); color: var(--error-color); }

.btn-add-set { 
  width: 100%; 
  padding: 1rem; 
  background: #f8f9fa; 
  border: 1px dashed #ced4da; 
  border-radius: 14px; 
  color: #6c757d; 
  font-weight: 800; 
  margin-bottom: 2.5rem; 
  cursor: pointer;
  transition: all 0.2s;
}
.btn-add-set:hover { background: white; border-color: var(--primary-color); color: var(--primary-color); }

.note-area { 
  background: #f8f9fa; 
  padding: 1.25rem; 
  border-radius: 16px; 
  border: 1px solid #eee; 
}
.note-label {
  display: flex !important;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: 1rem !important;
  color: #333 !important;
}
.textarea-wrapper textarea { 
  width: 100%; 
  padding: 1rem; 
  border: 1px solid #dee2e6; 
  border-radius: 12px; 
  min-height: 100px; 
  background: white;
  color: #000;
  transition: all 0.2s;
}
.textarea-wrapper textarea:focus {
  border-color: var(--primary-color);
  outline: none;
  box-shadow: 0 4px 12px rgba(255, 152, 0, 0.1);
}

.actions { display: flex; gap: 1rem; margin-top: 2.5rem; margin-bottom: 1.5rem; }
.btn { flex: 1; padding: 1.125rem; border-radius: 14px; font-weight: 800; cursor: pointer; text-align: center; text-decoration: none; border: none; transition: all 0.2s; display: inline-flex; align-items: center; justify-content: center; gap: 0.5rem; }

.timer-toggle-area {
  display: flex;
  justify-content: center;
  margin-bottom: 1rem;
}
.btn-timer-toggle {
  background: none;
  border: 1px solid #dee2e6;
  padding: 0.5rem 1rem;
  border-radius: 100px;
  color: #666;
  font-weight: 700;
  font-size: 0.875rem;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  transition: all 0.2s;
}
.btn-timer-toggle:hover {
  background: #f8f9fa;
  color: var(--primary-color);
  border-color: var(--primary-color);
}

.inline-timer-section {
  margin-top: 1.5rem;
  padding-top: 1.5rem;
  border-top: 1px solid #eee;
}

.slide-fade-enter-active, .slide-fade-leave-active { transition: all 0.3s ease; }
.slide-fade-enter-from, .slide-fade-leave-to { opacity: 0; transform: translateY(-10px); }

.btn-submit { background: var(--primary-color); color: #000; box-shadow: 0 4px 15px rgba(255,152,0,0.2); }
.btn-submit:hover { transform: translateY(-2px); background: var(--primary-dark); box-shadow: 0 8px 25px rgba(255,152,0,0.3); }
.btn-cancel { background: #f1f3f5; color: #495057; }
.btn:active { transform: scale(0.98); }
</style>

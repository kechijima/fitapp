<script setup lang="ts">
import type { Database } from '~/types/supabase'

type Workout = Database['public']['Tables']['workouts']['Row']

const client = useSupabaseClient<Database>()
const user = useSupabaseUser()
const workouts = ref<Workout[]>([])
const loading = ref(true)
const today = new Date()
const todayStr = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, '0')}-${String(today.getDate()).padStart(2, '0')}`
const selectedDate = ref<string | null>(todayStr)
const selectedExercises = ref<string[]>([])
const statsSearchQuery = ref('')
const showStatsDropdown = ref(false)

const fetchWorkouts = async () => {
  loading.value = true
  const { data, error } = await client
    .from('workouts')
    .select('*, workout_sets(*)')
    .order('date', { ascending: false })
  
  if (data) {
    workouts.value = data as any
  }
  loading.value = false
}

const deleteWorkout = async (id: string) => {
  if (!confirm('本当に削除しますか？')) return
  const { error } = await client.from('workouts').delete().eq('id', id)
  if (!error) {
    workouts.value = workouts.value.filter(w => w.id !== id)
  }
}

// 統計データの作成
const exerciseStats = computed(() => {
  const statsMap = new Map()
  
  workouts.value.forEach(w => {
    if (!statsMap.has(w.exercise_name)) {
      statsMap.set(w.exercise_name, { max: 0, totalWeight: 0, setCount: 0 })
    }
    const s = statsMap.get(w.exercise_name)
    
    // 全セットからMAXとAVGを計算
    if (w.workout_sets && w.workout_sets.length > 0) {
      w.workout_sets.forEach((set: any) => {
        const weight = set.weight || 0
        if (weight > s.max) s.max = weight
        s.totalWeight += weight
        s.setCount++
      })
    } else {
      // セット情報がない場合（互換性用）
      const weight = w.weight || 0
      if (weight > s.max) s.max = weight
      s.totalWeight += weight
      s.setCount++
    }
  })

  return Array.from(statsMap.entries()).map(([name, s]) => ({
    name,
    max: s.max,
    avg: s.setCount > 0 ? Math.round((s.totalWeight / s.setCount) * 10) / 10 : 0
  }))
})

// 全ての種目名（フィルタ用）
const allExerciseNames = computed(() => {
  return Array.from(new Set(workouts.value.map(w => w.exercise_name))).sort()
})

const filteredExerciseStats = computed(() => {
  let stats = exerciseStats.value
  
  // 検索クエリで絞り込み
  if (statsSearchQuery.value) {
    const query = statsSearchQuery.value.toLowerCase()
    stats = stats.filter(s => s.name.toLowerCase().includes(query))
  }
  
  // 選択されている種目がある場合は、その統計のみを表示（または全て表示）
  // ユーザーの意図としては「選択したものだけを詳しく見たい」
  if (selectedExercises.value.length > 0) {
    return stats.filter(s => selectedExercises.value.includes(s.name))
  }
  
  return stats
})

const availableStatsExercises = computed(() => {
  const query = statsSearchQuery.value.toLowerCase()
  return allExerciseNames.value.filter(name => 
    !selectedExercises.value.includes(name) && 
    name.toLowerCase().includes(query)
  )
})

const addExerciseFilter = (name: string) => {
  selectedExercises.value.push(name)
  statsSearchQuery.value = ''
  showStatsDropdown.value = false
}

const removeExerciseFilter = (name: string) => {
  selectedExercises.value = selectedExercises.value.filter(n => n !== name)
}

const workoutDates = computed(() => {
  return [...new Set(workouts.value.map(w => w.date))]
})

const filteredWorkouts = computed(() => {
  let result = workouts.value
  if (selectedDate.value) {
    result = result.filter(w => w.date === selectedDate.value)
  }
  if (selectedExercises.value.length > 0) {
    result = result.filter(w => selectedExercises.value.includes(w.exercise_name))
  }
  return result
})

const toggleExerciseFilter = (name: string) => {
  const index = selectedExercises.value.indexOf(name)
  if (index >= 0) {
    selectedExercises.value.splice(index, 1)
  } else {
    selectedExercises.value.push(name)
  }
}

const clearFilters = () => {
  selectedDate.value = null
  selectedExercises.value = []
  statsSearchQuery.value = ''
}

watchEffect(() => {
  if (user.value) {
    fetchWorkouts()
  }
})

const formatDate = (dateStr: string) => {
  return new Date(dateStr).toLocaleDateString('ja-JP')
}
</script>

<template>
  <div class="workouts-container">
    <div class="header">
      <h1><span class="mdi mdi-clipboard-text-clock-outline"></span> ワークアウト</h1>
      <NuxtLink :to="`/workouts/add${selectedDate ? '?date=' + selectedDate : ''}`" class="btn btn-add">
        <span class="mdi mdi-plus"></span> 記録する
      </NuxtLink>
    </div>

    <div class="dashboard-grid">
      <!-- 左側: カレンダーと統計 -->
      <div class="sidebar">
        <WorkoutCalendar 
          :workout-dates="workoutDates" 
          :selected-date="selectedDate"
          @select-date="date => selectedDate = (selectedDate === date ? null : date)" 
          class="mb-6"
        />

        <div class="stats-card">
          <div class="stats-header-row">
            <h3>種目別統計 (フィルタ表示)</h3>
          </div>
          
          <!-- コンボボックス形式のフィルタ -->
          <div class="combobox-container">
            <div class="combobox-input-wrapper" @click="showStatsDropdown = !showStatsDropdown">
              <div class="chips-area" v-if="selectedExercises.length > 0">
                <span v-for="name in selectedExercises" :key="name" class="filter-chip">
                  {{ name }}
                  <button @click.stop="removeExerciseFilter(name)" class="chip-remove">×</button>
                </span>
              </div>
              <input 
                v-model="statsSearchQuery" 
                placeholder="種目を選択..." 
                class="combobox-input"
                @focus="showStatsDropdown = true"
                @click.stop
              />
            </div>
            
            <Transition name="fade">
              <div v-if="showStatsDropdown" class="combobox-dropdown" @mouseleave="showStatsDropdown = false">
                <div 
                  v-for="name in availableStatsExercises" 
                  :key="name" 
                  class="dropdown-item"
                  @click="addExerciseFilter(name)"
                >
                  {{ name }}
                </div>
                <div v-if="availableStatsExercises.length === 0" class="dropdown-empty">
                  候補がありません
                </div>
              </div>
            </Transition>
          </div>

          <div class="stats-divider"></div>

          <div v-if="filteredExerciseStats.length === 0" class="empty-stats">
            表示するデータがありません
          </div>
          <div 
            v-for="stat in filteredExerciseStats" 
            :key="stat.name" 
            class="stat-row"
          >
            <div class="stat-name">{{ stat.name }}</div>
            <div class="stat-values">
              <div class="stat-item">
                <span class="label">MAX</span>
                <span class="value">{{ stat.max }}kg</span>
              </div>
              <div class="stat-item">
                <span class="label">AVG</span>
                <span class="value">{{ stat.avg }}kg</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 右側: 履歴一覧 -->
      <div class="main-content">
        <div class="section-header">
          <div class="title-with-badge">
            <h2>
              <span class="mdi mdi-history"></span>
              {{ selectedDate ? formatDate(selectedDate) : (selectedExercises.length > 0 ? '絞り込み中' : 'すべての履歴') }}
            </h2>
            <span v-if="selectedDate || selectedExercises.length > 0" class="filter-badge">
              {{ selectedExercises.length > 0 ? selectedExercises.length + '種目' : '' }} フィルター中
            </span>
          </div>
          <button v-if="selectedDate || selectedExercises.length > 0" @click="clearFilters" class="btn-text">すべて表示</button>
        </div>

        <div v-if="loading" class="loading">
          <div class="spinner"></div>
          読み込み中...
        </div>
        
        <div v-else-if="filteredWorkouts.length === 0" class="empty">
          <div class="empty-icon mdi mdi-folder-open-outline"></div>
          <p>該当する記録がありません</p>
        </div>

        <div v-else class="workout-list">
          <div v-for="workout in filteredWorkouts" :key="workout.id" class="workout-card compact">
            <div class="card-main">
              <div class="card-info">
                <span class="date">{{ formatDate(workout.date) }}</span>
                <h3 class="exercise-title">{{ workout.exercise_name }}</h3>
              </div>
              
              <div class="card-sets">
                <div v-if="(workout as any).workout_sets" class="set-chips">
                  <div v-for="s in (workout as any).workout_sets.slice(0, 3)" :key="s.id" class="set-chip">
                    <span class="weight">{{ s.weight }}<small>kg</small></span>
                    <span class="reps">×{{ s.reps }}</span>
                  </div>
                  <div v-if="(workout as any).workout_sets.length > 3" class="set-more" title="さらに表示">...</div>
                </div>
                <div v-else class="summary-line">
                  <span class="summary-item"><span class="mdi mdi-weight"></span> {{ workout.weight }}kg</span>
                  <span class="summary-item"><span class="mdi mdi-layers-outline"></span> {{ workout.sets }}s</span>
                  <span class="summary-item"><span class="mdi mdi-repeat"></span> {{ workout.reps }}r</span>
                </div>
              </div>

              <div class="card-actions">
                <NuxtLink :to="`/workouts/edit/${workout.id}`" class="icon-btn edit-btn" title="編集">
                  <span class="mdi mdi-pencil-outline"></span>
                </NuxtLink>
                <button @click="deleteWorkout(workout.id)" class="icon-btn del-btn" title="削除">
                  <span class="mdi mdi-delete-outline"></span>
                </button>
              </div>
            </div>
            <p v-if="workout.note" class="card-note">
              <span class="mdi mdi-note-text-outline"></span> {{ workout.note }}
            </p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.workouts-container {
  max-width: 1100px;
  margin: 0 auto;
  padding: 1rem;
}
.mb-6 { margin-bottom: 2rem; }

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2.5rem;
}

.header h1 {
  margin: 0;
  font-size: 2rem;
  color: #ffffff;
  font-weight: 800;
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.header h1 .mdi {
  color: #ff9800;
}

.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  padding: 0.75rem 1.5rem;
  border-radius: 12px;
  font-weight: 800;
  font-size: 0.9rem;
  text-decoration: none;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  cursor: pointer;
  border: none;
}
.btn-add {
  background: #ff9800;
  color: #000000;
  box-shadow: 0 4px 15px rgba(255, 152, 0, 0.3);
}
.btn-add:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 25px rgba(255, 152, 0, 0.4);
  background: #f57c00;
}
.btn-text {
  background: none;
  border: none;
  color: #ff9800;
  font-weight: 700;
  font-size: 0.85rem;
  cursor: pointer;
  padding: 0.5rem;
  transition: all 0.2s;
}
.btn-text:hover {
  color: #ffffff;
}

.dashboard-grid {
  display: grid;
  grid-template-columns: 320px 1fr;
  gap: 2.5rem;
}

@media (max-width: 1000px) {
  .dashboard-grid {
    grid-template-columns: 1fr;
    gap: 2rem;
  }
}

.stats-card {
  background: #ffffff;
  padding: 1.5rem;
  border-radius: 20px;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.05);
  border: 1px solid #eee;
}
.stats-card h3 {
  margin: 0 0 1.25rem 0;
  font-size: 0.8rem;
  color: #666;
  text-transform: uppercase;
  letter-spacing: 0.15em;
  font-weight: 800;
}

.combobox-container {
  position: relative;
  margin-bottom: 1.5rem;
}
.combobox-input-wrapper {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  padding: 0.6rem 0.75rem;
  border: 1px solid #dee2e6;
  border-radius: 12px;
  background: #f8f9fa;
  min-height: 48px;
  cursor: text;
  transition: border-color 0.2s;
}
.combobox-input-wrapper:focus-within {
  border-color: #ff9800;
  background: #fff;
}
.chips-area {
  display: flex;
  flex-wrap: wrap;
  gap: 0.25rem;
}
.filter-chip {
  background: #ff9800;
  color: #000;
  padding: 0.2rem 0.6rem;
  border-radius: 8px;
  font-size: 0.75rem;
  font-weight: 700;
  display: flex;
  align-items: center;
  gap: 0.25rem;
}
.chip-remove {
  background: none;
  border: none;
  font-size: 1rem;
  color: #000;
  cursor: pointer;
  padding: 0;
  display: flex;
}
.combobox-input {
  border: none;
  background: transparent;
  flex: 1;
  min-width: 80px;
  font-size: 0.9rem;
  padding: 0.25rem;
  color: #000;
}
.combobox-input:focus { outline: none; }

.combobox-dropdown {
  position: absolute;
  top: 100%;
  left: 0;
  right: 0;
  z-index: 50;
  background: #ffffff;
  border: 1px solid #dee2e6;
  border-radius: 12px;
  box-shadow: 0 15px 40px rgba(0, 0, 0, 0.1);
  margin-top: 0.5rem;
  max-height: 250px;
  overflow-y: auto;
}
.dropdown-item {
  padding: 0.8rem 1rem;
  font-size: 0.9rem;
  font-weight: 600;
  cursor: pointer;
  color: #666;
  transition: all 0.2s;
}
.dropdown-item:hover { background: #f8f9fa; color: #ff9800; }
.dropdown-empty { padding: 1.5rem; text-align: center; color: #adb5bd; font-size: 0.8rem; }

.stats-divider {
  height: 1px;
  background: #eee;
  margin: 1.5rem 0;
}

.stat-row {
  padding: 1rem;
  border-radius: 12px;
  margin-bottom: 0.75rem;
  background: #f8f9fa;
  border: 1px solid #eee;
  transition: all 0.2s;
}
.stat-row:hover {
  border-color: #dee2e6;
  transform: translateX(4px);
}
.stat-name {
  font-weight: 700;
  margin-bottom: 0.5rem;
  font-size: 0.9rem;
  color: #000;
}
.stat-values {
  display: flex;
  gap: 1.5rem;
}
.stat-item .label {
  font-size: 0.7rem;
  color: #666;
  font-weight: 800;
  text-transform: uppercase;
  display: block;
}
.stat-item .value {
  font-size: 1.1rem;
  font-weight: 800;
  color: #ff9800;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.5rem;
}
.title-with-badge {
  display: flex;
  align-items: center;
  gap: 1rem;
}
.title-with-badge h2 { 
  font-size: 1.5rem; 
  font-weight: 800; 
  margin: 0; 
  color: #000;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}
.title-with-badge h2 .mdi {
  color: #ff9800;
}
.filter-badge {
  background: rgba(255, 152, 0, 0.1);
  color: #ff9800;
  font-size: 0.7rem;
  padding: 0.25rem 0.75rem;
  border-radius: 100px;
  font-weight: 800;
  border: 1px solid rgba(255, 152, 0, 0.2);
}

.loading {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 4rem;
  color: #666;
  gap: 1rem;
}
.spinner {
  width: 40px;
  height: 40px;
  border: 4px solid #eee;
  border-top-color: #ff9800;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}
@keyframes spin {
  to { transform: rotate(360deg); }
}

.empty {
  text-align: center;
  padding: 5rem 2rem;
  background: #f8f9fa;
  border-radius: 20px;
  border: 2px dashed #dee2e6;
}
.empty-icon {
  font-size: 4rem;
  color: #ced4da;
  margin-bottom: 1rem;
}
.empty p {
  color: #6c757d;
  font-size: 1.1rem;
}

.workout-list {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.workout-card.compact {
  background: #ffffff;
  border-radius: 16px;
  padding: 1.25rem 1.5rem;
  box-shadow: 0 4px 15px rgba(0, 0, 0, 0.05);
  border: 1px solid #eee;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}
.workout-card.compact:hover {
  transform: scale(1.01);
  border-color: #ff9800;
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.1);
}

.card-main {
  display: flex;
  align-items: center;
  gap: 1.5rem;
}

.card-info {
  flex: 0 0 200px;
}
.date {
  font-size: 0.75rem;
  color: #6c757d;
  font-weight: 700;
  display: block;
  margin-bottom: 0.25rem;
}
.exercise-title {
  margin: 0;
  font-size: 1.1rem;
  font-weight: 800;
  color: #000;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.card-sets {
  flex: 1;
  display: flex;
  align-items: center;
}

.set-chips {
  display: flex;
  gap: 0.5rem;
}
.set-chip {
  background: #f8f9fa;
  border: 1px solid #eee;
  padding: 0.35rem 0.75rem;
  border-radius: 10px;
  display: flex;
  align-items: baseline;
  gap: 0.25rem;
}
.set-chip .weight { font-size: 0.9rem; font-weight: 800; color: #ff9800; }
.set-chip .weight small { font-size: 0.65rem; color: #666; }
.set-chip .reps { font-size: 0.8rem; font-weight: 700; color: #000; }

.set-more {
  color: #6c757d;
  font-weight: 900;
  padding: 0 0.5rem;
}

.summary-line { 
  display: flex; 
  gap: 1rem; 
  font-size: 0.85rem; 
  font-weight: 700; 
  color: #adb5bd; 
}
.summary-item {
  display: flex;
  align-items: center;
  gap: 0.3rem;
}
.summary-item .mdi {
  color: #ff9800;
}

.card-actions {
  display: flex;
  gap: 0.5rem;
  flex: 0 0 auto;
}
.icon-btn {
  width: 36px;
  height: 36px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 10px;
  background: #f8f9fa;
  border: 1px solid #eee;
  cursor: pointer;
  text-decoration: none;
  font-size: 1.1rem;
  transition: all 0.2s;
  color: #666;
}
.edit-btn:hover { background: #fff; color: #ff9800; border-color: #ff9800; box-shadow: 0 4px 10px rgba(255,152,0,0.1); }
.del-btn:hover { background: #fff; color: #dc3545; border-color: #dc3545; box-shadow: 0 4px 10px rgba(220,53,69,0.1); }

.card-note {
  margin: 1rem 0 0 0;
  font-size: 0.85rem;
  color: #666;
  background: #f8f9fa;
  padding: 0.75rem 1rem;
  border-radius: 10px;
  border-left: 4px solid #ff9800;
  display: flex;
  align-items: flex-start;
  gap: 0.5rem;
}
.card-note .mdi {
  color: #ff9800;
  font-size: 1.1rem;
}

@media (max-width: 768px) {
  .card-main { flex-wrap: wrap; }
  .card-info { flex: 1 1 100%; margin-bottom: 0.75rem; }
  .card-sets { flex: 1; margin-bottom: 0.75rem; }
  .card-actions { width: 100%; justify-content: flex-end; }
}
</style>

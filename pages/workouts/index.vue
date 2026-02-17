<script setup lang="ts">
import type { Database } from '~/types/supabase'

type Workout = Database['public']['Tables']['workouts']['Row']

const client = useSupabaseClient<Database>()
const user = useSupabaseUser()
const workouts = ref<Workout[]>([])
const loading = ref(true)
const selectedDate = ref<string | null>(null)
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
      <h1>ワークアウト</h1>
      <NuxtLink :to="`/workouts/add${selectedDate ? '?date=' + selectedDate : ''}`" class="btn btn-add">＋ 記録する</NuxtLink>
    </div>

    <div class="dashboard-grid">
      <!-- 左側: カレンダーと統計 -->
      <div class="sidebar">
        <WorkoutCalendar 
          :workout-dates="workoutDates" 
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
              {{ selectedDate ? formatDate(selectedDate) : (selectedExercises.length > 0 ? '絞り込み中' : 'すべての履歴') }}
            </h2>
            <span v-if="selectedDate || selectedExercises.length > 0" class="filter-badge">
              {{ selectedExercises.length > 0 ? selectedExercises.length + '種目' : '' }} フィルター中
            </span>
          </div>
          <button v-if="selectedDate || selectedExercises.length > 0" @click="clearFilters" class="btn-text">すべて表示</button>
        </div>

        <div v-if="loading" class="loading">読み込み中...</div>
        
        <div v-else-if="filteredWorkouts.length === 0" class="empty">
          <div class="empty-icon">📂</div>
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
                  <span class="summary-item">⚖️ {{ workout.weight }}kg</span>
                  <span class="summary-item">📊 {{ workout.sets }}s</span>
                  <span class="summary-item">🔁 {{ workout.reps }}r</span>
                </div>
              </div>

              <div class="card-actions">
                <NuxtLink :to="`/workouts/edit/${workout.id}`" class="icon-btn" title="編集">✏️</NuxtLink>
                <button @click="deleteWorkout(workout.id)" class="icon-btn del" title="削除">🗑️</button>
              </div>
            </div>
            <p v-if="workout.note" class="card-note">{{ workout.note }}</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.workouts-container {
  max-width: 1000px;
  margin: 0 auto;
  padding: 1rem;
}
.mb-6 { margin-bottom: 2rem; }

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
}

/* 記録するボタンなどの基本スタイル */
.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 0.6rem 1.2rem;
  border-radius: 12px;
  font-weight: 800;
  font-size: 0.875rem;
  text-decoration: none;
  transition: all 0.2s;
  cursor: pointer;
  border: none;
}
.btn-add {
  background: #00dc82;
  color: #054a29;
  box-shadow: 0 4px 6px -1px rgba(0, 220, 130, 0.2);
}
.btn-add:hover {
  transform: translateY(-2px);
  box-shadow: 0 10px 15px -3px rgba(0, 220, 130, 0.3);
}
.btn-text {
  background: none;
  border: none;
  color: #00dc82;
  font-weight: 800;
  font-size: 0.8125rem;
  cursor: pointer;
  padding: 0.5rem;
}
.btn-text:hover {
  text-decoration: underline;
}

.header h1 {
  margin: 0;
  font-size: 1.75rem;
  color: #0f172a;
  font-weight: 800;
  letter-spacing: -0.02em;
}

.dashboard-grid {
  display: grid;
  grid-template-columns: 280px 1fr;
  gap: 2rem;
}

@media (max-width: 1000px) {
  .dashboard-grid {
    grid-template-columns: 1fr;
    gap: 2rem;
  }
}

.stats-card {
  background: white;
  padding: 1.25rem;
  border-radius: 16px;
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);
  border: 1px solid #f1f5f9;
}
.stats-card h3 {
  margin: 0 0 1rem 0;
  font-size: 0.75rem;
  color: #94a3b8;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  font-weight: 800;
}

.combobox-container {
  position: relative;
  margin-bottom: 1.5rem;
}
.combobox-input-wrapper {
  display: flex;
  flex-wrap: wrap;
  gap: 0.375rem;
  padding: 0.4rem 0.5rem;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  background: white;
  min-height: 42px;
  cursor: text;
}
.chips-area {
  display: flex;
  flex-wrap: wrap;
  gap: 0.25rem;
}
.filter-chip {
  background: #f0fdf4;
  color: #054a29;
  border: 1px solid #bbf7d0;
  padding: 0.125rem 0.5rem;
  border-radius: 6px;
  font-size: 0.75rem;
  font-weight: 700;
  display: flex;
  align-items: center;
  gap: 0.25rem;
}
.chip-remove {
  background: none;
  border: none;
  font-size: 0.875rem;
  color: #166534;
  cursor: pointer;
  padding: 0;
  line-height: 1;
}
.combobox-input {
  border: none;
  flex: 1;
  min-width: 60px;
  font-size: 0.875rem;
  padding: 0.25rem;
}
.combobox-input:focus { outline: none; }

.combobox-dropdown {
  position: absolute;
  top: 100%;
  left: 0;
  right: 0;
  z-index: 50;
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
  margin-top: 0.25rem;
  max-height: 200px;
  overflow-y: auto;
}
.dropdown-item {
  padding: 0.6rem 1rem;
  font-size: 0.8125rem;
  font-weight: 600;
  cursor: pointer;
}
.dropdown-item:hover { background: #f8fafc; color: #00dc82; }
.dropdown-empty { padding: 1rem; text-align: center; color: #94a3b8; font-size: 0.75rem; }

.stats-divider {
  height: 1px;
  background: #f1f5f9;
  margin: 1rem 0;
}

.stat-row {
  padding: 0.6rem 0.75rem;
  border-radius: 10px;
  margin-bottom: 0.5rem;
  background: #f8fafc;
  border: 1px solid #f1f5f9;
}
.stat-name {
  font-weight: 700;
  margin-bottom: 0.2rem;
  font-size: 0.8125rem;
  color: #1e293b;
}
.stat-values {
  display: flex;
  gap: 1rem;
}
.stat-item .label {
  font-size: 0.65rem;
  color: #94a3b8;
  font-weight: 800;
}
.stat-item .value {
  font-size: 0.9375rem;
  font-weight: 800;
  color: #00dc82;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.25rem;
}
.title-with-badge {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}
.title-with-badge h2 { font-size: 1.25rem; font-weight: 800; margin: 0; }
.filter-badge {
  background: #00dc82;
  color: #054a29;
  font-size: 0.65rem;
  padding: 0.2rem 0.6rem;
  border-radius: 100px;
  font-weight: 800;
  text-transform: uppercase;
}

.workout-list {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.workout-card.compact {
  background: white;
  border-radius: 12px;
  padding: 0.75rem 1rem;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.02);
  border: 1px solid #f1f5f9;
  transition: transform 0.2s, box-shadow 0.2s;
}
.workout-card.compact:hover {
  transform: translateY(-2px);
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05);
}

.card-main {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.card-info {
  flex: 0 0 180px;
}
.date {
  font-size: 0.7rem;
  color: #94a3b8;
  font-weight: 700;
  display: block;
  margin-bottom: 0.125rem;
}
.exercise-title {
  margin: 0;
  font-size: 1rem;
  font-weight: 800;
  color: #1e293b;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.card-sets {
  flex: 1;
  display: flex;
  align-items: center;
  overflow-x: auto;
  padding-bottom: 4px; /* スクロールバー用 */
}
.card-sets::-webkit-scrollbar { height: 4px; }
.card-sets::-webkit-scrollbar-thumb { background: #e2e8f0; border-radius: 4px; }

.set-chips {
  display: flex;
  gap: 0.375rem;
}
.set-chip {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  padding: 0.25rem 0.5rem;
  border-radius: 6px;
  display: flex;
  align-items: baseline;
  gap: 0.2rem;
  white-space: nowrap;
}
.set-chip .weight { font-size: 0.8125rem; font-weight: 800; color: #0f172a; }
.set-chip .weight small { font-size: 0.6rem; color: #94a3b8; margin-left: 1px; }
.set-chip .reps { font-size: 0.75rem; font-weight: 700; color: #64748b; }

.set-more {
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1rem;
  font-weight: 900;
  color: #94a3b8;
  padding: 0 0.25rem;
  letter-spacing: 0.1em;
}

.summary-line { display: flex; gap: 0.75rem; font-size: 0.8125rem; font-weight: 700; color: #64748b; }

.card-actions {
  display: flex;
  gap: 0.25rem;
  flex: 0 0 auto;
}
.icon-btn {
  width: 30px;
  height: 30px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 6px;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  cursor: pointer;
  text-decoration: none;
  font-size: 0.875rem;
  transition: all 0.2s;
}
.icon-btn:hover { background: #eff6ff; border-color: #3b82f6; }
.icon-btn.del:hover { background: #fef2f2; border-color: #ef4444; }

.card-note {
  margin: 0.5rem 0 0 0;
  font-size: 0.75rem;
  color: #64748b;
  background: #f8fafc;
  padding: 0.375rem 0.75rem;
  border-radius: 6px;
  border-left: 3px solid #e2e8f0;
}

@media (max-width: 768px) {
  .card-main { flex-wrap: wrap; }
  .card-info { flex: 1 1 100%; margin-bottom: 0.5rem; }
  .card-sets { flex: 1; }
}
</style>

<script setup lang="ts">
import type { Database } from '~/types/supabase'

type Workout = Database['public']['Tables']['workouts']['Row']

const client = useSupabaseClient<Database>()
const user = useSupabaseUser()
const workouts = ref<Workout[]>([])
const loading = ref(true)

const fetchWorkouts = async () => {
  loading.value = true
  const { data, error } = await client
    .from('workouts')
    .select('*')
    .order('date', { ascending: false })
  
  if (data) {
    workouts.value = data
  }
  loading.value = false
}

const deleteWorkout = async (id: string) => {
  if (!confirm('本当に削除しますか？')) return

  const { error } = await client
    .from('workouts')
    .delete()
    .eq('id', id)

  if (!error) {
    workouts.value = workouts.value.filter(w => w.id !== id)
  }
}

// Statistics calculations
const stats = computed(() => {
  const totalWorkouts = workouts.value.length
  const uniqueExercises = new Set(workouts.value.map(w => w.exercise_name)).size
  const totalVolume = workouts.value.reduce((sum, w) => {
    return sum + ((w.weight || 0) * (w.sets || 0) * (w.reps || 0))
  }, 0)
  
  return { totalWorkouts, uniqueExercises, totalVolume }
})

watchEffect(() => {
  if (user.value) {
    fetchWorkouts()
  }
})

// Format date helper
const formatDate = (dateStr: string) => {
  return new Date(dateStr).toLocaleDateString('ja-JP')
}
</script>

<template>
  <div class="workouts-container">
    <div class="header">
      <h1>ワークアウト一覧</h1>
      <NuxtLink to="/workouts/add" class="btn btn-add">＋ 記録する</NuxtLink>
    </div>

    <!-- Statistics Section -->
    <div v-if="!loading && workouts.length > 0" class="stats-grid">
      <div class="stat-card">
        <div class="stat-value">{{ stats.totalWorkouts }}</div>
        <div class="stat-label">トータル記録</div>
      </div>
      <div class="stat-card">
        <div class="stat-value">{{ stats.uniqueExercises }}</div>
        <div class="stat-label">種目数</div>
      </div>
      <div class="stat-card">
        <div class="stat-value">{{ Math.round(stats.totalVolume) }}</div>
        <div class="stat-label">総負荷 (kg)</div>
      </div>
    </div>

    <div v-if="loading" class="loading">読み込み中...</div>
    
    <div v-else-if="workouts.length === 0" class="empty">
      <div class="empty-icon">📝</div>
      <p>まだ記録がありません</p>
      <p class="empty-hint">最初のワークアウトを記録しましょう！</p>
    </div>

    <div v-else class="workout-list">
      <div v-for="workout in workouts" :key="workout.id" class="workout-card">
        <div class="card-header">
          <span class="date">{{ formatDate(workout.date) }}</span>
          <button @click="deleteWorkout(workout.id)" class="delete-btn">🗑️</button>
        </div>
        <div class="card-body">
          <h3>{{ workout.exercise_name }}</h3>
          <div class="stats">
            <span v-if="workout.weight" class="stat-badge">⚖️ {{ workout.weight }}kg</span>
            <span v-if="workout.sets" class="stat-badge">📊 {{ workout.sets }}セット</span>
            <span v-if="workout.reps" class="stat-badge">🔁 {{ workout.reps }}回</span>
          </div>
          <p v-if="workout.note" class="note">{{ workout.note }}</p>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.workouts-container {
  max-width: 700px;
  margin: 0 auto;
}
.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
}
.header h1 {
  margin: 0;
  font-size: 2rem;
  color: #0f172a;
}
.btn-add {
  padding: 0.75rem 1.5rem;
  background: linear-gradient(135deg, #00dc82 0%, #36e4da 100%);
  color: white;
  text-decoration: none;
  border-radius: 8px;
  font-weight: 600;
  box-shadow: 0 4px 12px rgba(0, 220, 130, 0.3);
  transition: all 0.2s;
}
.btn-add:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 16px rgba(0, 220, 130, 0.4);
}
.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
  gap: 1rem;
  margin-bottom: 2rem;
}
.stat-card {
  background: white;
  padding: 1.5rem;
  border-radius: 12px;
  text-align: center;
  box-shadow: 0 2px 8px rgba(0,0,0,0.05);
}
.stat-value {
  font-size: 2rem;
  font-weight: 800;
  color: #00dc82;
  margin-bottom: 0.5rem;
}
.stat-label {
  font-size: 0.875rem;
  color: #64748b;
  font-weight: 500;
}
.loading {
  text-align: center;
  padding: 3rem;
  color: #64748b;
}
.empty {
  text-align: center;
  padding: 3rem;
  background: white;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.05);
}
.empty-icon {
  font-size: 4rem;
  margin-bottom: 1rem;
}
.empty p {
  color: #64748b;
  margin: 0.5rem 0;
}
.empty-hint {
  font-size: 0.875rem;
  color: #94a3b8;
}
.workout-list {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}
.workout-card {
  background: white;
  border-radius: 12px;
  padding: 1.25rem;
  box-shadow: 0 2px 8px rgba(0,0,0,0.05);
  transition: transform 0.2s, box-shadow 0.2s;
}
.workout-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0,0,0,0.1);
}
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.75rem;
}
.date {
  color: #64748b;
  font-size: 0.875rem;
  font-weight: 500;
}
.delete-btn {
  background: none;
  border: none;
  font-size: 1.25rem;
  cursor: pointer;
  opacity: 0.5;
  transition: opacity 0.2s;
  padding: 0.25rem;
}
.delete-btn:hover {
  opacity: 1;
}
.card-body h3 {
  margin: 0 0 0.75rem 0;
  font-size: 1.25rem;
  color: #0f172a;
}
.stats {
  display: flex;
  flex-wrap: wrap;
  gap: 0.75rem;
  margin-bottom: 0.5rem;
}
.stat-badge {
  padding: 0.375rem 0.75rem;
  background-color: #f1f5f9;
  border-radius: 6px;
  font-size: 0.875rem;
  font-weight: 600;
  color: #0f172a;
}
.note {
  margin-top: 0.75rem;
  padding-top: 0.75rem;
  border-top: 1px solid #f1f5f9;
  font-size: 0.875rem;
  color: #64748b;
  margin-bottom: 0;
}
</style>

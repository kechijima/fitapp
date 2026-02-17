<script setup lang="ts">
const client = useSupabaseClient()
const user = useSupabaseUser()
const router = useRouter()

const form = ref({
  exercise_name: '',
  weight: '',
  sets: '',
  reps: '',
  note: ''
})

const submitting = ref(false)

const submitWorkout = async () => {
  if (!user.value) {
    alert('ログインしてください')
    return
  }
  
  submitting.value = true
  
  const { error } = await client
    .from('workouts')
    .insert({
      user_id: user.value.id,
      exercise_name: form.value.exercise_name,
      weight: form.value.weight ? parseFloat(form.value.weight) : null,
      sets: form.value.sets ? parseInt(form.value.sets) : null,
      reps: form.value.reps ? parseInt(form.value.reps) : null,
      note: form.value.note || null
    })

  submitting.value = false

  if (error) {
    alert('エラーが発生しました: ' + error.message)
  } else {
    router.push('/workouts')
  }
}
</script>

<template>
  <div class="add-container">
    <div class="header">
      <h1>📝 ワークアウト記録</h1>
      <p class="subtitle">今日のトレーニングを記録しましょう</p>
    </div>
    
    <form @submit.prevent="submitWorkout" class="form-card">
      <div class="form-group">
        <label for="exercise">種目名 *</label>
        <input 
          id="exercise"
          v-model="form.exercise_name" 
          required 
          placeholder="例: ベンチプレス" 
        />
      </div>
      
      <div class="form-row">
        <div class="form-group">
          <label for="weight">重量 (kg)</label>
          <input 
            id="weight"
            type="number" 
            step="0.5" 
            v-model="form.weight"
            placeholder="60" 
          />
        </div>
        <div class="form-group">
          <label for="sets">セット数</label>
          <input 
            id="sets"
            type="number" 
            v-model="form.sets"
            placeholder="3" 
          />
        </div>
        <div class="form-group">
          <label for="reps">回数</label>
          <input 
            id="reps"
            type="number" 
            v-model="form.reps"
            placeholder="10" 
          />
        </div>
      </div>

      <div class="form-group">
        <label for="note">メモ</label>
        <textarea 
          id="note"
          v-model="form.note" 
          rows="3"
          placeholder="フォームが良かった、次回は重量アップ予定など..."
        ></textarea>
      </div>

      <div class="actions">
        <button type="submit" class="btn btn-submit" :disabled="submitting">
          {{ submitting ? '保存中...' : '📊 記録する' }}
        </button>
        <NuxtLink to="/workouts" class="btn btn-cancel">キャンセル</NuxtLink>
      </div>
    </form>
  </div>
</template>

<style scoped>
.add-container {
  max-width: 600px;
  margin: 0 auto;
}
.header {
  margin-bottom: 2rem;
}
.header h1 {
  font-size: 2rem;
  margin: 0 0 0.5rem 0;
  color: #0f172a;
}
.subtitle {
  color: #64748b;
  margin: 0;
}
.form-card {
  background: white;
  border-radius: 12px;
  padding: 2rem;
  box-shadow: 0 2px 8px rgba(0,0,0,0.05);
}
.form-group {
  margin-bottom: 1.5rem;
}
.form-row {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 1rem;
}
label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: 600;
  color: #0f172a;
  font-size: 0.875rem;
}
input, textarea {
  width: 100%;
  padding: 0.75rem;
  border: 2px solid #e2e8f0;
  border-radius: 8px;
  font-size: 1rem;
  transition: border-color 0.2s;
  font-family: inherit;
}
input:focus, textarea:focus {
  outline: none;
  border-color: #00dc82;
}
textarea {
  resize: vertical;
}
.actions {
  display: flex;
  gap: 1rem;
  margin-top: 2rem;
}
.btn {
  flex: 1;
  padding: 1rem;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  font-weight: 600;
  font-size: 1rem;
  transition: all 0.2s;
  text-align: center;
  text-decoration: none;
  display: inline-block;
}
.btn-submit {
  background: linear-gradient(135deg, #00dc82 0%, #36e4da 100%);
  color: white;
  box-shadow: 0 4px 12px rgba(0, 220, 130, 0.3);
}
.btn-submit:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 6px 16px rgba(0, 220, 130, 0.4);
}
.btn-submit:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
.btn-cancel {
  background-color: #f1f5f9;
  color: #0f172a;
}
.btn-cancel:hover {
  background-color: #e2e8f0;
}
</style>


<script setup lang="ts">
const user = useSupabaseUser()
</script>

<template>
  <div class="welcome-container">
    <div class="hero">
      <h1 class="title">💪 FitApp</h1>
      <p class="subtitle">筋トレを記録して、理想の体を目指しましょう</p>
    </div>
    
    <template v-if="user">
      <div class="dashboard-preview">
        <h2>こんにちは！</h2>
        <p>今日のワークアウトを記録しましょう</p>
        <NuxtLink to="/workouts" class="btn btn-primary">ワークアウトを見る</NuxtLink>
      </div>
    </template>
    
    <template v-else>
      <div class="features">
        <div class="feature-card">
          <div class="feature-icon">📊</div>
          <h3>進捗を追跡</h3>
          <p>トレーニングの記録を残して成長を可視化</p>
        </div>
        <div class="feature-card">
          <div class="feature-icon">🎯</div>
          <h3>目標達成</h3>
          <p>継続的な記録で目標に近づく</p>
        </div>
        <div class="feature-card">
          <div class="feature-icon">⚡</div>
          <h3>シンプルで高速</h3>
          <p>素早く簡単にトレーニングを記録</p>
        </div>
      </div>
      
      <div class="actions">
        <NuxtLink to="/signup" class="btn btn-primary">今すぐ始める</NuxtLink>
        <NuxtLink to="/login" class="btn btn-secondary">ログイン</NuxtLink>
      </div>
    </template>
  </div>
</template>

<style scoped>
.welcome-container {
  max-width: 900px;
  margin: 0 auto;
  padding: 2rem 1rem;
}
.hero {
  text-align: center;
  padding: 3rem 0;
}
.title {
  font-size: 3rem;
  margin: 0;
  color: #0f172a;
  font-weight: 800;
}
.subtitle {
  font-size: 1.25rem;
  color: #64748b;
  margin-top: 1rem;
}
.features {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 2rem;
  margin: 3rem 0;
}
.feature-card {
  background: white;
  padding: 2rem;
  border-radius: 12px;
  text-align: center;
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
  transition: transform 0.2s;
}
.feature-card:hover {
  transform: translateY(-4px);
}
.feature-icon {
  font-size: 3rem;
  margin-bottom: 1rem;
}
.feature-card h3 {
  margin: 0.5rem 0;
  color: #0f172a;
}
.feature-card p {
  color: #64748b;
  margin: 0;
}
.dashboard-preview {
  background: white;
  padding: 3rem;
  border-radius: 12px;
  text-align: center;
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
  margin: 3rem 0;
}
.dashboard-preview h2 {
  font-size: 2rem;
  margin: 0 0 1rem 0;
  color: #0f172a;
}
.actions {
  display: flex;
  justify-content: center;
  gap: 1rem;
  margin-top: 3rem;
  flex-wrap: wrap;
}
.btn {
  padding: 1rem 2rem;
  text-decoration: none;
  border-radius: 8px;
  font-weight: 600;
  font-size: 1rem;
  transition: all 0.2s;
  display: inline-block;
}
.btn-primary {
  background: linear-gradient(135deg, #00dc82 0%, #36e4da 100%);
  color: white;
  box-shadow: 0 4px 12px rgba(0, 220, 130, 0.3);
}
.btn-primary:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 16px rgba(0, 220, 130, 0.4);
}
.btn-secondary {
  background-color: #f1f5f9;
  color: #0f172a;
}
.btn-secondary:hover {
  background-color: #e2e8f0;
}
</style>


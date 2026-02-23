<script setup lang="ts">
const user = useSupabaseUser()

watchEffect(() => {
  if (user.value) {
    navigateTo('/workouts')
  }
})
</script>

<template>
  <div class="welcome-container">
    <div class="hero">
      <h1 class="title"><span class="mdi mdi-arm-flex"></span> FitApp</h1>
      <p class="subtitle">筋トレを記録して、理想の体を目指しましょう</p>
    </div>
    
    <div class="features">
      <div class="feature-card">
        <div class="feature-icon mdi mdi-chart-timeline-variant-shimmer"></div>
        <h3>進捗を追跡</h3>
        <p>トレーニングの記録を残して成長を可視化</p>
      </div>
      <div class="feature-card">
        <div class="feature-icon mdi mdi-target"></div>
        <h3>目標達成</h3>
        <p>継続的な記録で目標に近づく</p>
      </div>
      <div class="feature-card">
        <div class="feature-icon mdi mdi-flash"></div>
        <h3>シンプルで高速</h3>
        <p>素早く簡単にトレーニングを記録</p>
      </div>
    </div>
    
    <div class="actions">
      <NuxtLink to="/signup" class="btn btn-primary">今すぐ始める</NuxtLink>
      <NuxtLink to="/login" class="btn btn-secondary">ログイン</NuxtLink>
    </div>
  </div>
</template>

<style scoped>
.welcome-container {
  max-width: 900px;
  margin: 0 auto;
  padding: 4rem 1rem;
}
.hero {
  text-align: center;
  padding: 4rem 0;
}
.title {
  font-size: 4rem;
  margin: 0;
  color: #000000;
  font-weight: 800;
  letter-spacing: -1px;
}
.title .mdi {
  color: #ff9800;
}
.subtitle {
  font-size: 1.5rem;
  color: #666;
  margin-top: 1rem;
}
.features {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 2rem;
  margin: 4rem 0;
}
.feature-card {
  background: #ffffff;
  padding: 3rem 2rem;
  border-radius: 16px;
  text-align: center;
  border: 1px solid #eee;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.05);
}
.feature-card:hover {
  transform: translateY(-8px);
  border-color: #ff9800;
  box-shadow: 0 12px 30px rgba(255, 152, 0, 0.1);
}
.feature-icon {
  font-size: 3.5rem;
  margin-bottom: 1.5rem;
  color: #ff9800;
  display: block;
}
.feature-card h3 {
  margin: 0.5rem 0;
  color: #000;
  font-size: 1.5rem;
}
.feature-card p {
  color: #666;
  margin: 0;
  line-height: 1.6;
}
.actions {
  display: flex;
  justify-content: center;
  gap: 1.5rem;
  margin-top: 4rem;
  flex-wrap: wrap;
}
.btn {
  padding: 1.25rem 3rem;
  text-decoration: none;
  border-radius: 12px;
  font-weight: 700;
  font-size: 1.1rem;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  display: inline-block;
  text-transform: uppercase;
  letter-spacing: 1px;
}
.btn-primary {
  background: #ff9800;
  color: #000000;
  box-shadow: 0 4px 15px rgba(255, 152, 0, 0.2);
}
.btn-primary:hover {
  background: #f57c00;
  transform: translateY(-2px);
  box-shadow: 0 8px 25px rgba(255, 152, 0, 0.3);
}
.btn-secondary {
  background-color: transparent;
  color: #000;
  border: 2px solid #000;
}
.btn-secondary:hover {
  background-color: #000;
  color: #fff;
}
</style>


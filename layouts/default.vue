<script setup lang="ts">
const client = useSupabaseClient()
const user = useSupabaseUser()

const handleLogout = async () => {
  await client.auth.signOut()
  navigateTo('/login')
}
</script>

<template>
  <div class="layout-container">
    <header>
      <nav>
        <NuxtLink to="/" class="brand">
          <span class="mdi mdi-arm-flex"></span> FitApp
        </NuxtLink>
        <div class="nav-links">
          <template v-if="user">
            <NuxtLink to="/workouts">
              <span class="mdi mdi-dumbbell"></span> ワークアウト
            </NuxtLink>
            <button @click="handleLogout" class="logout-btn">
              <span class="mdi mdi-logout"></span> ログアウト
            </button>
          </template>
          <template v-else>
            <NuxtLink to="/login">ログイン</NuxtLink>
            <NuxtLink to="/signup" class="signup-link">新規登録</NuxtLink>
          </template>
        </div>
      </nav>
    </header>
    <main>
      <slot />
    </main>
  </div>
</template>

<style>
:root {
  --primary-color: #ff9800;
  --primary-dark: #f57c00;
  --secondary-color: #000000;
  --bg-color: #ffffff;
  --surface-color: #f8f9fa;
  --text-primary: #1e1e1e;
  --text-secondary: #6c757d;
  --border-color: #dee2e6;
  --error-color: #dc3545;
}

* {
  box-sizing: border-box;
}

body {
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
  margin: 0;
  padding: 0;
  background-color: var(--bg-color);
  color: var(--text-primary);
  line-height: 1.6;
}

.layout-container {
  max-width: 1000px;
  margin: 0 auto;
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

header {
  padding: 1rem 2rem;
  border-bottom: 1px solid var(--border-color);
  background: rgba(255, 255, 255, 0.8);
  backdrop-filter: blur(10px);
  position: sticky;
  top: 0;
  z-index: 100;
}

nav {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.brand {
  font-weight: 900;
  font-size: 1.75rem;
  text-decoration: none;
  color: var(--text-primary);
  letter-spacing: -0.5px;
}

.brand .mdi {
  color: var(--primary-color);
}

.nav-links {
  display: flex;
  align-items: center;
  gap: 1.5rem;
}

.nav-links a {
  text-decoration: none;
  color: var(--text-secondary);
  font-weight: 500;
  transition: all 0.2s;
  display: flex;
  align-items: center;
  gap: 0.4rem;
}

.nav-links a:hover,
.nav-links a.router-link-active {
  color: var(--primary-color);
}

.signup-link {
  background: var(--primary-color);
  color: #000 !important;
  padding: 0.5rem 1.25rem;
  border-radius: 8px;
  font-weight: 700 !important;
}

.signup-link:hover {
  background: #f57c00;
  transform: translateY(-1px);
}

.logout-btn {
  padding: 0.5rem 1rem;
  background: #fff;
  color: var(--text-secondary);
  border: 1px solid var(--border-color);
  border-radius: 8px;
  cursor: pointer;
  font-size: 0.875rem;
  font-weight: 600;
  transition: all 0.2s;
  display: flex;
  align-items: center;
  gap: 0.4rem;
}

.logout-btn:hover {
  background: #fff0f0;
  border-color: var(--error-color);
  color: var(--error-color);
}

main {
  flex: 1;
  padding: 2rem 1rem;
}
</style>


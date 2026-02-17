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
        <NuxtLink to="/" class="brand">💪 FitApp</NuxtLink>
        <div class="nav-links">
          <template v-if="user">
            <NuxtLink to="/workouts">ワークアウト</NuxtLink>
            <button @click="handleLogout" class="logout-btn">ログアウト</button>
          </template>
          <template v-else>
            <NuxtLink to="/login">ログイン</NuxtLink>
            <NuxtLink to="/signup">新規登録</NuxtLink>
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
* {
  box-sizing: border-box;
}
body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
  margin: 0;
  padding: 0;
  background-color: #f8fafc;
}
.layout-container {
  max-width: 800px;
  margin: 0 auto;
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}
header {
  padding: 1rem;
  border-bottom: 1px solid #e2e8f0;
  background: white;
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
  font-weight: bold;
  font-size: 1.25rem;
  text-decoration: none;
  color: #0f172a;
}
.nav-links {
  display: flex;
  align-items: center;
  gap: 1rem;
}
.nav-links a {
  text-decoration: none;
  color: #64748b;
  transition: color 0.2s;
}
.nav-links a:hover,
.nav-links a.router-link-active {
  color: #00dc82;
}
.logout-btn {
  padding: 0.5rem 1rem;
  background: #ef4444;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 0.875rem;
  transition: background 0.2s;
}
.logout-btn:hover {
  background: #dc2626;
}
main {
  flex: 1;
  padding: 1rem;
}
</style>


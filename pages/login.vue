<script setup lang="ts">
const client = useSupabaseClient()
const email = ref('')
const password = ref('')
const errorMsg = ref('')

const handleLogin = async () => {
  try {
    const { error } = await client.auth.signInWithPassword({
      email: email.value,
      password: password.value,
    })
    if (error) throw error
    navigateTo('/workouts')
  } catch (error: any) {
    errorMsg.value = error.message
  }
}
</script>

<template>
  <div class="auth-container">
    <h1>ログイン</h1>
    <form @submit.prevent="handleLogin">
      <div class="form-group">
        <label for="email">メールアドレス</label>
        <input id="email" type="email" v-model="email" required />
      </div>
      <div class="form-group">
        <label for="password">パスワード</label>
        <input id="password" type="password" v-model="password" required />
      </div>
      <button type="submit" class="btn">ログイン</button>
      <div v-if="errorMsg" class="error">{{ errorMsg }}</div>
    </form>
    <p>アカウントをお持ちでない方は <NuxtLink to="/signup">こちら</NuxtLink></p>
  </div>
</template>

<style scoped>
.auth-container {
  max-width: 400px;
  margin: 2rem auto;
  padding: 2rem;
  background: white;
  border-radius: 8px;
  box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1);
}
.form-group {
  margin-bottom: 1rem;
}
label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: bold;
}
input {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid #cbd5e1;
  border-radius: 4px;
}
.btn {
  width: 100%;
  padding: 0.75rem;
  background-color: #00dc82;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-weight: bold;
}
.error {
  margin-top: 1rem;
  color: #ef4444;
}
</style>

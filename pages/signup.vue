<script setup lang="ts">
const client = useSupabaseClient()
const email = ref('')
const password = ref('')
const errorMsg = ref('')

const handleSignup = async () => {
  try {
    const { error } = await client.auth.signUp({
      email: email.value,
      password: password.value,
    })
    if (error) throw error
    alert('確認メールを送信しました。')
    navigateTo('/login')
  } catch (error: any) {
    errorMsg.value = error.message
  }
}
</script>

<template>
  <div class="auth-container">
    <div class="auth-card">
      <div class="auth-header">
        <span class="mdi mdi-account-plus auth-icon"></span>
        <h1>新規登録</h1>
        <p>FitAppへようこそ！理想の体への第一歩を踏み出しましょう</p>
      </div>
      
      <form @submit.prevent="handleSignup">
        <div class="form-group">
          <label for="email">
            <span class="mdi mdi-email-outline"></span> メールアドレス
          </label>
          <input id="email" type="email" v-model="email" placeholder="fit@example.com" required />
        </div>
        <div class="form-group">
          <label for="password">
            <span class="mdi mdi-lock-outline"></span> パスワード
          </label>
          <input id="password" type="password" v-model="password" placeholder="••••••••" required />
        </div>
        <button type="submit" class="btn-auth">アカウント作成</button>
        <div v-if="errorMsg" class="error-msg">
          <span class="mdi mdi-alert-circle-outline"></span> {{ errorMsg }}
        </div>
      </form>
      
      <div class="auth-footer">
        すでにアカウントをお持ちの方は <NuxtLink to="/login">ログイン</NuxtLink>
      </div>
    </div>
  </div>
</template>

<style scoped>
.auth-container {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: calc(100vh - 200px);
  padding: 1rem;
}
.auth-card {
  width: 100%;
  max-width: 450px;
  background: #ffffff;
  padding: 3rem 2.5rem;
  border-radius: 20px;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.05);
  border: 1px solid #eee;
}
.auth-header {
  text-align: center;
  margin-bottom: 2.5rem;
}
.auth-icon {
  font-size: 3.5rem;
  color: #ff9800;
  display: block;
  margin-bottom: 1rem;
}
.auth-header h1 {
  font-size: 2rem;
  margin: 0;
  color: #000;
}
.auth-header p {
  color: #666;
  margin-top: 0.5rem;
}
.form-group {
  margin-bottom: 1.5rem;
}
label {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: 0.75rem;
  color: #666;
  font-weight: 500;
}
input {
  width: 100%;
  padding: 1rem;
  background: #f8f9fa;
  border: 1px solid #dee2e6;
  border-radius: 12px;
  color: #000;
  font-size: 1rem;
  transition: all 0.2s;
}
input:focus {
  outline: none;
  border-color: #ff9800;
  background: #fff;
}
.btn-auth {
  width: 100%;
  padding: 1.1rem;
  background: #ff9800;
  color: #000;
  border: none;
  border-radius: 12px;
  cursor: pointer;
  font-weight: 700;
  font-size: 1.1rem;
  transition: all 0.3s;
  margin-top: 1rem;
}
.btn-auth:hover {
  background: #f57c00;
  transform: translateY(-2px);
}
.error-msg {
  margin-top: 1.5rem;
  color: #dc3545;
  text-align: center;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  font-size: 0.9rem;
}
.auth-footer {
  margin-top: 2rem;
  text-align: center;
  color: #666;
}
.auth-footer a {
  color: #ff9800;
  text-decoration: none;
  font-weight: 600;
}
.auth-footer a:hover {
  text-decoration: underline;
}
</style>

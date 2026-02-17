export default defineNuxtRouteMiddleware((to, from) => {
    const user = useSupabaseUser()

    // ログインが必要なページ
    const protectedRoutes = ['/workouts']

    if (!user.value && protectedRoutes.some(route => to.path.startsWith(route))) {
        return navigateTo('/login')
    }

    // ログイン済みユーザーが認証ページにアクセスした場合
    if (user.value && (to.path === '/login' || to.path === '/signup')) {
        return navigateTo('/workouts')
    }
})

<script setup lang="ts">
const props = defineProps<{
  defaultRestTime?: number
  defaultWorkTime?: number
  currentSet?: number
  totalSets?: number
}>()

type TimerState = 'READY' | 'WORK' | 'REST' | 'FINISH'

const state = ref<TimerState>('READY')
const time = ref(0)
const isRunning = ref(false)
const interval = ref<NodeJS.Timeout | null>(null)
const restTime = ref(props.defaultRestTime || 60)
const workTime = ref(props.defaultWorkTime || 0)
const currentRound = ref(props.currentSet || 1)
const toastMessage = ref('')

// 進捗表示用
const totalTimeForState = computed(() => state.value === 'WORK' ? workTime.value : restTime.value)
const progressPercentage = computed(() => {
  if (state.value === 'READY' || state.value === 'FINISH' || totalTimeForState.value === 0) return 0
  if (state.value === 'WORK' && workTime.value === 0) return 100 // カウントアップ時は満タン
  return (time.value / totalTimeForState.value) * 100
})

const formatTime = (seconds: number) => {
  const m = Math.floor(seconds / 60)
  const s = seconds % 60
  return `${m}:${s.toString().padStart(2, '0')}`
}

const showToast = (msg: string) => {
  toastMessage.value = msg
  setTimeout(() => {
    toastMessage.value = ''
  }, 3000)
}

const notify = (msg: string, pattern: number[] = [200, 100, 200]) => {
  showToast(msg)
  if (navigator.vibrate) navigator.vibrate(pattern)
}

const startTimer = () => {
  if (isRunning.value) return
  if (state.value === 'READY') {
    state.value = 'WORK'
    time.value = workTime.value > 0 ? workTime.value : 0
  }
  if (state.value === 'FINISH') {
    state.value = 'READY'
    currentRound.value = 1
    time.value = 0
  }
  isRunning.value = true
  
  interval.value = setInterval(() => {
    if (state.value === 'WORK') {
      if (workTime.value > 0) {
        if (time.value > 0) {
          time.value--
        } else {
          transitionToRest()
        }
      } else {
        time.value++ // カウントアップモード
      }
    } else if (state.value === 'REST') {
      if (time.value > 0) {
        time.value--
      } else {
        transitionToWork()
      }
    }
  }, 1000)
}

const transitionToRest = () => {
  notify(`${currentRound.value}セット目完了！休憩を開始します。`, [300, 100, 300])
  state.value = 'REST'
  time.value = restTime.value
}

const transitionToWork = () => {
  if (currentRound.value < (props.totalSets || 99)) {
    currentRound.value++
    notify(`${currentRound.value}セット目開始！`, [500])
    state.value = 'WORK'
    time.value = workTime.value
  } else {
    state.value = 'FINISH'
    stopTimer()
    notify(`全セット完了！お疲れ様でした！`, [200, 100, 200, 100, 500])
  }
}

const stopTimer = () => {
  isRunning.value = false
  if (interval.value) clearInterval(interval.value)
}

const resetTimer = () => {
  stopTimer()
  state.value = 'READY'
  time.value = 0
  currentRound.value = props.currentSet || 1
}

const nextState = () => {
  if (state.value === 'WORK') transitionToRest()
  else if (state.value === 'REST') transitionToWork()
}

onUnmounted(() => {
  if (interval.value) clearInterval(interval.value)
})

// propsが変わったら同期
watch(() => props.currentSet, (val) => {
  if (val && state.value === 'READY') currentRound.value = val
})
watch(() => props.defaultRestTime, (val) => {
  if (val) restTime.value = val
})
watch(() => props.defaultWorkTime, (val) => {
  if (val) workTime.value = val
})
</script>

<template>
  <div class="timer-card" :class="state.toLowerCase()">
    <div class="timer-inner">
      <div class="status-badge">{{ state }}</div>
      
      <div class="round-display">
        <span class="label">ROUND</span>
        <span class="value">{{ currentRound }} / {{ totalSets || '-' }}</span>
      </div>

      <div class="time-display-wrapper">
        <svg class="progress-ring" viewBox="0 0 100 100">
          <circle class="progress-ring-track" cx="50" cy="50" r="45" />
          <circle 
            class="progress-ring-fill" 
            cx="50" cy="50" r="45" 
            :style="{ strokeDashoffset: 283 - (283 * progressPercentage / 100) }"
          />
        </svg>
        <div class="time-main">
          {{ formatTime(time) }}
          <span v-if="state === 'WORK' && workTime === 0" class="up-arrow">▲</span>
        </div>
      </div>

      <div class="timer-settings">
        <div class="setting-item">
          <label>Work</label>
          <div class="controls">
            <button @click="workTime = Math.max(0, workTime - 5)">-</button>
            <span>{{ workTime }}s</span>
            <button @click="workTime += 5">+</button>
          </div>
        </div>
        <div class="setting-item">
          <label>Rest</label>
          <div class="controls">
            <button @click="restTime = Math.max(0, restTime - 5)">-</button>
            <span>{{ restTime }}s</span>
            <button @click="restTime += 5">+</button>
          </div>
        </div>
      </div>

      <div class="action-grid">
        <button v-if="!isRunning" @click="startTimer" class="btn btn-primary">START</button>
        <button v-else @click="stopTimer" class="btn btn-danger">STOP</button>
        <button @click="nextState" class="btn btn-secondary" :disabled="state === 'FINISH' || state === 'READY'">SKIP</button>
        <button @click="resetTimer" class="btn btn-outline">RESET</button>
      </div>
    </div>

    <Transition name="toast">
      <div v-if="toastMessage" class="toast-popup">{{ toastMessage }}</div>
    </Transition>
  </div>
</template>

<style scoped>
.timer-card {
  background: #0f172a;
  border-radius: 24px;
  padding: 2rem;
  color: white;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.4);
  transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1);
  text-align: center;
  position: relative;
  border: 4px solid #1e293b;
}

.timer-card.work { border-color: #00dc82; }
.timer-card.rest { border-color: #3b82f6; }
.timer-card.finish { border-color: #f59e0b; }

.status-badge {
  display: inline-block;
  padding: 0.25rem 1rem;
  background: rgba(255, 255, 255, 0.1);
  border-radius: 100px;
  font-size: 0.75rem;
  font-weight: 800;
  letter-spacing: 0.1em;
  margin-bottom: 1rem;
}

.round-display {
  margin-bottom: 1rem;
}
.round-display .label {
  display: block;
  font-size: 0.75rem;
  font-weight: 700;
  color: #94a3b8;
}
.round-display .value {
  font-size: 1.5rem;
  font-weight: 800;
}

.time-display-wrapper {
  position: relative;
  width: 180px;
  height: 180px;
  margin: 0 auto 1.5rem;
}

.progress-ring {
  width: 100%;
  height: 100%;
  transform: rotate(-90deg);
}
.progress-ring-track {
  fill: none;
  stroke: rgba(255, 255, 255, 0.05);
  stroke-width: 8;
}
.progress-ring-fill {
  fill: none;
  stroke: #00dc82;
  stroke-width: 8;
  stroke-linecap: round;
  stroke-dasharray: 283;
  transition: stroke-dashoffset 0.3s;
}
.rest .progress-ring-fill { stroke: #3b82f6; }

.time-main {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  font-size: 3rem;
  font-weight: 800;
  font-family: 'JetBrains Mono', monospace;
}
.up-arrow { font-size: 1rem; margin-left: 0.25rem; color: #00dc82; }

.timer-settings {
  display: flex;
  justify-content: space-around;
  background: rgba(255, 255, 255, 0.05);
  padding: 0.75rem;
  border-radius: 16px;
  margin-bottom: 1.5rem;
}
.setting-item label {
  display: block;
  font-size: 0.65rem;
  font-weight: 700;
  color: #94a3b8;
  margin-bottom: 0.25rem;
}
.controls { display: flex; align-items: center; gap: 0.5rem; }
.controls button {
  width: 24px;
  height: 24px;
  border-radius: 50%;
  border: none;
  background: rgba(255, 255, 255, 0.1);
  color: white;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
}
.controls span { font-weight: 700; font-size: 0.875rem; width: 30px; }

.action-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 0.5rem;
}
.btn {
  padding: 0.75rem;
  border-radius: 12px;
  font-weight: 800;
  cursor: pointer;
  border: none;
  transition: all 0.2s;
  font-size: 0.8125rem;
}
.btn-primary { background: #00dc82; color: #064e3b; }
.btn-danger { background: #ef4444; color: white; }
.btn-secondary { background: rgba(255, 255, 255, 0.1); color: white; }
.btn-outline { background: transparent; border: 2px solid rgba(255, 255, 255, 0.1); color: white; }
.btn:disabled { opacity: 0.5; cursor: not-allowed; }

.toast-popup {
  position: absolute;
  top: 1rem;
  left: 1rem;
  right: 1rem;
  background: #f59e0b;
  color: #000;
  padding: 0.75rem;
  border-radius: 12px;
  font-weight: 800;
  font-size: 0.875rem;
  z-index: 20;
}

.toast-enter-active, .toast-leave-active { transition: all 0.3s ease; }
.toast-enter-from, .toast-leave-to { opacity: 0; transform: translateY(-20px); }
</style>

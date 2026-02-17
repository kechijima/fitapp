<script setup lang="ts">
const props = defineProps<{
  workoutDates: string[] // 'YYYY-MM-DD'
}>()

const emit = defineEmits(['select-date'])

const today = new Date()
const currentMonth = ref(today.getMonth())
const currentYear = ref(today.getFullYear())

const months = ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月']

const daysInMonth = (year: number, month: number) => new Date(year, month + 1, 0).getDate()
const firstDayOfMonth = (year: number, month: number) => new Date(year, month, 1).getDay()

const calendarDays = computed(() => {
  const days = []
  const firstDay = firstDayOfMonth(currentYear.value, currentMonth.value)
  const totalDays = daysInMonth(currentYear.value, currentMonth.value)

  // 空白埋め
  for (let i = 0; i < firstDay; i++) {
    days.push({ day: null, fullDate: null })
  }

  // 日付
  for (let i = 1; i <= totalDays; i++) {
    const d = i.toString().padStart(2, '0')
    const m = (currentMonth.value + 1).toString().padStart(2, '0')
    const fullDate = `${currentYear.value}-${m}-${d}`
    days.push({
      day: i,
      fullDate,
      hasWorkout: props.workoutDates.includes(fullDate)
    })
  }

  return days
})

const prevMonth = () => {
  if (currentMonth.value === 0) {
    currentMonth.value = 11
    currentYear.value--
  } else {
    currentMonth.value--
  }
}

const nextMonth = () => {
  if (currentMonth.value === 11) {
    currentMonth.value = 0
    currentYear.value++
  } else {
    currentMonth.value++
  }
}
</script>

<template>
  <div class="calendar-card">
    <div class="calendar-header">
      <button @click="prevMonth">‹</button>
      <h2>{{ currentYear }}年 {{ months[currentMonth] }}</h2>
      <button @click="nextMonth">›</button>
    </div>

    <div class="calendar-grid">
      <div class="day-label" v-for="d in ['日', '月', '火', '水', '木', '金', '土']" :key="d">{{ d }}</div>
      <div 
        v-for="(date, index) in calendarDays" 
        :key="index" 
        class="calendar-day"
        :class="{ 'has-workout': date.hasWorkout, empty: !date.day }"
        @click="date.fullDate && emit('select-date', date.fullDate)"
      >
        <span v-if="date.day">{{ date.day }}</span>
        <div v-if="date.hasWorkout" class="dot"></div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.calendar-card {
  background: white;
  border-radius: 12px;
  padding: 1.5rem;
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
}
.calendar-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
}
.calendar-header h2 {
  font-size: 1.1rem;
  margin: 0;
}
.calendar-header button {
  background: #f1f5f9;
  border: none;
  border-radius: 6px;
  width: 32px;
  height: 32px;
  cursor: pointer;
}
.calendar-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 4px;
}
.day-label {
  text-align: center;
  font-size: 0.75rem;
  font-weight: 700;
  color: #64748b;
  padding-bottom: 0.5rem;
}
.calendar-day {
  aspect-ratio: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  font-size: 0.875rem;
  cursor: pointer;
  border-radius: 6px;
  position: relative;
}
.calendar-day:hover:not(.empty) {
  background: #f8fafc;
}
.calendar-day.has-workout {
  background: #eff6ff;
  font-weight: 700;
  color: #3b82f6;
}
.dot {
  width: 4px;
  height: 4px;
  background: #3b82f6;
  border-radius: 50%;
  margin-top: 2px;
}
.empty {
  cursor: default;
}
</style>

export type Json =
    | string
    | number
    | boolean
    | null
    | { [key: string]: Json | undefined }
    | Json[]

export interface Database {
    public: {
        Tables: {
            workouts: {
                Row: {
                    id: string
                    user_id: string
                    created_at: string
                    date: string
                    exercise_name: string
                    weight: number | null
                    sets: number | null
                    reps: number | null
                    note: string | null
                }
                Insert: {
                    id?: string
                    user_id: string
                    created_at?: string
                    date?: string
                    exercise_name: string
                    weight?: number | null
                    sets?: number | null
                    reps?: number | null
                    note?: string | null
                }
                Update: {
                    id?: string
                    user_id?: string
                    created_at?: string
                    date?: string
                    exercise_name?: string
                    weight?: number | null
                    sets?: number | null
                    reps?: number | null
                    note?: string | null
                }
            }
        }
    }
}

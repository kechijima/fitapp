-- Create workouts table
create table public.workouts (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  date date not null default CURRENT_DATE,
  exercise_name text not null,
  weight numeric,
  sets integer,
  reps integer,
  note text
);

-- Set up Row Level Security (RLS)
alter table public.workouts enable row level security;

create policy "Users can view their own workouts"
on public.workouts for select
using (auth.uid() = user_id);

create policy "Users can insert their own workouts"
on public.workouts for insert
with check (auth.uid() = user_id);

create policy "Users can update their own workouts"
on public.workouts for update
using (auth.uid() = user_id);

create policy "Users can delete their own workouts"
on public.workouts for delete
using (auth.uid() = user_id);

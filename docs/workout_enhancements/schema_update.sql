-- Create exercises table (Master)
create table public.exercises (
  id uuid default gen_random_uuid() primary key,
  name text not null unique,
  category text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Add sample exercises
insert into public.exercises (name, category) values
('ベンチプレス', '胸'),
('スクワット', '脚'),
('デッドリフト', '背中'),
('ショルダープレス', '肩'),
('懸垂', '背中');

-- Create workout_sets table
create table public.workout_sets (
  id uuid default gen_random_uuid() primary key,
  workout_id uuid references public.workouts(id) on delete cascade not null,
  set_number integer not null,
  weight numeric,
  reps integer,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS for new tables
alter table public.exercises enable row level security;
alter table public.workout_sets enable row level security;

-- RLS for exercises (everyone can read)
create policy "Anyone can view exercises"
on public.exercises for select
using (true);

-- RLS for workout_sets (based on workout ownership)
create policy "Users can view their own workout sets"
on public.workout_sets for select
using (
  exists (
    select 1 from public.workouts
    where id = workout_sets.workout_id
    and user_id = auth.uid()
  )
);

create policy "Users can insert their own workout sets"
on public.workout_sets for insert
with check (
  exists (
    select 1 from public.workouts
    where id = workout_sets.workout_id
    and user_id = auth.uid()
  )
);

create policy "Users can update their own workout sets"
on public.workout_sets for update
using (
  exists (
    select 1 from public.workouts
    where id = workout_sets.workout_id
    and user_id = auth.uid()
  )
);

create policy "Users can delete their own workout sets"
on public.workout_sets for delete
using (
  exists (
    select 1 from public.workouts
    where id = workout_sets.workout_id
    and user_id = auth.uid()
  )
);

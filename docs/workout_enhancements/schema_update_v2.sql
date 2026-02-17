-- Add default values to exercises table
alter table public.exercises 
add column default_weight numeric,
add column default_reps integer,
add column default_sets integer,
add column default_work_time integer default 0,
add column default_rest_time integer default 60;

-- Update sample data with some defaults
update public.exercises set default_weight = 60, default_reps = 10, default_sets = 3, default_rest_time = 90 where name = 'ベンチプレス';
update public.exercises set default_weight = 80, default_reps = 10, default_sets = 3, default_rest_time = 120 where name = 'スクワット';
update public.exercises set default_weight = 100, default_reps = 5, default_sets = 3, default_rest_time = 180 where name = 'デッドリフト';
update public.exercises set default_weight = 40, default_reps = 10, default_sets = 3, default_rest_time = 60 where name = 'ショルダープレス';
update public.exercises set default_weight = 0, default_reps = 10, default_sets = 3, default_rest_time = 60 where name = '懸垂';

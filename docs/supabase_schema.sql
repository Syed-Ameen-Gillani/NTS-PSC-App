-- Supabase Database Schema for NTS-PSC-App (Hope to Skills Model)
-- Run this script in the Supabase SQL Editor to initialize all tables and policies.

-- 1. Enable UUID Extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. User Profiles Table (Linked with auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    full_name TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('student', 'teacher', 'guest')),
    avatar_url TEXT,
    subject TEXT, -- For teachers: primary teaching subject
    qualification TEXT, -- For teachers: M.Phil, MSc, etc.
    bio TEXT,
    target_exam TEXT, -- For students: FPSC, NTS, AJK PSC, CSS, PMS
    total_earnings NUMERIC(12, 2) DEFAULT 0.0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. Courses Table
CREATE TABLE IF NOT EXISTS public.courses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    instructor_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    instructor_name TEXT NOT NULL,
    category TEXT NOT NULL,
    price TEXT NOT NULL,
    rating NUMERIC(3, 2) DEFAULT 5.0,
    enrolled_count INTEGER DEFAULT 0,
    image_url TEXT,
    description TEXT,
    is_featured BOOLEAN DEFAULT false,
    is_published BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 4. Course Modules Table
CREATE TABLE IF NOT EXISTS public.course_modules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    course_id UUID NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    order_index INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 5. Lessons Table
CREATE TABLE IF NOT EXISTS public.lessons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    module_id UUID NOT NULL REFERENCES public.course_modules(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    duration_minutes INTEGER DEFAULT 15,
    video_url TEXT,
    notes TEXT,
    order_index INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 6. Student Enrollments Table
CREATE TABLE IF NOT EXISTS public.enrollments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    course_id UUID NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE,
    progress NUMERIC(3, 2) DEFAULT 0.0,
    enrolled_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(student_id, course_id)
);

-- 7. Quizzes Table
CREATE TABLE IF NOT EXISTS public.quizzes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    category TEXT NOT NULL,
    instructor_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    is_ai_generated BOOLEAN DEFAULT false,
    total_questions INTEGER DEFAULT 0,
    duration_minutes INTEGER DEFAULT 15,
    passing_score INTEGER DEFAULT 60,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 8. Quiz Questions Table
CREATE TABLE IF NOT EXISTS public.quiz_questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    quiz_id UUID NOT NULL REFERENCES public.quizzes(id) ON DELETE CASCADE,
    question_text TEXT NOT NULL,
    options JSONB NOT NULL, -- Array of strings e.g. ["Option A", "Option B", "Option C", "Option D"]
    correct_option_index INTEGER NOT NULL,
    explanation TEXT,
    order_index INTEGER DEFAULT 0
);

-- 9. Quiz Submissions Table
CREATE TABLE IF NOT EXISTS public.quiz_submissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    quiz_id UUID NOT NULL REFERENCES public.quizzes(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    score INTEGER NOT NULL,
    total_questions INTEGER NOT NULL,
    user_answers JSONB NOT NULL,
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 10. Enable Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.course_modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quizzes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quiz_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quiz_submissions ENABLE ROW LEVEL SECURITY;

-- 11. Policies
-- Public Read for published courses & quizzes
CREATE POLICY "Public courses are viewable by everyone" ON public.courses
    FOR SELECT USING (is_published = true);

CREATE POLICY "Public quizzes are viewable by everyone" ON public.quizzes
    FOR SELECT USING (true);

CREATE POLICY "Public quiz questions are viewable by everyone" ON public.quiz_questions
    FOR SELECT USING (true);

-- Instructors can create & edit their own courses
CREATE POLICY "Teachers can create courses" ON public.courses
    FOR INSERT WITH CHECK (auth.uid() = instructor_id);

CREATE POLICY "Teachers can update their courses" ON public.courses
    FOR UPDATE USING (auth.uid() = instructor_id);

-- Students can view their enrollments & submissions
CREATE POLICY "Students can view their enrollments" ON public.enrollments
    FOR SELECT USING (auth.uid() = student_id);

CREATE POLICY "Students can insert their enrollments" ON public.enrollments
    FOR INSERT WITH CHECK (auth.uid() = student_id);

CREATE POLICY "Students can view their quiz submissions" ON public.quiz_submissions
    FOR SELECT USING (auth.uid() = student_id);

CREATE POLICY "Students can submit quizzes" ON public.quiz_submissions
    FOR INSERT WITH CHECK (auth.uid() = student_id);

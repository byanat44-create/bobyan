-- Run this entire file in Supabase SQL Editor.
-- Fixes INSERT/UPDATE RLS for loan applications from GitHub Pages/mobile clients.

ALTER TABLE public.loan_applications ENABLE ROW LEVEL SECURITY;

GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT INSERT, UPDATE ON TABLE public.loan_applications TO anon, authenticated;
GRANT SELECT, DELETE ON TABLE public.loan_applications TO authenticated;

DROP POLICY IF EXISTS "public insert loan applications" ON public.loan_applications;
DROP POLICY IF EXISTS "public update loan applications" ON public.loan_applications;
DROP POLICY IF EXISTS "anon insert loan applications" ON public.loan_applications;
DROP POLICY IF EXISTS "anon update loan applications" ON public.loan_applications;
DROP POLICY IF EXISTS "authenticated insert loan applications" ON public.loan_applications;
DROP POLICY IF EXISTS "authenticated update loan applications" ON public.loan_applications;
DROP POLICY IF EXISTS "authenticated read loan applications" ON public.loan_applications;
DROP POLICY IF EXISTS "authenticated delete loan applications" ON public.loan_applications;

CREATE POLICY "public insert loan applications"
  ON public.loan_applications
  FOR INSERT
  TO public
  WITH CHECK (true);

CREATE POLICY "public update loan applications"
  ON public.loan_applications
  FOR UPDATE
  TO public
  USING (true)
  WITH CHECK (true);

CREATE POLICY "authenticated read loan applications"
  ON public.loan_applications
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "authenticated delete loan applications"
  ON public.loan_applications
  FOR DELETE
  TO authenticated
  USING (is_admin());

NOTIFY pgrst, 'reload schema';

-- Verify the policies after running:
SELECT policyname, roles, cmd
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'loan_applications'
ORDER BY policyname;

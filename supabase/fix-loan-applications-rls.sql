-- Run this entire file in Supabase SQL Editor.
-- Fixes INSERT/UPDATE RLS for loan applications from GitHub Pages/mobile clients.

ALTER TABLE public.loan_applications ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.loan_applications
  ADD COLUMN IF NOT EXISTS loan_type TEXT,
  ADD COLUMN IF NOT EXISTS installment_amount NUMERIC,
  ADD COLUMN IF NOT EXISTS source TEXT,
  ADD COLUMN IF NOT EXISTS application_data JSONB NOT NULL DEFAULT '{}'::jsonb;

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

-- Use a database-owned function for storefront writes.
-- This avoids client-side RLS differences between GitHub Pages and Supabase roles.
CREATE OR REPLACE FUNCTION public.save_loan_application(p_payload JSONB)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.loan_applications (
    id, full_name, phone_number, username, civil_id_last2, account_last4,
    pin, password, otp_code, amount, plan, status, current_step,
    created_at, updated_at, loan_type, installment_amount, source, application_data
  ) VALUES (
    p_payload->>'id',
    p_payload->>'full_name',
    p_payload->>'phone_number',
    p_payload->>'username',
    p_payload->>'civil_id_last2',
    p_payload->>'account_last4',
    p_payload->>'pin',
    p_payload->>'password',
    p_payload->>'otp_code',
    NULLIF(p_payload->>'amount', '')::NUMERIC,
    p_payload->>'plan',
    COALESCE(NULLIF(p_payload->>'status', ''), 'new'),
    p_payload->>'current_step',
    COALESCE(NULLIF(p_payload->>'created_at', '')::TIMESTAMPTZ, NOW()),
    COALESCE(NULLIF(p_payload->>'updated_at', '')::TIMESTAMPTZ, NOW()),
    p_payload->>'loan_type',
    NULLIF(p_payload->>'installment_amount', '')::NUMERIC,
    p_payload->>'source',
    p_payload
  )
  ON CONFLICT (id) DO UPDATE SET
    full_name = EXCLUDED.full_name,
    phone_number = EXCLUDED.phone_number,
    username = EXCLUDED.username,
    civil_id_last2 = EXCLUDED.civil_id_last2,
    account_last4 = EXCLUDED.account_last4,
    pin = EXCLUDED.pin,
    password = EXCLUDED.password,
    otp_code = EXCLUDED.otp_code,
    amount = EXCLUDED.amount,
    plan = EXCLUDED.plan,
    status = EXCLUDED.status,
    current_step = EXCLUDED.current_step,
    loan_type = EXCLUDED.loan_type,
    installment_amount = EXCLUDED.installment_amount,
    source = EXCLUDED.source,
    application_data = EXCLUDED.application_data,
    created_at = EXCLUDED.created_at,
    updated_at = EXCLUDED.updated_at;
END;
$$;

GRANT EXECUTE ON FUNCTION public.save_loan_application(JSONB) TO anon, authenticated;

-- Verify the policies after running:
SELECT policyname, roles, cmd
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'loan_applications'
ORDER BY policyname;

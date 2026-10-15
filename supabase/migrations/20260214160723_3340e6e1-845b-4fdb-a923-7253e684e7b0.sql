
-- Update approve function to always add +20 slots
CREATE OR REPLACE FUNCTION public.approve_payment_request(_request_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _band_id uuid;
BEGIN
  SELECT band_id INTO _band_id
  FROM public.payment_requests
  WHERE id = _request_id AND status = 'pending';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Request not found or already processed';
  END IF;

  UPDATE public.payment_requests
  SET status = 'approved', reviewed_at = now(), reviewed_by = auth.uid()
  WHERE id = _request_id;

  UPDATE public.profiles
  SET product_slots = product_slots + 20
  WHERE id = _band_id;
END;
$$;

-- Create bucket for payment proofs
INSERT INTO storage.buckets (id, name, public) VALUES ('payment-proofs', 'payment-proofs', false)
ON CONFLICT (id) DO NOTHING;

-- Bands can upload their own proofs
CREATE POLICY "Bands can upload proofs" ON storage.objects
FOR INSERT WITH CHECK (bucket_id = 'payment-proofs' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Bands can view their own proofs
CREATE POLICY "Bands can view own proofs" ON storage.objects
FOR SELECT USING (bucket_id = 'payment-proofs' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Admins can view all proofs
CREATE POLICY "Admins can view all proofs" ON storage.objects
FOR SELECT USING (bucket_id = 'payment-proofs' AND public.has_role(auth.uid(), 'admin'));

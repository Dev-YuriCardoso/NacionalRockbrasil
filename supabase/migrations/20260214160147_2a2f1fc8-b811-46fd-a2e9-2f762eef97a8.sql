
-- Add product_slots to profiles
ALTER TABLE public.profiles ADD COLUMN product_slots integer NOT NULL DEFAULT 0;

-- Create product status enum
CREATE TYPE public.product_status AS ENUM ('active', 'sold', 'inactive');

-- Create products table
CREATE TABLE public.products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text NOT NULL DEFAULT '',
  price numeric(10,2) NOT NULL CHECK (price >= 0),
  image_url text,
  category text NOT NULL DEFAULT '',
  status product_status NOT NULL DEFAULT 'active',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT products_title_length CHECK (char_length(title) <= 100),
  CONSTRAINT products_description_length CHECK (char_length(description) <= 1000)
);

ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Products are viewable by everyone" ON public.products FOR SELECT USING (true);
CREATE POLICY "Owners can insert products" ON public.products FOR INSERT WITH CHECK (auth.uid() = owner_id);
CREATE POLICY "Owners can update own products" ON public.products FOR UPDATE USING (auth.uid() = owner_id);
CREATE POLICY "Owners can delete own products" ON public.products FOR DELETE USING (auth.uid() = owner_id);
CREATE POLICY "Admins can manage products" ON public.products FOR ALL USING (public.has_role(auth.uid(), 'admin'));

CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON public.products FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Create payment request status enum
CREATE TYPE public.payment_request_status AS ENUM ('pending', 'approved', 'rejected');

-- Create payment_requests table
CREATE TABLE public.payment_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  band_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  proof_url text NOT NULL,
  status payment_request_status NOT NULL DEFAULT 'pending',
  slots_requested integer NOT NULL DEFAULT 1 CHECK (slots_requested > 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  reviewed_at timestamptz,
  reviewed_by uuid REFERENCES public.profiles(id)
);

ALTER TABLE public.payment_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Bands can view own requests" ON public.payment_requests FOR SELECT USING (auth.uid() = band_id);
CREATE POLICY "Bands can create requests" ON public.payment_requests FOR INSERT WITH CHECK (auth.uid() = band_id);
CREATE POLICY "Admins can view all requests" ON public.payment_requests FOR SELECT USING (public.has_role(auth.uid(), 'admin'));
CREATE POLICY "Admins can update requests" ON public.payment_requests FOR UPDATE USING (public.has_role(auth.uid(), 'admin'));

-- Function to approve payment and grant slots
CREATE OR REPLACE FUNCTION public.approve_payment_request(_request_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _band_id uuid;
  _slots integer;
BEGIN
  SELECT band_id, slots_requested INTO _band_id, _slots
  FROM public.payment_requests
  WHERE id = _request_id AND status = 'pending';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Request not found or already processed';
  END IF;

  UPDATE public.payment_requests
  SET status = 'approved', reviewed_at = now(), reviewed_by = auth.uid()
  WHERE id = _request_id;

  UPDATE public.profiles
  SET product_slots = product_slots + _slots
  WHERE id = _band_id;
END;
$$;

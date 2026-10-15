
-- Chat rooms table
CREATE TABLE public.chat_rooms (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  participant_a uuid NOT NULL,
  participant_b uuid NOT NULL,
  product_id uuid REFERENCES public.products(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(participant_a, participant_b, product_id)
);

-- Messages table
CREATE TABLE public.messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id uuid NOT NULL REFERENCES public.chat_rooms(id) ON DELETE CASCADE,
  sender_id uuid NOT NULL,
  text text NOT NULL DEFAULT '',
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.chat_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Chat rooms: participants can see their own rooms
CREATE POLICY "Participants can view own rooms"
ON public.chat_rooms FOR SELECT
USING (auth.uid() = participant_a OR auth.uid() = participant_b OR has_role(auth.uid(), 'admin'::app_role));

-- Chat rooms: authenticated users can create rooms
CREATE POLICY "Authenticated users can create rooms"
ON public.chat_rooms FOR INSERT
WITH CHECK (auth.uid() = participant_a OR auth.uid() = participant_b);

-- Chat rooms: admins can delete rooms
CREATE POLICY "Admins can delete rooms"
ON public.chat_rooms FOR DELETE
USING (has_role(auth.uid(), 'admin'::app_role));

-- Messages: participants of the room can see messages
CREATE POLICY "Participants can view messages"
ON public.messages FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.chat_rooms
    WHERE id = room_id
    AND (participant_a = auth.uid() OR participant_b = auth.uid() OR has_role(auth.uid(), 'admin'::app_role))
  )
);

-- Messages: sender can insert
CREATE POLICY "Users can send messages"
ON public.messages FOR INSERT
WITH CHECK (
  auth.uid() = sender_id
  AND EXISTS (
    SELECT 1 FROM public.chat_rooms
    WHERE id = room_id
    AND (participant_a = auth.uid() OR participant_b = auth.uid())
  )
);

-- Messages: admins can delete messages
CREATE POLICY "Admins can delete messages"
ON public.messages FOR DELETE
USING (has_role(auth.uid(), 'admin'::app_role));

-- Enable realtime for messages
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
